public class LoyaltyTransactionTriggerHandler extends TriggerHandlerX {
    public static Boolean disabled = false;

    public override void afterInsert() { 
        execute((List<LoyaltyTransaction__c>)Trigger.new);
    }
    
    public override void afterUpdate() { 
        execute((List<LoyaltyTransaction__c>)Trigger.new);
    }

    public static void execute(List<LoyaltyTransaction__c> scope) {
        if (disabled) { return; }
        for (LoyaltyTransaction__c s : scope) {
            if (s.GatewayStatus__c == null) {
                Database.executeBatch(new YotpoService());
                return;
            }
        }
    }
}