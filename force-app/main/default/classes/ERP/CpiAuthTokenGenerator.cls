public class CpiAuthTokenGenerator {
    public static String className = CpiAuthTokenGenerator.class.getName();

    // This Method is used to request access token to CPI and it will returns auth token
    public static String getCpiAuthToken() {
        String authToken;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        try {
            Sap_Cpi_Credentials__mdt creds = [SELECT Sap_Cpi_Client_Id__c, Sap_Cpi_Client_Secret__c, Sap_Cpi_Grant_Type__c FROM Sap_Cpi_Credentials__mdt];
            String requestBody = 'client_id=' + creds.Sap_Cpi_Client_Id__c +
                '&client_secret=' + creds.Sap_Cpi_Client_Secret__c +
                '&grant_type=' + creds.Sap_Cpi_Grant_Type__c;
            request.setEndpoint('callout:Cpi_Auth');
            request.setHeader('Content-Type','application/x-www-form-urlencoded');
            request.setMethod('POST');
            request.setBody(requestBody);
            HTTPResponse response = http.send(request);
            if(response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>)System.JSON.deserializeUntyped(response.getBody());
                System.debug('Access Token Response ' + responseMap);
                if(responseMap.containsKey('access_token')) {
                    authToken = (String)responseMap.get('access_token');
                }
            }
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
		return authToken;
    }
}