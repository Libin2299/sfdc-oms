public class SapRefundExportJobSchedule {
    public void execute(SchedulableContext sc) {
    	SapRefundExportJob sapRefundObj = new SapRefundExportJob();
        Id batchId = Database.executeBatch(sapRefundObj, 2000);
    }
}