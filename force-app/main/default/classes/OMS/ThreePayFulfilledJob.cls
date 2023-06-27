/*
 * ThreePayFulfilledJob fetches the OrderSummary records whose all the Order Items Summaries missing SAP Material Code and 
 * updates the OrderSummary status to "3-Pay Fulfilled" and Fulfillement Order Status to "Fulilled"
*/
public class ThreePayFulfilledJob implements Database.Batchable<sObject>, Database.Stateful {
    public final String WAITING_TO_FULFILL = 'Waiting To Fulfill';
    public final String THREE_PAY_FULFILLED = '3-Pay Fulfilled';
    public final String PRODUCT_TYPE = 'Order Product';
    public final String CLASS_NAME = ThreePayFulfilledJob.class.getName();
    public final String MANAGED = 'MANAGED';
    public final String FULFULLED = 'FULFILLED';
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator queryResult;
        String orderByAndLimitClause = Test.isRunningTest()? 'ORDER BY CreatedDate DESC LIMIT 2' :  'ORDER BY CreatedDate ASC';
        try {
            queryResult = Database.getQueryLocator(
                'SELECT Id, Status, IsExportedToAmware__c, OrderLifeCycleType, ' +
                '(SELECT Id, Type, sfcc_SAPMaterialCode__c FROM OrderItemSummaries ' +
                'WHERE sfcc_SAPMaterialCode__c != null AND Type = :PRODUCT_TYPE), ' +
                '(SELECT Id, Status FROM FulfillmentOrders) ' +
                'FROM OrderSummary WHERE Status = :WAITING_TO_FULFILL AND IsExportedToAmware__c = false ' +
                'AND OrderLifeCycleType = :MANAGED ' + orderByAndLimitClause);
        } catch (Exception ex) { CustomCommonUtil.logException(CLASS_NAME, ex); }
        return queryResult;
    }
    
    public void execute(Database.BatchableContext bc, List<OrderSummary> orderSummaryList) {
        List<OrderSummary> osListToUpdate = new List<OrderSummary>();
        List<FulfillmentOrder> foListToUpdate = new List<FulfillmentOrder>();
        try {
            for (OrderSummary os : orderSummaryList) {
                if (os.OrderItemSummaries.isEmpty()) {
                    os.Status = THREE_PAY_FULFILLED;
                    osListToUpdate.add(os);
                    for (FulfillmentOrder fo : os.FulfillmentOrders) {
                        fo.Status = FULFULLED;
                        foListToUpdate.add(fo);
                    }
                }
            }
            if (!osListToUpdate.isEmpty()) {
                CustomCommonUtil.updateSObjectAndLogErros(osListToUpdate, CLASS_NAME);
            }
            if (!foListToUpdate.isEmpty()) {
                CustomCommonUtil.updateSObjectAndLogErros(foListToUpdate, CLASS_NAME);
            }
        } catch (Exception ex) { CustomCommonUtil.logException(CLASS_NAME, ex); }
    }
    
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}