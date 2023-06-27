@isTest
class DatabaseJobTest {
    @testSetup
    static void setup() {
        Account parentAccount = new Account(Name='ParentTest', Business_Unit__c='US');
        insert parentAccount;
        insert new Account(Name='Test', ParentId=parentAccount.Id, Business_Unit__c='US');
    }

    @isTest static void shouldBatchThrow() {
        Test.startTest();
        Boolean actual = false;
        try {
            new DatabaseJob(null, new HandledException()).execute(null, null);
        } catch (Exception e) { actual = true; }
        Test.stopTest();
        System.assertEquals(true, actual, 'Should be value');
	}

	@isTest static void shouldBatchInsertRefAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id FROM Account WHERE Name = \'Test\'',
            new DatabaseJob.InsertRefAction(Contact.class, 'Id', new Map<String, Object> { 
                'LastName' => 'LastName',
                'Description' => 'Test'
            })).run();
        Test.stopTest();
	}

	@isTest static void shouldBatchUpdateAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id FROM Account WHERE Name = \'Test\'',
            new DatabaseJob.UpdateAction('Description', 'Test')).run();
        Test.stopTest();
	}

    @isTest static void shouldBatchUpdateRefAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id, Parent.OwnerId FROM Account WHERE Name = \'Test\'',
            new DatabaseJob.UpdateRefAction(User.class, 'Parent.OwnerId', 'LastName', 'Test')).run();
        Test.stopTest();
	}

    @isTest static void shouldBatchDeleteAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id FROM Account WHERE Name = \'Test\'',
            new DatabaseJob.DeleteAction()).run();
        Test.stopTest();
	}

    @isTest static void shouldBatchDeleteRefAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id, ParentId FROM Account WHERE Name = \'Test\'',
            new DatabaseJob.DeleteRefAction(Account.class, 'ParentId')).run();
        Test.stopTest();
	}

	@isTest static void shouldBatchFlowAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id FROM Account WHERE Name = \'Test\'',
            new DatabaseJob.FlowAction('Some_Flow.AccountId', 'Description', 'Test')).run();
        Test.stopTest();
	}

    @isTest static void shouldBatchFlowRefAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id, Parent.OwnerId FROM Account WHERE Name = \'Test\'',
            new DatabaseJob.FlowRefAction(User.class, 'Parent.OwnerId', 'Some_Flow.AccountId', 'LastName', 'Test')).run();
        Test.stopTest();
	}

    class MyCustomAction extends DatabaseJob.CustomAction {
        public override void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) { }
    }

    @isTest static void shouldBatchCustomAction() {
        Test.startTest();
        new DatabaseJob('SELECT Id FROM Account WHERE Name = \'Test\'',
            new MyCustomAction()).run();
        Test.stopTest();
	}

    @isTest static void shouldScheduleCustomAction() {
        Test.startTest();
        new DatabaseJob.Schedule('SELECT Id FROM Account WHERE Name = \'Test\'',
            new MyCustomAction()).run();
        Test.stopTest();
        }

    @isTest static void shouldQueueCustomAction() {
        Test.startTest();
        new DatabaseJob.Queue('SELECT Id FROM Account WHERE Name = \'Test\'',
            new MyCustomAction()).run();
        Test.stopTest();
	}
}