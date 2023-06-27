public class SapRefundExportJob implements Database.Batchable<sObject> {
	//TODO To Identify Refund Fields in the Query.
	public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, CreditMemoNumber FROM CreditMemo'
        );
    }

    public void execute(Database.BatchableContext bc, List<CreditMemo> creditMemoList) {
        List<String> csv = new List<String>();
        for (CreditMemo cm : creditMemoList) {
        	csv.add('"' + cm.CreditMemoNumber + '","' + 'Line number' + '","' + 
                    'Create Date' + '","' + 'Transaction ID' + '","' + 'Time Stamp' + '","' + 'Time Zone' + '","' +
                   	'Original Order number' + '","' + 'Material' + '","' + 'Currency' + '","' + 'Refund Total Amount' + '","' +
                    'Item Total Amount' + '","' + 'Item Tax' + '","' + 'Shipping' + '","' + 'Adjustment Refund' + '","' +
                    'Adjustment Fee' + '","' + 'Shipping Tax' +'"');
        }
        if (!csv.isEmpty()) {   
        
            //TODO Identify right Custom Object instead of Export_FOI__c to link with the contentdocumentlink for OrderProductSummary.
            //Creating Custom Object Export_OPS__c to link with ContentDocumentLink
            /* 
            *   Export_FOI__c exportFO = new Export_FOI__c(
            *   ExportName__c = 'Export Product Summary records',
            *   ExportDate__c = System.today());
            *   insert exportFO; 
            */
        
            String fileContent = String.join(csv, '\n');
            ContentVersion ver = new ContentVersion(
                ContentLocation = 'S',
                Title = 'REFUND',
                VersionData = Blob.valueOf(fileContent),
                PathOnClient = 'REFUND.csv');
            insert ver;
            
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :ver.Id].ContentDocumentId;
            ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                //TODO Link Content Document to the Custom Object 
                //LinkedEntityId = exportFO.Id,
                ShareType = 'V');
            insert link;
        }
    }
    
    public void finish(Database.BatchableContext bc) { }
    
}