@isTest
global class HttpCalloutServiceMock implements HttpCalloutMock {
    HttpResponse response;
    Integer responseCode;
    String responseBody;
    String responseStatus;
    Blob responseBodyAsBlob;
    Map<String, String> responseHeaders;

    global HttpCalloutServiceMock() {
        responseHeaders = new Map<String, String>();
    }
    global HttpCalloutServiceMock(Integer responseCode, String responseBody) {
        responseHeaders = new Map<String, String>();
        this.responseCode = responseCode;
        this.responseBody = responseBody;
    }

    global Integer getResponseCode() { return responseCode; }
    global void setResponseCode(Integer responseCode) { this.responseCode = responseCode; }

    global String getResponseBody() { return responseBody; }
    global void setResponseBody(String responseBody) { this.responseBody = responseBody; }

    global Map<String, String> getResponseHeaders() { return responseHeaders; }
    global void setResponseHeader(String key, String value) { responseHeaders.put(key, value); }

    global String getResponseStatus() { return responseStatus; }
    global void setResponseStatus(String responseStatus) { this.responseStatus = responseStatus; }

    global Blob getResponseBodyAsBlob() { return responseBodyAsBlob; }
    global void setResponseBodyAsBlob(Blob responseBodyAsBlob) { this.responseBodyAsBlob = responseBodyAsBlob; }

    global HttpResponse respond(HttpRequest request) {
        response = new HttpResponse();
        if (responseCode != null) response.setStatusCode(responseCode);
        if (responseStatus != null) response.setStatus(responseStatus);
        if (responseBodyAsBlob != null) response.setBodyAsBlob(responseBodyAsBlob);
        else response.setBody(responseBody);
        if (responseHeaders != null) for (String headerKey : responseHeaders.keySet()) response.setHeader(headerKey, responseHeaders.get(headerKey));
        return response;
    }
}