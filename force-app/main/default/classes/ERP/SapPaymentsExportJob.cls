public class SapPaymentsExportJob implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public String time_Zone = 'PST';
    public string transType = 'SALE';
    public List<String> paymentUS = new List<String>();
    public List<String> paymentCA = new List<String>();
    public String startDateTime;
    public String endDateTime;
    List<Id> opsIdsToUpdate = new List<Id>();
    public String className = SapPaymentsExportJob.class.getName();
    public final String SALESCHANNEL_US = 'viviscal';
    public final String SALESCHANNEL_CA = 'viviscal-ca';
    public Boolean isCPIExport = false;
    public final String ORDER_LIFECYCLE_TYPE = 'MANAGED';
    
    public SapPaymentsExportJob() {
    }
    
    public SapPaymentsExportJob(String startDateTime, String endDateTime, Boolean isCPIExport) {
        this.startDateTime = String.valueOf(startDateTime).replace(' ','T') + 'Z';
       	this.endDateTime = String.valueOf(endDateTime).replace(' ','T') + 'Z';
        this.isCPIExport = isCPIExport;
    }
    
     // Getting  OrderPaymentSummary payments and PaymentAuthorizations with the filter 
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator queryResult;
        TimeZone tz = Timezone.getTimeZone('America/Los_Angeles');
        Integer offSet = tz.getOffSet(DateTime.now())/(60*60*1000);//offSet in hours
        DateTime todayDT = DateTime.now();
        String yesterdayStartDateTime = Datetime.newInstanceGmt(todayDT.yearGmt(), todayDT.monthGmt(),todayDT.dayGmt() - 1, 0 + Math.abs(offset), 0, 0).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String yesterdayEndDateTime = Datetime.newInstanceGmt(todayDT.yearGmt(), todayDT.monthGmt(), todayDT.dayGmt() - 1, 23 + Math.abs(offset), 59, 59).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String paymentWhereClause = ' WHERE CreatedDate >= ' + (!String.isBlank(startDateTime) ? startDateTime : yesterdayStartDateTime) + ' AND  CreatedDate <= ' + (!String.isBlank(endDateTime) ? endDateTime : yesterdayEndDateTime);
        if (Test.isRunningTest()) {
            paymentWhereClause = ' WHERE CreatedDate >= Today ';
        }
        String query = 'SELECT Id, OrderSummary.OrderNumber, OrderSummary.CreatedDate,OrderSummary.SalesChannel.SalesChannelName, ' +
            'IsExportedToSAP__c,(SELECT Id, GatewayRefNumber, Amount FROM PaymentAuthorizations), (SELECT Id, PaymentNumber,CreatedDate, ' +
            'AccountId,CurrencyIsoCode,PaymentAuthorizationId, Amount from Payments' + paymentWhereClause +') FROM OrderPaymentSummary ';
        //query += (!String.isBlank(startDateTime) && !String.isBlank(endDateTime)) ? '' : ' WHERE IsExportedToSAP__c = false ';
        query += Test.isRunningTest() ? ((!String.isBlank(startDateTime) && !String.isBlank(endDateTime)) ? ' LIMIT 2' : ' WHERE OrderSummary.OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND IsExportedToSAP__c = false ORDER BY CreatedDate DESC LIMIT 2 ') : ((!String.isBlank(startDateTime) && !String.isBlank(endDateTime)) ? ' ' : ' WHERE OrderSummary.OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND IsExportedToSAP__c = false ');
        try {
            queryResult = Database.getQueryLocator(query);
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return queryResult;
    }
 
     /* In the execute method we are creating the text file for the records returned from the start method  
     * text file format:
     * Transaction ID | Trans Type | Credit Type | Order number | Time Stamp | Time Zone | Customer Number | Currency |Transaction Total Amount
     */
    public void execute(Database.BatchableContext bc, List<OrderPaymentSummary> OrderPaymentSummarys) {
        try {
            for (OrderPaymentSummary Ops : OrderPaymentSummarys) {
                Boolean isOpsAddedToList = false;
                String SalesChannel = Ops.OrderSummary.SalesChannel.SalesChannelName;
                for (PaymentAuthorization opa : Ops.PaymentAuthorizations) {    
                    if ( SalesChannel == SALESCHANNEL_US) {
                        for (Payment paymentData : Ops.Payments) {
                            if (paymentData.PaymentAuthorizationId == opa.Id){
                                if (!isOpsAddedToList) {
                                    opsIdsToUpdate.add(Ops.Id);
                                    isOpsAddedToList = true;
                                }
                                String content = getContent(Ops, opa, paymentData);
                                paymentUS.add(content);
                            }
                        }
                    } else if (SalesChannel == SALESCHANNEL_CA) {
                        for (Payment paymentData : Ops.Payments) {
                            if (paymentData.PaymentAuthorizationId == opa.Id){
                                if (!isOpsAddedToList) {
                                    opsIdsToUpdate.add(Ops.Id);
                                    isOpsAddedToList = true;
                                }
                                String content = getContent(Ops, opa, paymentData);
                                paymentCA.add(content);
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        } 
    }
    
    public void finish(Database.BatchableContext bc) {
        List<ContentVersion> cvList = new List<ContentVersion>();
        String currentDT = System.now().format('yyyyMMddhhmmss', 'America/Los_Angeles');
        Set<Set<Id>> setOfIdSet;
        try {
            String fileContentUS = !paymentUS.isEmpty() ? String.join(paymentUS, '\n') : ' ';
            String titleUS = 'PAYMENTS_VIVISCAL_' + currentDT;
            ContentVersion verUS = new ContentVersion(
                ContentLocation = 'S',
                Title = titleUS,
                VersionData = Blob.valueOf(fileContentUS),
                PathOnClient = titleUS + '.txt');
            cvList.add(verUS);
            
            String fileContentCA = !paymentCA.isEmpty() ? String.join(paymentCA, '\n') : ' ';
            String titleCA = 'PAYMENTS_VIVISCALCA_' + currentDT;
            ContentVersion verCA = new ContentVersion(
                ContentLocation = 'S',
                Title = titleCA,
                VersionData = Blob.valueOf(fileContentCA),
                PathOnClient = titleCA + '.txt');
            cvList.add(verCA);
            
            if (!String.isBlank(startDateTime) && !String.isBlank(endDateTime) && isCPIExport) {
                SapFilesExport.exportFilesToCpi(cvList);
            }
            insert cvList;
            
            if (!opsIdsToUpdate.isEmpty()) {
                setOfIdSet = CustomCommonUtil.getIdSet(opsIdsToUpdate);
                for (Set<Id> opsIds : setOfIdSet) {
                    List<OrderPaymentSummary> opsList = [SELECT Id, IsExportedToSAP__c FROM OrderPaymentSummary WHERE Id IN :opsIds FOR UPDATE];
                    for (OrderPaymentSummary ops : opsList) {
                        ops.IsExportedToSAP__c = true;
                    }
                    Database.SaveResult[] srList = Database.update(opsList, false);
                    CustomCommonUtil.logDmlException(srList, className);
                }
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    private String getContent(OrderPaymentSummary ops, PaymentAuthorization opa, Payment paymentData) {
        String content = opa.GatewayRefNumber + '|' + transType + '|' + '' + '|' +Ops.OrderSummary.OrderNumber+ '|' +
        	paymentData.CreatedDate + '|' + time_Zone + '|' + paymentData.AccountId + '|' + paymentData.CurrencyIsoCode+ '|' + opa.Amount;
        return content;
    }
}