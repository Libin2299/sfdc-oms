@isTest
public class NotificationServiceTest implements SystemX.HasRun {
    public String run() {
        return 'OK';
    }

    static void setup() {
        insert new NotificationServiceProvider__c(ApexAdapter__c = 'NotificationServiceTest', Reference__c = 'Reference');
        insert new NotificationServiceProvider__c(ApexAdapter__c = 'NotificationServiceTest', Reference__c = 'Reference', Locale__c = 'en-US');
        insert new NotificationServiceProvider__c(ApexAdapter__c = 'NoAdapter', Reference__c = 'NoAdapter');
        insert new NotificationServiceProvider__c(ApexAdapter__c = 'Account', Reference__c = 'NoRun');
    }

    @isTest static void shouldInvokable() {
        setup();
        Test.startTest();
        NotificationService.FlowInput input1 = new NotificationService.FlowInput();
        input1.event = true;
        input1.referenceEntityId = UserInfo.getUserId();
        input1.reference = 'Reference';
        NotificationService.FlowInput input2 = new NotificationService.FlowInput();
        input2.event = false;
        input2.referenceEntityId = UserInfo.getUserId();
        input2.reference = 'Shipped';
        NotificationService.FlowInput input3 = new NotificationService.FlowInput();
        input2.event = false;
        input2.referenceEntityId = UserInfo.getUserId();
        input2.reference = 'Canceled';
        NotificationService.FlowInput input4 = new NotificationService.FlowInput();
        input2.event = false;
        input2.referenceEntityId = UserInfo.getUserId();
        input2.reference = 'RefundInitiated';
        NotificationService.FlowInput input5 = new NotificationService.FlowInput();
        input2.event = false;
        input2.referenceEntityId = UserInfo.getUserId();
        input2.reference = 'RefundComplete';
        List<NotificationService.FlowOutput> outputs = NotificationService.invocable(new List<NotificationService.FlowInput> { input1, input2, input3, input4, input5 });
        Test.stopTest();
        System.assert(outputs[0].result != null, 'Should be value');
        System.assert(outputs[1].result != null, 'Should be value');
    }

    @isTest static void shouldSendNotification() {
        setup();
        Test.startTest();
        List<String> actuals1 = NotificationService.sendNotifications(new List<NotificationService.Notification> {
            new NotificationService.Notification(UserInfo.getUserId(), 'Reference', null, null)
        });
        List<String> actuals2 = NotificationService.sendNotifications(new List<NotificationService.Notification> {
            new NotificationService.Notification(UserInfo.getUserId(), 'Reference', 'Locale', null)
        });
        List<String> actuals3 = NotificationService.sendNotifications(new List<NotificationService.Notification> {
            new NotificationService.Notification(UserInfo.getUserId(), 'NoAdapter', null, null)
        });
        List<String> actuals4 = NotificationService.sendNotifications(new List<NotificationService.Notification> {
            new NotificationService.Notification(UserInfo.getUserId(), 'NoRun', null, null)
        });
        List<String> actuals5 = NotificationService.sendNotifications(new List<NotificationService.Notification> {
            new NotificationService.Notification(UserInfo.getUserId(), 'Unknown', null, null)
        });
        Test.stopTest();
    }
}