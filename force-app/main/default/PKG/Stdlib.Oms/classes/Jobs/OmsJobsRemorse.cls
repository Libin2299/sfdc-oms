global class OmsJobsRemorse extends DatabaseJob implements QuickScheduleJob.HasArgs {
    static final String PEE_DESCRIPTION = 'Payment Failed';
    static final String PEE_SEVERITY = 'High';
    static final String QUERYX = 'SELECT Id, OrderedDate, (SELECT Id, ScheduleStatus FROM OrderSummaryRoutingSchedules WHERE ScheduleStatus=\'SCHEDULED\') FROM OrderSummary WHERE PickedupByRemorse__c = False And Status = \'Remorse\' And OrderedAgeInMinutes__c >= {RPIM} LIMIT 500';
    Integer remorsePeriodMinutes = UserInfoX.isSandboxOrganization() ? 2 : 60;

    // check each order summary if past remorse period, and if so, then allocate
    class CustomAction extends DatabaseJob.CustomAction {
        OmsJobsRemorse parent;
        public CustomAction(OmsJobsRemorse parent) {
            this.parent = parent;
        }

        public override void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            this.parent.execute((List<OrderSummary>)scope, exceptions);
        }
    }

    global OmsJobsRemorse() {
        super(QUERYX, null);
        action = new CustomAction(this);
    }

    global void setArgs(Map<String, Object> args) {
        if (args != null) {
            for (String key : args.keySet()) {
                switch on key {
                    when 'remorsePeriodMinutes' { this.remorsePeriodMinutes = (Integer)args.get(key); }
                }
            }
        }
        this.query = this.query.replace('{RPIM}', String.valueOf(this.remorsePeriodMinutes));
        System.debug('new:' + this.query);
    }

    /**
    * @description batchable exception
    * @param scope the scope
    **/
    public override void handleExceptions(List<Exception_SObject> scope) { handleExceptions(this, scope); }

    /**
    * @description batchable execute
    * @param scope the scope
    * @param exceptions the exceptions
    **/
    void execute(List<OrderSummary> scope, List<Exception_SObject> exceptions) {
        List<Id> newScope = new List<Id>();
        for (OrderSummary s : scope) {
            try {
                Boolean scheduleExists = s.OrderSummaryRoutingSchedules != null && !s.OrderSummaryRoutingSchedules.isEmpty();
                DateTime allocationDate = s.OrderedDate.addMinutes(this.remorsePeriodMinutes);
                if (allocationDate < Datetime.now() && !scheduleExists) { newScope.add(s.Id); }
            } catch (Exception e) { System.debug(e); exceptions.add(new Exception_SObject(e, s)); }                    
        }   
        if (!newScope.isEmpty()) { release(newScope, exceptions); }
    }

    static void release(List<Id> scope, List<Exception_SObject> exceptions) {
         List<OrderSummary> updates = new List<OrderSummary>();
         List<SObject> events = new List<SObject>();
        for (OrderSummary s : [SELECT Id, Status FROM OrderSummary WHERE Id In :scope]) {
            try {
                if (!s.Status.contains('Closed')) {
                    events.add(new OrderSummaryEvent__e(Action__c = 'Remorse', OrderSummaryId__c = s.Id));
                }
                updates.add(new OrderSummary(Id = s.Id, PickedupByRemorse__c = true));
            } catch (Exception e) { System.debug(e); exceptions.add(new Exception_SObject(e, s)); }                    
        }
        if (!events.isEmpty()) { EventBusX.publish(events); }
        if (!updates.isEmpty()) { Database.update(updates, false); }
    }

    static void handleExceptions(Object parent, List<Exception_SObject> scope) {
        List<SObject> events = new List<SObject>();
        for (Exception_SObject s : scope) {
            Id id = s.item2.Id;
            events.add(OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, id, id, s.item1.getMessage()));
        }
        if (!events.isEmpty()) { EventBusX.publish(events); }
    }
}
