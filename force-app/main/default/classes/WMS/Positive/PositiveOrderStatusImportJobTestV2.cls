@isTest
public class PositiveOrderStatusImportJobTestV2 {
	static final String AUTH_RESPONSE = '{"access_token":"accessToken"}';
    static DateTime currentDt = DateTime.now();
    static String fromDT = Datetime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(),currentDt.dayGmt() - 2).formatGmt('yyyy-MM-dd');
    static String toDT = Datetime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(), currentDt.dayGmt() - 1).formatGmt('yyyy-MM-dd');
    static Integer rowsPerPage = 200;
    static String sorting = 'Ascending';
    
    @isTest(SeeAllData=true)
    static void positiveOrderStatusImportJobTest() {
        Ordersummary ois;
        String osId = OmsTestDataFactory.createOrderSummaryCA();
        String foId = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        OrderSummary os = [SELECT Id, status, ordernumber FROM ordersummary WHERE Id = :osId limit 1];
        os.status = 'Waiting to Fulfill';
        update os;
        String positiveOrderStatus = PositiveMockResponseTest.getOrdersStatusResponse(new Set<String>{osId});
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:PositiveAuth/oauth/token'  => new HttpCalloutServiceMock(200, AUTH_RESPONSE),
            'callout:PositiveAPI/v0/order?FromDate=' + EncodingUtil.urlEncode(fromDT, 'UTF-8') + 
				'&ToDate=' + EncodingUtil.urlEncode(toDT, 'UTF-8') + '&Offset=' + 0 +
                '&Limit=' + rowsPerPage + '&Sorting=' + sorting => new HttpCalloutServiceMock(200, positiveOrderStatus),
            'callout:PositiveAPI/v0/order?FromDate=' + EncodingUtil.urlEncode(fromDT, 'UTF-8') + 
				'&ToDate=' + EncodingUtil.urlEncode(toDT, 'UTF-8') + '&Offset=' + 1 +
                '&Limit=' + rowsPerPage + '&Sorting=' + sorting => new HttpCalloutServiceMock(200, positiveOrderStatus)
                }));
        Test.startTest();
        Database.executeBatch(new PositiveOrderStatusImportJobV2(fromDT, toDT, rowsPerPage, sorting));
        Test.stopTest();
		ois = [SELECT Id, PF_Order_ID__c, status FROM ordersummary WHERE Id = :osId];
        Assert.isNotNull(ois);
    }

    @isTest(seeAllData=true)
    static void testPositiveOrderStatusImportJobScheduler() {
        new PositiveOrderStatusImportJobScheduler().execute(null);
    }
}