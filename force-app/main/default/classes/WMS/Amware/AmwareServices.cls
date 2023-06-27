public class AmwareServices {
    static String className = AmwareServices.class.getName();
    static Integer timeout = 120000; //2 Minutes
    
    // This Method is used to make request access token to Amware and it will returns auth token
    public static String getAmwareAuthToken() {
        String authToken;
        HttpRequest req = new HttpRequest();
        HttpResponse res;
        try {
            Amware_Credentials__mdt creds = [SELECT Amware_Client_Id__c, Amware_Client_Identifier__c from Amware_Credentials__mdt];
            String requestBody = '{"clientId":"' + creds.Amware_Client_Id__c + '","clientIdentifier":"' + creds.Amware_Client_Identifier__c + '"}';
            req.setEndpoint('callout:Amware/api/authentication/authenticate');
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('POST');
            req.setBody(requestBody);
            req.setTimeout(timeout);
            res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> authResMap = (Map<String, Object>)System.JSON.deserializeUntyped(res.getBody());
                System.debug('Amware jsonMap=' + authResMap);
                if (authResMap.containsKey('token')) {
                    authToken = (String)authResMap.get('token');
                }
            }
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return authToken;
    }
    
    // This method makes GET request to the Amware and gets fulfillment order details by date and time
    public static List<Object> getFulfillmentByUTCDate(String sinceDateTime, Integer rowsPerPage, Integer pageIndex) {
        String amwareResponse;
        List<Object> objList;
        HttpResponse res;
        String authToken = getAmwareAuthToken();
        if(!String.isBlank(authToken)) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Amware/api/fulfillment/fulfillmentbyUTCDate?orderSource=API'+ 
                            '&rowsPerPage=' + rowsPerPage +
                            '&pageIndex=' + pageIndex +
                            '&sinceDateTime=' + EncodingUtil.urlEncode(sinceDateTime, 'UTF-8'));
            req.setHeader('Authorization', 'Bearer ' + authToken);
            req.setMethod('GET');
            req.setTimeout(timeout);
            try {
                res = new Http().send(req);
            } catch(Exception ex) {
                CustomCommonUtil.logException(className, ex);
            }
            objList = new List<Object> {req, res};
        } 
        return objList;
    }
    
    // Following method will be used to Post Order to Amware.
	public static String postOrder(String jsonStringRequest) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        HttpResponse response;
		String accessToken = getAmwareAuthToken();
        if(!String.isBlank(accessToken)) {
            request.setEndpoint('callout:Amware/api/order/order');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setBody(jsonStringRequest);
            request.setMethod('POST');
            request.setTimeout(timeout);
            
            try {
                response = http.send(request); 
            } catch(System.CalloutException e) {
                CustomCommonUtil.logException(className, e);
            }   
            return response.toString();
        } else {
            System.debug('Invalid Auth Token:' + accessToken);
            return null;
        }
	}
    
    // Following method will be used to process GET Returns from to Amware.
    public static List<Object> getReturns(Integer rowsPerPage, Integer pageIndex, String sinceDateTime) {
        List<Object> objList;
        Http http = new Http();
        HttpResponse response;  
        HttpRequest request = new HttpRequest();
        String accessToken = getAmwareAuthToken();
        if(!String.isBlank(accessToken)) {
            request.setEndpoint('callout:Amware/api/return/returnsbyDate'+
                                '?rowsPerPage=' + rowsPerPage + '&pageIndex=' + pageIndex +
                                '&sinceDateTime=' + EncodingUtil.urlEncode(sinceDateTime, 'UTF-8'));
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setMethod('GET');
            request.setTimeout(timeout);
            try {
                response = http.send(request);
            } catch(Exception ex) {
                CustomCommonUtil.logException(className, ex);
            } 
        	objList = new List<Object> {request, response};
            System.debug('End Get Return');
            return objList;
        } else {
            System.debug('Invalid Auth Token:' + accessToken);
            return null;
        }
    }

    public static List<Object> getOrderStatusByOrderNumber(String orderNumber) {
        List<Object> objList;
        HttpResponse res;
        String authToken = getAmwareAuthToken();
        if(!String.isBlank(authToken)) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Amware/api/fulfillment/fulfillment?ReferenceNumber=' + orderNumber);
            req.setHeader('Authorization', 'Bearer ' + authToken);
            req.setMethod('GET');
            req.setTimeout(timeout);
            try {
                res = new Http().send(req);
            } catch(Exception ex) {
                CustomCommonUtil.logException(className, ex);
            }
            objList = new List<Object> {req, res};
        } 
        return objList;
    }
}