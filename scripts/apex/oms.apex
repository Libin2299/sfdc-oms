// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

//Loyalty rewards
Database.executeBatch(new YotpoService());

//Shipment email confirmation
OmsEmailTest2.shouldShipped();

//check gateway logs
SELECT CreatedDate, Request__c FROM WmsGatewayLog__c 
WHERE CreatedDate > 2022-12-15T00:00:00.000Z and CreatedDate <2022-12-15T23:59:00.000Z
ORDER BY CreatedDate DESC

//SAP Order export job
String fromDate = '2023-03-05T00:00:01.000';
String endDate = '2023-03-06T23:59:59.000';
SapOrdersExportJob soej = new SapOrdersExportJob(fromDate, endDate);
Database.executeBatch(soej);

//SAP Order Payment export job
SapPaymentsExportJob sopej = new SapPaymentsExportJob(fromDate, endDate, false);
Database.executeBatch(sopej);

//SAP Refund export job
SapRefundExportJob screj = new SapRefundExportJob();
Database.executeBatch(screj);

//SAP Files export job
SapFilesExportJob sfej = new SapFilesExportJob();
Database.executeBatch(sfej);

//Amware Order export Job 
AmwareOrderExportJob aoej = new AmwareOrderExportJob();
Database.executeBatch(aoej);

// Amware Fulillment status import job
AmwareFulFillmentStatusImportJob afsij = new AmwareFulFillmentStatusImportJob();
Database.executeBatch(afsij);

// Amware Fulillment status import job by date
Database.executeBatch(new AmwareFulFillmentStatusImportJob('2023-01-11 6:22'));

// Amware Refund status import job
AmwareReturnsImportJob arij = new AmwareReturnsImportJob();
Database.executeBatch(arij);

//positive status import
Database.executeBatch(new PositiveOrderStatusImportJobV2());

Database.executeBatch(new PositiveOrderDetailsStatusImportJobV2());

String cronExpression = '00 40 01 * * ? *';//01:40 am
String scheduleName = 'PositiveOrderDetailsImportJob';
id jobID = System.schedule(scheduleName, cronExpression, new PositiveOrderDetailsImpScheduler());

String cronExpression = '00 10 01 * * ? *';//01:10 am
String scheduleName = 'PositiveOrderStatusImportJob';
id jobID = System.schedule(scheduleName, cronExpression, new PositiveOrderStatusImpScheduler());

//positive status import custom
Database.executeBatch(new PositiveOrderStatusImportJobV2('2023-06-26', '2023-06-28', 200, 'Ascending'));

List<String> orderSummaryIds = new List<String>();
orderSummaryIds.add('1Os6w000000Ce4MCAS');
orderSummaryIds.add('1Os6w000000Ce4RCAS');
Database.executeBatch(new PositiveOrderDetailsStatusImportJobV2(orderSummaryIds));

String cronExpression = '0 10 0 * * ? *';//12:10 am
String scheduleName = 'SapOrdersExportJob';
id jobID = System.schedule(scheduleName, cronExpression, new SapOrdersExportJobScheduler());

String cronExpression = '0 10 0 * * ? *';//12:10 am
String scheduleName = 'SapPaymentsExportJob';
Id jobID = System.schedule(scheduleName, cronExpression, new SapPaymentsExportJobScheduler());

String cronExpression = '0 10 0 * * ? *';//12:10 am
String scheduleName = 'SapRefundExportJob';
Id jobID = System.schedule(scheduleName, cronExpression, new SapRefundExportJobScheduler());

String cronExpression = '0 40 0 * * ? *';//12:40 am
String scheduleName = 'SapFileExportJob';
Id jobID = System.schedule(scheduleName, cronExpression, new SapFilesExportJobScheduler());

System.schedule('SapOrdersExportJob', '0 10 0 * * ? *', new SapOrdersExportJobScheduler());
System.schedule('SapPaymentsExportJob', '0 10 0 * * ? *', new SapPaymentsExportJobScheduler());
System.schedule('SapRefundExportJob', '0 10 0 * * ? *', new SapRefundExportJobScheduler());
System.schedule('SapFileExportJob', '0 40 0 * * ? *', new SapFilesExportJobScheduler());

