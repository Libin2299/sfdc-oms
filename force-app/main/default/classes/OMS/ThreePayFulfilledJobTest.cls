@isTest
public class ThreePayFulfilledJobTest {
	
    @isTest(SeeAllData=true)
    static void threePayJobTest() {
        String osId = OmsTestDataFactory.createOsWithNoSapMaterialSku();
        String foId = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        OrderSummary os = [SELECT Id, Status FROM OrderSummary WHERE Id = :osId];
        os.Status = 'Waiting to Fulfill';
        update os;
        Test.startTest();
        Database.executeBatch(new ThreePayFulfilledJob());
        Test.stopTest();
        FulfillmentOrder fo = [SELECT Id, Status FROM FulfillmentOrder WHERE Id = :foId];
        System.assertEquals(fo.Status, 'Fulfilled');
    }

    @isTest
    static void threePayFulfilledJobSchedulerTest() {
        Test.StartTest();
        String cron = '0 0 23 * * ?';
        System.schedule('ThreeFulfilledJobTest', cron, new ThreePayFulfilledJobScheduler());
        Test.stopTest();
    }
}