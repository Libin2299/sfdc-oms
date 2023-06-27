public class PositiveServices {
    static final String CLASS_NAME = PositiveServices.class.getName();
    static final Integer TIMEOUT = 120000; //2 Minutes
    static final String POSITIVE_CACHE_KEY = 'local.CommonCache.PositiveAuthToken';
    static final Integer CACHE_TIME = 86400; //24 hours
    
	// This Method is used to request access token from Positive Fulfillement Services and return it as a String.
    public static String requestAccessToken() {
        String accessToken;
        String requestBody;
        PositiveAuthWrapper autWrapReq;
        HttpRequest req;
        HttpResponse res;
        try {
            Positive_Credentials__mdt creds = [SELECT Client_Id__c, Client_Secret__c, Audience__c, Grant_Type__c from Positive_Credentials__mdt];
            autWrapReq = new PositiveAuthWrapper();
            autWrapReq.client_id = creds.Client_Id__c;
            autWrapReq.client_secret = creds.Client_Secret__c;
            autWrapReq.audience = creds.Audience__c;
            autWrapReq.grant_type = creds.Grant_Type__c;
            requestBody = JSON.serializePretty(autWrapReq, true);
            req = new HttpRequest();
            req.setEndpoint('callout:PositiveAuth/oauth/token');
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('POST');
            req.setBody(requestBody);
            req.setTimeout(TIMEOUT);
            res = new http().send(req);
            accessToken = CustomCommonUtil.getAccessToken(res, 'access_token');
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return accessToken;
    }
    
    public static Map<String, Object> postOrder(String orderRequest) {
        HttpRequest req;
        HttpResponse res;
        String accessToken = getAccessTokenFromCache();
        if (!String.isBlank(accessToken)) {
            req = new HttpRequest();
            req.setEndpoint('callout:PositiveAPI/v0/order');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setBody(orderRequest);
            req.setMethod('POST');
            req.setTimeout(TIMEOUT);
            res = new Http().send(req);
        }
        return new Map<String, Object>{'request' => req, 'response' => res};
	}
    
    public static Map<String, Object> getOrders(String fromDT, String toDT, Integer offSet, Integer rowsPerPage, String sorting) {
        HttpRequest req;
        HttpResponse res;
        String accessToken = getAccessTokenFromCache();
        if (!String.isBlank(accessToken)) {
            req = new HttpRequest();
            req.setEndpoint('callout:PositiveAPI/v0/order?FromDate=' + EncodingUtil.urlEncode(fromDT, 'UTF-8') + 
                            '&ToDate=' + EncodingUtil.urlEncode(toDT, 'UTF-8') + '&Offset=' + offSet + 
                            '&Limit=' + rowsPerPage + '&Sorting=' + sorting);
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setMethod('GET');
            req.setTimeout(TIMEOUT);
            res = new Http().send(req);
        }
        return new Map<String, Object>{'request' => req, 'response' => res};
    }

    public static Map<String, Object> getOrderByOrderId(String orderId) {
        HttpRequest req;
        HttpResponse res;
        String accessToken = getAccessTokenFromCache();
        if (!String.isBlank(accessToken)) {
            req = new HttpRequest();
            req.setEndpoint('callout:PositiveAPI/v0/order/'+orderId);
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setMethod('GET');
            req.setTimeout(TIMEOUT);
            res = new Http().send(req);
        }
        return new Map<String, Object>{'request' => req, 'response' => res};
    }

    public static String getAccessTokenFromCache() {
        String accessToken = Test.isRunningTest() ? null : (String)Cache.Org.get(POSITIVE_CACHE_KEY);
        //If the cache is null make an auth call to PFS and cache the access token.
        if (String.isBlank(accessToken)) {
            accessToken = requestAccessToken();
            if (!Test.isRunningTest()) {
            	Cache.Org.put(POSITIVE_CACHE_KEY, accessToken, CACHE_TIME);
            }            
        }
        return accessToken;
    }

    class PositiveAuthWrapper {
        String client_id;
        String client_secret;
        String audience;
        String grant_type;
    }
}