@isTest
public class SapFilesExportJobSchedulerTest {
    static final String authResponse = '{"access_token":"eyJhbGciOiJSUzI1NiIs"}';
    static final String cron = '0 0 0 15 3 ?';
    static List<String> titleList = new List<String>{'ORDERS_VIVISCAL_', 'REFUNDS_VIVISCAL_', 'PAYMENTS_VIVISCAL_'};   
    
    @testSetup
    static void setup() {
        List<String> fileInfo = new List<String>();
        List<ContentVersion> cvList = new List<ContentVersion>();
        fileInfo.add('LA|DTM|202107221959-5|Ship Date|202107221959-B2|1|EA|255.20|USD|214.37|291.39|13.88|9.99|0.50|53.59|N');
		String fileContent = String.join(fileInfo, '\n');
        for (String title: titleList) {
            ContentVersion cv = new ContentVersion(
                ContentLocation = 'S',
                Title = title,
                VersionData = Blob.valueOf(fileContent),
                PathOnClient = title + '.txt');
            cvList.add(cv);
        }
        insert cvList;
    }
    
    @isTest
    static void exportFilesToCpiTest() {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:Cpi_Auth' => new HttpCalloutServiceMock(200, authResponse),
            'callout:Cpi_Inventory_Information' => new HttpCalloutServiceMock(200, '{}')
        })); 
        Test.startTest();
        String jobId = System.schedule('Export Sap files to CPI Test', cron, new SapFilesExportJobScheduler());
		Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        List<ContentDocument> cdList = [SELECT Id, Title FROM ContentDocument];
        System.assertEquals(cron, ct.CronExpression);
        System.assertEquals(3, cdList.size());
        for (ContentDocument cd : cdList) {
            System.assertEquals(titleList.Contains(cd.Title), True);
        }
    }
}