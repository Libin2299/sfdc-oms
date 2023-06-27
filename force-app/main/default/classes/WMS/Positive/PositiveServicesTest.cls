@isTest
public class PositiveServicesTest {
    static final String AUTH_RESPONSE = '{"access_token":"accessToken"}';
    static DateTime currentDt = DateTime.now();
    static String fromDT = String.valueOf(currentDt.addHours(-1));
    static String toDT = String.valueOf(currentDt);
    static Integer rowsPerPage = 200;
    static String sorting = 'Ascending';
    
    @isTest 
    static void requestAccessTokenTest() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(200, AUTH_RESPONSE));
        String accessToken = PositiveServices.requestAccessToken();
        Assert.isNotNull(accessToken); // Succeeds
    }
    
    @isTest 
    static void postOrderTest(){
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:PositiveAuth/oauth/token' => new HttpCalloutServiceMock(200, AUTH_RESPONSE),
            'callout:PositiveAPI/v0/order' => new HttpCalloutServiceMock(200, '')
        }));
        Map<String, Object> reqResMap = PositiveServices.postOrder('');
        HttpResponse res = (HttpResponse)reqResMap.get('response');
        System.assert(reqResMap != null);
        System.assertEquals(200, res.getStatusCode());
    }
    
    @isTest
    static void getOrders() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:PositiveAuth/oauth/token'  => new HttpCalloutServiceMock(200, AUTH_RESPONSE),
            'callout:PositiveAPI/v0/order?FromDate=' + EncodingUtil.urlEncode(fromDT, 'UTF-8') +
                '&ToDate=' + EncodingUtil.urlEncode(toDT, 'UTF-8') + '&Offset=' + 0 +
                '&Limit=' + rowsPerPage + '&Sorting=' + sorting => new HttpCalloutServiceMock(200, '')
        }));
        Map<String, Object> reqResMap = PositiveServices.getOrders(fromDT, toDT, 0, rowsPerPage, sorting);
        HttpResponse res = (HttpResponse)reqResMap.get('response');
        System.assert(reqResMap != null);
        System.assertEquals(200, res.getStatusCode());
    }
    
    @isTest
    static void getOrderByOrderIdTest() {
        String orderNo = '010110';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:PositiveAuth/oauth/token'  => new HttpCalloutServiceMock(200, AUTH_RESPONSE),
            'callout:PositiveAPI/v0/order/' + orderNo => new HttpCalloutServiceMock(200, '')
        }));
        Map<String, Object> reqResMap = PositiveServices.getOrderByOrderId(OrderNo);
        HttpResponse res = (HttpResponse)reqResMap.get('response');
        System.assert(reqResMap != null);
        System.assertEquals(200, res.getStatusCode());
    }
}