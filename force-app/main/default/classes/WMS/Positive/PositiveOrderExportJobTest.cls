@isTest
public class PositiveOrderExportJobTest {
    static final String authResponse = '{"access_token":"accessToken"}';
    
    @isTest(SeeAllData=true)
    static void PositiveOrderExportJobTestMethod() {
        String osId;
        String foId;
        List<FulfillmentOrder> foList;
        List<OrderSummary> osList;
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:PositiveAuth/oauth/token'  => new HttpCalloutServiceMock(200, authResponse),
            'callout:PositiveAPI/v0/order' => new HttpCalloutServiceMock(200, '')
        }));
        osId = OmsTestDataFactory.createOrderSummaryCA();
        foId = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        osList = [SELECT Id, CreatedDate,OrderedDate ,Status FROM OrderSummary where Id =: osId];
        for (OrderSummary os : osList) {
            os.Status = 'Waiting to Fulfill'; 
        }
        update osList;
        Test.startTest();
        Database.executeBatch(new PositiveOrderExportJob());
        Test.stopTest();
        foList = [SELECT Id, PositiveStatus__c, Status FROM FulfillmentOrder WHERE Id = :foId];
        for(FulfillmentOrder fo :foList) {
            System.assertEquals(fo.PositiveStatus__c, 'Sent');
        }
    }
}