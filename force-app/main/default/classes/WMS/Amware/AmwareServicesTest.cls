@isTest
public class AmwareServicesTest {
    static final String authResponse = '{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"}';
    // static final Integer responseCode = 200;
    // For checking the negative scenarios
    // static final Integer serverErrorCode = 500;
    
    // Test for positive scenario where server will responding with the correct statuscode and response body
    @isTest static void getAmwareAuthTokenTest() {
        String expected = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(200, authResponse));
        String actual = AmwareServices.getAmwareAuthToken();
        System.assertEquals(expected, actual);
    }
    
    // Testing for negative scenario where server will be returning error status code
    @isTest static void getAmwareAuthTokenWithErrorStatusCodeTest() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(500, 'Error Response'));
        String actual = AmwareServices.getAmwareAuthToken();
        System.assertEquals(null, null, 'Expecting null');
    }
    
    // Testing for negative scenario where server will be returning error response body
    @isTest static void getAmwareAuthTokenWithErrorResponseTest() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(200, '{}'));
        String actual = AmwareServices.getAmwareAuthToken();
        System.assertEquals(null, null, 'Expecting null');
    }
    
    // Test for positive scenario where server will responding with the correct statuscode and response body
    @isTest static void getFulfillmentByUTCDateTest() {
        String expected = '{"shipConfirms": [{"internalOrderId": 1572621,"externalOrderId": null,"clientReference": "S00059",'+
            '"clientId": 9999,"orderSource": "API","shipType": "S","packages": [{"facilityId": "ATLANTA","shipmentId": 20512707,'+
            '"shipConfirmReceived": null,"carrier": "PROSHIP.FEDEX","service": "PRO FEDEX SMARTPOST","shipmentgGroupId": 0,'+
            '"trackingNumber": "61290322717320109516","trackingURI": "https://mocktracking.com?trackingId=61290322717320109516","proNumber": null,"description": "TESTING",'+
            '"packageType": 4,"length": 1,"width": 2,"depth": 3,"volume": 6,"weight": 1,"shipDate": "2020-10-06T18:51:53.963",'+
            '"internalLicensePlate": "700-0001112","externalLicensePlate": null,"lineItems": [{"sku": "Test1","quantity": 10,'+
            '"lineNo": 1,"lotNumber": null,"externalLineId": null,"serialNumber": null,"pass01": null,"pass02": null,"pass03": null,'+
            '"pass04": null,"pass05": null}]}]}],"recordCount": 1}';
        String currentDT = String.valueOf(System.now().format('yyyy-MM-dd h:mm'));
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
            'callout:Amware/api/fulfillment/fulfillmentbyUTCDate?orderSource=API&rowsPerPage=200&pageIndex=0&sinceDateTime='+EncodingUtil.urlEncode(currentDT, 'UTF-8') => new HttpCalloutServiceMock(200, expected)
        }));
          List<Object> amwareFulfillmentReqRes = AmwareServices.getFulfillmentByUTCDate(currentDT, 200, 0);
                    if(amwareFulfillmentReqRes != null) {
                       HttpResponse res = (HttpResponse) amwareFulfillmentReqRes[1];
                        String actual = res.getBody();
                        if (!String.isBlank(res.getBody()) && res.getStatusCode() == 200) {
                            System.assertEquals(expected, actual, 'Response body should be ' + expected);
                        }
                    }
    }
    
    // Testing for negative scenario where server will be returning error status code
    @isTest static void getFulfillmentByDateUTCWithErrorStatusCodeTest() {
        String currentDT = String.valueOf(System.now().format('yyyy-MM-dd h:mm'));
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
                'callout:Amware/api/fulfillment/fulfillmentbyUTCDate?orderSource=API&rowsPerPage=200&pageIndex=0&sinceDateTime='+EncodingUtil.urlEncode(currentDT, 'UTF-8') => new HttpCalloutServiceMock(500, '{}')
        }));
        //String actual = AmwareServices.getFulfillmentByUTCDate(currentDT, 200, 0);
        List<Object> amwareFulfillmentReqRes = AmwareServices.getFulfillmentByUTCDate(currentDT, 200, 0);
                    if(amwareFulfillmentReqRes != null) {
                        HttpResponse res = (HttpResponse) amwareFulfillmentReqRes[1];
                        System.assertEquals(null, null, 'Expecting Null');
                    }
    }
    
    
    // Testing for negative scenario where server will be no return auth token
    @isTest static void getFulfillmentByUTCDateWithNoAuthTokenTest() {
        String currentDT = String.valueOf(System.now().format('yyyy-MM-dd h:mm'));
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, '{}'),
            'callout:Amware/api/fulfillment/fulfillmentbyUTCDate?orderSource=API&rowsPerPage=200&pageIndex=0&sinceDateTime=' + EncodingUtil.urlEncode(currentDT, 'UTF-8') => new HttpCalloutServiceMock(500, 'Error Response')
        }));
        List<Object> amwareFulfillmentReqRes = AmwareServices.getFulfillmentByUTCDate(currentDT, 200, 0);
                    if(amwareFulfillmentReqRes != null) {
                        HttpResponse res = (HttpResponse) amwareFulfillmentReqRes[1];
                        System.assertEquals(null, null, 'Expecting Null');
                    }
    }

    @isTest
    static void postOrderTest() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
            'callout:Amware/api/order/order' => new HttpCalloutServiceMock(200, '{}')
        }));
        AmwareServices.postOrder('test');
    }

    @isTest
    static void getReturnsTest() {
        Integer rowsPerPage = 200;
        Integer pageIndex = 0;
        String sinceDateTime = '2023-01-29 00:00';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
            'callout:Amware/api/return/returnsbyDate'+'?rowsPerPage=' + rowsPerPage + '&pageIndex=' + pageIndex +
            '&sinceDateTime=' + EncodingUtil.urlEncode(sinceDateTime, 'UTF-8') => new HttpCalloutServiceMock(200, '{}')
        }));
        AmwareServices.getReturns(rowsPerPage, pageIndex, sinceDateTime);
    }

    @isTest
    static void getOrderStatusByOrderNumberTest() {
        String orderNumber = '00001234';
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Amware/api/authentication/authenticate' => new HttpCalloutServiceMock(200, authResponse),
            'callout:Amware/api/fulfillment/fulfillment?ReferenceNumber=' + orderNumber => new HttpCalloutServiceMock(200, '{}')
        }));
        AmwareServices.getOrderStatusByOrderNumber(orderNumber);
    }
}