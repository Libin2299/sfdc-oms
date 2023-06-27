@isTest
public class PositiveOrderExportJobTest {
    static final String authResponse = '{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"}';    
    static String orderSummaryId;
    static List<String> fulfillmentIds;
    static String OrderResponse = '';
    @isTest(SeeAllData=true)
    
    static void PositiveOrderExportJobTestMethod() {
       Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
        'callout:Positive/oauth/token'  => new HttpCalloutServiceMock(200, authResponse),
        'callout:PositiveAPI/v0/order' => new HttpCalloutServiceMock(200, OrderResponse)
               }));
       OrderSummary orderSummary = null;
       List<FulfillmentOrder> fullfillmentOrderList;
       orderSummaryId = OmsTestDataFactory.createOrderSummaryCA();
       fulfillmentIds = OmsTestDataFactory.createFulfillmentOrder(orderSummaryId, 'Warehouse');
       list<OrderSummary> orderSummaryList = [SELECT Id, CreatedDate,OrderedDate ,Status FROM OrderSummary where Id =: orderSummaryId];
       for(OrderSummary os:orderSummaryList )
       {
          os.Status = 'Waiting to Fulfill'; 
       }
       update orderSummaryList;
       system.debug('OrderSummary'+orderSummaryList);
       Test.startTest();
       Database.executeBatch(new PositiveOrderExportJob());
       Test.stopTest();
        for(FulfillmentOrder fo :fullfillmentOrderList ) {
            System.assertEquals(fo.PositiveStatus__c,'Sent');
       }
    }
}