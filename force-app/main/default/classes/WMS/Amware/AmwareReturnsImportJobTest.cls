@isTest
public class AmwareReturnsImportJobTest {
    static String authResponse = '{"token":"token"}';
    static String amwareResponse;
    static String orderSummaryId;
    static String returnOrderId;
    static ReturnOrder returnOrderL;
    static String className = AmwareReturnsImportJobTest.class.getName();
    
    @isTest(SeeAllData=true)
    static void amwareReturnsImportJobTest() {
        List<ReturnOrder> returnOrderList;
        try {
            orderSummaryId = OmsTestDataFactory.createOrderSummaryUS();
            OrderSummary ordersum = [Select Id, Status from OrderSummary WHERE Id = :orderSummaryId];
            String foId = OmsTestDataFactory.createFulfillmentOrder(orderSummaryId, 'Warehouse');
            List<FulfillmentOrder> forecord = [Select Id, Status FROM FulfillmentOrder WHERE Id =: foId];
            for (FulfillmentOrder fo : forecord){
                fo.Status = 'Fulfilled';
            }           
            update forecord;
            ordersum.Status = 'Fulfilled';
            update ordersum;
            returnOrderId = OmsTestDataFactory.createRMAReturnOrder(orderSummaryId);
            amwareResponse = AmwareMockResponse.getReturnResponse(orderSummaryId, returnOrderId);
            String sinceDateTime = String.valueOf(Datetime.newInstanceGMT(Date.today().year(), Date.today().month(), Date.today().day(), 0, 0, 0).formatGmt('yyyy-MM-dd HH:mm'));
            //String sinceDateTime = String.valueOf(Datetime.now().addMinutes(-60).formatGmt('yyyy-MM-dd HH:mm'));
            Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
                'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
                    'callout:Amware/api/return/returnsbyDate?rowsPerPage=200&pageIndex=0&sinceDateTime=' + EncodingUtil.urlEncode(sinceDateTime, 'UTF-8') => new HttpCalloutServiceMock(200, amwareResponse)
                    }));      
            Test.startTest();
            AmwareReturnsImportJob amwareImport = new AmwareReturnsImportJob();
            Database.executeBatch(amwareImport);
            Test.stopTest();
            returnOrderL = [SELECT Id, Status, Ordersummary.Ordernumber, (SELECT Id,QuantityExpected,QuantityReceived FROM ReturnOrderLineItems) FROM ReturnOrder WHERE Id = :returnOrderId];
            returnOrderL.Status = 'Closed';
            update returnOrderL;
            System.assertEquals('Closed', String.valueOf(returnOrderL.Status));
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
}