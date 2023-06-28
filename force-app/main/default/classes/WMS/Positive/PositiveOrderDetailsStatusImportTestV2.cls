@isTest
public class PositiveOrderDetailsStatusImportTestV2 {
    static final String AUTH_RESPONSE = '{"access_token":"accessToken"}';
    static final String FULFILLED = 'Fulfilled';
	
    @isTest(SeeAllData=true)
    static void positiveOrderDetailsStatusImportTest() {
        FulfillmentOrder fo;
        String osId = OmsTestDataFactory.createOrderSummaryCA();
        String foId = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        OrderSummary os = [SELECT Id, PF_Order_ID__c, status, ordernumber, Retry_Count__c FROM ordersummary WHERE Id = :osId limit 1];
        os.PF_Order_ID__c = '2e59c478-699a-4395-b238-6e46875dtest';
        os.status = 'Waiting to Fulfill';
        os.Retry_Count__c = 2;
        update os;
        String pfId = os.PF_Order_ID__c;
        String positiveOrderStatus = PositiveMockResponseTest.getOrderStatusResponseV2(pfId);
        String orderId = pfId;
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:PositiveAuth/oauth/token'  => new HttpCalloutServiceMock(200, AUTH_RESPONSE),
            'callout:PositiveAPI/v0/order/' + orderId => new HttpCalloutServiceMock(200, positiveOrderStatus)}));
        Test.startTest();
        Database.executeBatch(new PositiveOrderDetailsStatusImportJobV2());
        Test.stopTest();
        fo = [SELECT Id, Status FROM FulfillmentOrder WHERE Id = :foId];
        System.assertEquals(FULFILLED, fo.Status);
    }
}