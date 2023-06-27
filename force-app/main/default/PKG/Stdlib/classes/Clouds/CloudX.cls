global class CloudX {
    final static String SFCC_TOKENENDPOINT = 'https://account.demandware.com:443/dwsso/oauth2/access_token';
    final static String SFMC_TOKENENDPOINT = 'https://{stack}.auth.marketingcloudapis.com/v2/token';

    global interface HasArgs {
        void setArgs(Map<String, Object> args);
    }

    /**
    * @description gets a SFCC access token
    * @return Map<String, Object> - access_token
    */
    public static Map<String, Object> getSfccAccessToken() {
        // constructing the header and claims
        String iss = options.sfccClientId();
        String sub = options.sfccClientId();
        String aud = SFCC_TOKENENDPOINT;
        Long exp = DateTime.now().addMinutes(29).getTime() / 1000;
        String jwtHeader = '{"typ":"JWT","alg":"RS256"}';
        String jwtClaims = '{"iss":"' + iss + '","sub":"' + sub + '","aud":"' + aud + '","exp":' + exp + '}';
        String jwtRequest = System.EncodingUtil.base64Encode(Blob.valueOf(jwtHeader)).replace('+', '-').replace('/', '_') + '.' +
            System.EncodingUtil.base64Encode(Blob.valueOf(jwtClaims)).replace('+', '-').replace('/', '_');
        Blob signatureBlob = Test.isRunningTest()
            ? Blob.valueOf('signed')
            : Crypto.signWithCertificate('RSA-SHA256', Blob.valueOf(jwtRequest), options.sfccCertificateName());
        String signature = System.EncodingUtil.base64Encode(signatureBlob).replace('+', '-').replace('/', '_');
        String signedJwtRequest = jwtRequest + '.' + signature;
        
        // The JWT is fully constructed, now it's time to make the call to get the access token.
        String body = 'grant_type=client_credentials&client_assertion_type=' +
            System.EncodingUtil.urlEncode('urn:ietf:params:oauth:client-assertion-type:jwt-bearer', 'UTF-8') +
            '&client_assertion=' + signedJwtRequest;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(SFCC_TOKENENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Connection', 'keep-alive'); 
        req.setTimeout(120000);
        req.setBody(body);
        HttpResponse res;
        if (Test.isRunningTest()) {
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"accessToken","token_type":"Bearer"}');
        }
        else {
            res = new Http().send(req);
        }
        if (res.getStatusCode() != 200) {
            return null;
        }
        Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        result.put('Authorization', result.get('token_type') + ' ' + result.get('access_token'));
        return result;
    }

    /**
    * @description gets a SFMC access token
    * @return Map<String, Object> - access_token, token_type, rest_instance_url
    */
    public static Map<String, Object> getSfmcAccessToken() {
        SFMC_Credentials__mdt creds = [SELECT sfmcClientId__c, sfmcClientSecret__c, sfmcAccountId__c, sfmcStack__c from SFMC_Credentials__mdt];
        String body = '{"grant_type":"client_credentials","client_id":"' + creds.sfmcClientId__c +
            '","client_secret":"' + creds.sfmcClientSecret__c + '","scope":null,"account_id":"' + creds.sfmcAccountId__c + '"}';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(SFMC_TOKENENDPOINT.replace('{stack}', creds.sfmcStack__c));
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        // req.setHeader('Authorization', 'Bearer Token'); 
        req.setHeader('Connection', 'keep-alive'); 
        req.setTimeout(120000);
        req.setBody(body);  
        HttpResponse res;
        if (Test.isRunningTest()) {
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"accessToken","token_type":"Bearer","expires_in":1079,"scope":"scope",' +
                '"soap_instance_url":"https://x.soap.marketingcloudapis.com/","rest_instance_url":"https://x.rest.marketingcloudapis.com/"}');
        }
        else {
            res = new Http().send(req);
        }
        if (res.getStatusCode() != 200) {
            return null;
        }
        Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        result.put('Authorization', result.get('token_type') + ' ' + result.get('access_token'));
        return result;
    }

    /**
    * @description gets an OAuth access token
    * @param format the format
    * @param endpoint the endpoint
    * @param grantType the grantType
    * @param clientId the clientId
    * @param clientSecret the clientSecret
    * @param scope the scope
    * @return Map<String, Object> - access_token, token_type
    */
    public static Map<String, Object> getOauthAccessToken(String format, String endpoint, String grantType, String clientId, String clientSecret, String scope) {
        String contentType;
        String body;
        if (grantType == null) { grantType = 'client_credentials'; }
        switch on format {
            when 'json' {
                contentType = 'application/json';
                body = '{"grant_type":"' + grantType + '","client_id":"' + clientId + '","client_secret":"' + clientSecret + '","scope":' + (scope == null ? 'null' : '"' + scope + '"') + '}';
            }
            when 'json2' {
                contentType = 'application/json';
                body = '{"grantType":"' + grantType + '","clientId":"' + clientId + '","clientIdentifier":"' + clientSecret + '","scope":' + (scope == null ? 'null' : '"' + scope + '"') + '}';
            }
            when 'form' {
                contentType = 'application/x-www-form-urlencoded';
                body = 'grant_type=' + grantType + '&client_id=' + clientId + '&client_secret=' + clientSecret;
            }
            when else { throw new HandledException('Unknown: ' + format); }
        } 
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', contentType);
        req.setHeader('Connection', 'keep-alive'); 
        req.setTimeout(120000);
        req.setBody(body);  
        HttpResponse res;
        if (Test.isRunningTest()) {
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"accessToken","token_type":"Bearer","expires_in":1079,"scope":"scope"}');
        }
        else {
            res = new Http().send(req);
        }
        if (res.getStatusCode() != 200) {
            return null;
        }
        Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        if (!result.containsKey('access_token')) {
            if (result.containsKey('token')) { result.put('access_token', result.get('token')); }
        }
        if (!result.containsKey('token_type')) { result.put('token_type', 'Bearer'); }
        result.put('Authorization', result.get('token_type') + ' ' + result.get('access_token'));
        return result;
    }

    /**
    * @description gets a SFMC endpoint
    * @param accessToken the accessToken
    * @param type the type
    * @param endpoint the endpoint
    * @return String - the combined endpoint
    */
    public static String getSfmcEndpoint(Map<String, Object> accessToken, String type, string endpoint) {
        switch on type {
            when 'trigger' { return '/messaging/v1/messageDefinitionSends/key:' + endpoint + '/send'; }
            when else { throw new HandledException('Unknown type: ' + type); }
        }
    }

    /**
    * @description gets a SFCC endpoint
    * @param accessToken the accessToken
    * @param type the type
    * @param endpoint the endpoint
    * @return String - the combined endpoint
    */
    public static String getSfccEndpoint(Map<String, Object> accessToken, String type, string endpoint) {
        String sfccVersion = String.valueOf(options.sfccVersion()).replace('.', '_');
        switch on type {
            when 'data' { return '/s/-/dw/data/v' + sfccVersion + '/' + endpoint; }
            when 'shop' { return '/s/-/dw/shop/v' + sfccVersion + '/' + endpoint; }
            when else { throw new HandledException('Unknown type: ' + type); }
        }
    }

    /**
    * @description the options
    */
    global static ICloudOptions options = (ICloudOptions)SystemX.getOptions(DefaultCloudOptions.class);

    /**
    * @description makes a callout
    * @param callout the callout
    * @param accessToken the accessToken
    * @param args the args
    * @return HttpResponse
    **/
    public static HttpResponse callout(String callout, Map<String, Object> accessToken, Map<String, Object> args) {
        callout = callout.startsWith('http') ? callout : 'callout:' + callout;
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        req.setEndpoint(callout);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        if (accessToken != null) { req.setHeader('Authorization', (String)accessToken.get('Authorization')); }
        for (String key : args.keySet()) {
            Object value = args.get(key);
            switch on key {
                when 'method' { req.setMethod(String.valueOf(value)); }
                when 'endpoint' { req.setEndpoint(callout + String.valueOf(value)); }
                when 'body' {
                    if (value instanceOf String) { req.setBody((String)value); }
                    else { req.setBody(JSON.serialize(value, true)); }
                }
                when else { req.setHeader(key, String.valueOf(value)); }
            }
        }
        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (Exception e) {
            res = new HttpResponse();
            System.debug(e.getMessage() + ' #' + e.getLineNumber() + '\n' + e.getStackTraceString());
        }
		return res;
    }

    /**
    * @description makes a SFCC batched callout
    * @param callout the callout
    * @param accessToken the accessToken
    * @param batch the batch
    * @param headerArgs the header Args
    * @param args the args
    * @return HttpResponse[]
    **/
    public static HttpResponse[] calloutSfccBatch(String callout, Map<String, Object> accessToken, List<Map<String, Object>> batch, Map<String, Object> headerArgs, Map<String, Object> args) {
        // batch and return
        Integer batchSize = headerArgs.containsKey('batchSize') ? (Integer)headerArgs.get('batchSize') : 50;
        if (args != null) { batch.add(args); if (batch.size() < batchSize) { return null; } }
        if (batch.isEmpty()) { return null; }

        // submit batch
        String boundary = '23dh3f9f4';
        callout = callout.startsWith('http') ? callout : 'callout:' + callout;
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        req.setMethod('POST');
        req.setEndpoint(callout);
        req.setHeader('Content-Type', 'multipart/mixed; boundary=' + boundary);
        if (accessToken != null) { req.setHeader('Authorization', (String)accessToken.get('Authorization')); }
        req.setEndpoint(callout + '/s/-/dw/batch');
        for (String key : headerArgs.keySet()) {
            Object value = headerArgs.get(key);
            switch on key {
                when 'method' { req.setHeader('x-dw-http-method', String.valueOf(value)); }
                when 'method-override' { req.setHeader('x-dw-http-method-override', String.valueOf(value)); }
                when 'endpoint' { req.setHeader('x-dw-resource-path', String.valueOf(value)); }
                when else { req.setHeader(key, String.valueOf(value)); }
            }
        }
		List<String> body = new List<String>(); Integer r = 0;
		for (Map<String, Object> s : batch) {
            body.add('--' + boundary);
            body.add('x-dw-content-id: r' + String.valueOf(++r));
            if (s.containsKey('method')) { body.add('x-dw-http-method: ' + String.valueOf(s.get('method'))); }
            if (s.containsKey('endpoint')) { body.add('x-dw-resource-path-extension: ' + String.valueOf(s.get('endpoint'))); }
            body.add('');
            if (s.containsKey('body')) {
                Object value = s.get('body');
                if (value instanceOf String) { body.add((String)value); }
                else { body.add(JSON.serialize(value, true)); }
            }
        }
        body.add('--' + boundary + '--');
		req.setBody(String.join(body, '\n'));
        batch.clear();

        // make callout
        Integer retries = headerArgs.containsKey('retries') ? (Integer)headerArgs.get('retries') : 0;
        Http http = new Http();
        HttpResponse[] res = new HttpResponse[0];
        try {
            String rep;
            while (retries-- >= 0) {
                try {
                    rep = http.send(req).getBody();
                    break;
                }
                catch (CalloutException e) {
                    if (retries >= 0 && e.getMessage().startsWith('Exceeded maximum time allotted for callout')) {
                        System.debug('RETRY ' + retries + ' ' + e.getMessage());
                        continue;
                    }
                    throw e;
                }
            }
            // System.debug(rep);
            if (batchSize == 0) {
                HttpResponse res2 = new HttpResponse();
                res2.setBody(rep);
                res2.setStatusCode(200);
                res.add(res2);
                return res;
            }
            for (String part : rep.split('--' + boundary)) {
                Integer partIndex = part.indexOf('\n\n');
                if (partIndex == -1) { continue; }
                HttpResponse res2 = new HttpResponse();
                for (String headerBody : part.substring(1, partIndex).split('\n')) {
                    String[] header = headerBody.split(': ');
                    // System.debug('header => '+ header);
                    String headerKey = header[0];
                    String headerValue = header[1];
                    if (headerKey == 'x-dw-content-id') { continue; }
                    if (headerKey == 'x-dw-status-code') { res2.setStatusCode(Integer.valueOf(headerValue)); continue; }
                    res2.setHeader(headerKey, headerValue);
                }
                // System.debug('body => '+ part.substring(partIndex+2));
                res2.setBody(part.substring(partIndex + 2));
                res.add(res2);
            }
        } catch (Exception e) {
            System.debug(e.getMessage() + ' #' + e.getLineNumber() + '\n' + e.getStackTraceString());
            HttpResponse res2 = new HttpResponse();
            res2.setBody(e.getMessage());
            res2.setStatusCode(500);
            res.add(res2);
        }
        return res;
    }
}