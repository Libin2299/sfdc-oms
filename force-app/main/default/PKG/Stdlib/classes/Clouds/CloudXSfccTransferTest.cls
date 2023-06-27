@isTest
public class CloudXSfccTransferTest {

    public class TestTransfer extends CloudXSfccTransfer {
        public TestTransfer() {
            // endpoint = 'endpoint';
        }

        public void calloutx() {
            BatchContext ctx = new BatchContext('callout', null, new Map<String, Object> {
            });
            callout(ctx, new Map<String, Object> {
            });
        }

        public void deletex() {
            BatchContext ctx = new BatchContext('callout', null, new Map<String, Object> {
            });
            deleteBatch(ctx, 'endpoint', new String[] { 'id' });
        }

        public void queryx() {
            BatchContext ctx = new BatchContext('callout', null, new Map<String, Object> {
            });
            QueryContext qtx = new QueryContext('endpoint', 'query', 'selectx');
            queryBatch(ctx, qtx, 100);
        }

        public void queryListTotalx() {
            BatchContext ctx = new BatchContext('callout', null, new Map<String, Object> {
            });
            queryListTotal(ctx, 'endpoint');
        }
    }

	@isTest public static void shouldNewInstance() {
		Test.startTest();
        TestTransfer actual = (TestTransfer)TestTransfer.newInstance(TestTransfer.class, null);
		Test.stopTest();
        System.assert(actual != null, 'Should be value');
	}

    @isTest public static void shouldCallout() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'https://x.rest.marketingcloudapis.com' => new HttpCalloutServiceMock(200, '{}')
        }));
		Test.startTest();
        TestTransfer actual = (TestTransfer)TestTransfer.newInstance(TestTransfer.class, null);
        actual.calloutx();
		Test.stopTest();
	}

    @isTest public static void shouldDelete() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'https://x.rest.marketingcloudapis.com' => new HttpCalloutServiceMock(200, '{}')
        }));
		Test.startTest();
        TestTransfer actual = (TestTransfer)TestTransfer.newInstance(TestTransfer.class, null);
        actual.deletex();
		Test.stopTest();
	}

    @isTest public static void shouldQueryBatch() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'https://x.rest.marketingcloudapis.com' => new HttpCalloutServiceMock(200, '{}')
        }));
		Test.startTest();
        TestTransfer actual = (TestTransfer)TestTransfer.newInstance(TestTransfer.class, null);
        actual.queryx();
		Test.stopTest();
	}

    @isTest public static void shouldQueryListTotal() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'https://x.rest.marketingcloudapis.com' => new HttpCalloutServiceMock(200, '{}')
        }));
		Test.startTest();
        TestTransfer actual = (TestTransfer)TestTransfer.newInstance(TestTransfer.class, null);
        actual.queryListTotalx();
		Test.stopTest();
	}
}