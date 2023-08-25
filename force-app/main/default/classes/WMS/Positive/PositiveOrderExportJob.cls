public class PositiveOrderExportJob  implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public final String GATEWAY_SUCCESS = 'Success: Fulfillment Order sent successfully to Positive';
	public final String GATEWAY_FAIL = 'Failed: Fulfillment Order failed to send to Positive';
    public final String UNIT_OF_MEASURE = 'EA';
    public final String LANGUAGE_CODE = 'EN';
    public final String SALESCHANNEL_CA = 'viviscal-ca';
    public final String WAITING_TO_FULFILL = 'Waiting to Fulfill';
    public final String CLASS_NAME = PositiveOrderExportJob.class.getName();
    
    /* It gets all the Fulfillment Orders with the filter 
     * conditon OrderSummary.IsExportedToPositive__c as false so that it query only those Order Summary for which 
     * Fulfillment Order is not sent to Positive
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator queryResult;
        String orderByAndLimitClause = Test.isRunningTest()? 'ORDER BY CreatedDate DESC LIMIT 1' :  'ORDER BY CreatedDate';
        try {
            queryResult = Database.getQueryLocator(
                'SELECT Id, OrderSummary.OrderNumber, OrderSummary.Status, OrderSummary.IsExportedToPositive__c , OrderSummary.Id, ' +
                'Account.LastName, Account.FirstName, OrderSummary.OrderedDate, FulfilledToStreet, FulfilledToCity, FulfilledToPostalCode,' + 
                'FulfilledToState, FulfilledToStateCode, FulfilledToCountryCode, FulfilledToPhone, FulfilledToEmailAddress, OrderSummary.sfcc_sourceChannel__c, ' +
                '(SELECT Id, Type, OriginalQuantity, Quantity, OrderItemSummary.OrderDeliveryGroupSummary.GiftMessage, OrderItemSummary.OrderDeliveryGroupSummary.DeliverToName, OrderItemSummary.sfcc_SAPMaterialCode__c ' + 
                'FROM FulfillmentOrderLineItems WHERE OrderItemSummary.sfcc_SAPMaterialCode__c != null AND OrderItemSummary.Type = \'Order Product\') ' +
                'FROM FulfillmentOrder WHERE OrderSummary.SalesChannel.SalesChannelName = :SALESCHANNEL_CA AND OrderSummary.IsExportedToPositive__c = false AND OrderSummary.Status = :WAITING_TO_FULFILL ' +
                orderByAndLimitClause
            );
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return queryResult;
    }
    
    /* This method gets list of OrderSummary and corresponding OrderItemSummary records as input and 
    * creates list of string which contains the data that needs to be added to the text file */
    public void execute(Database.BatchableContext bc, List<FulfillmentOrder> foList) {
        String errorMessage;
        String gatewayMessage;
        String requestBody;
        PositiveOrderRequest poRequest;
        PositiveOrderRequest.Consignee consignee;
        PositiveOrderRequest.OrderLineDetails lineItem;
        List<PositiveOrderRequest.OrderLineDetails> lineItemList;
        Map<String, Object> reqResMap;
        List<FulfillmentOrder> foToUpdate = new List<FulfillmentOrder>();
        Set<Id> osIdsToUpdate = new Set<Id>();
        List<OrderSummary> osListToUpdate = new List<OrderSummary>();
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        try {
            for (FulfillmentOrder fo : foList) {
                if (!fo.FulfillmentOrderLineItems.isEmpty()) {
                    poRequest = new PositiveOrderRequest();
                    consignee = new PositiveOrderRequest.Consignee();
                    if (fo.Account.LastName == 'Unknown' || fo.Account.LastName == '[not provided]' || fo.Account.LastName == Null || fo.Account.FirstName == Null ){  
                        for(FulfillmentOrderLineItem fulFillOrderLineItem :fo.FulfillmentOrderLineItems){
                            String fullName = fulFillOrderLineItem.OrderItemSummary.OrderDeliveryGroupSummary.DeliverToName;
                             // Find the index of the space character
                            Integer spaceIndex = fullName.indexOf(' ');
                            // Check if spaceIndex is valid
                            if(spaceIndex != -1) {
                                consignee.FirstName = fullName.substring(0, spaceIndex);
                                consignee.LastName = fullName.substring(spaceIndex + 1);
                            } else {
                                // If no space found, consider the entire name as the first name
                                consignee.FirstName = fullName;
                                consignee.LastName = '';
                            }                         
                        }                    
                    }
                    else {
                        consignee.lastName = fo.Account.LastName;
                        consignee.firstName = fo.Account.FirstName;
                    }
                    consignee.address1 = fo.FulfilledToStreet;
                    consignee.City = fo.FulfilledToCity;
                    if(consignee.address1.length() >50) {
                        consignee.address2 = consignee.address1.substring(50, consignee.address1.length());
                        consignee.address1 = consignee.address1.substring(0,50);
                    }
                    consignee.provinceCode = fo.FulfilledToStateCode;
                    consignee.postalCode = fo.FulfilledToPostalCode;
                    consignee.countryCode = fo.FulfilledToCountryCode;
                    consignee.telephone = fo.FulfilledToPhone.replaceAll('\\s+', '');
                    consignee.email = fo.FulfilledToEmailAddress;
                    consignee.languageCode = LANGUAGE_CODE;
                    poRequest.uniqueOrderReference = fo.OrderSummary.OrderNumber;
                    poRequest.purchaseOrderNumber = fo.OrderSummary.Id;
                    poRequest.dateOfOrder = fo.OrderSummary?.OrderedDate?.format('yyyy-MM-dd\'T\'hh:mm:ss');
                    poRequest.specialComments = fo.FulfillmentOrderLineItems.isEmpty() ? null : fo.FulfillmentOrderLineItems[0].OrderItemSummary.OrderDeliveryGroupSummary?.GiftMessage;
                    lineItemList = new List<PositiveOrderRequest.OrderLineDetails>();
                    for(FulfillmentOrderLineItem foLine : fo.FulfillmentOrderLineItems) {
                        lineItem = new PositiveOrderRequest.OrderLineDetails();
                        lineItem.customerProductCode = foLine.OrderItemSummary.sfcc_SAPMaterialCode__c;
                        lineItem.quantityOrdered = Integer.valueOf(foLine.OriginalQuantity);
                        lineItem.quantityToShip = Integer.valueOf(foLine.Quantity);
                        lineItem.unitOfMeasure = UNIT_OF_MEASURE;
                        lineItemList.add(lineItem);
                    }
                    poRequest.consignee = consignee;
                    poRequest.orderLineDetails = lineItemList;
                    requestBody = JSON.serialize(poRequest, true);
                    if (!poRequest.orderLineDetails.isEmpty()) {
                        HttpResponse postOrderResponse;
                        try {
                            reqResMap = PositiveServices.postOrder(requestBody);
                            if (!reqResMap.isEmpty()) {
                                postOrderResponse = (HttpResponse)reqResMap.get('response');
                                if(postOrderResponse?.getStatusCode() == 200) {
                                    gatewayMessage = GATEWAY_SUCCESS;
                                    foToUpdate.add(new FulfillmentOrder(Id = fo.Id, PositiveStatus__c = 'Sent', PositiveSentOn__c = Datetime.now()));
                                    osIdsToUpdate.add(fo.OrderSummary.Id);
                                } else {
                                    gatewayMessage = GATEWAY_FAIL;
                                    foToUpdate.add(new FulfillmentOrder(Id = fo.Id, PositiveStatus__c = 'Failed'));
                                }
                            } else {
                                errorMessage = 'No Request or Response Found';
                                gatewayMessage = GATEWAY_FAIL;
                                foToUpdate.add(new FulfillmentOrder(Id = fo.Id, PositiveStatus__c = 'Failed'));
                            }
                        } catch (Exception ex) {
                            errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { ex.getMessage(), ex.getLineNumber(), ex.getStackTraceString(), ex.getCause() });
                            foToUpdate.add(new FulfillmentOrder(Id = fo.Id, PositiveStatus__c = 'Failed'));
                        } finally {
                            logs.add(new WMSGatewayLog__c(InteractionType__c = 'FulfillmentExport', OrderSummary__c = fo.OrderSummary.Id, 
                                                        Request__c = ((HttpRequest)reqResMap?.get('request'))?.getBody(), Response__c = postOrderResponse?.getBody(),
                                                        ErrorMessage__c = errorMessage, GatewayMessage__c = gatewayMessage, 
                                                        ResultCode__c = postOrderResponse?.getStatusCode()));
                            //Reseting
                            poRequest = null;
                            consignee= null;
                            lineItem = null;
                            lineItemList = null;
                            requestBody = null;
                            reqResMap = null;
                            gatewayMessage = null;
                            errorMessage = null;
                        
                        }
                    }
                }
            }

            if (!logs.isEmpty()) {
                insert logs;
            }
            
            if(!foToUpdate.isEmpty()) {
           		update foToUpdate;
       		}
            
            if(!osIdsToUpdate.isEmpty()) { 
               for(Id osId : osIdsToUpdate){
                   osListToUpdate.add(new OrderSummary(Id = osId, IsExportedToPositive__c = true));
               }
               if(!osListToUpdate.isEmpty()) {
                   update osListToUpdate; 
               }
           }
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
    }
    
    //TODO Add  logic on Finish, if required
    public void finish(Database.BatchableContext bc) {
    }
}