// To Start Schedules
new AppQuickSchedule().run();

//Pass the FO IDs to update the FO status to fulfilled and creates shipments 
MockUtility.updateFoStatusAndCreateShipment(new List<String>{'0a36w0000008OZ2AAM','0a36w0000008OZ3AAM','',''});

//Pass the FO IDs to update the RO lines QuanityReceived field and RO status to Refund_Initiated
MockUtility.updateReturnOrders(new List<String>{'','','',''});

//sap order export by IDs
SapOrdersExportJob soej = new SapOrdersExportJob('\'1Os6w000000Cb6PCAS\', \'1Os6w000000Cb6UCAS\', \'1Os6w000000Cb6ZCAS\', \'1Os6w000000Cb6eCAC\'');
Database.executeBatch(soej);

//import historical orders and create order summary
Database.executeBatch(new OmsBatchableApiOrderSummaryCreator());

//Creates notication service provider records, before it creates it will all the records just to avoid the duplication of records
void createOmsEmailAdapters() {
    delete [SELECT Id, Name FROM NotificationServiceProvider__c];
    List<NotificationServiceProvider__c> npsList = new List<NotificationServiceProvider__c>();
    npsList.add(new NotificationServiceProvider__c(Name = 'Canceled', ApexAdapter__c = 'OmsEmailCanceled', Reference__c = 'Canceled'));
    npsList.add(new NotificationServiceProvider__c(Name = 'Shipped', ApexAdapter__c = 'OmsEmailShipped', Reference__c = 'Shipped'));
    npsList.add(new NotificationServiceProvider__c(Name = 'RefundInitiated', ApexAdapter__c = 'OmsEmailRefundInitiated', Reference__c = 'RefundInitiated'));
    npsList.add(new NotificationServiceProvider__c(Name = 'RefundComplete', ApexAdapter__c = 'OmsEmailRefundComplete', Reference__c = 'RefundComplete'));
    insert npsList;
}
createOmsEmailAdapters();

//check wms logs for order export
SELECT OrderSummary__c, Id, Request__c, Response__c FROM WmsGatewayLog__c WHERE OrderSummary__r.ordernumber IN( '00011029','00011030','00011031','00011032','00011033','00011034','00011035','00011036')


String fromDate = '2023-01-04T00:00:01.000';
String endDate = '2023-01-04T23:59:59.000';
SapOrdersExportJob soej = new SapOrdersExportJob(fromDate, endDate);
Database.executeBatch(soej);

//rerun yesterday, exportToCPI
Database.executeBatch(new SapOrdersExportJob(true, true));

String fromDate = '2023-01-04T00:00:01.000';
String endDate = '2023-01-04T23:59:59.000';
SapPaymentsExportJob spej = new SapPaymentsExportJob(fromDate, endDate, false);
Database.executeBatch(spej);

//sap refund export by Custom_Refund__c IDs
SapRefundExportJob srej = new SapRefundExportJob('\'a3X6w0000006RlUEAU\',\'a3X6w0000006RlSEAU\',\'a3X6w0000006RlPEAU\',\'a3X6w0000006RlQEAU\'', true);//true is to decide if the file should be exported to cpi
Database.executeBatch(srej);

//create person account
RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
Account parentAccount = new Account(FirstName = 'Parent', LastName = 'Test', RecordTypeId = rt.Id, Business_Unit__c = 'US');
insert parentAccount;
insert new Account(FirstName = 'Child', LastName = 'Test', ParentId=parentAccount.Id);

//send shipment email
List<String> foIds = new List<String>{'0axxxxxxxxKyqDAAS'};//fulfillment order IDs
List<Shipment> shipmentList = [SELECT Id FROM Shipment WHERE FulfillmentOrderId IN :foIds];
for (Shipment ship:shipmentList) {
    String response = OmsEmailShipped.newInstance(OmsEmailShipped.class, null, new Map<String, Object> {'entityId' => ship.Id}).run();
    system.debug('***response***'+ response);
}

