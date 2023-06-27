public class SapFilesExportJobScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {
        Database.executeBatch(new SapFilesExportJob());
    }
}