global class QuickScheduleJob {
    global Integer minutes;
    global Type klass;
    global Integer batchSize;
    global Map<String, Object> args;

    global interface HasArgs {
        void setArgs(Map<String, Object> args);
    }

    global QuickScheduleJob(Integer minutes, Type klass) { this(minutes, klass, 200, null); }
    global QuickScheduleJob(Integer minutes, Type klass, Integer batchSize) { this(minutes, klass, batchSize, null); }
    global QuickScheduleJob(Integer minutes, Type klass, Integer batchSize, Map<String, Object> args) {
        this.minutes = minutes;
        this.klass = klass;
        this.batchSize = batchSize;
        this.args = args;
    }
}