//export a specific file to CPI
List<Id> contentDocumentIds = new List<Id>();
String query = 'SELECT Id, Title from ContentDocument WHERE Id = \'0693w00000Hh0SbAAJ\'';
List<ContentDocument> contentDocumentList = Database.query(query);
if (contentDocumentList.size() > 0) {
    for (ContentDocument cd: contentDocumentList) {
        contentDocumentIds.add(cd.Id);
    }
}
List<ContentVersion> cvList = [SELECT Id, ContentDocumentId, ContentUrl, CreatedDate, FileExtension, FileType, Title, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE];
SapFilesExport.exportFilesToCpi(cvList);


//Account Bulk Update
String customerList = 'a3G3w000002IuvJEAS';
List<Account> accList = [SELECT Id, BillingState, BillingStateCode, BillingCountryCode, BillingCountry, B2C_CustomerList__pc FROM Account
						WHERE B2C_CustomerList__pc = :customerList AND 
                         (BillingState = null OR BillingCountryCode = null OR BillingStateCode = null OR BillingCountry = null) AND 
                         CreatedDate >= 2023-01-25T07:59:59.000Z LIMIT 10];
for (Account acc : accList) {
    acc.BillingCountryCode = 'US';
    acc.BillingCountry = 'United States';
    Database.update(acc);
}
Database.update(accList);

//Create Bulk FO
List<OrderSummary> osList = [Select Id from OrderSummary 
                             Where Status = 'Approved' AND 
                             CreatedDate >= 2023-01-28T00:59:59.000Z AND 
                             OrderLifeCycleType = 'MANAGED' 
                             ORDER BY CreatedDate ASC LIMIT 40];
for (OrderSummary os : osList) {
    try{
        Flow.Interview.Create_Fulfillment_Orders foFlow = new Flow.Interview.Create_Fulfillment_Orders(new Map<String, Object> { 'OrderSummaryId' => os.Id } );
        foFlow.start();
    } catch (Exception ex) {
        String errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { ex.getMessage(), ex.getLineNumber(), ex.getStackTraceString(), ex.getCause() });
        System.debug('*****Exception***'+ errorMessage + ', OrderSummary ID:'+ os.Id);
    }
}

//Bulk Update ODGS By OrderSummary
List<OrderDeliveryGroupSummary> odgsList = new List<OrderDeliveryGroupSummary>();
List<OrderSummary> osList = [Select Id from OrderSummary 
                             Where Status = 'Approved' AND 
                             CreatedDate >= 2023-01-30T19:59:59.000Z AND 
                             OrderLifeCycleType = 'MANAGED' 
                             LIMIT 99];
for (OrderSummary os : osList) {
    OrderDeliveryGroupSummary odgs = [SELECT Id, DeliverToState, DeliverToStateCode, DeliverToCountry, DeliverToCountryCode, DeliverToAddress, CurrencyIsoCode, OrderSummaryId 
     FROM OrderDeliveryGroupSummary where OrderSummaryId = :os.Id LIMIT 1];
    odgsList.add(odgs);
}
Database.update(odgsList);


//Bulk Update ODGS by Invalid Country
List<OrderDeliveryGroupSummary> odgsList = [SELECT Id, DeliverToState, DeliverToStateCode, DeliverToCountry, DeliverToCountryCode, 
                                        DeliverToAddress, CurrencyIsoCode, OrderSummaryId 
                                        FROM OrderDeliveryGroupSummary 
                                        where DeliverToState = null OR DeliverToStateCode = null OR 
                                        DeliverToCountry = null OR DeliverToCountryCode = null OR 
                                        DeliverToCountry = 'US' LIMIT 100];
for (OrderDeliveryGroupSummary odgs : odgsList) {
    odgs.DeliverToCountry = 'United States';
}
Database.update(odgsList);

//Get Object Name by ID:
string findObjectAPIName( String recordId ){
        if(recordId == null)
            return null;
        String objectAPIName = '';
        String keyPrefix = recordId.substring(0,3);
         for( Schema.SObjectType obj : Schema.getGlobalDescribe().Values() ){
              String prefix = obj.getDescribe().getKeyPrefix();
               if(prefix == keyPrefix){
                         objectAPIName = obj.getDescribe().getName();
                          break;
                }
         }
         return objectAPIName;
}
system.debug(findObjectAPIName('1Os3w0000004R3K'));