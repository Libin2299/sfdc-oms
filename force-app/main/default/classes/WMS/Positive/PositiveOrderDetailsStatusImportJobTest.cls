@isTest
public class PositiveOrderDetailsStatusImportJobTest {
    static final String AUTH_RESPONSE = '{"access_token":"accessToken"}';
    static final String FULFILLED = 'Fulfilled';
	
    @isTest(SeeAllData=true)
    static void positiveOrderDetailsStatusImportJobTest() {
        FulfillmentOrder fo;
        String osId = OmsTestDataFactory.createOrderSummaryCA();
        String foId = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        String positiveOrderStatus = PositiveMockResponseTest.getOrderStatusResponse(foId);
        String orderId = '12345';
        PositiveOrderStatus__c pos = new PositiveOrderStatus__c(FulfillmentOrder__c = foId, OrderId__c = orderId, IsImported__c = false);
        insert pos;
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:PositiveAuth/oauth/token'  => new HttpCalloutServiceMock(200, AUTH_RESPONSE),
            'callout:PositiveAPI/v0/order/' + orderId => new HttpCalloutServiceMock(200, positiveOrderStatus)}));
        Test.startTest();
        Database.executeBatch(new PositiveOrderDetailsStatusImportJob());
        Test.stopTest();
        fo = [SELECT Id, Status FROM FulfillmentOrder WHERE Id = :foId];
        System.assertEquals(FULFILLED, fo.Status);
        pos = [SELECT Id, IsImported__c FROM PositiveOrderStatus__c WHERE Id = :pos.Id];
        System.assertEquals(true, pos.IsImported__c);
    }
}