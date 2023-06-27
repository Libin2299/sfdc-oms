@isTest
class UserInfoXTest {
    @isTest static void shouldIsEnabledOrganization() {
        Test.startTest();
        Boolean actual = UserInfoX.isEnabledOrganization();
        Test.stopTest();
        // System.assert(actual, 'Should be value');
    }

    @isTest static void shouldIsMultiCurrencyOrganization() {
        Test.startTest();
        Boolean actual = UserInfo.isMultiCurrencyOrganization();
        Test.stopTest();
    }

    @isTest static void shouldIsPersonAccountOrganization() {
        Test.startTest();
        Boolean actual = UserInfoX.isPersonAccountOrganization();
        Test.stopTest();
    }

    @isTest static void shouldIsSandboxOrganization() {
        Test.startTest();
        Boolean actual = UserInfoX.isSandboxOrganization();
        Test.stopTest();
    }
    
    @isTest static void shouldIsStateAndCountryPicklistOrganization() {
        Test.startTest();
        Boolean actual = UserInfoX.isStateAndCountryPicklistOrganization();
        Test.stopTest();
    }
}