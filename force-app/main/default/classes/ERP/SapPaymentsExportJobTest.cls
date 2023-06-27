@isTest 
public class SapPaymentsExportJobTest {
    static List<String> osIds = new List<String>();
    static List<String> foIds = new List<String>();
    @IsTest(SeeAllData=true)
  	static void testSapOrderPaymentsExport() {
       try {
           String osCA = OmsTestDataFactory.createOrderSummaryCA();
           String osUS = OmsTestDataFactory.createOrderSummaryUS();
           osIds.add(osUS);
           osIds.add(osCA);
           for (String osId : osIds) {
            //    List<String> fulfillmentOrderIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
            //    foIds.addAll(fulfillmentOrderIds);
                String fulfillmentOrderIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
               foIds.add(fulfillmentOrderIds);
           }
           List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id IN :foIds];
           for(FulfillmentOrder fo: foList) {
               OmsTestDataFactory.invoiceFulfillmentOrder(fo);
           }
           Test.startTest();
           SapPaymentsExportJob sapJobExport = new SapPaymentsExportJob();
           database.executeBatch(sapJobExport);
           Test.stopTest();
           List<OrderPaymentSummary>  opsList = [SELECT Id, OrderSummaryId, IsExportedToSAP__c,
                                                 (SELECT Id, GatewayRefNumber, Amount FROM PaymentAuthorizations), 
                                                 (SELECT Id, PaymentNumber, CreatedDate, AccountId, CurrencyIsoCode, 
                                                  PaymentAuthorizationId, Amount from Payments) 
                                                 FROM OrderPaymentSummary where OrderSummaryId IN :osIds ];
           for(OrderPaymentSummary ops : opsList) {
               for(PaymentAuthorization opa : ops.PaymentAuthorizations) {
                   for (Payment paymentData : ops.Payments) {
                       if(paymentData.PaymentAuthorizationId == opa.Id) {
                           system.assertEquals(true,ops.IsExportedToSAP__c);
                       }
                   }
               }
           }
       }
        catch (Exception e) {
            System.debug('Exception occoured' + e.getMessage());
        }
    }
    
    @IsTest(SeeAllData=true)
  	static void testSapPaymentsExportJobScheduler() {
        SapPaymentsExportJobScheduler spej = new SapPaymentsExportJobScheduler();
        spej.execute(null);
    }
    
    @IsTest(SeeAllData=true)
  	static void testSapPaymentsExportJobConstructor() {
        String fromDate = '2022-10-10T00:00:01.000';
        String endDate = '2023-11-30T23:59:59.000';
        SapPaymentsExportJob spej = new SapPaymentsExportJob(fromDate, endDate, false);
        Database.executeBatch(spej);
    }
}