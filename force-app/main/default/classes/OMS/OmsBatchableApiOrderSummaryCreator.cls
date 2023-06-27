/*
 * Important: ========================================================================================================
 * Before running this code - you must adjust any filters on associated OrderSummary creation Flows to filter out
 * Orders based on the custom field called IsHistorical BEFORE they touch the OrderSummaryInputRepresentation object.
 * Otherwise, the flow may run when the status is updated to Active in addition to the Connect API call. This race
 * condition will result in many errors along the lines of "Order Summary already exists for this Order" and a large
 * clean up effort to reset the custom attributes back to their original state in order to re-run the batch.
 * * Description: ======================================================================================================
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

 public with sharing class OmsBatchableApiOrderSummaryCreator implements Database.Batchable<sObject>, Database.Stateful  {
 
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
     public enum OrderLifeCycleType {
         MANAGED,
         UNMANAGED
     }
 
     //The query for the batch operations
     
     // The start method fulfilling our batchable interface implementation requirement - Put the gloves on!
     public Database.QueryLocator start(Database.BatchableContext batchableContext) {
         String QUERY_FOR_BATCHES = 'SELECT Id, OrderNumber, Name, Type, Status, isHistoricalManaged__c ' +
         'FROM   Order ' +
         'WHERE  ' +
         'isHistorical__c = true ' +
         'AND Status = \'' + OrderStatus.Draft.name() + '\'' +
         'AND HistoricalProcessingStatus__c = \'' + HistoricalOrderProcessingStatus.NotProcessed.name() + '\' ';
         if (Test.isRunningTest()) {
            QUERY_FOR_BATCHES += 'And CreatedDate >= Today '; 
         }
         QUERY_FOR_BATCHES += 'ORDER BY createdDate DESC';
 
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableApiOrderSummaryCreator start().');
         Database.QueryLocator queryLocator = Database.getQueryLocator(QUERY_FOR_BATCHES);
         return queryLocator;
     }
 
     //The execute method fulfilling our batchable interface implementation requirement - Now we're doing work!
     public void execute(Database.BatchableContext batchableContext, List<Order> listOrders) {
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableApiOrderSummaryCreator execute() begins...');
         System.debug(System.LoggingLevel.DEBUG, 'OmsBatchableApiOrderSummaryCreator listOrders size:' + listOrders.size());
         List<OmsHistoricalProcessingError__c> batchProcessingErrors = new List<OmsHistoricalProcessingError__c>();
         List<Order> finishedOrders = new List<Order>();
 
         System.debug('OmsBatchableApiOrderSummaryCreator - Processing list of ' + listOrders.size() + ' started...');
 
         for(Order order : listOrders) {
             //Set the status to activated on the order (the flow should already be filtering out anything where isHistorical__c is true)
             System.debug('Setting Order Status to ' + OrderStatus.Activated.name() + ' for order #: ' + order.OrderNumber);
             order.Status = OrderStatus.Activated.name();
             update order;
 
             // Create the order summary using the OrderSummaryInputRepresentation black box
             System.debug('OmsBatchableApiOrderSummaryCreator - Trying to create the Order Summary');
             ConnectApi.OrderSummaryInputRepresentation orderSummaryInputRepresentation = new ConnectApi.OrderSummaryInputRepresentation();
             orderSummaryInputRepresentation.orderId = order.Id;
             orderSummaryInputRepresentation.orderLifeCycleType = OrderLifeCycleType.UNMANAGED.name();
 
             try {
                 System.debug('Making call to ConnectApi call for Order #: \'' + order.OrderNumber + '\'');
                 ConnectApi.OrderSummaryOutputRepresentation output = ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInputRepresentation);
                 order.HistoricalProcessingStatus__c = HistoricalOrderProcessingStatus.Processed.name();
                 finishedOrders.add(order);
             } catch(ConnectApi.ConnectApiException e) {
                 System.debug('Error making ConnectApi call for Order #: \'' + order.OrderNumber + '\'' + e.getMessage());
                 order.Status = OrderStatus.Draft.name();
                 order.HistoricalProcessingStatus__c = HistoricalOrderProcessingStatus.NotProcessed.name();
                 OmsHistoricalProcessingError__c batchProcessingError = new OmsHistoricalProcessingError__c(
                    OrderId__c = order.Id,
                    Error_Message__c = e.getErrorCode() + ': ' + e.getMessage());
                 batchProcessingErrors.add(batchProcessingError);
             }
         }
         try {
            update finishedOrders;
            // Attach errors to the orders where errors occurred
            if(batchProcessingErrors.size() > 0) {
            Insert batchProcessingErrors;
            }
        } catch(DMLException e) {
            for(Integer i=0; i < e.getNumDml(); i++) {
                System.debug(System.LoggingLevel.ERROR, 'OmsBatchableApiOrderSummaryCreator execute(): Order ' + e.getDmlId(i) +
                            ' had errors but unable to insert Historical Order Batch Processing Error records: '+ e.getDmlMessage(i));
            }
        }
        System.debug(System.LoggingLevel.INFO, 'OmsBatchableApiOrderSummaryCreator execute() completed.');
     }
 
     public void finish(Database.BatchableContext batchableContext) {
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableApiOrderSummaryCreator finish() started...');
         // Get the ID of the AsyncApexJob representing this batch job and query the AsyncApexJob object to get additional status
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         AsyncApexJob a = [SELECT    Id, Status, NumberOfErrors, JobItemsProcessed,
                                     TotalJobItems, CreatedBy.Email
                             FROM      AsyncApexJob
                             WHERE     Id = :batchableContext.getJobId()];
 
         // Send notification email
         try {
             String msg = 'The batch Apex job processed ' + a.TotalJobItems + ' batches with ' + a.NumberOfErrors + ' failures.';
             String[] toAddresses = new String[] {a.CreatedBy.Email};
             mail.setToAddresses(toAddresses);
             mail.setSubject('Historical Managed Order Batch processing status: ' + a.Status);
             mail.setPlainTextBody(msg);
             Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         } catch(Exception ex) {
             System.debug('OmsBatchableApiOrderSummaryCreator error sending email: ' + mail + '; ErrorMsg: ' + ex.getmessage());
         }
 
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableApiOrderSummaryCreator finish() completed.');
     }
 }