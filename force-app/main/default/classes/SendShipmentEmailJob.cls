public class SendShipmentEmailJob implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public String startDt;
    public String endDt;
    public String orderNumber;
    public final String FULFILLED = 'Fulfilled';
    public final String ORDER_LIFE_CYCLE_TYPE_MANAGED = 'MANAGED';
    public final String CLASS_NAME = SendShipmentEmailJob.class.getName();
    Map<String, Object> accessToken;
    public final String GATEWAY_SUCCESS = 'Successfully sent SFMC Shipment email';
    public final String GATEWAY_FAIL = 'Failed to send SFMC Shipment email';
    public final String ERROR_MESSAGE = 'SFMC Shipment email failed to send and it\'s Order Summary Id: ';
    
    public SendShipmentEmailJob() {}
    
    public SendShipmentEmailJob(String startDt, String endDt) {
        this.startDt = startDt.replace(' ', 'T') + 'Z';
        this.endDt = endDt.replace(' ', 'T') + 'Z';
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        TimeZone tz = Timezone.getTimeZone('America/Los_Angeles');
        Integer offSet = tz.getOffSet(DateTime.now())/(60*60*1000);//offSet in hours
        DateTime todayDT = DateTime.now();
        String currentDayStartDateTime = Datetime.newInstanceGmt(todayDT.yearGmt(), todayDT.monthGmt(),todayDT.dayGmt(), 0 + Math.abs(offset), 0, 0).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String createdDateWhereClause = ' AND CreatedDate >= ' + currentDayStartDateTime;
        Database.QueryLocator queryResult;
        createdDateWhereClause = !String.isBlank(startDt) && !String.isBlank(endDt) ? 
            ' AND CreatedDate >= ' + this.startDt + ' AND CreatedDate <= ' + this.endDt : createdDateWhereClause;
        
        try {
            queryResult = Database.getQueryLocator(
                'SELECT Id FROM Shipment WHERE OrderSummary.Status = :FULFILLED  AND FulfillmentOrder.Status =  :FULFILLED AND TrackingUrl != NULL ' +
                'AND OrderSummary.SFMC_Shipment_Email_Sent__c = false AND OrderSummary.OrderLifeCycleType =  :ORDER_LIFE_CYCLE_TYPE_MANAGED ' +
                createdDateWhereClause + 
                ' ORDER BY CreatedDate ASC LIMIT 50');
        } catch(Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return queryResult;
    }
   
    public void execute(Database.BatchableContext bc, List<Shipment> shipmentList) {
        this.accessToken = CloudX.getSfmcAccessToken();
        triggerEmail(shipmentList);
    }
    
    public void finish(Database.BatchableContext bc){
        //Any Post Processing Operations
    }

    public void triggerEmail(List<Shipment> shipmentList) {
        String osId;
        Integer statusCode;
        HttpResponse res;
        CloudXSfmcTrigger.TriggerContext ctx;
        GenericGatewayLog__c log;
        List<Id> shipmentIds = new List<Id>();
        Map<String, ShipmentAndItems> tupleByShipmentId = new Map<String, ShipmentAndItems>();
        Map<Id, Id> shipmentIdByfoId = new Map<Id, Id>();
        Set<String> osIds = new Set<String>();
        Map<String, String> paymentTypeMap = new Map<String, String>();
        List<GenericGatewayLog__c> logList = new List<GenericGatewayLog__c>();
        Set<Id> osIdsToUpdate = new Set<Id>();
        List<Map<String, Object>> orders;
        String errorMessage;
        
        try {
            //Make a Map of Shipment and FO and a list of all Order Summaries
            for (Shipment s : [SELECT Id, FulfillmentOrderId, TrackingNumber, TrackingUrl,
                FulfillmentOrder.OrderSummary.CreatedDate, FulfillmentOrder.OrderSummary.Id, FulfillmentOrder.OrderSummary.OrderNumber, FulfillmentOrder.FulfilledToAddress,
                FulfillmentOrder.FulfilledToName, FulfillmentOrder.FulfilledToStreet, 
                FulfillmentOrder.FulfilledToCity, FulfillmentOrder.OrderSummary.OriginalOrderId,
                FulfillmentOrder.FulfilledToState, FulfillmentOrder.FulfilledToPostalCode, FulfillmentOrder.FulfilledToCountry, 
                FulfillmentOrder.AccountId, FulfillmentOrder.Account.Name, FulfillmentOrder.Account.AccountNumber, FulfillmentOrder.Type,
                FulfillmentOrder.Account.FirstName, FulfillmentOrder.Account.LastName, 
                FulfillmentOrder.OrderSummary.GrandTotalAmount, FulfillmentOrder.OrderSummary.SalesChannelId,
                FulfillmentOrder.OrderSummary.SalesChannel.SalesChannelName,FulfillmentOrder.OrderSummary.BillingEmailAddress,
                FulfillmentOrder.OrderSummary.BillingStreet, FulfillmentOrder.OrderSummary.BillingCity, 
                FulfillmentOrder.OrderSummary.BillingState, FulfillmentOrder.OrderSummary.BillingPostalCode, 
                FulfillmentOrder.OrderSummary.BillingCountry, FulfillmentOrder.OrderSummary.CurrencyIsoCode,
                FulfillmentOrder.OrderSummary.Account.ContactID__pc, FulfillmentOrder.OrderSummary.Account.Name,
                FulfillmentOrder.OrderSummary.TotalAmount, FulfillmentOrder.OrderSummary.TotalTaxAmount
                FROM Shipment WHERE TrackingUrl != NULL AND Id IN :shipmentList]) {
                ShipmentAndItems tuple = new ShipmentAndItems(s, new List<FulfillmentOrderLineItem>());
                tupleByShipmentId.put(s.Id, tuple);
                shipmentIdByfoId.put(s.FulfillmentOrderId, s.Id);
                osIds.add(s.FulfillmentOrder.OrderSummary.Id);
            }

            //Collect FO line items by Shipment ID
            for (FulfillmentOrderLineItem item : [
                SELECT Quantity, TotalPrice, Description, FulfillmentOrderId, Product2.ProductCode 
                FROM FulfillmentOrderLineItem WHERE FulfillmentOrderId In :shipmentIdByfoId.keySet()]) {
                if (!tupleByShipmentId.containsKey(shipmentIdByfoId.get(item.FulfillmentOrderId))) { continue; }
                ShipmentAndItems tuple = tupleByShipmentId.get(shipmentIdByfoId.get(item.FulfillmentOrderId));
                tuple.items.add(item);
                tupleByShipmentId.put(shipmentIdByfoId.get(item.FulfillmentOrderId), tuple);
            }
            
            //fetch the payment info by Order Summary ID
            for(OrderPaymentSummary ops : [SELECT Id, Method, Type, OrderSummaryId FROM OrderPaymentSummary WHERE OrderSummaryId IN :osIds]) {
                paymentTypeMap.put(ops.OrderSummaryId, ops.Type);
            }
            
            //Process the Shipments and send email
            for (ShipmentAndItems tuple : tupleByShipmentId.values()) {
                orders = new List<Map<String, Object>>();
                try {
                    ctx = new CloudXSfmcTrigger.TriggerContext(null, this.accessToken, null);
                    Shipment shipment = tuple.shipment;
                    FulfillmentOrder fo = shipment.FulfillmentOrder;
                    OrderSummary s = fo.OrderSummary;
                    osId = fo.OrderSummary.Id;

                    // get addr
                    Map<String, String> addr = new Map<String, String>();
                    MapX.putIfNotNull(addr, 'bill_to_customer_nbr', fo.Account.AccountNumber);
                    MapX.putIfNotNull(addr, 'bill_to_fname', fo.Account.FirstName);
                    MapX.putIfNotNull(addr, 'bill_to_lname', fo.Account.LastName);
                    MapX.putIfNotNull(addr, 'bill_to_company', fo.Account.Name);
                    MapX.putIfNotNull(addr, 'bill_to_addr1', s.BillingStreet);
                    MapX.putIfNotNull(addr, 'bill_to_city', s.BillingCity);
                    MapX.putIfNotNull(addr, 'bill_to_state', s.BillingState);
                    MapX.putIfNotNull(addr, 'bill_to_postal_code', s.BillingPostalCode);
                    MapX.putIfNotNull(addr, 'bill_to_country', s.BillingCountry);
                    MapX.putIfNotNull(addr, 'email_address', s.BillingEmailAddress);
                    
                    // get item
                    Map<String, Object> order = new Map<String, Object>();
                    MapX.putIfNotNull(order, 'OrderType', 'OrderType');
                    MapX.putIfNotNull(order, 'OriginalOrderNumber', s.OrderNumber);
                    MapX.putIfNotNull(order, 'OrderDate', NumericX.formatDatetime(s.CreatedDate, 'iso', 'GMT'));
                    MapX.putIfNotNull(order, 'FulfilledToAddressLine1', fo.FulfilledToStreet);
                    MapX.putIfNotNull(order, 'FulfilledToCountry', fo.FulfilledToCountry);
                    MapX.putIfNotNull(order, 'FulfilledToCity', fo.FulfilledToCity);
                    MapX.putIfNotNull(order, 'FulfilledToState', fo.FulfilledToState);
                    MapX.putIfNotNull(order, 'FulfilledToPostalCode', fo.FulfilledToPostalCode);
                    MapX.putIfNotNull(order, 'FulfilledToName', fo.FulfilledToName);
                    MapX.putIfNotNull(order, 'FulfilledToAddressLine1', fo.FulfilledToStreet);
                    MapX.putIfNotNull(order, 'CustomerBillToAddress', addr);
                    orders.add(order); 

                    // get lineitems
                    List<Map<String, String>> lineItems = new List<Map<String, String>>();
                    for (FulfillmentOrderLineItem x : tuple.items) {
                        Map<String, String> item = new Map<String, String>();
                        MapX.putIfNotNull(item, 'Name', x.Description);
                        MapX.putIfNotNull(item, 'TotalPrice', NumericX.formatCurrency(x.TotalPrice, s.CurrencyIsoCode));
                        MapX.putIfNotNull(item, 'Quantity', x.Quantity);
                        MapX.putIfNotNull(item, 'ProductId', x.Product2.ProductCode);
                        lineItems.add(item);
                    }

                    // post value
                    ctx.endpoint = 'oms.shipment';
                    ctx.address = s.BillingEmailAddress;
                    ctx.subscriberKey = s.Account.ContactID__pc;
                    ctx.contactAttributes = new Map<String, Object> {
                        'SubscriberAttributes' => new Map<String, Object> {
                            'EmailAddress' => s.BillingEmailAddress,
                            'OrderNumber' => s.OrderNumber,
                            'TrackingNumber' => shipment.TrackingNumber,
                            'TrackingUrl' => shipment.TrackingUrl != null ? shipment.TrackingUrl  : '',
                            'SiteID' => s.SalesChannel.SalesChannelName,
                            'ShipmentID' => shipment.Id,
                            'AmountCurrencyCode' => s.CurrencyIsoCode,
                            'AccountName' => s.Account.Name,
                            'PaymentMethod' => paymentTypeMap.get(osId),
                            'Subtotal' => s.TotalAmount,
                            'Tax' => s.TotalTaxAmount,
                            'GrandTotal' => s.GrandTotalAmount,
                            'OrderDetailsJSON' => 
                            JSON.serialize(new Map<String, Object> {
                                'FulFillmentOrders' => orders,
                                'LineItems' => lineItems
                            }).replace('"','\\"')
                        }
                    };
                    
                    if (orders.size() == 1) {
                        Map<String, String> customerBillToAddressMap = (Map<String, String>)orders.get(0).get('CustomerBillToAddress');
                        if (s.BillingEmailAddress == customerBillToAddressMap.get('email_address')) {
                            res = CloudXSfmcTrigger.post(ctx);
                            statusCode = res.getStatusCode();
                            if (statusCode == 200 || statusCode == 202) {
                                osIdsToUpdate.add(osId);
                            } else {
                                log = CustomCommonUtil.getLogObj(CLASS_NAME, ctx.toString(), res.getBody(), statusCode, 
                                    GATEWAY_FAIL, ERROR_MESSAGE + osId, osId);
                            }
                        }
                    } else {
                        log = CustomCommonUtil.getLogObj(CLASS_NAME, ctx.toString(), '', null, 
                        	GATEWAY_FAIL, 'Multiple Orders in a payload', osId);
                    }
                } catch (Exception ex) {
                    errorMessage = 'Exception Type: ' + ex.getTypeName() + ', Error Message: ' + ex.getMessage() + ', LineNumber: ' + ex.getLineNumber() + ', StackTrace: ' + ex.getStackTraceString();
                    log = CustomCommonUtil.getLogObj(CLASS_NAME, '', '', ex.getLineNumber(), 
                        GATEWAY_FAIL, errorMessage, osId);
                } finally {
                    if (log != null) {
                        logList.add(log);
                        log = null;
                    }
                }
            }
            
            if (!osIdsToUpdate.isEmpty()) {
                updateSfmcExportFlag(osIdsToUpdate);
            }
            
            if (!logList.isEmpty()) {
                insert logList;
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
    }
    
    class ShipmentAndItems {
        final Shipment shipment;
        final List<FulfillmentOrderLineItem> items;
        ShipmentAndItems(Shipment shipment, List<FulfillmentOrderLineItem> items) {
            this.shipment = shipment;
            this.items = items;
        }
    }
    
    public void updateSfmcExportFlag(Set<Id> osIds) {
        List<OrderSummary> osList = [SELECT Id, SFMC_Shipment_Email_Sent__c FROM OrderSummary WHERE Id IN :osIds FOR UPDATE];
        for (OrderSummary os: osList) {
            os.SFMC_Shipment_Email_Sent__c = true;
        }
        update osList;
    }
}