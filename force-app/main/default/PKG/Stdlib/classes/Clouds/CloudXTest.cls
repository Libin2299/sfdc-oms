@isTest
class CloudXTest {
    @isTest static void shouldCreateDefaultCloudOptions() {
        DefaultCloudOptions option = new DefaultCloudOptions();
        System.assert(option.sfccVersion() != null, 'Should be value');
        System.assert(option.sfccClientId() != null, 'Should be value');
        System.assert(option.sfccCertificateName() != null, 'Should be value');
        System.assert(option.sfmcStack() != null, 'Should be value');
        System.assert(option.sfmcAccountId() != null, 'Should be value');
        System.assert(option.sfmcClientId() != null, 'Should be value');
        System.assert(option.sfmcClientSecret() != null, 'Should be value');
    }

    @isTest static void shouldGetSfccAccessToken() {
        Test.startTest();
        Map<String, Object> actual = CloudX.getSfccAccessToken();
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }

    @isTest static void shouldGetSfmcAccessToken() {
        Test.startTest();
        Map<String, Object> actual = CloudX.getSfmcAccessToken();
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }

    @isTest static void shouldGetOauthAccessToken() {
        Test.startTest();
        Map<String, Object> actual = CloudX.getOauthAccessToken('json', 'endpoint', null, 'clientId', 'clientSecret', null);
        Map<String, Object> actual2 = CloudX.getOauthAccessToken('json2', 'endpoint', null, 'clientId', 'clientSecret', null);
        Map<String, Object> actual3 = CloudX.getOauthAccessToken('form', 'endpoint', null, 'clientId', 'clientSecret', null);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
        System.assert(actual3 != null, 'Should be value');
    }

    @isTest static void shouldGetSfccEndpoint() {
        Map<String, Object> accessToken = CloudX.getSfccAccessToken();
        Test.startTest();
        String actual = CloudX.getSfccEndpoint(accessToken, 'data', 'endpoint');
        String actual2 = CloudX.getSfccEndpoint(accessToken, 'shop', 'endpoint');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
    }
    
    @isTest static void shouldGetSfmcEndpoint() {
        Map<String, Object> accessToken = CloudX.getSfmcAccessToken();
        Test.startTest();
        String actual = CloudX.getSfmcEndpoint(accessToken, 'trigger', 'endpoint');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }

    
    @isTest static void shouldCallout() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(200, 'httpResponse'));
        Map<String, Object> accessToken = CloudX.getSfccAccessToken();
        Test.startTest();
        HttpResponse actual = CloudX.callout('callout', accessToken, new Map<String, Object> {
		    'method' => 'PUT',
		    'endPoint' => 'endpoint',
            'body' => 'body'
        });
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }

    @isTest static void shouldCalloutSfccBatch() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(200, 'httpResponse'));
        Map<String, Object> accessToken = CloudX.getSfccAccessToken();
        Test.startTest();
		List<Map<String, Object>> batch = new List<Map<String, Object>>();
        HttpResponse[] actual = CloudX.calloutSfccBatch('callout', accessToken, batch, new Map<String, Object> {
            'batchSize' => 1,
		    'method' => 'PUT',
		    'endPoint' => 'endpoint'
        }, new Map<String, Object> {
            'endPoint' => 'id',
            'body' => 'body'
        });
        HttpResponse[] actual1 = CloudX.calloutSfccBatch('callout', accessToken, batch, new Map<String, Object> {
            'batchSize' => 0,
		    'method' => 'PUT',
		    'endPoint' => 'endpoint',
            'headerBody' => 'headerKey + headerValue'
        }, new Map<String, Object> {
            'endPoint' => 'id',
            'body' => 'body'
        });
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual1 != null, 'Should be value');
    }
}