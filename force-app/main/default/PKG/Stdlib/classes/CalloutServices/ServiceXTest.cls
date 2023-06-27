@isTest
class ServiceXTest {
	@isTest static void shouldDoPost() {
        String std = ServiceX.getAction('echo', String.class, 'value');
        String action = 'echo';

        RestRequest req = RestContext.request = new RestRequest();
		RestResponse res = RestContext.response = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/stdx.ServiceX/' + action;

		Test.startTest();
        ServiceX.doPost(std);
		Test.stopTest();
		
		System.assertEquals(200, res.statusCode, 'Should be value');
		System.assertEquals('value', res.responseBody.toString(), 'Should be value');
	}

	@isTest static void shouldActAction_Echo() {
        String std = ServiceX.getAction(ServiceX.EchoServiceAction_Name, String.class, 'value');

		Test.startTest();
        ServiceX.actAction(ServiceX.EchoServiceAction_Name, std);
		Test.stopTest();
	}
    
	@isTest static void shouldActAction_PublishEvents() {
        String std = ServiceX.getAction(EventBusX.PublishServiceAction_Name, List<SObject>.class, new SObject[] { new BatchApexErrorEvent() });

		Test.startTest();
        ServiceX.actAction(EventBusX.PublishServiceAction_Name, std);
		Test.stopTest();
	}

    @isTest static void shouldSubmit() {
		Test.startTest();
        ServiceX.submit('endpoint', null, 'echo', String.class, 'value');
		Test.stopTest();
	}
}