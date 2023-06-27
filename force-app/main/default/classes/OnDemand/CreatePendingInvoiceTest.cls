@isTest
public class CreatePendingInvoiceTest {
    @IsTest(SeeAllData=true)
    static void testOmsBatchableApiInvoiceCreator() {
        String osId = OmsTestDataFactory.createOrderSummaryUS();
        String foIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        FulfillmentOrder fulfilorder = [SELECT Id, Status, InvoiceId, FulfillmentOrderNumber, OrderSummaryId FROM FulfillmentOrder WHERE Id =: foIds LIMIT 1];
        fulfilorder.Status = 'Fulfilled' ;
        update fulfilorder;
        system.debug('fulfilorder :'+fulfilorder);
        Test.startTest();
        Database.executeBatch(new CreatePendingInvoice(), 2000);
        Test.stopTest();
 	    FulfillmentOrder foRecord = [SELECT Id, Status, InvoiceId FROM FulfillmentOrder where Id =: fulfilorder.Id];
   	    system.assertEquals('Fulfilled',foRecord.Status);
}
}