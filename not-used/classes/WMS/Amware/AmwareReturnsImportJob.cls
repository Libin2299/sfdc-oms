public class AmwareReturnsImportJob  implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    //getOsReturnsMap in <osId, Returns> format;
    Map<String,AmwareReturnsResponse.Returns> getAmwareReturnsMap = new Map<String,AmwareReturnsResponse.Returns>();
    public List<ReturnOrder> roToUpdateList = new List<ReturnOrder>();

    public Map<Id,ReturnOrderLineItem> roLIToUpdateMap = new Map<Id,ReturnOrderLineItem>();    
    public Map<Id,ReturnOrderLineItem> roLIBundleToUpdateMap = new Map<Id,ReturnOrderLineItem>();

    public AmwareReturnsResponse.Returns getReturn;
    static final String PEE_DESCRIPTION = 'Return Item Failed';
    static final String PEE_SEVERITY = 'High';
    Boolean isOrderReturned;
    public List<SObject> exceptionEvents = new List<SObject>();
    public Integer orgROLICount = 0;
    public Integer amwareROLICount = 0;
    public Integer roLIBundlesCount = 0;
    public Integer totalROLIRetuned;
    public Boolean isBundle = FALSE;


    public Database.QueryLocator start(Database.BatchableContext bc) {
        List <String> osStringIdsList = getReturnsRecords();
        return Database.getQueryLocator(
            'SELECT Id, OrderSummaryId ' +
            'FROM ReturnOrder where Ordersummary.Ordernumber =: osStringIdsList ');
    }

   public void execute(Database.BatchableContext bc, List<ReturnOrder> returnOrderList) {
        System.debug('returnOrderList: '+returnOrderList);

        for (ReturnOrder retOrder : [
            SELECT Id, OrderSummaryId, Description, Ordersummary.Ordernumber,
            (SELECT Id, OrderItemId, Product2Id, Product2.StockKeepingUnit, OrderItemSummaryId, 
            QuantityReturned, QuantityUnitOfMeasure, ReasonForReturn, QuantityReceived, QuantityExpected, ReasonForRejection,Description FROM ReturnOrderLineItems) 
            FROM ReturnOrder WHERE Id In :returnOrderList AND Status NOT IN ('Closed','Canceled')]) {
                if(getAmwareReturnsMap.get(String.valueOf(retOrder.OrderSummary.OrderNumber)) != null) {
                    getReturn = getAmwareReturnsMap.get(String.valueOf(retOrder.OrderSummary.OrderNumber));
                    isOrderReturned = true;
                    System.debug('get Return : '+getReturn);
                    ReturnOrder rOrder = new ReturnOrder();
                    rOrder.Id = retOrder.Id;
                    rOrder.Description = ' Amware Returned' + ' dateReceived: ' +getReturn.dateReceived + ' Reason For Return:' + getReturn.reasonForReturn; 
                    orgROLICount = retOrder.ReturnOrderLineItems.size();
                    amwareROLICount = getReturn.returnLines.size();
                    roLIBundlesCount = 0;
                    for (ReturnOrderLineItem roLineItem : retOrder.ReturnOrderLineItems) {
                        isBundle = FALSE;
                        System.debug('retOrder.ReturnOrderLineItems.size(): '+retOrder.ReturnOrderLineItems.size());
                        System.debug('getReturn.returnLines.size(): '+getReturn.returnLines.size());
                        for(Integer i = 0 ; i < getReturn.returnLines.size(); i++) {
                            AmwareReturnsResponse.ReturnLines rl = getReturn.returnLines[i];
                            if(roLineItem.Product2.StockKeepingUnit == rl.sku) {
                                ReturnOrderLineItem returnOItem = new ReturnOrderLineItem();   
                                returnOItem.Id = roLineItem.Id;
                                returnOItem.QuantityReceived = rl.quantity;
                                returnOItem.description = 'Following : ROLI Returned FROM Amware ROI diposition: '+rl.disposition +' Qty: '+rl.quantity+' ROLI updated on '+String.valueOf(System.now());
                                if(roLineItem.QuantityExpected == returnOItem.QuantityReceived) {
                                    roLIToUpdateMap.put(returnOItem.Id,returnOItem);
                                    isOrderReturned = true;
                                } else {
                                    exceptionEvents.add(OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, retOrder.OrderSummaryId, retOrder.OrderSummaryId, 'Quantity Expected is not equal to quantity returned'));
                                    isOrderReturned = false;
                                }

                                isBundle = FALSE;
                            } else {
                                isBundle = TRUE;
                            }
                        }
                        if(isBundle && !roLIToUpdateMap.containsKey(roLineItem.Id)) {
                            ReturnOrderLineItem returnOItem = new ReturnOrderLineItem();   
                            returnOItem.Id = roLineItem.Id;
                            returnOItem.QuantityReceived = roLineItem.QuantityExpected;
                            returnOItem.description = 'Update Bundle Collection: ' + ' Qty: '+roLineItem.QuantityExpected+' ROLI Bundle updated on '+String.valueOf(System.now());
                            roLIBundleToUpdateMap.put(returnOItem.Id,returnOItem);
                            roLIBundlesCount++;
                        }
                    }
                    totalROLIRetuned = amwareROLICount + roLIBundlesCount;
                    System.debug('RO: '+retOrder.OrderSummary.OrderNumber+ ' amwareROLICount: '+amwareROLICount + ' roLIBundlesCount: '+roLIBundlesCount+ ' orgROLICount: '+orgROLICount + ' totalROLIRetuned: '+totalROLIRetuned +'isOrderReturned: '+isOrderReturned);
                    if(isOrderReturned && orgROLICount == totalROLIRetuned){
                        rOrder.Status = 'Closed';
                        rOrder.description = 'RO updated on '+String.valueOf(System.now());
                        roToUpdateList.add(rOrder);
                    }                    
                }
        }

        try {
            if(!roToUpdateList.isEmpty()) {
                update roToUpdateList;
            }
            if(!roLIToUpdateMap.values().isEmpty()) {
                update roLIToUpdateMap.values();
            }
            if(!roLIBundleToUpdateMap.values().isEmpty()) {
                update roLIBundleToUpdateMap.values();
            }
            if(!exceptionEvents.isEmpty()) {
                EventBusX.publish(exceptionEvents);
                exceptionEvents.clear();
            }
        } catch (Exception e) {
            String errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
            insert new GenericGatewayLog__c(InteractionType__c = 'AmwareReturnsImportJob', ErrorMessage__c = errorMessage);
			System.debug('exception: '+errorMessage);
			System.debug(System.LoggingLevel.ERROR, errorMessage);
        }
    }
   
    //TODO Add  logic on Finish, if required
    public void finish(Database.BatchableContext bc) {
    }

    public List<String> getReturnsRecords(){
        try{
            getAmwareReturnsMap = AmwareReturnsUtility.getReturnsResponse(200,0);
            if(!getAmwareReturnsMap.isEmpty()) {
                return new List<String>(getAmwareReturnsMap.keySet());
            }
            else {
                return null;
            }
        } catch (Exception e){
            String errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
            insert new GenericGatewayLog__c(InteractionType__c = 'AmwareReturnsImportJob', ErrorMessage__c = errorMessage);
			System.debug('exception: '+errorMessage);
         }
        return new List<String>();
    }
}