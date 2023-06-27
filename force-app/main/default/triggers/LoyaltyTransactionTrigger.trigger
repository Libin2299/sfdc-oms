trigger LoyaltyTransactionTrigger on LoyaltyTransaction__c (after insert, after update) {
    new LoyaltyTransactionTriggerHandler().run();
}