global abstract class QuickSchedule implements Schedulable {
    global protected Integer intervalInMinutes;
    Integer interval = 0;

    global QuickSchedule() { this.intervalInMinutes = 5; }
    global QuickSchedule(Integer intervalInMinutes) { this.intervalInMinutes = intervalInMinutes; }

    global protected virtual List<QuickScheduleJob> getJobs() { throw new HandledException('getJobs() must be defined'); }

    /**
    * @description get cron and job name
    * @param intervalInMinutes the interval in minutes
    * @param className the class name
    * @return String[]
    **/
    static String[] getCronAndJobName(Integer intervalInMinutes, String className) {
        DateTime now = DateTime.now(), next = now.addMinutes(intervalInMinutes);
        return new String[] {
            // cron
            ''+next.second()+' '+next.minute()+' '+next.hour()+' '+next.day()+' '+next.month()+' ? '+next.year(),
            // jobName
            className+'-'+(Test.isRunningTest() ? 'Test' : now.format())
        };
    }

    /**
    * @description Re-schedule ourself to run again in MINUTES
    * @return List<AsyncApexJob>
    **/
    global List<AsyncApexJob> run() {
        String className = String.valueOf(this).split(':', 2)[0];

        // increment interval
        this.interval += this.intervalInMinutes; if (this.interval >= 1440) { this.interval = 0; }

        // schedule job
        String[] cronAndJobName = getCronAndJobName(this.intervalInMinutes, className);
        String cron = cronAndJobName[0], jobName = cronAndJobName[1];
        System.debug('Scheduling ' + className + ' @' + this.interval + ' #' + cron);
        System.schedule(jobName, cron, this);

        // get running jobs
        List<AsyncApexJob> asyncApexJobs = [
            SELECT Id FROM AsyncApexJob WHERE JobType = 'BatchApex'
            And (Status='Queued' Or Status='Processing' Or Status='Preparing')
            And ApexClassId In (SELECT Id FROM ApexClass WHERE Name = :className)];
        return asyncApexJobs;
    }

    /**
    * @description abort job
    **/
    global void abort() {
        String className = String.valueOf(this).split(':', 2)[0];
        String namePattern = className + '-%';
        for (CronTrigger s : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name Like :namePattern]) {
            try {
                System.abortJob(s.id);
            } catch (Exception e) { }
        }
    }

    /**
    * @description schedule execute
    * @param sc the SchedulableContext
    **/
    global virtual void execute(SchedulableContext sc) {
        List<QuickScheduleJob> jobs = getJobs();

        // Abort the current job
        if (sc != null) { System.abortJob(sc.getTriggerId()); }

        // schedule next job
        List<AsyncApexJob> asyncApexJobs = run();

        // Launch a batch job, if ...enabled, apex jobs is not null, and no jobs currently running = 0
        if (jobs == null || jobs.isEmpty() || (asyncApexJobs != null && !asyncApexJobs.isEmpty())) { return; }

        // execute jobs
        for (QuickScheduleJob job : jobs) {
            if (job == null || (job.minutes != 0 && !shouldExecute(this.interval, Math.abs(job.minutes)))) { continue; }

            // create klass
            Type klass = job.klass;
            String className = klass.getName();
            System.debug('Creating ' + className);
            Object obj = klass.newInstance();
            if (obj instanceOf QuickScheduleJob.HasArgs) { ((QuickScheduleJob.HasArgs)obj).setArgs(job.args); }

            // call klass
            System.debug('Calling ' + className);
            execute(sc, job, obj, className);
        }
    }

    /**
    * @description execute job
    * @param sc the SchedulableContext 
    * @param job the QuickScheduleJob
    * @param obj the object
    * @param className the class Name
    * @param obj the Job
    **/
    global protected virtual void execute(SchedulableContext sc, QuickScheduleJob job, Object obj, String className) {
        if (job.minutes < 0 && obj instanceOf Schedulable) {
            String[] cronAndJobName = getCronAndJobName(Math.abs(job.minutes), className);
            String cron = cronAndJobName[0], jobName = cronAndJobName[1];
            System.schedule(jobName, cron, (Schedulable)obj);
        }
        else if (obj instanceOf Schedulable) { ((Schedulable)obj).execute(sc); }
        else if (obj instanceOf Queueable) { System.enqueueJob((Queueable)obj); }
        else if (obj instanceOf Database.Batchable<SObject>) { Database.executeBatch((Database.Batchable<SObject>)obj, job.batchSize); }
        else { throw new HandledException('Unknown Type: ' + job.klass.getName()); }
    }

    /**
    * @description checks if job should execute
    * @param interval the interval
    * @param minutes the minutes
    * @return Boolean 
    **/
    static Boolean shouldExecute(Integer interval, Integer minutes) {
        return Math.mod(interval, minutes) == 0;
    }
}