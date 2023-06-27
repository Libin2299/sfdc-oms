public class ThreePayFulfilledJobScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {
        Id batchId = Database.executeBatch(new ThreePayFulfilledJob(), 2000);
    }
}