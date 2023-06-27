@IsTest
public class CaptureAsynRefundsTest {
    
    @IsTest(SeeAllData=true)
    static void captureAsynRefundsTest() {
    	String osId = OmsTestDataFactory.createOrderSummaryUS();
        String foIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id =: foIds];
        for(FulfillmentOrder fo: foList) {
            OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        }
        String roId = OmsTestDataFactory.createRMAReturnOrder(osId);
        String changeOrderId = OmsTestDataFactory.RetunRMAReturnOrder(roId);
        Order o = [SELECT Id, GrandTotalAmount from Order WHERE Id =:changeOrderId];
        OrderPaymentSummary ops  = [SELECT Id, CreatedDate, OrderSummaryId FROM OrderPaymentSummary where OrderSummaryId =: osId];
        Refund ref = new Refund ();
        ref.GatewayRefNumber = 'cmVmdW5kXzR3NXNiNWI1'; 
        ref.CurrencyIsoCode = 'USD';
        ref.Amount = Math.abs(o.GrandTotalAmount);
        ref.Type = 'Referenced';
        ref.Status = 'processed';
        ref.ProcessingMode = 'External';
        ref.OrderPaymentSummaryId = ops.Id;
        insert ref; 
        Custom_Refund__c cr = new Custom_Refund__c();
        cr.Reference_ChangeOrder__c = changeOrderId;
        cr.Reference_Order_Payment_Summary__c = ops.Id;
        cr.IsCancelledRefund__c = false;
        cr.IsExportedToSAP__c = false;
        insert cr;
        Test.startTest();
        System.schedule('CaptureAsynRefunds', '0 0 * * * ?', new CaptureAsynRefunds());
        Test.stopTest();
        Refund rFund = [SELECT Id, 	IsLinkedToCustomRefund__c FROM Refund WHERE Id =:ref.Id];
        System.assertEquals(true, rFund.IsLinkedToCustomRefund__c);
    }
}