public class SapFilesExport {
    public static String currentDate = System.now().format('yyyyMMddhhmmss');
    public static String className = CpiAuthTokenGenerator.class.getName();

    public static void exportFilesToCpi(List<ContentVersion> cvList) {
        try {
            if (!cvList.isEmpty()) {
                String accessToken = CpiAuthTokenGenerator.getCpiAuthToken();
                List<GenericGatewayLog__c> genericGatewayList = new List<GenericGatewayLog__c>();
                if (!String.isBlank(accessToken)) {
                    HttpRequest request = new HttpRequest();
                    for (ContentVersion cv: cvList) {
                        String fileName = String.valueOf(cv.Title).substringBeforeLast('_');
                        Blob fileContent =cv.VersionData;
                        String fileContentAsString= fileContent.toString();
                        GenericGatewayLog__c genericGateway = new GenericGatewayLog__c();
                        request.setEndpoint('callout:Cpi_Inventory_Information');
                        request.setHeader('Authorization', 'Bearer ' + accessToken);
                        request.setHeader('Content-Type', 'text/plain');
                        request.setHeader('File_Name', fileName);
                        request.setHeader('Time_Stamp', currentDate);
                        request.setMethod('POST');
                        request.setBody(fileContentAsString);
                        HttpResponse response = new Http().send(request);
                        genericGateway.InteractionType__c = 'SapFilesExport';
                        genericGateway.Request__c = request.toString();
                        genericGateway.Response__c = response.toString();
                        genericGateway.ResultCode__c = response.getStatusCode();
                        if (response.getStatusCode() != 200) {
                            genericGateway.ErrorMessage__c = cv.Title + ' is not successfully exported to CPI and its Content Document Id is ' + cv?.ContentDocumentId; 
                        }
                        genericGatewayList.add(genericGateway);
                    }
                } else {
                    genericGatewayList.add(new GenericGatewayLog__c(InteractionType__c = 'CpiAuthTokenGenerator', ErrorMessage__c = 'No CPI access token generated'));
                }
                if(!genericGatewayList.isEmpty()) {
                    insert genericGatewayList;
                }
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
}