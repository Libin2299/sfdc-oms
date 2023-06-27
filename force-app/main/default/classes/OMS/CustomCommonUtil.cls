public class CustomCommonUtil {
    
    public static void logException(String interactionType, Exception ex) {
        String errorMessage = 'Exception Type: ' + ex.getTypeName() + ', Error Message: ' + ex.getMessage() + ', LineNumber: ' + ex.getLineNumber() + ', StackTrace: ' + ex.getStackTraceString();
        insert new GenericGatewayLog__c(InteractionType__c = interactionType, ErrorMessage__c = errorMessage);
        //sendEmail(interactionType, errorMessage);
    }
    
    public static String getAccessToken(HttpResponse res, String key) {
        String accessToken;
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>)System.JSON.deserializeUntyped(res.getBody());
            if (responseMap.containsKey(key)) {
                accessToken = (String)responseMap.get(key);
            }
        }
        return accessToken;
    }
    public static void sendEmail(String interactionType, String errorMessage) {
        List<Notification__mdt> notificationList = [SELECT Id, Interaction_Type__c, Email_addresses__c FROM Notification__mdt WHERE Interaction_Type__c = :interactionType];
        if (!notificationList.isEmpty()) {
            for (Notification__mdt notification : notificationList) {
                List<String> emailIds = notification.Email_addresses__c.split(',');
                if (!emailIds.isEmpty()) {
                    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                    msg.setSubject('Exception from ' + interactionType);
                    msg.setToAddresses(emailIds);
                    msg.setPlainTextBody(errorMessage);
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{msg});
                }
            }
        }
    }

    public static void logCallout(String interactionType, String request, String response, Integer statusCode, String gatewayMessage, String errorMessage, String referenceId) {
        insert new GenericGatewayLog__c(InteractionType__c = interactionType, Request__c = request, 
                                        Response__c = response, ResultCode__c = statusCode, 
                                        GatewayMessage__c = gatewayMessage, ErrorMessage__c = errorMessage, 
                                        Object_Reference_Id__c = referenceId);
    }

    //Breaks the list of ids into 10 thousand separate set
    public static Set<Set<Id>> getIdSet(List<Id> idList) {
        Set<Set<Id>> setOfIdSet = new Set<Set<Id>>();
        if (!idList.isEmpty()) {
            Integer sObjSize = idList.size();
            Integer maxRecords = 10000;
            Integer outerCount = Integer.valueOf(Math.ceil(Decimal.valueOf(sObjSize) / Decimal.valueOf(maxRecords)));
            Integer innerCount = outerCount == 1 ? sObjSize : 9999;
            Integer j = 0;
            for (Integer i = 1; i <= outerCount; i++) {
                Set<Id> idSet = new Set<Id>();
                for (; j <= innerCount && j < sObjSize; j++) {
                    idSet.add(idList.get(j));
                }
                setOfIdSet.add(idSet);
                j = innerCount + 1;
                innercount = j + 9999;
            }
        }
        return setOfIdSet;
    }

    public static void logDmlException(Database.SaveResult[] srList, String interactionType) {
        String errorMessage;
        List<String> errorList = new List<String>();
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    errorMessage = err.getMessage() + ' and the fields that are affected this error: ' + err.getFields();
                    errorList.add(errorMessage);
                }
            }
        }
        if (!errorList.isEmpty()) {
            insert new GenericGatewayLog__c(InteractionType__c = interactionType, ErrorMessage__c = errorList.toString());
        }
    }

    public static void updateSObjectAndLogErros(sObject[] recordsToUpdate, String interactionType) {
        Database.SaveResult[] srList = Database.update(recordsToUpdate, false);
        logDmlException(srList, interactionType);
    }

    public static GenericGatewayLog__c getLogObj(String interactionType, String request, String response, Integer statusCode, String gatewayMessage, String errorMessage, String referenceId) {
        return new GenericGatewayLog__c(
            InteractionType__c = interactionType, Request__c = request, Response__c = response, 
            ResultCode__c = statusCode, GatewayMessage__c = gatewayMessage, 
            ErrorMessage__c = errorMessage, Object_Reference_Id__c = referenceId);
    }
}