@isTest
class AccountDataFactoryTest {
    @isTest static void shouldCreateAccount() {
        Test.startTest();
        Account actual = AccountDataFactory.get.createAccount('John Doe');
		Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
    
     @isTest static void shouldCreateAccount1() {
        Test.startTest();
        AccountDataFactory a = new AccountDataFactory();
        Account actual = a.createAccount('John Doe');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
}