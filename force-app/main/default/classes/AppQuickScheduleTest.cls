@isTest
class AppQuickScheduleTest {
    static final String CRON_EXP = '0 0 23 * * ?';

    static void setup() {
        OmsOrderDataFactory.get.preamble();
        OrderSummary orderSummary = OmsOrderDataFactory.get.createOrderSummary('Standard');
    }

    @isTest
    static void shouldSchedule() {
        setup();
		Test.startTest();
        System.schedule('Test Sched', CRON_EXP, new AppQuickSchedule());
		Test.stopTest();
    }
}