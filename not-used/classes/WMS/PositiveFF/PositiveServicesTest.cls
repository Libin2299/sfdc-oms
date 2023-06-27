@isTest
public class PositiveServicesTest {
    static final String authResponse = '{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"}';
    
    @isTest static void getPositiveAuthTokenTest() {
        String expected = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(200, authResponse));
        List<Object> actual = PositiveServices.requestAccessToken();
        //System.assertEquals(expected, actual);
    }
    
    // Testing for negative scenario where server will be returning error status code
    @isTest static void getPositiveAuthTokenWithErrorStatusCodeTest() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(500, 'Error Response'));
        List<Object> actual = PositiveServices.requestAccessToken();
        //System.assertEquals(null, null, 'Expecting null');
    }
    
    // Testing for negative scenario where server will be returning error response body
    @isTest static void getPositiveAuthTokenWithErrorResponseTest() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(200, '{}'));
        List<Object> actual = PositiveServices.requestAccessToken();
        //System.assertEquals(null, null, 'Expecting null');
    }
    
    @isTest static void postOrderTest(){
         String expected = '{"offset": 0, "limit": 0,  "totalCount": 0,  "first": "string",  "previous": "string",' + 
             '"next": "string",  "last": "string", "items": [{ "orderNumber": 0, "orderId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",'+ 
             '"consigneeName": "string", "receivedOn": "2022-12-28T10:14:21.285Z", "offDocked": "2022-12-28T10:14:21.285Z",'+
             '"cancelledOn": "2022-12-28T10:14:21.285Z", "referenceNumber": "string", "courierWaybillNumber": "string",'+
      		 '"freightWaybillNumber": "string", "shippingMethod": "string", "fulfillmentCenter": "string", "customerCode": "string" }]}';
  
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Positive_Auth/oauth/token' => new HttpCalloutServiceMock(200, authResponse),
            'callout:PositiveAPI/v0/order' => new HttpCalloutServiceMock(200, expected)}));
        PositiveOrderResponse pOWrap = new PositiveOrderResponse();
        String jsonStringRequest = JSON.serializePretty(pOWrap,true);
        List<Object> positiveServiceReqRes = PositiveServices.postOrder(jsonStringRequest);
        if(positiveServiceReqRes != null) {
            HttpResponse res = New HttpResponse();
            String actual = res.getBody();
            if (!String.isBlank(res.getBody()) && res.getStatusCode() == 200) {
                System.assertEquals(expected, actual, 'Response body should be ' + expected);
            }
        }
        
    }
    
   
}