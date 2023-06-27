//: curl https://test.salesforce.com/services/oauth2/token -d 'grant_type=password' -d 'client_id=3MVG9RezSyZYLh2tSdQjMmu3bpRucCSGUpXrH5sPXYwn5uBEt2Nighmam5V9beab0TaCHmhp3oVIsJAjNouRH' -d 'client_secret=E3D2ED9AB6A04FD7F8FC1070EF2D44A4954794780ED4F46ED4B8BA7D261ACA87' -d 'username=sky.morey@merklecxm.com1.dev' -d 'password=my-password'
@RestResource(urlMapping='/stdx.ServiceX/*')
global with sharing class ServiceX {
    static final Map<String, IServiceAction> serviceActions = SystemX.options.serviceActions();

    global interface IServiceAction {
        String act(String std);
        String get(Type type, Object std);
    }

    global static final string EchoServiceAction_Name = 'echo';
    global class EchoServiceAction implements IServiceAction {
        global String act(String std) { return std; }
        global String get(Type type, Object std) { return (String)std; }
    }

    /**
    * @description post handler
    * @param std the std
    **/
	@HttpPost //:post {"std":""}
    global static void doPost(String std) {
        SystemX.debug(std);
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // do action
        Savepoint sp = Database.setSavepoint();
        String action = req.requestUri.substring(req.requestUri.lastIndexOf('/') + 1);
        try {
            setResponse(res, 200, actAction(action, std));
        } catch (Exception e) {
            Database.rollback(sp);
            String resBody = e.getMessage() + '\n' + e.getStackTraceString();
            System.debug(resBody);
            setResponse(res, 500, resBody);
        }
	}

    /**
    * @description sets a response
    * @param res the res
    * @param statusCode the statusCode
    * @param body the body
    **/
    static void setResponse(RestResponse res, Integer statusCode, string body) {
        if ((statusCode != 200 || body == 'Throw') && Test.isRunningTest()) { throw new HandledException(body); }
        res.headers.put('Content-Type', 'application/json;charset=UTF-8');
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(body);
    }

    /**
    * @description does the action
    * @param action the action
    * @param std the std
    * @return String
    **/
    @testVisible
    static String actAction(String action, String std) {
        IServiceAction service = serviceActions?.get(action);
        if (service != null) { return service.act(std) ; }
        else { throw new HandledException('Unknown: ' + action); }
    }

    /**
    * @description decodes the action
    * @param action the action
    * @param type the type
    * @param std the std
    * @return String
    **/
    @testVisible
    static String getAction(String action, Type type, Object std) {
        IServiceAction service = serviceActions?.get(action);
        if (service != null) { return service.get(type, std) ; }
        else { throw new HandledException('Unknown: ' + action); }
    }

    /**
    * @description submits a request
    * @param endpoint the endpoint
    * @param accessToken the accessToken
    * @param action the action
    * @param type the type
    * @param std the std
    * @return Boolean
    **/
    global static Boolean submit(String endpoint, String accessToken, String action, Type type, Object std) {
        //:ref https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_streamline_api_calls.htm&type=5&release=216
        String body = getAction(action, type, std);
        String newEndpoint = endpoint == 'Payments' ? ''
            : endpoint == 'Self' ? Url.getOrgDomainUrl().toExternalForm()
            : endpoint;
        String authorization = accessToken == null ? null 
            : accessToken == 'Self' ? 'Bearer ' + UserInfo.getSessionId()
            : 'Bearer ' + accessToken;
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setEndpoint(newEndpoint + '/services/apexrest/stdx.ServiceX/' + action);
        if (authorization != null) { req.setHeader('Authorization', authorization); }
        req.setBody('{"std":"' + body.replace('"', '\\"') + '"}');
        req.setTimeout(120000);
        // SystemX.debug(req.getEndpoint());
        // SystemX.debug(req.getBody());
        HttpResponse res = new HttpResponse();
        try {
            res = endpoint == 'Payments'
                ? new commercepayments.PaymentsHttp().send(req)
                : new Http().send(req);
            if (res.getStatusCode() == 200) { return true; }
            System.debug('Error: [' + res.getStatusCode() + ']' + res.getBody());
            for (String s : res.getHeaderKeys()) { System.debug(s + ':' + res.getHeader(s)); }
        } catch (CalloutException e) {
            System.debug('Callout Exception: ' + e.getMessage() + '#' + e.getLineNumber() + '\n' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + '#' + e.getLineNumber() + '\n' + e.getStackTraceString());
        }
        return false;
    }
}