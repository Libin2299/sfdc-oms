@isTest 
public class CustomCommonUtilTest {
    static final String CLASS_NAME = CustomCommonUtilTest.class.getName();
    
    @isTest
    static void logExceptionTest() {
        Notification__mdt notificaiont = [SELECT Id, Interaction_Type__c, Email_addresses__c FROM Notification__mdt LIMIT 1];
        String className = notificaiont.Interaction_Type__c;
        integer i = 2;
        try {
            i = i/0;
        }
        catch(Exception ex) {
            Test.startTest();
            CustomCommonUtil.logException(className, ex);
            Test.stopTest();
        }
        GenericGatewayLog__c gl = [Select InteractionType__c from GenericGatewayLog__c where InteractionType__c =:ClassName];
        System.assertEquals(className, gl.InteractionType__c);
    }
    
    @isTest
    static void getAccessTokenTest() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setStatus('OK');
        response.setBody('{"message": "Success"}');
        System.assertEquals('Success', CustomCommonUtil.getAccessToken(response, 'message'));
    }
    
    @isTest
    static void logCalloutTest() {
        CustomCommonUtil.logCallout('interactionType', 'request', 'response', 200, 'gatewayMessage', 'errorMessage', 'referenceId');
    }

    @isTest
    static void sendEmailTest() {
        Notification__mdt notificaiont = [SELECT Id, Interaction_Type__c, Email_addresses__c FROM Notification__mdt LIMIT 1];
        CustomCommonUtil.sendEmail(notificaiont.Interaction_Type__c, 'Error');
    }

    @isTest
    static void getIdSetTest() {
        Account acc = OmsTestDataFactory.createAccount();
        List<Id> idList = new List<Id>{acc.Id};
        Test.startTest();
        Set<Set<Id>> setOfIdSet = CustomCommonUtil.getIdSet(idList);
        Test.stopTest();
        Assert.isNotNull(setOfIdSet);
    }

    @isTest
    static void updateSObjectAndLogErrosTest() {
        List<Account> accList = new List<Account>{new Account()};
        Test.startTest();
        CustomCommonUtil.updateSObjectAndLogErros(accList, CLASS_NAME);
        Test.stopTest();
        GenericGatewayLog__c log = [SELECT Id, InteractionType__c  FROM GenericGatewayLog__c  WHERE InteractionType__c = :CLASS_NAME];
        Assert.areEqual(CLASS_NAME, log.InteractionType__c);
    }
    
    @isTest
    static void getLogObjTest() {
        GenericGatewayLog__c log = CustomCommonUtil.getLogObj(
            'interactionType', 'request', 'response', 
            200, 'gatewayMessage', 'errorMessage', 'referenceId'
        );
        Assert.isNotNull(log);
    }
}