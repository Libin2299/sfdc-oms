global virtual class TriggerHandlerX {
    static Map<String, LoopCount> loopCountMap;
    static Set<String> bypassedHandlers;
    @testVisible TriggerContext context; // the current context of the trigger, overridable in tests
    @testVisible Boolean isTriggerExecuting; // the current context of the trigger, overridable in tests
  
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }
    global TriggerHandlerX() {
        this.setTriggerContext(null, false);
    }
  
    global void run() {
        if (!validateRun()) { return; }
        addToLoopCount();

        // dispatch to the correct handler method
        switch on this.context {
            when BEFORE_INSERT { this.beforeInsert(); }
            when BEFORE_UPDATE { this.beforeUpdate(); }
            when BEFORE_DELETE { this.beforeDelete(); }
            when AFTER_INSERT { this.afterInsert(); }
            when AFTER_UPDATE { this.afterUpdate(); }
            when AFTER_DELETE { this.afterDelete(); }
            when AFTER_UNDELETE { this.afterUndelete(); }
        }
    }
  
    global void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if (!TriggerHandlerX.loopCountMap.containsKey(handlerName)) { TriggerHandlerX.loopCountMap.put(handlerName, new LoopCount(max)); }
        else { TriggerHandlerX.loopCountMap.get(handlerName).setMax(max); }
    }
    global void clearMaxLoopCount() { this.setMaxLoopCount(-1); }

    global static void bypass(String handlerName) { TriggerHandlerX.bypassedHandlers.add(handlerName); }
    global static void clearBypass(String handlerName) { TriggerHandlerX.bypassedHandlers.remove(handlerName); }
    global static Boolean isBypassed(String handlerName) { return TriggerHandlerX.bypassedHandlers.contains(handlerName); }
    global static void clearAllBypasses() { TriggerHandlerX.bypassedHandlers.clear(); }
  
    @testVisible void setTriggerContext() { this.setTriggerContext(null, false); }
    @testVisible void setTriggerContext(String ctx, Boolean testMode) {
        if (!Trigger.isExecuting && !testMode) { this.isTriggerExecuting = false; return; }
        else { this.isTriggerExecuting = true; }
        if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) || ctx == 'before insert') { this.context = TriggerContext.BEFORE_INSERT; }
        else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) || ctx == 'before update') { this.context = TriggerContext.BEFORE_UPDATE; }
        else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) || ctx == 'before delete') { this.context = TriggerContext.BEFORE_DELETE; }
        else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) || ctx == 'after insert') { this.context = TriggerContext.AFTER_INSERT; }
        else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) || ctx == 'after update') { this.context = TriggerContext.AFTER_UPDATE; }
        else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) || ctx == 'after delete') { this.context = TriggerContext.AFTER_DELETE; }
        else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) || ctx == 'after undelete') { this.context = TriggerContext.AFTER_UNDELETE; }
    }
  
    // increment the loop count
    @testVisible void addToLoopCount() {
        String handlerName = getHandlerName();
        if (TriggerHandlerX.loopCountMap.containsKey(handlerName) && TriggerHandlerX.loopCountMap.get(handlerName).increment()) {
            throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(TriggerHandlerX.loopCountMap.get(handlerName).max) + ' reached in ' + handlerName);
        }
    }
  
    // make sure this trigger should continue to run
    @testVisible Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        return !TriggerHandlerX.bypassedHandlers.contains(getHandlerName());
    }
  
    @testVisible String getHandlerName() { return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':')); }
  
    // context-specific methods for override
    @testVisible global protected virtual void beforeInsert() { }
    @testVisible global protected virtual void beforeUpdate() { }
    @testVisible global protected virtual void beforeDelete() { }
    @testVisible global protected virtual void afterInsert() { }
    @testVisible global protected virtual void afterUpdate() { }
    @testVisible global protected virtual void afterDelete() { }
    @testVisible global protected virtual void afterUndelete() { }
  
    // manage the loop count per handler
    @testVisible class LoopCount {
        Integer max;
        Integer count;
        public LoopCount() { this.max = 5; this.count = 0; }
        public LoopCount(Integer max) { this.max = max; this.count = 0; }
        public Boolean increment() { this.count++; return this.exceeded(); }
        public Boolean exceeded() { return this.max >= 0 && this.count > this.max; }
        public Integer getMax() { return this.max; }
        public Integer getCount() { return this.count; }
        public void setMax(Integer max) { this.max = max; }
    }
  
    @testVisible enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
        AFTER_UNDELETE
    }
  
    global class TriggerHandlerException extends Exception { }
  }