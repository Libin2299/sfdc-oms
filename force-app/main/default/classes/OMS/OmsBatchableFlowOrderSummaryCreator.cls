@isTest
/*
 * Important: ========================================================================================================
 * Before running this code - you must adjust any filters on associated Order Summary Creation Flows to stop
 * filtering out Orders based on the custom field called IsHistorical. Otherwise, the flow will not process them when
 * the Status is updated to Active. In addition to this, you need to make adjustments to the flow for handling whether
 * the historical order will be turned into a Managed or Unmanaged Order Summary as the methodology used in this class
 * does not use the Connect APIs.
 * Description: ======================================================================================================
 *   Batchable apex to automatically update Order.Status = 'Activated' and then execute a call to
 *   ConnectApi.OrderSummaryCreation.createOrderSummary() to generate OrderSummaries for historical orders that are in
 *   Draft status and Historical status is 'NotProcessed'. Any errors during process execution are written to the
 *   custom object OmsHistoricalProcessingError__c as a lookup (related list in UI) to Order and Order is reverted to a
 *   Draft and NotProcessed status. A successful OrderSummary generation results in historical order batch status
 *   updated to "Processed".
 * Development notes: ================================================================================================
 * Dependencies:
 *  1) Order.isHistorical__c checkbox default = false
 *  2) Order.HistoricalProcessingStatus__c picklist (NotProcessed | Working | Processed)
 *  3) Order.isHistoricalManaged__c checkbox default = false. True means create a Managed Order Summary.
 *  3) OmsHistoricalProcessingError__c custom sObject to record errors during batch processing.
 *     FIELDNAME          DATATYPE           COMMENTS
 *     OrderID__c         Lookup(Order)      Links the record to the Order
 *     Error_Message__c   LongTextArea(32k)  Contains the error message returned by the flow
 */

 public with sharing class OmsBatchableFlowOrderSummaryCreator implements Database.Batchable<sObject>, Database.Stateful {
 
     // Enumeration mapping to the Picklist values on Order's HistoricalProcessingStatus__c field
     public enum HistoricalOrderProcessingStatus {
         NotProcessed,
         Working,
         Processed
     }
 
     // Enumeration mapping to the Picklist values on the Order's Status field
     public enum OrderStatus {
         Draft,
         Activated
     }
 
     // Enumeration mapping to the OrderLifeCycleType for OrderSummary
     //TODO: Get rid of this
     /*
     public enum OrderLifeCycleType
     {
         MANAGED,
         UNMANAGED
     }
     */
 
     //The query for the batch operations
     static final String QUERY_FOR_BATCHES = 'SELECT Id, OrderNumber, Name, Type, Status, isHistoricalManaged__c ' +
     'FROM   Order ' +
     'WHERE  isHistorical__c = true ' +
     'AND    Status = \'' + OrderStatus.Draft.name() + '\'' +
     'AND    HistoricalProcessingStatus__c = \'' + HistoricalOrderProcessingStatus.NotProcessed.name() + '\'' +
     'ORDER BY createdDate DESC';
 
     // The start method fulfilling our batchable interface implementation requirement - Put the gloves on!
     public Database.QueryLocator start(Database.BatchableContext batchableContext) {
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableFlowOrderSummaryCreator start().');
         Database.QueryLocator queryLocator = Database.getQueryLocator(QUERY_FOR_BATCHES);
         return queryLocator;
     }
 
     //The execute method fulfilling our batchable interface implementation requirement - Now we're doing work!
     public void execute(Database.BatchableContext batchableContext, List<Order> listOrders) {
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableFlowOrderSummaryCreator execute() begins...');
         System.debug(System.LoggingLevel.DEBUG, 'OmsBatchableFlowOrderSummaryCreator listOrders size:' + listOrders.size());
         List<OmsHistoricalProcessingError__c> batchProcessingErrors = new List<OmsHistoricalProcessingError__c>();
         List<Order> finishedOrders = new List<Order>();
 
         System.debug('OmsBatchableFlowOrderSummaryCreator - Processing list of ' + listOrders.size() + ' started...');
 
         for(Order order : listOrders) {
             //Set the status to activated on the order (the flow should already be set to allow anything where isHistorical__c is true)
             try {
                 System.debug('Setting Order Status to ' + OrderStatus.Activated.name() + ' for order #: ' + order.OrderNumber);
                 order.Status = OrderStatus.Activated.name();
                 update order;
             } catch(Exception ex) {
                 System.debug('Error setting Order Status to ' + OrderStatus.Activated.name() + ' for order #: ' + order.OrderNumber + ': ' + ex.getMessage());
                 OmsHistoricalProcessingError__c batchProcessingError = new OmsHistoricalProcessingError__c(OrderId__c = order.Id, Error_Message__c = ex.getMessage());
                 batchProcessingErrors.add(batchProcessingError);
             }
         }
 
         // Attach errors to the orders where errors occurred
         if(batchProcessingErrors.size() > 0) {insert batchProcessingErrors;
             /*try {
                 insert batchProcessingErrors;
             } catch(DMLException e) {
                 for(Integer i=0; i < e.getNumDml(); i++) {
                     System.debug(System.LoggingLevel.ERROR, 'OmsBatchableFlowOrderSummaryCreator execute(): Order ' + e.getDmlId(i) +
                                 ' had errors but unable to insert Historical Order Batch Processing Error records: '+ e.getDmlMessage(i));
                 }
             }*/
         }
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableFlowOrderSummaryCreator execute() completed.');
     }
 
     public void finish(Database.BatchableContext batchableContext) {
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableFlowOrderSummaryCreator finish() started...');
         // Get the ID of the AsyncApexJob representing this batch job and query the AsyncApexJob object to get additional status
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         AsyncApexJob a = [SELECT    Id, Status, NumberOfErrors, JobItemsProcessed,
                                     TotalJobItems, CreatedBy.Email
                             FROM      AsyncApexJob
                             WHERE     Id = :batchableContext.getJobId()];
 
         // Send notification email
         try {
             String msg = 'The batch Apex job processed ' + a.TotalJobItems + ' batches with ' + a.NumberOfErrors + ' failures.';
             System.debug(msg);
             String[] toAddresses = new String[] {a.CreatedBy.Email};
             mail.setToAddresses(toAddresses);
             mail.setSubject('Historical Managed Order Batch processing status: ' + a.Status);
             mail.setPlainTextBody(msg);
             Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         } catch(Exception ex) {
             System.debug('OmsBatchableFlowOrderSummaryCreator error sending email: ' + mail + '; ErrorMsg: ' + ex.getmessage());
         }
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableFlowOrderSummaryCreator finish() completed.');
     }
 }