global class PositiveOrderStatusImportJobScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
        Id batchId = Database.executeBatch(new PositiveOrderStatusImportJobV2(), 100);
    }
}