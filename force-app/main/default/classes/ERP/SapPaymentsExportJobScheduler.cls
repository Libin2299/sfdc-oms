public class SapPaymentsExportJobScheduler implements Schedulable {
    //This class is for scheduling SapPaymentsExportJob class
    public void execute(SchedulableContext sc) {
        Id batchId = Database.executeBatch(new SapPaymentsExportJob(), 2000);
    }
}