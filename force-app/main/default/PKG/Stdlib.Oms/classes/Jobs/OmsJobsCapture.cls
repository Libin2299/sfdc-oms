global class OmsJobsCapture extends DatabaseJob implements QuickScheduleJob.HasArgs {
    static final String PEE_DESCRIPTION = 'Payment Failed';
    static final String PEE_SEVERITY = 'High';
    static final String QUERYX = 'SELECT Id FROM OrderSummary WHERE Status = \'Ready to Capture\' And ActiveProcessExceptionCount = 0 LIMIT 500';
    static final String FLOWFIELD = 'Capture_Upon_Order_Acceptance.OrderSummaryId';

    global class Schedule extends DatabaseJob.Schedule {
        global Schedule() {
            super(QUERYX,
                new DatabaseJob.FlowRefAction(OrderSummary.class, 'Id', FLOWFIELD));
        }

        /**
        * @description set arguments
        * @param args the args
        **/
        global void setArgs(Map<String, Object> args) { setArgs((DatabaseJob.FlowRefAction)this.action, args); }

        /**
        * @description batchable exception
        * @param scope the scope
        **/
        public override void handleExceptions(List<Exception_SObject> scope) { handleExceptions(this, scope); }
    }

    global class Queue extends DatabaseJob.Queue {
        global Queue() {
            super(QUERYX,
                new DatabaseJob.FlowRefAction(OrderSummary.class, 'Id', FLOWFIELD));
        }

        /**
        * @description set arguments
        * @param args the args
        **/
        global void setArgs(Map<String, Object> args) { setArgs((DatabaseJob.FlowRefAction)this.action, args); }

        /**
        * @description batchable exception
        * @param scope the scope
        **/
        public override void handleExceptions(List<Exception_SObject> scope) { handleExceptions(this, scope); }
    }

    global OmsJobsCapture() {
        super(QUERYX,
            new DatabaseJob.FlowRefAction(OrderSummary.class, 'Id', FLOWFIELD));
    }

    /**
    * @description set arguments
    * @param args the args
    **/
    global void setArgs(Map<String, Object> args) { setArgs((DatabaseJob.FlowRefAction)this.action, args); }

    /**
    * @description batchable exception
    * @param scope the scope
    **/
    public override void handleExceptions(List<Exception_SObject> scope) { handleExceptions(this, scope); }

    static void setArgs(DatabaseJob.FlowRefAction action, Map<String, Object> args) {
        if (args != null) {
            for (String key : args.keySet()) {
                switch on key {
                    when 'flowField' { action.flowField = (String)args.get(key); }
                    when 'values' { action.values = (Map<String, Object>)args.get(key); }
                }
            }
        }
    }

    static void handleExceptions(Object parent, List<Exception_SObject> scope) {
        List<SObject> events = new List<SObject>();
        for (Exception_SObject s : scope) {
            Id id = s.item2.Id;
            events.add(OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, id, id, 'Unable to capture payment, the flow has failed.'));
        }
        if (!events.isEmpty()) { EventBusX.publish(events); }
    }
}