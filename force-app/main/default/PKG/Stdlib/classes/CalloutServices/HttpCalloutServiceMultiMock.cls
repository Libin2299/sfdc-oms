@isTest
global class HttpCalloutServiceMultiMock implements HttpCalloutMock {
    Map<String, HttpCalloutServiceMock> calloutMocks;

    global HttpCalloutServiceMultiMock() {
        calloutMocks = new Map<String, HttpCalloutServiceMock>();
    }
    global HttpCalloutServiceMultiMock(Map<String, HttpCalloutServiceMock> calloutMocks) {
        this.calloutMocks = calloutMocks != null ? calloutMocks : new Map<String, HttpCalloutServiceMock>();
    }

    global void addCalloutMock(String endpoint, HttpCalloutServiceMock calloutMock) { calloutMocks.put(endpoint, calloutMock); }

    global HttpResponse respond(HttpRequest request) {
        HttpCalloutServiceMock calloutMock = calloutMocks.get(request.getEndpoint());
        if (calloutMock != null) { return calloutMock.respond(request); }
        else { throw new HandledException('Response Mock not found for the current request URL'); }
    }
}