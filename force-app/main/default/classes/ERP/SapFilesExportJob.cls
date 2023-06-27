public class SapFilesExportJob implements Database.Batchable<ContentVersion>, Database.AllowsCallouts {
	public static String className = CpiAuthTokenGenerator.class.getName();
    public Iterable<ContentVersion> start(Database.BatchableContext bc) {
        List<Id> contentDocumentIds = getSapExportContentDocumentIds();
        List<ContentVersion> contentVersionList = getContentVersionsByContentDocumentIds(contentDocumentIds);
        return contentVersionList;
    }
    public void execute(Database.BatchableContext bc, List<ContentVersion> cvList){
        SapFilesExport.exportFilesToCpi(cvList);
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
    //This method takes the the list of ContentDocument Ids as input returns the corresponding list of the ContentVersion records
    public static List<ContentVersion> getContentVersionsByContentDocumentIds(List<Id> contentDocumentIds) {
        List<ContentVersion> cvList;
        try {
            if (contentDocumentIds.size() > 0) {
                cvList = [SELECT Id, ContentDocumentId, ContentUrl, CreatedDate, FileExtension, FileType, Title, VersionData 
                          FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE];
        	}
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return cvList;
    }
    
    //This method first gets the SAP ContentDocument records and returns the list of IDs 
    public static List<Id> getSapExportContentDocumentIds() {
        TimeZone tz = Timezone.getTimeZone('America/Los_Angeles');
        Integer offSet = tz.getOffSet(DateTime.now())/(60*60*1000);
        Datetime todayStartDateTime = Datetime.newInstanceGMT(Date.today().year(), Date.today().month(), Date.today().day(), 0 - offSet, 10, 0);
        Datetime todayEndDateTime = Datetime.newInstanceGMT(Date.today().year(), Date.today().month(), Date.today().day(), 0 - offSet, 40, 0);
        List<Id> contentDocumentIds = new List<Id>();
        List<ContentDocument> contentDocumentList;
        List<String> titleList = new List<String>{'ORDERS\\_VIVISCAL\\_%', 'REFUNDS\\_VIVISCAL\\_%', 'PAYMENTS\\_VIVISCAL\\_%', 'ORDERS\\_VIVISCALCA\\_%','REFUNDS\\_VIVISCALCA\\_%', 'PAYMENTS\\_VIVISCALCA\\_%'};
        try {
            if (Test.isRunningTest()) {
                contentDocumentList = [SELECT Id, Title from ContentDocument WHERE Title LIKE :titleList];
            } else {
                contentDocumentList = [SELECT Id, Title from ContentDocument WHERE CreatedDate >= :todayStartDateTime AND CreatedDate <= :todayEndDateTime AND Title LIKE :titleList];
            }
        	if (contentDocumentList.size() > 0) {
                for (ContentDocument cd: contentDocumentList) {
                    contentDocumentIds.add(cd.Id);
                }
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return contentDocumentIds;
    }
}