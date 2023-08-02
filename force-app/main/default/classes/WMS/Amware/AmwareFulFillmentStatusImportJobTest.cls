@isTest
public class AmwareFulFillmentStatusImportJobTest {
    static String authResponse = '{"token":"token"}';
    static String amwareResponse;
    static String orderSummaryId;
    static List<String> fulfillmentIds = new List<String>();
    static String className = AmwareFulFillmentStatusImportJobTest.class.getName();
        
    @isTest(SeeAllData=true)
    static void amwareFulFillmentStatusImportJobTest() {
        OrderSummary orderSummary = null;
        List<FulfillmentOrder> fullfillmentOrderList;
        List<Shipment> shipmentList;
        DateTime currentDt = DateTime.now();
        String sinceDateTime = String.valueOf(Datetime.newInstanceGMT(Date.today().year(), Date.today().month(), Date.today().day(), 0, 0, 0).formatGmt('yyyy-MM-dd HH:mm'));//String.valueOf(System.now().addMinutes(-120).formatGmt('yyyy-MM-dd HH:mm'));
        //String sinceDateTime = DateTime.newInstance(currentDt.year(), currentDt.month(), currentDt.day(), (currentDt.hour() - 2), 0, 0).formatGmt('yyyy-MM-dd HH:mm');
        try {
            orderSummaryId = OmsTestDataFactory.createOrderSummaryCA();
            String foIds = OmsTestDataFactory.createFulfillmentOrder(orderSummaryId, 'Warehouse');
            fulfillmentIds.add(foIds);           
            amwareResponse = AmwareMockResponse.getfulfillmentResponse(fulfillmentIds);
            Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
                'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
                'callout:Amware/api/fulfillment/fulfillmentbyUTCDate?orderSource=API&OrderType=VS&rowsPerPage=200&pageIndex=0&sinceDateTime='+EncodingUtil.urlEncode(sinceDateTime, 'UTF-8') => new HttpCalloutServiceMock(200, amwareResponse)
            }));
            Test.startTest();
            Database.executeBatch(new AmwareFulFillmentStatusImportJob());
            Test.stopTest();
            orderSummary = [SELECT Id, Status FROM OrderSummary WHERE Id = :orderSummaryId];
            fullfillmentOrderList = [SELECT Id, Status, (SELECT Id FROM FulfillmentOrderLineItems WHERE Type = 'Order Product') FROM FulfillmentOrder WHERE Id  IN :fulfillmentIds];
            shipmentList = [SELECT Id, (SELECT Id FROM ShipmentItems) FROM Shipment WHERE FulfillmentOrderId IN :fulfillmentIds];
            //System.assertEquals(fullfillmentOrderList.size(), shipmentList.size());
            //System.assertEquals('Fulfilled', String.valueOf(fullfillmentOrderList.get(0).Status));
            //System.assertEquals('Fulfilled', String.valueOf(orderSummary.get(0).Status));
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    
    @isTest(SeeAllData=true)
    static void amwareFulFillmentStatusBySinceDateTime() {
        OrderSummary orderSummary = null;
        List<FulfillmentOrder> fullfillmentOrderList;
        List<Shipment> shipmentList;
        String sinceDateTime = '2023-01-11 06:22';
        try {
            orderSummaryId = OmsTestDataFactory.createOrderSummary();
            String foIds = OmsTestDataFactory.createFulfillmentOrder(orderSummaryId, 'Warehouse');
            fulfillmentIds.add(foIds);           
            amwareResponse = AmwareMockResponse.getfulfillmentResponse(fulfillmentIds);
            System.debug('AmwareResponse ' + amwareResponse);
            Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
                'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
                'callout:Amware/api/fulfillment/fulfillmentbyUTCDate?orderSource=API&OrderType=VS&rowsPerPage=200&pageIndex=0&sinceDateTime='+EncodingUtil.urlEncode(sinceDateTime, 'UTF-8') => new HttpCalloutServiceMock(200, amwareResponse)
            }));
            Test.startTest();
            Database.executeBatch(new AmwareFulFillmentStatusImportJob(sinceDateTime));
            Test.stopTest();
            orderSummary = [SELECT Id, Status FROM OrderSummary WHERE Id = :orderSummaryId];
            fullfillmentOrderList = [SELECT Id, Status, (SELECT Id FROM FulfillmentOrderLineItems WHERE Type = 'Order Product') FROM FulfillmentOrder WHERE Id  IN :fulfillmentIds];
            shipmentList = [SELECT Id, (SELECT Id FROM ShipmentItems) FROM Shipment WHERE FulfillmentOrderId IN :fulfillmentIds];
            System.assertEquals(fullfillmentOrderList.size(), shipmentList.size());
            System.assertEquals('Fulfilled', String.valueOf(fullfillmentOrderList.get(0).Status));
            //System.assertEquals('Fulfilled', String.valueOf(orderSummary.get(0).Status));
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }   
    }
}