@isTest
public class PositiveOrderStatusImportJobTest {
	static final String AUTH_RESPONSE = '{"access_token":"accessToken"}';
    static final String FULFILLED = 'Fulfilled';
    static DateTime currentDt = DateTime.now();
    static String fromDT = Datetime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(), currentDt.dayGmt(), 0, 0, 0).formatGmt('yyyy-MM-dd HH:mm:ss');
    static String toDT = Datetime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(), currentDt.dayGmt(), 23, 59, 59).formatGmt('yyyy-MM-dd HH:mm:ss');
    static Integer rowsPerPage = 200;
    static String sorting = 'Ascending';
    
    @isTest(SeeAllData=true)
    static void positiveOrderImportJobTest() {
        PositiveOrderStatus__c pos;
        String osId = OmsTestDataFactory.createOrderSummaryCA();
        String foId = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
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
        Database.executeBatch(new PositiveOrderStatusImportJob(fromDT, toDT, rowsPerPage, sorting));
        Test.stopTest();
		pos = [SELECT Id, FulfillmentOrder__c, IsImported__c  FROM PositiveOrderStatus__c WHERE FulfillmentOrder__c = :foId];
        Assert.isNotNull(pos);
    }
}