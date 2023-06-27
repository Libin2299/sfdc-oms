public class AppQuickSchedule extends QuickSchedule {
    public override List<QuickScheduleJob> getJobs() {
        List<OMS_Job_Schedule__mdt> omsJobs = [SELECT Id, DeveloperName, Job_Name__c, Batch_Size__c, Dev_Frequency__c, Prod_Frequency__c FROM OMS_Job_Schedule__mdt];
        List<QuickScheduleJob> quickScheduleJobList = new List<QuickScheduleJob>();
        QuickScheduleJob quickScheduleJobObj;
        Boolean isSandBoxOrg = UserInfoX.isSandboxOrganization();
        for (OMS_Job_Schedule__mdt job : omsJobs) {
            if (job.Job_Name__c != null && job.Dev_Frequency__c != null && job.Prod_Frequency__c != null) {
                Type klass = Type.forName(job.Job_Name__c);
                Integer frequency = isSandBoxOrg ? job.Dev_Frequency__c.intValue() : job.Prod_Frequency__c.intValue();
                Integer batchSize = job.Batch_Size__c != null ? job.Batch_Size__c.intValue() : null;
                if (batchSize != null) {
                    quickScheduleJobObj = new QuickScheduleJob(frequency, klass, batchSize);
                } else {
                    quickScheduleJobObj = new QuickScheduleJob(frequency, klass); 
                }
                quickScheduleJobList.add(quickScheduleJobObj);
            }
        }
        return quickScheduleJobList;
        /* return new List<QuickScheduleJob> {
            new QuickScheduleJob(UserInfoX.isSandboxOrganization() ? 1 : 5, OmsJobsCapture.class, 1),
            new QuickScheduleJob(UserInfoX.isSandboxOrganization() ? 1 : 5, OmsJobsRemorse.class),
            new QuickScheduleJob(UserInfoX.isSandboxOrganization() ? 1 : 5, AmwareOrderExportJob.class, 50),
            new QuickScheduleJob(UserInfoX.isSandboxOrganization() ? 1 : 5, CaptureAsynRefunds.class),
            new QuickScheduleJob(UserInfoX.isSandboxOrganization() ? 30 : 5, AmwareFulFillmentStatusImportJob.class, 50),
            new QuickScheduleJob(UserInfoX.isSandboxOrganization() ? 30 : 60, AmwareReturnsImportJob.class, 50),
            new QuickScheduleJob(UserInfoX.isSandboxOrganization() ? 1 : 5, SendShipmentEmailJob.class, 50)
        }; */
    }
}