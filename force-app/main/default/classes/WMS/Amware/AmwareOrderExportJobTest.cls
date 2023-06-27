@isTest
public class AmwareOrderExportJobTest {
    static final String authResponse = '{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"}';
    
    @isTest(seealldata=true)
    static void AmwareOrderExportJobTestMethod() {
        String orderSummaryId;
        String OrderResponse = '';
        String fulfillmentIds;
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
                'callout:Amware/api/order/order' => new HttpCalloutServiceMock(200, OrderResponse)
                }));
        OrderSummary orderSummary = null;
        FulfillmentOrder fullfillmentOrderList;
        orderSummaryId = OmsTestDataFactory.createOrderSummaryUS();
        fulfillmentIds = OmsTestDataFactory.createFulfillmentOrder(orderSummaryId, 'Warehouse');
        list<OrderSummary> orderSummaryList = [SELECT Id, CreatedDate,OrderedDate ,Status FROM OrderSummary where Id =: orderSummaryId];
        for(OrderSummary os:orderSummaryList )
        {
            os.Status = 'Waiting to Fulfill'; 
        }
        update orderSummaryList;
        Test.startTest();
        Database.executeBatch(new AmwareOrderExportJob());
        Test.stopTest();
        fullfillmentOrderList = [SELECT Id, AmwareStatus__c, status FROM FulfillmentOrder WHERE  Id  =:fulfillmentIds];
        System.assertEquals(fullfillmentOrderList.AmwareStatus__c,'Sent');
    }
}