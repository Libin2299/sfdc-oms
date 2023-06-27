@isTest
class QuickScheduleTest {
    static final String CRON_EXP = '0 0 23 * * ?';

    @isTest static void shouldSchedule() {
		Test.startTest();
        String jobId = System.schedule('Test Sched', CRON_EXP, new QuickScheduleTestSchedule());
		Test.stopTest();
    }

    @isTest static void shouldRun() {
		Test.startTest();
        new QuickScheduleTestSchedule().run();
		Test.stopTest();
    }

    @isTest static void shouldAbort() {
        new QuickScheduleTestSchedule().run();
		Test.startTest();
        new QuickScheduleTestSchedule().abort();
		Test.stopTest();
    }
}