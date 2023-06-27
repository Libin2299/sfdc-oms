@isTest
class LogBuilderTest {

    public class TestLogBuilder extends LogBuilder {
        public override Map<Schema.SObjectType, String> makeRelatedMap() {
            return new Map<Schema.SObjectType, String> { Schema.User.SObjectType => 'OwnerId' };
        }
        public override Map<Field, String> makeFieldMap() {
            return new Map<Field, String> {
                Field.InteractionType => 'Name',
                Field.GatewayMessage => 'Description',
                Field.ErrorMessage => 'Description',
                Field.Request => 'Description',
                Field.Response => 'Description',
                Field.ResultCode => 'NumberOfEmployees'
            };
        }
        public override SObject createLog() { return new Account(); }
    }

    class TestLogBuilderCodeCoverage extends LogBuilder {
        public TestLogBuilderCodeCoverage() {
            makeRelatedMap();
            makeFieldMap();
        }
        public override SObject createLog() { return new Account(); }
    }

	@isTest static void shouldBuild() {
        Test.startTest();
        User user = [SELECT Id FROM User LIMIT 1];
        Map<String, Object> args = new Map<String, Object>();
        HttpRequest req = new HttpRequest();
        RestRequest req2 = new RestRequest();
        HttpResponse res = new HttpResponse();
        RestResponse res2 = new RestResponse();
        LogBuilder b = new TestLogBuilder()
            .relatedTo(user.Id)
            .showMoreInfo(true)
            .interactionType('interaction')
            .withGatewayMessage('gatewayMessage')
            .withErrorMessage('errorMessage')
            .withRequest(args)
            .withRequest(req)
            .withRequest(req2)
            .withResponse(res)
            .withResponse(res2);
        b.build();
        b.buildAndLog();
        Test.stopTest();
    }

    @isTest static void shouldCodeCoverage() {
        Test.startTest();
        LogBuilder b = new TestLogBuilderCodeCoverage();
        Test.stopTest();
    }
}