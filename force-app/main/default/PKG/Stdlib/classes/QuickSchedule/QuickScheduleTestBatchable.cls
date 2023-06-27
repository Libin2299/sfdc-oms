@isTest
global class QuickScheduleTestBatchable implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('Batchable: ' + bc);
    }
        
    global void finish(Database.BatchableContext bc) { }
}
