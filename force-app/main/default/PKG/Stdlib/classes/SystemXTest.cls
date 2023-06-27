@isTest
class SystemXTest {
    @isTest static void shouldCreateAppProcessException() {
        AppProcessException e = new AppProcessException();
        System.assert(e != null, 'Should be value');
    }

    @isTest static void shouldCreateDefaultOmsOptions() {
        DefaultOmsOptions option = new DefaultOmsOptions();
        System.assert(option.factoryTestOrder() != null, 'Should be value');
        System.assert(option.factorySalesChannel() != null, 'Should be value');
        System.assert(option.factoryDeliveryMethod() != null, 'Should be value');
        System.assert(option.factoryPaymentGateway() != null, 'Should be value');
        System.assert(option.createFulfillmentOrdersFlow() != null, 'Should be value');
        System.assert(option.createInvoiceAndEnsureFundsFlow() != null, 'Should be value');
    }

    @isTest static void shouldCreateDefaultOptions() {
        DefaultOptions option = new DefaultOptions();
        System.assert(option.enabledOrganizationIds() != null, 'Should be value');
        System.assert(option.environment() != null, 'Should be value');
        System.assert(option.serviceActions() != null, 'Should be value');
        option.serviceUserAlias(null);
    }

    @isTest static void shouldCreateEnvironment() {
        SystemX.Environment e = new SystemX.Environment(SystemX.Environs.PRODUCTION, 'f');
        System.assert(e != null, 'Should be value');
    }

    @isTest static void shouldDebug() {
        Test.startTest();
        SystemX.debug(null);
        SystemX.debug('String');
        SystemX.debug(123);
        Test.stopTest();
    }

    @isTest static void shouldGetFactory() {
        Test.startTest();
        IUserDataFactory actual = (IUserDataFactory)SystemX.getFactory(UserDataFactory.class);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
    
    @isTest static void shouldGetServiceUser() {
        Test.startTest();
        User actual = SystemX.getServiceUser(null);
        Test.stopTest();
    }

    @isTest static void shouldGetTimestamp() {
        Test.startTest();
        String actual = SystemX.getTimestamp();
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }

    @isTest static void shouldGetOptions() {
        Test.startTest();
        IOptions actual = (IOptions)SystemX.getOptions(DefaultOptions.class);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
    
    @isTest static void shouldIfNull() {
        Test.startTest();
        String actual = SystemX.ifNull(null, 'default');
        Object actual2 = SystemX.ifNull(null, 'default');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
    }

    @isTest static void shouldOptions() {
        Test.startTest();
        IOptions actual = SystemX.options;
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }

    @isTest static void shouldThreadSleep() {
        SystemX.threadSleep(1);
    }
}