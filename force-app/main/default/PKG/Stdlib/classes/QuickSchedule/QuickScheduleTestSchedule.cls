@isTest
public class QuickScheduleTestSchedule extends QuickSchedule {

    class TestSchedulable implements Schedulable {
        public void execute(SchedulableContext sc) {
            System.debug('Schedulable: ' + sc);
        }
    }

    class TestQueueable implements Queueable {
        public void execute(QueueableContext qc) {
            System.debug('Queueable: ' + qc);
        }
    }

    public override List<QuickScheduleJob> getJobs() {
        return new List<QuickScheduleJob> {
            new QuickScheduleJob(-5, TestSchedulable.class),
            new QuickScheduleJob(5, TestSchedulable.class),
            new QuickScheduleJob(5, TestQueueable.class),
            new QuickScheduleJob(5, QuickScheduleTestBatchable.class, 1)
        };
    }
}
