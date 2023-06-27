public class AmwareOrderExportJob  implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public static final String GATEWAY_SUCCESS = 'Send: Fulfillment Order sent successfully';
    public static final String GATEWAY_FAIL = 'Send: Fulfillment Order failed to send';
    public String prirty = '0';
    public String faclity = 'VANNUYS';
    public String shipPaymentType = 'PPD';
    public String sCode = 'GRND';
    public String satDelivery = 'N';
    public Integer lineNumber;
    public DateTime orderDateTime;
    public String jsonString;
    String className = AmwareOrderExportJob.class.getName();
    
    public class OrderWrapper {
        public String ReferenceNumber1;
        public String ReferenceNumber2;
        public String Priority;
        public String Facility;
        public String SaturdayDelivery;
        public String PacklistComments1;
        public String OrderSubtotal;
        public String DiscountAmount;
        public String TotalTax;
        public String PaymentAmount;
        public String OrderTotal;
        public String DateCreated;
        public String ClientOrderType;
        public Shipping Shipping;
        public List<LineItems> LineItems;
    }
    
    public class Shipping {
        public String LastName;
        public String FirstName;
        public String Address1;
        public String City;
        public String State;
        public String Zip;
        public String Country;
        public String Phone;
        public String Email;
        public String ShipPaymentType;
        public String ShipCode;
    }
    
    public class LineItems {
        public String Quantity;
        public String Item;
        public String ItemDescription;
        public String CostPerUofm;
        public String Pass1;
        public String Pass2;
        public String Pass3;
        public String Pass4;
        public String OrderLineNumber;
    }
    
    /* It gets all the Fulfillment Orders with the filter 
* conditon OrderSummary.IsExportedToAmware__c as false so that it query only those Order Summary for which 
* Fulfillment Order is not sent to Amware
*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String orderByAndLimitClause = Test.isRunningTest() ? 'ORDER BY CreatedDate DESC LIMIT 2' :  'ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(
            'SELECT Id , OrderSummary.Status, OrderSummary.IsExportedToAmware__c, OrderSummary.SalesChannel.SalesChannelName ' +
            'FROM FulfillmentOrder WHERE OrderSummary.IsExportedToAmware__c = false AND OrderSummary.Status = \'Waiting to Fulfill\' AND OrderSummary.SalesChannel.SalesChannelName = \'Viviscal\' ' + 
            orderByAndLimitClause);
    }
    
    /* This method gets list of OrderSummary and corresponding OrderItemSummary records as input and 
* creates list of string which contains the data that needs to be added to the text file */
    public void execute(Database.BatchableContext bc, List<FulfillmentOrder> fulfillmentOrderList) {
        List<FulfillmentOrder> fulFillOrderListToUpdate = new List<FulfillmentOrder>();
        Set<Id> osSetIdsToUpdate = new Set<Id>();
        List<OrderSummary> osListToUpdate = new List<OrderSummary>();
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        String responseString;
        String gatewayMessage = GATEWAY_SUCCESS;
        String errorMessage = null;
        for (FulfillmentOrder fulFillOrder : [
            SELECT Id, OrderSummary.OrderNumber, OrderSummary.Status,
            OrderSummary.IsExportedToAmware__c, OrderSummary.Id, Account.LastName,
            Account.FirstName, OrderSummary.OrderedDate, FulfilledToStreet, FulfilledToCity, FulfilledToState, FulfilledToCountry, FulfilledToPostalCode, FulfilledToPhone, FulfilledToEmailAddress, DeliveryMethodId,
            OrderSummary.OriginalOrder.OrderNumber, OrderSummary.TotalAdjustedProductAmount, OrderSummary.PaymentAmount__c, OrderSummary.TotalAdjDistAmount,
            OrderSummary.TotalTaxAmount, OrderSummary.GrandTotalAmount, OrderSummary.sfcc_sourceChannel__c,
            (SELECT Id, Type, OrderItemId, OrderItemSummaryId, Quantity, QuantityUnitOfMeasure, Description, FulfillmentOrderId, Product2Id, OrderItemSummary.OrderDeliveryGroupSummary.GiftMessage,OrderItemSummary.OrderDeliveryGroupSummary.DeliverToName, OrderItem.sfcc_SAPMaterialCode__c, OrderItem.UnitPrice, Product2.Name FROM FulfillmentOrderLineItems)
            FROM FulfillmentOrder WHERE Id In :fulfillmentOrderList]) {
                //Create Shipping Object
                Shipping shipObj = new Shipping();
                //Create OrderWrapper Obj
                OrderWrapper oWrap = new OrderWrapper();
                //Adding custom line number to FO post.
                lineNumber = 1;
                //Create LineItemprirty
                List<LineItems> listLItems = new List<LineItems>();
                for(FulfillmentOrderLineItem fulFillOrderLineItem :fulFillOrder.FulfillmentOrderLineItems){
                    LineItems createLineItem = new LineItems();
                    if(fulFillOrderLineItem.Type == 'Delivery Charge') {
                        if(fulFillOrder.Account.LastName == 'Unknown' || fulFillOrder.Account.LastName == '[not provided]' || fulFillOrder.Account.LastName == Null || fulFillOrder.Account.FirstName == Null ){
                            String fullName = fulFillOrderLineItem.OrderItemSummary.OrderDeliveryGroupSummary.DeliverToName;
                            // Find the index of the space character
                            Integer spaceIndex = fullName.indexOf(' ');
                            // Check if spaceIndex is valid
                            if(spaceIndex != -1) {
                                // Extract the first name using substring
                                shipObj.FirstName = fullName.substring(0, spaceIndex);
                                // Extract the last name using substring
                                shipObj.LastName = fullName.substring(spaceIndex + 1);
                            } else {
                                // If no space found, consider the entire name as the first name
                                shipObj.FirstName = fullName;
                                shipObj.LastName = '';
                            }
                        }
                        else {
                            shipObj.LastName = fulFillOrder.Account.LastName;
                            shipObj.FirstName = fulFillOrder.Account.FirstName;
                        } 
                        shipObj.Address1 = fulFillOrder.FulfilledToStreet;
                        shipObj.City = fulFillOrder.FulfilledToCity;
                        shipObj.State = fulFillOrder.FulfilledToState;
                        shipObj.Zip = fulFillOrder.FulfilledToPostalCode;
                        shipObj.Country = fulFillOrder.FulfilledToCountry;
                        shipObj.Phone = String.valueOf(fulFillOrder.FulfilledToPhone);
                        shipObj.Email = fulFillOrder.FulfilledToEmailAddress;
                        shipObj.ShipPaymentType = shipPaymentType;
                        shipObj.ShipCode = sCode ;
                        oWrap.PacklistComments1= fulFillOrderLineItem.OrderItemSummary.OrderDeliveryGroupSummary.GiftMessage;                        
                    } else {
                        if(fulFillOrderLineItem.OrderItem.sfcc_SAPMaterialCode__c != null) {
                            createLineItem.Quantity = String.valueOf(fulFillOrderLineItem.Quantity);
                            createLineItem.Item = String.valueOf(fulFillOrderLineItem.OrderItem.sfcc_SAPMaterialCode__c);
                            createLineItem.ItemDescription = fulFillOrderLineItem.Product2.Name; 
                            createLineItem.CostPerUofm = fulFillOrderLineItem.OrderItem.UnitPrice > 0.0 ? String.valueOf(fulFillOrderLineItem.OrderItem.UnitPrice) : null ;
                            createLineItem.Pass1 = String.valueOf(fulFillOrderLineItem.OrderItemSummaryId);     
                            createLineItem.Pass2 = String.valueOf(fulFillOrder.Id);
                            createLineItem.Pass3 = String.valueOf(fulFillOrder.OrderSummary.Id);
                            createLineItem.Pass4 = String.valueOf(fulFillOrderLineItem.Id);
                            createLineItem.OrderLineNumber = String.valueOf(lineNumber++);
                            listLItems.add(createLineItem);
                        }
                    }
                }
                oWrap.ReferenceNumber1 = String.valueOf(fulFillOrder.OrderSummary.OrderNumber);
                oWrap.ReferenceNumber2 = String.valueOf(fulFillOrder.OrderSummary.Id);
                oWrap.Priority = prirty;
                oWrap.Facility = faclity;
                oWrap.SaturdayDelivery = satDelivery;
                oWrap.OrderSubtotal = String.valueOf(fulFillOrder.OrderSummary.TotalAdjustedProductAmount);
                oWrap.DiscountAmount = String.valueOf(fulFillOrder.OrderSummary.TotalAdjDistAmount);
                oWrap.TotalTax = String.valueOf(fulFillOrder.OrderSummary.TotalTaxAmount);
                oWrap.PaymentAmount = String.valueOf(fulFillOrder.OrderSummary.PaymentAmount__c);
                oWrap.OrderTotal = String.valueOf(fulFillOrder.OrderSummary.GrandTotalAmount);
                if(!Test.isRunningTest()) {
                    orderDateTime = fulFillOrder.OrderSummary.OrderedDate;
                    oWrap.DateCreated = orderDateTime.format('MM-dd-YYYY');
                } else {
                    orderDateTime = System.now();
                    oWrap.DateCreated = orderDateTime.format('MM-dd-YYYY');
                }
                oWrap.ClientOrderType = String.valueOf(String.isNotBlank(fulFillOrder.OrderSummary.sfcc_sourceChannel__c) ? fulFillOrder.OrderSummary.sfcc_sourceChannel__c :'Viviscal-WEB'  )  ;
                oWrap.Shipping = shipObj;
                oWrap.LineItems = listLItems;
                String jsonStringRequest = JSON.serializePretty(oWrap,true);
                if (!listLItems.isEmpty()) {
                    try {
                        //Callout to AmwareSerivces.postOrder();Total number of callouts (HTTP requests or Web services calls) is 100. Keep batch size as 100.
                        responseString = AmwareServices.postOrder(jsonStringRequest);
                        if (responseString.contains('200')) {
                            gatewayMessage = GATEWAY_SUCCESS;
                            fulFillOrderListToUpdate.add(new FulfillmentOrder(Id = fulFillOrder.Id, AmwareStatus__c = 'Sent', AmwareSentOn__c = Datetime.now()));
                            //If sent success we update OrderSummary Is_ExportedToAmware__c to TRUE 
                            osSetIdsToUpdate.add(fulFillOrder.OrderSummary.Id);                    
                        } else {
                            gatewayMessage = GATEWAY_FAIL;
                            fulFillOrderListToUpdate.add(new FulfillmentOrder(Id = fulFillOrder.Id, AmwareStatus__c = 'Failed'));
                        }
                    } catch (Exception e) {           
                        gatewayMessage = GATEWAY_FAIL;
                        errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
                        fulFillOrderListToUpdate.add(new FulfillmentOrder(Id = fulFillOrder.Id, AmwareStatus__c = 'Failed'));
                    } finally {
                        logs.add(new WmsGatewayLog__c(InteractionType__c = 'FulfillmentExport', OrderSummary__c = fulFillOrder.OrderSummary.Id, Request__c = jsonStringRequest, Response__c = responseString, ErrorMessage__c = errorMessage, GatewayMessage__c = gatewayMessage));
                    }
                }
            }
        //TODO : Enable DMLs once confirmed
        if(!logs.isEmpty()) {
            insert logs;
        }
        if(!fulFillOrderListToUpdate.isEmpty()) {
            update fulFillOrderListToUpdate;
        }
        if(!osSetIdsToUpdate.isEmpty()) { 
            for(Id osSetId : osSetIdsToUpdate){
                osListToUpdate.add(new OrderSummary(Id=osSetId, IsExportedToAmware__c = true));
            }
            if(!osListToUpdate.isEmpty()) {
                update osListToUpdate; 
            }
        }
    }
    
    //TODO Add  logic on Finish, if required
    public void finish(Database.BatchableContext bc) {
        
    }
}