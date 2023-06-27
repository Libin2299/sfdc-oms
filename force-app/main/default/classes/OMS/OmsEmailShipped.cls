public class OmsEmailShipped extends CloudXSfmcTrigger implements CloudX.HasArgs {
    public Id shipmentId;
    public Id osId;
    public static final String GATEWAY_SUCCESS = 'Successfully sent SFMC Shipment email';
	public static final String GATEWAY_FAIL = 'Failed to send SFMC Shipment email';
    public String CLASS_NAME = OmsEmailShipped.class.getName();
    public static final String ERROR_MESSAGE = 'SFMC Shipment email failed to send and it\'s Order Summary Id: ';
    public HttpResponse res;
    public Integer statusCode;

    public void setArgs(Map<String, Object> args) {
        shipmentId = (Id)args.get('entityId');
    }

    class ShipmentAndItems {
        final Shipment shipment;
        final List<FulfillmentOrderLineItem> items;
        ShipmentAndItems(Shipment shipment, List<FulfillmentOrderLineItem> items) {
            this.shipment = shipment;
            this.items = items;
        }
    }

    public override String execute(TriggerContext ctx) {
        List<Id> shipmentIds = new List<Id> { shipmentId };
        Map<String, ShipmentAndItems> tupleByShipmentId = new Map<String, ShipmentAndItems>();
        Map<Id, Id> shipmentIdByfoId = new Map<Id, Id>();
        Integer statusCode;
        try {
            for (Shipment s : [SELECT Id, FulfillmentOrderId, TrackingNumber,
                FulfillmentOrder.OrderSummary.CreatedDate, FulfillmentOrder.OrderSummary.OrderNumber, FulfillmentOrder.FulfilledToAddress,
                FulfillmentOrder.FulfilledToName, FulfillmentOrder.FulfilledToStreet, 
                FulfillmentOrder.FulfilledToCity, FulfillmentOrder.OrderSummary.OriginalOrderId,
                FulfillmentOrder.FulfilledToState, FulfillmentOrder.FulfilledToPostalCode, FulfillmentOrder.FulfilledToCountry, 
                // FulfillmentOrder.FulfilledToShippingStreet2__c, FulfillmentOrder.FulfilledToShippingStreet3__c, FulfillmentOrder.FulfilledToShippingStreet4__c,
                FulfillmentOrder.AccountId, FulfillmentOrder.Account.Name, FulfillmentOrder.Account.AccountNumber, FulfillmentOrder.Type,
                /*FulfillmentOrder.Account.Salutation__pc,*/ FulfillmentOrder.Account.FirstName, /*FulfillmentOrder.Account.MiddleName,*/ FulfillmentOrder.Account.LastName, /*FulfillmentOrder.Account.Suffix__pc,*/
                // FulfillmentOrder.Order_Delivery_Group_Summary__r.DeliverToLocation__r.ExternalReference,
                FulfillmentOrder.OrderSummary.GrandTotalAmount, FulfillmentOrder.OrderSummary.SalesChannelId,
                FulfillmentOrder.OrderSummary.SalesChannel.SalesChannelName,FulfillmentOrder.OrderSummary.BillingEmailAddress,
                FulfillmentOrder.OrderSummary.BillingStreet, FulfillmentOrder.OrderSummary.BillingCity, 
                FulfillmentOrder.OrderSummary.BillingState, FulfillmentOrder.OrderSummary.BillingPostalCode, 
                FulfillmentOrder.OrderSummary.BillingCountry, FulfillmentOrder.OrderSummary.CurrencyIsoCode,
                FulfillmentOrder.OrderSummary.Account.ContactID__pc, FulfillmentOrder.OrderSummary.Account.Name,
                FulfillmentOrder.OrderSummary.TotalAmount, FulfillmentOrder.OrderSummary.TotalTaxAmount
                FROM Shipment Where Id In :shipmentIds]) {
                ShipmentAndItems tuple = new ShipmentAndItems(s, new List<FulfillmentOrderLineItem>());
                tupleByShipmentId.put(s.Id, tuple);
                shipmentIdByfoId.put(s.FulfillmentOrderId, s.Id);
            }

            for (FulfillmentOrderLineItem item : [
                SELECT Quantity, TotalPrice, Description, FulfillmentOrderId, Product2.ProductCode 
                FROM FulfillmentOrderLineItem WHERE FulfillmentOrderId In :shipmentIdByfoId.keySet()]) {
                if (!tupleByShipmentId.containsKey(shipmentIdByfoId.get(item.FulfillmentOrderId))) { continue; }
                ShipmentAndItems tuple = tupleByShipmentId.get(shipmentIdByfoId.get(item.FulfillmentOrderId));
                tuple.items.add(item);
                tupleByShipmentId.put(shipmentIdByfoId.get(item.FulfillmentOrderId), tuple);
            }
        
            List<Shipment> shipmentUpdates = new List<Shipment>();
            List<Map<String, Object>> orders = new List<Map<String, Object>>();
            for (ShipmentAndItems tuple : tupleByShipmentId.values()) {
                Shipment shipment = tuple.shipment;
                FulfillmentOrder fo = shipment.FulfillmentOrder;
                OrderSummary s = fo.OrderSummary;
                OrderPaymentSummary ops = [SELECT Id, Method, Type FROM OrderPaymentSummary WHERE OrderSummaryId = :s.Id LIMIT 1];

                // get addr
                Map<String, String> addr = new Map<String, String>();
                MapX.putIfNotNull(addr, 'bill_to_customer_nbr', fo.Account.AccountNumber);
                // MapX.putIfNotNull(addr, 'bill_to_prefix', fo.Account.Salutation__pc);
                MapX.putIfNotNull(addr, 'bill_to_fname', fo.Account.FirstName);
                // MapX.putIfNotNull(addr, 'bill_to_initial', fo.Account.MiddleName);
                MapX.putIfNotNull(addr, 'bill_to_lname', fo.Account.LastName);
                // MapX.putIfNotNull(addr, 'bill_to_suffix', fo.Account.Suffix__pc);
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
                // MapX.putIfNotNull(order, 'FulfilledToAddressLine2', fo.FulfilledToShippingStreet2__c);
                // MapX.putIfNotNull(order, 'FulfilledToAddressLine3', fo.FulfilledToShippingStreet3__c);
                // MapX.putIfNotNull(order, 'FulfilledToAddressLine4', fo.FulfilledToShippingStreet4__c);
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
                        'SiteID' => s.SalesChannel.SalesChannelName,
                        'ShipmentID' => shipment.Id,
                        'AmountCurrencyCode' => s.CurrencyIsoCode,
                        'AccountName' => s.Account.Name,
                        'PaymentMethod' => ops.Type,
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
                osId = fo.OrderSummary.Id;
                shipmentUpdates.add(tuple.shipment);
            }
            res = post(ctx);
            statusCode = res.getStatusCode();
            if (statusCode == 200 || statusCode == 202) {
                OrderSummary os = [SELECT Id, SFMC_Shipment_Email_Sent__c FROM OrderSummary WHERE Id = :osId FOR UPDATE];
                os.SFMC_Shipment_Email_Sent__c = true;
                update os;
                //if (!shipmentUpdates.isEmpty()) { update shipmentUpdates; }
            } else {
                CustomCommonUtil.logCallout(CLASS_NAME, ctx.toString(), res.getBody(), statusCode, 
                                                GATEWAY_FAIL, ERROR_MESSAGE + osId, osId);
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return 'OK';
    }
}