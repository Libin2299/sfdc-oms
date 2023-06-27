global class SapRefundExportJobScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
        Id batchId = Database.executeBatch(new SapRefundExportJob(), 2000);
    }
}