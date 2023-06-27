public class PositiveServices {
    static String className = AmwareServices.class.getName();
    static Integer timeout = 120000; //2 Minutes
    
	// This Method is used to request access token from Positive Fulfillement Services and return it as a String.
    public static List<Object> requestAccessToken() {
        String accessToken;
        String requestBody;
        PositiveAuthWrapper autWrapReq;
        HttpRequest req;
        HTTPResponse res;
        try {
            Positive_Credentials__mdt creds = [SELECT Client_Id__c, Client_Secret__c, Audience__c, Grant_Type__c from Positive_Credentials__mdt];
            autWrapReq = new PositiveAuthWrapper();
            autWrapReq.client_id = creds.Client_Id__c;
            autWrapReq.client_secret = creds.Client_Secret__c;
            autWrapReq.audience = creds.Audience__c;
            autWrapReq.grant_type = creds.Grant_Type__c;
            requestBody = JSON.serializePretty(autWrapReq, true);
            req = new HttpRequest();
            req.setEndpoint('callout:Positive_Auth/oauth/token');
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('POST');
            req.setBody(requestBody);
            req.setTimeout(timeout);
            res = new http().send(req);
        } catch(System.CalloutException e) {
            String errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
            insert new GenericGatewayLog__c(InteractionType__c = 'PositiveServices', ErrorMessage__c = errorMessage);    
        }
        //return accessToken;
        return new List<Object>{req, res};
    }
    
    public static List<Object> postOrder(String orderRequest) {
        HttpRequest req;
        HTTPResponse res;
        String accessToken;
        List<Object> accessTokenReqRes;
        accessTokenReqRes = requestAccessToken();
        accessToken = CustomCommonUtil.getAccessToken((HttpResponse)accessTokenReqRes[1], 'access_token');
        if(!String.isBlank(accessToken)) {
            req = new HttpRequest();
            req.setEndpoint('callout:PositiveAPI/v0/order');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setBody(orderRequest);
            req.setMethod('POST');
            req.setTimeout(timeout);
            res = new Http().send(req);
        }
        return new List<Object> {accessTokenReqRes[0], accessTokenReqRes[1], req, res};
	}
    
    public static List<Object> getOrders(String fromDT, String toDT, Integer offSet, Integer rowsPerPage, String sorting) {
        HttpRequest req;
        HTTPResponse res;
        String accessToken;
        List<Object> accessTokenReqRes;
        accessTokenReqRes = requestAccessToken();
        accessToken = CustomCommonUtil.getAccessToken((HttpResponse)accessTokenReqRes[1], 'access_token');
        if(!String.isBlank(accessToken)) {
            req = new HttpRequest();
            req.setEndpoint('callout:PositiveAPI/v0/order?FromDate=' + fromDT + '&ToDate=' + toDT + 
                            '&Offset=' + offSet + '&Limit=' + rowsPerPage + '&Sorting=' + sorting);
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setMethod('GET');
            req.setTimeout(timeout);
            res = new Http().send(req);
            System.debug('Response body ' + res.getBody());
        }
        return new List<Object>{accessTokenReqRes[0], accessTokenReqRes[1], req, res};
    }

    class PositiveAuthWrapper {
        String client_id;
        String client_secret;
        String audience;
        String grant_type;
    }
}