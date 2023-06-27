public class PositiveOrderExportJob  implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public static final String GATEWAY_SUCCESS = 'Send: Fulfillment Order sent successfully to Positive';
	public static final String GATEWAY_FAIL = 'Send: Fulfillment Order failed to send to Positive';
    public static final String ACCESS_TOKEN_ERROR = 'No Access Token generated';
    public static String className = AmwareFulFillmentStatusImportJob.class.getName();
    public static String unitOfMeasure = 'EA';
    
    /* It gets all the Fulfillment Orders with the filter 
     * conditon OrderSummary.IsExportedToPositive__c as false so that it query only those Order Summary for which 
     * Fulfillment Order is not sent to Positive
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, OrderSummary.OrderNumber, OrderSummary.Status, OrderSummary.IsExportedToAmware__c, OrderSummary.Id, ' +
            'Account.LastName, Account.FirstName,OrderSummary.OrderedDate, FulfilledToStreet, FulfilledToCity, FulfilledToState, ' + 
            'FulfilledToCity, FulfilledToState, FulfilledToCountry, FulfilledToPostalCode, FulfilledToPhone, FulfilledToEmailAddress, ' +
            'DeliveryMethodId, OrderSummary.OriginalOrder.OrderNumber, OrderSummary.TotalAdjustedProductAmount, OrderSummary.PaymentAmount__c, ' +
            'OrderSummary.TotalAdjDistAmount, OrderSummary.TotalTaxAmount, OrderSummary.GrandTotalAmount, OrderSummary.sfcc_sourceChannel__c, ' +
            '(SELECT Id, Type, OrderItemId, OrderItemSummaryId, OriginalQuantity, Quantity, QuantityUnitOfMeasure, Description, FulfillmentOrderId, ' + 
            'Product2Id, OrderItemSummary.OrderDeliveryGroupSummary.GiftMessage, OrderItem.Product2.StockKeepingUnit, OrderItem.sfcc_SAPMaterialCode__c, ' + 
            'OrderItem.UnitPrice, Product2.Name from FulfillmentOrderLineItems WHERE OrderItem.sfcc_SAPMaterialCode__c != null AND OrderItem.Type = \'Order Product\') ' +
            'FROM FulfillmentOrder WHERE OrderSummary.SalesChannel.SalesChannelName = \'viviscal-ca\' AND OrderSummary.IsExportedToAmware__c = false AND OrderSummary.Status = \'Waiting to Fulfill\''
        );
    }
    
    /* This method gets list of OrderSummary and corresponding OrderItemSummary records as input and 
    * creates list of string which contains the data that needs to be added to the text file */
    public void execute(Database.BatchableContext bc, List<FulfillmentOrder> foList) {
        String errorMessage;
        String gatewayMessage;
        PositiveOrderResponse pOWrap;
        PositiveOrderResponse.Consignee consObj;
        List<PositiveOrderResponse.OrderLineDetails> orderLineDetailsList;
        List<Object> reqResList;
        List<FulfillmentOrder> foToUpdate = new List<FulfillmentOrder>();
        Set<Id> osIdsToUpdate = new Set<Id>();
        List<OrderSummary> osListToUpdate = new List<OrderSummary>();
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        try {
            for (FulfillmentOrder fulFillOrder : foList) {
                pOWrap = new PositiveOrderResponse();
                consObj = new PositiveOrderResponse.Consignee();
                consObj.lastName = fulFillOrder.Account.LastName;
                consObj.firstName = fulFillOrder.Account.FirstName;
                consObj.address1 = fulFillOrder.FulfilledToStreet;
                consObj.City = fulFillOrder.FulfilledToCity;
                if(consObj.address1.length() >50) {
                    consObj.address2 = consObj.address1.substring(50, consObj.address1.length());
                    consObj.address1 = consObj.address1.substring(0,50);
                }
                consObj.provinceCode = CustomCommonUtil.getStateCode(fulFillOrder.FulfilledToState);
                consObj.postalCode = fulFillOrder.FulfilledToPostalCode;
                consObj.countryCode = CustomCommonUtil.getCountryCode(fulFillOrder.FulfilledToCountry);
                consObj.telephone = String.valueOf(fulFillOrder.FulfilledToPhone).length() < 15 ? String.valueOf(fulFillOrder.FulfilledToPhone) : null ;
                consObj.email = fulFillOrder.FulfilledToEmailAddress;
                consObj.languageCode = CustomCommonUtil.getUserLanguage() == 'French' ? 'FR' : 'EN';//TODO
                pOWrap.uniqueOrderReference = String.valueOf(fulFillOrder.OrderSummary.OrderNumber);
                pOWrap.purchaseOrderNumber = String.valueOf(fulFillOrder.OrderSummary.Id);
                pOWrap.dateOfOrder = String.valueOf(fulFillOrder.OrderSummary.OrderedDate);
                orderLineDetailsList = new List<PositiveOrderResponse.OrderLineDetails>();
                for(FulfillmentOrderLineItem fulFillOrderLineItem :fulFillOrder.FulfillmentOrderLineItems) {
                    PositiveOrderResponse.OrderLineDetails createLineItem = new PositiveOrderResponse.OrderLineDetails();
                    createLineItem.customerProductCode = fulFillOrderLineItem.OrderItem.sfcc_SAPMaterialCode__c;
					createLineItem.quantityOrdered = Integer.valueOf(fulFillOrderLineItem.OriginalQuantity);
                    createLineItem.quantityToShip = Integer.valueOf(fulFillOrderLineItem.Quantity);
                    createLineItem.unitOfMeasure = unitOfMeasure;
                    orderLineDetailsList.add(createLineItem);
                }
                //pOWrap.specialComments = ;
                //pOWrap.shippingComments = ;
                //pOWrap.carrierCode = ;
                //pOWrap.serviceCode = ;
                //pOWrap.specialComments = ;
                //DynamicFields dynField1 = new DynamicFields();
                //dynField1.dynamicField =;
                //dynField1.value = ;
                //DynamicFields dynField2 = new DynamicFields();
                //dynField2.dynamicField =;
                //dynField2.value = ;
                //List<DynamicFields> dynFieldList = new List<DynamicFields>();
                //dynFieldList.add(dynField1);
                //dynFieldList.add(dynField1);
                //pOWrap.dynamicFields = dynFieldList;
                //pOWrap.ClientOrderType = String.valueOf(String.isNotBlank(fulFillOrder.OrderSummary.sfcc_sourceChannel__c) ? fulFillOrder.OrderSummary.sfcc_sourceChannel__c :'Viviscal-WEB'  )  ;
                pOWrap.Consignee = consObj;
                pOWrap.orderLineDetails = orderLineDetailsList;
                // Serialize the list of NOT Null objects.
                String requestBody = JSON.serializePretty(pOWrap, true);
                if (!pOWrap.orderLineDetails.isEmpty()) {
                    HttpResponse accessTokenResponse;
                    HttpResponse postOrderResponse;
                    try {
                        reqResList = PositiveServices.postOrder(requestBody);
                        accessTokenResponse = (HttpResponse)reqResList[1];
                        postOrderResponse = (HttpResponse)reqResList[3];
                        if (accessTokenResponse?.getStatusCode() == 200) {
                            if(postOrderResponse?.getStatusCode() == 200) {
                                gatewayMessage = GATEWAY_SUCCESS;
                    			foToUpdate.add(new FulfillmentOrder(Id = fulFillOrder.Id, PositiveStatus__c = 'Sent', PositiveSentOn__c = Datetime.now()));
                                osIdsToUpdate.add(fulFillOrder.OrderSummary.Id);
                            } else {
                                gatewayMessage = GATEWAY_FAIL;
								foToUpdate.add(new FulfillmentOrder(Id = fulFillOrder.Id, PositiveStatus__c = 'Failed'));
                            }
                        } else {
                            //Logging Access Token request and response only if it fails to generate access token  
                            logs.add(new WMSGatewayLog__c(InteractionType__c = 'Fulfillment', OrderSummary__c = fulFillOrder.OrderSummary.Id, 
                                                      Request__c = ((HttpRequest)reqResList[0]).toString(), Response__c = accessTokenResponse.getBody(),
                                                      ErrorMessage__c = ACCESS_TOKEN_ERROR, GatewayMessage__c = ACCESS_TOKEN_ERROR, 
                                                      ResultCode__c = accessTokenResponse.getStatusCode()));
                            foToUpdate.add(new FulfillmentOrder(Id = fulFillOrder.Id, PositiveStatus__c = 'Failed'));
                        }
                    } catch (Exception ex) {
                        errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { ex.getMessage(), ex.getLineNumber(), ex.getStackTraceString(), ex.getCause() });
                		foToUpdate.add(new FulfillmentOrder(Id = fulFillOrder.Id, PositiveStatus__c = 'Failed'));
                    } finally {
                        logs.add(new WMSGatewayLog__c(InteractionType__c = 'Fulfillment', OrderSummary__c = fulFillOrder.OrderSummary.Id, 
                                                      Request__c = ((HttpRequest)reqResList[2])?.toString(), Response__c = postOrderResponse?.getBody(),
                                                      ErrorMessage__c = errorMessage, GatewayMessage__c = gatewayMessage, 
                                                      ResultCode__c = postOrderResponse.getStatusCode()));
                        //Reseting
                        pOWrap = null;
                        reqResList = null;
                        gatewayMessage = null;
                        errorMessage = null;
                       
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
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    
    //TODO Add  logic on Finish, if required
    public void finish(Database.BatchableContext bc) {
    }
}