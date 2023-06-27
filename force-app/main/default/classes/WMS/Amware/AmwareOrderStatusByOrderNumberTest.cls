@isTest
public class AmwareOrderStatusByOrderNumberTest {
    static String authResponse = '{"token":"token"}';
    static String amwareResponse;
    static String className = AmwareFulFillmentStatusImportJobTest.class.getName();
       
    @isTest(SeeAllData=true)
    static void amwareOrderStatusByOrderNumberTest() {
        OrderSummary orderSummary = null;
        List<FulfillmentOrder> fullfillmentOrderList;
        List<Shipment> shipmentList;
    	List<String> fulfillmentIds = new List<String>();
        String orderSummaryId = OmsTestDataFactory.createOrderSummaryUS();
        String foIds = OmsTestDataFactory.createFulfillmentOrder(orderSummaryId, 'Warehouse');
        fulfillmentIds.add(foIds);           
        amwareResponse = AmwareMockResponse.getfulfillmentResponse(fulfillmentIds);
        orderSummary = [SELECT Id, OrderNumber FROM OrderSummary WHERE Id = :orderSummaryId];
        System.debug('AmwareResponse ' + amwareResponse);
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
                'callout:Amware/api/fulfillment/fulfillment?ReferenceNumber=' + orderSummary.OrderNumber => new HttpCalloutServiceMock(200, amwareResponse)
                }));
        Test.startTest();
        Database.executeBatch(new AmwareOrderStatusByOrderNumber('\'testOrder1234cv\'', true));
        Test.stopTest();
        orderSummary = [SELECT Id, Status FROM OrderSummary WHERE Id = :orderSummaryId];
        fullfillmentOrderList = [SELECT Id, Status, (SELECT Id FROM FulfillmentOrderLineItems WHERE Type = 'Order Product') FROM FulfillmentOrder WHERE Id  IN :fulfillmentIds];
        shipmentList = [SELECT Id, (SELECT Id FROM ShipmentItems) FROM Shipment WHERE FulfillmentOrderId IN :fulfillmentIds];
        //System.assertEquals(fullfillmentOrderList.size(), shipmentList.size());
        //System.assertEquals('Fulfilled', String.valueOf(fullfillmentOrderList.get(0).Status));
        //System.assertEquals('Fulfilled', String.valueOf(orderSummary.get(0).Status));   
    }
}