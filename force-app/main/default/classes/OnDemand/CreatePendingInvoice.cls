public with sharing class CreatePendingInvoice implements Database.Batchable<sObject>, Database.Stateful  { 
     public String CLASS_NAME = CreatePendingInvoice.class.getName(); 
     public enum FulfillmentOrderStatus {
         Fulfilled
     }
 
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
         String query = 'SELECT Id, Status, InvoiceId, FulfillmentOrderNumber, OrderSummaryId, CreatedDate FROM FulfillmentOrder WHERE Status = \'' + FulfillmentOrderStatus.Fulfilled.name() + '\' AND InvoiceId = null ';
         if (Test.isRunningTest()) {
            query += 'And CreatedDate >= Today '; 
         }
         Database.QueryLocator queryLocator = Database.getQueryLocator(query);
         return queryLocator;
     }
    
     public void execute (Database.BatchableContext batchableContext, List<FulfillmentOrder> listOrders) {
         List<FulfillmentOrder> fulfilledOrders = new List<FulfillmentOrder>();
         for (FulfillmentOrder fulfilorder : listOrders) {
             ApplyInvoicePaymentsAsyncInputRepre applyInvoicePaymentsInput = new ApplyInvoicePaymentsAsyncInputRepre();
             ConnectApi.FulfillmentOrderInvoiceInputRepresentation createInvoiceInputRepresentation = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
             String fulfillmentOrderId = fulfilorder.Id;
             try {
                 ConnectApi.FulfillmentOrderInvoiceOutputRepresentation output = ConnectApi.FulfillmentOrder.createInvoice(fulfillmentOrderId,createInvoiceInputRepresentation);
                 fulfilorder.InvoiceId = output.invoiceId;
                 fulfilledOrders.add(fulfilorder);
                 applyInvoicePaymentsInput.invoiceId = output.invoiceId;
                 ConnectApiXOrderSummary.applyInvoicePaymentsAsync(fulfilorder.orderSummaryId, applyInvoicePaymentsInput);
             } catch (ConnectApi.ConnectApiException ex) { CustomCommonUtil.logException(CLASS_NAME, ex); }
         }
         try {
             update fulfilledOrders;
         }
         catch (DMLException e) { 
             for (Integer i=0; i < e.getNumDml(); i++) {
                System.debug(System.LoggingLevel.ERROR, 'OmsBatchableApiInvoiceCreator execute(): FulfillmentOrder ' + e.getDmlId(i) + e.getDmlMessage(i));
             }
         }
         System.debug(System.LoggingLevel.INFO, 'OmsBatchableApiInvoiceCreator execute() completed.');
     }
    
     public void finish (Database.BatchableContext batchableContext) {
         
     }
 }