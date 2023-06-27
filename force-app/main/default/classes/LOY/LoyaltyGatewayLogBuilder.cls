global class LoyaltyGatewayLogBuilder extends LogBuilder {
    global protected override Map<Schema.SObjectType, String> makeRelatedMap() {
        return new Map<Schema.SObjectType, String> { Schema.OrderSummary.SObjectType => 'OrderSummary__c' };
    }
    global protected override SObject createLog() { return new LoyaltyGatewayLog__c(); }
}