@isTest
class UserDataFactoryTest {
    @isTest static void shouldCreateUser() {
        Test.startTest();
        Account account = new Account(Name='name', Business_Unit__c='US'); insert account;
        Contact contact = new Contact(FirstName='first name', LastName = 'last name', Email='mail@mail.com'); insert contact;
        User actual = UserDataFactory.get.createUser(account, contact, 'Standard User');
        User actual2 = UserDataFactory.get.createUser('name', 'last name', 'Standard User');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
    }

    @isTest static void shouldCreateEmail() {
        Test.startTest();
        String actual = UserDataFactory.get.createEmail('name', 'last name');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
    
    @isTest static void shouldCreateAlias() {
        Test.startTest();
        String actual = UserDataFactory.get.createAlias('name', 'last name');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
}