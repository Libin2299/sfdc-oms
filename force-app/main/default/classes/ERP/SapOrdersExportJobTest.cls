@isTest
public class SapOrdersExportJobTest {
    static List<String> osIds = new List<String>();
    static List<String> foIds = new List<String>();
    
    @isTest(seeAllData=true)
    static void sapOrdersJobExportTest() {
        String osUS = OmsTestDataFactory.createOrderSummaryUS();
        osIds.add(osUS);
        String osCA = OmsTestDataFactory.createOrderSummaryCA();
        osIds.add(osCA);
        for (String osId : osIds) {
            String fulfillmentOrderIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
            foIds.add(fulfillmentOrderIds);
        }
        List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id IN :foIds];
        for(FulfillmentOrder fo: foList) {
            OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        }
        Test.startTest();
        Database.executeBatch(new SapOrdersExportJob(),2000);
        Test.stopTest();
        List<OrderSummary> osList = [SELECT Id, IsExportedToSAP__c FROM OrderSummary WHERE Id IN :osIds];
        for(OrderSummary os : osList) {
            System.assertEquals(true, os.IsExportedToSAP__c);
        }
    }
    
    @isTest(seeAllData=true)
    static void testSapOrdersExportJobScheduler() {
        new SapOrdersExportJobScheduler().execute(null);
    }
    
    @isTest(seeAllData=true)
    static void sapOrdersExportJobByDateTest() {
        String osUS = OmsTestDataFactory.createOrderSummaryUS();
        osIds.add(osUS);
        String osCA = OmsTestDataFactory.createOrderSummaryCA();
        osIds.add(osCA);
        String osIdStr = osUS + ',' + osCa;
        for (String osId : osIds) {
            String fulfillmentOrderIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
            foIds.add(fulfillmentOrderIds);
        }
        List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id IN :foIds];
        for(FulfillmentOrder fo: foList) {
            OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        }
        Test.startTest();
        	DateTime currentDt = DateTime.now();
            String fromDate = DateTime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(), currentDt.dayGmt(), 0, 0, 0) + '';
            String endDate = DateTime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(), currentDt.dayGmt(), 23,59, 59) + '';
            SapOrdersExportJob soej = new SapOrdersExportJob(fromDate, endDate);
            SapOrdersExportJob soej2 = new SapOrdersExportJob(fromDate, endDate, true);
            Database.executeBatch(soej, 2000);
        Test.stopTest();
    }
    
    @isTest(seeAllData=true)
    static void sapOrdersExportJobByOsIdsTest() {
        String osUS = OmsTestDataFactory.createOrderSummaryUS();
        osIds.add(osUS);
        String osCA = OmsTestDataFactory.createOrderSummaryCA();
        osIds.add(osCA);
        String osIdStr = '\'' + osUS + '\',\'' + osCA + '\'';
        for (String osId : osIds) {
            String fulfillmentOrderIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
            foIds.add(fulfillmentOrderIds);
        }
        List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id IN :foIds];
        for(FulfillmentOrder fo: foList) {
            OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        }
        SapOrdersExportJob soej = new SapOrdersExportJob(osIdStr, true);
        SapOrdersExportJob soej2 = new SapOrdersExportJob(true, true);
        Test.startTest();
            Database.executeBatch(new SapOrdersExportJob(osIdStr));
        Test.stopTest();
        List<OrderSummary> osList = [SELECT Id, IsExportedToSAP__c FROM OrderSummary WHERE Id IN :osIds];
        for(OrderSummary os : osList) {
            System.assertEquals(true, os.IsExportedToSAP__c);
        }
    }
}