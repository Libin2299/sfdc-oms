@isTest
class OmsImportsTest {
    static final String CRON_EXP = '0 0 23 * * ?';

    static void setup() {
        OmsOrderDataFactory.get.preamble();
        OrderSummary orderSummary = OmsOrderDataFactory.get.createOrderSummary('Standard');
    }

    @isTest static void shouldExecuteBatch() {
        setup();
		Test.startTest();
        Database.executeBatch(new OmsImportsOrderSummary(1), 1);
        Database.executeBatch(new OmsImportsOrderSummary(2), 1);
		Test.stopTest();
    }
}