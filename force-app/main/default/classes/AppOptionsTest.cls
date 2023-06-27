@isTest
class AppOptionsTest {
    @isTest static void shouldCreateAppCloudOptions() {
        AppCloudOptions option = new AppCloudOptions();
        System.assert(option.sfmcStack() != null, 'Should be value');
        System.assert(option.sfmcAccountId() != null, 'Should be value');
        System.assert(option.sfmcClientId() != null, 'Should be value');
        System.assert(option.sfmcClientSecret() != null, 'Should be value');
    }

    @isTest static void shouldCreateAppOmsOptions() {
        AppOmsOptions option = new AppOmsOptions();
        System.assert(option.factorySalesChannel() != null, 'Should be value');
    }
}