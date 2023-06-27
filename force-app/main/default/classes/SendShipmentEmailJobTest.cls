@IsTest
public class SendShipmentEmailJobTest {
    @isTest(seeAllData=true)
    public static void sendShipmentEmailTest() {
        String osId = OmsTestDataFactory.createOrderSummaryUS();
		String foId = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        FulfillmentOrder fo = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id = :foId];
        OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        Test.startTest();
        Shipment ship = [SELECT Id, CreatedDate FROM Shipment WHERE OrderSummaryId = :osId];
        String dt = ship.CreatedDate.formatGmt('yyyy-MM-dd HH:mm:ss');
        Database.executeBatch(new SendShipmentEmailJob(dt, dt));
        Test.stopTest();
        OrderSummary os = [SELECT Id, SFMC_Shipment_Email_Sent__c FROM OrderSummary WHERE id = :osId];
        //System.assertEquals(true, os.SFMC_Shipment_Email_Sent__c);
    }
}