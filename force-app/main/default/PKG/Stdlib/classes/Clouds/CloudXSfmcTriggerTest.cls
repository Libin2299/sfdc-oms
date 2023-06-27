@isTest
public class CloudXSfmcTriggerTest {

    public class TestTransfer extends CloudXSfmcTrigger implements CloudX.HasArgs {
        public String value;
        
        public void setArgs(Map<String, Object> args) {
            for (String key : args.keySet()) {
                switch on key {
                    when 'value' { value = (String)args.get(key); }
                }
            }
        }

        public override String execute(TriggerContext ctx) {
            ctx.endpoint = 'endpoint';
            ctx.address = 'address';
            ctx.subscriberKey = 'subscriberKey';
            ctx.contactAttributes = new Map<String, Object> {
                'key1' => value,
                'key2' => value
            };
            post(ctx);
            return 'OK';
        }
    }

	@isTest public static void shouldNewInstance() {
		Test.startTest();
        TestTransfer actual = (TestTransfer)TestTransfer.newInstance(TestTransfer.class, null, new Map<String, Object> {
            'value' => 'value'
        });
		Test.stopTest();
        System.assert(actual != null, 'Should be value');
	}

    @isTest public static void shouldRun() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'https://x.rest.marketingcloudapis.com' => new HttpCalloutServiceMock(200, '{}')
        }));
		Test.startTest();
        TestTransfer actual = (TestTransfer)TestTransfer.newInstance(TestTransfer.class, null, new Map<String, Object> {
            'value' => 'value'
        });
        actual.run();
		Test.stopTest();
	}
}