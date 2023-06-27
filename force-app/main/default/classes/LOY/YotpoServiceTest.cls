@isTest
public class YotpoServiceTest {
    static OrderSummary setup() {
        OmsOrderDataFactory.get.preamble();
        OrderSummary orderSummary = OmsOrderDataFactory.get.createOrderSummary('Standard');
        return orderSummary;
    }

    @isTest(seeAllData=true)
    static void shouldExecuteBatch() {
        //OrderSummary orderSummary = setup();
        String osId = OmsTestDataFactory.createOrderSummaryUS();
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(201, '{}'));
        LoyaltyTransactionTriggerHandler.disabled = true;
        Test.startTest();
        LoyaltyTransaction__c t = new LoyaltyTransaction__c(Action__c = 'Refund', Amount__c = 1, OrderSummary__c = osId);
        insert t;
        Database.executeBatch(new YotpoService(), 2000);
        Test.stopTest();
        LoyaltyTransaction__c actual = [SELECT GatewayStatus__c FROM LoyaltyTransaction__c WHERE Id = :t.Id];
        System.assertEquals('Sent', actual.GatewayStatus__c);
    }

    @isTest(seeAllData=true)
    public static void shouldTrigger() {
        //OrderSummary orderSummary = setup();
        String osId = OmsTestDataFactory.createOrderSummaryUS();
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMock(201, '{}'));
        LoyaltyTransactionTriggerHandler.disabled = false;
        Test.startTest();
        LoyaltyTransaction__c t = new LoyaltyTransaction__c(Action__c = 'Refund', Amount__c = 1, OrderSummary__c = osId);
        insert t;
        Test.stopTest();
        LoyaltyTransaction__c actual = [SELECT GatewayStatus__c FROM LoyaltyTransaction__c WHERE Id = :t.Id];
        System.assertEquals('Sent', actual.GatewayStatus__c);
    }
}