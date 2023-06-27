@isTest 
public class SapRefundExportJobTest {
    static List<String> foIds = new List<String>();
    @IsTest(SeeAllData=true)
    static void testSapRefundExportJobTest() {
        try {
            String osId = OmsTestDataFactory.createOrderSummaryCA();
            String fulfillmentOrderIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
            foIds.add(fulfillmentOrderIds);
            FulfillmentOrder foList = [SELECT Id, OrderSummaryId, InvoiceId FROM FulfillmentOrder WHERE Id IN :foIds limit 1];
            foList.Status = 'Fulfilled';
            update foList;
            //FulfillmentOrder invoice = OmsTestDataFactory.invoiceFulfillmentOrder(foList);
            Order changeOrderId = OmsTestDataFactory.createOrderChange(osId, foList, 'Return');
            CreditMemo creditmemorecord = OmsTestDataFactory.createCreditMemo(osId, changeOrderId.Id);
			OrderPaymentSummary ops  = [SELECT Id, CreatedDate, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId =: osId ];
            
            Refund ref = new Refund ();
            ref.GatewayRefNumber = 'cmVmdW5kXzR3NXNiNWI1'; 
            ref.CurrencyIsoCode = 'USD';
            ref.Amount = 10;
            ref.Type = 'Referenced';
            ref.Status = 'processed';
            ref.ProcessingMode = 'External';
            ref.OrderPaymentSummaryId = ops.Id;
            insert ref; 
           
            Custom_Refund__c cr = new Custom_Refund__c();
            cr.Reference_Refund__c = ref.Id;
            cr.Reference_ChangeOrder__c = changeOrderId.Id;
            cr.Reference_Order_Payment_Summary__c = ops.Id;
            cr.IsCancelledRefund__c = false;
            cr.IsExportedToSAP__c = false;
            insert cr;
            
            Test.startTest();
            Database.executeBatch(new SapRefundExportJob());
            Test.stopTest();
            Custom_Refund__c crc = [SELECT Id, Reference_Refund__c, IsExportedToSAP__c, IsCancelledRefund__c, Reference_ChangeOrder__c, Reference_Order_Payment_Summary__c FROM Custom_Refund__c where Reference_Refund__c =: ref.Id ];
            system.assertEquals(true, crc.IsExportedToSAP__c);
        } 
        catch (Exception e) {
            System.debug('Exception occoured' + e.getMessage());
        } 
    }
   
    @IsTest(SeeAllData=true)
    static void testSapRefundExportJobScheduler() {
        Test.StartTest();
        String CRON = '0 0 23 * * ?';
        system.schedule('testSapRefundExportJobScheduler', CRON, new SapRefundExportJobScheduler());
        Test.stopTest();
    }
}