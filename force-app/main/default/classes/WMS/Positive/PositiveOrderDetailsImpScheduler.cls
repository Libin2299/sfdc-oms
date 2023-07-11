global class PositiveOrderDetailsImpScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
        Id batchId = Database.executeBatch(new PositiveOrderDetailsStatusImportJobV2(), 10);
    }
}