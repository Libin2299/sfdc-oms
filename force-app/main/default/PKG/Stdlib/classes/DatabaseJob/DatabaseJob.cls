global virtual class DatabaseJob implements Database.Batchable<SObject> {
    global String query;
    global Object action;
    global Integer batchSize;
    global Boolean allOrNone = true;
    global final List<Exception_SObject> exceptions = new List<Exception_SObject>();
 
    global DatabaseJob(String query, Object action) {
        this.query = query;
        this.action = action;
        this.batchSize = action instanceOf FlowAction || action instanceOf FlowRefAction ? 10 : 1000;
        System.debug('DatabaseJob:' + this);
    }
    global DatabaseJob(String query, Object action, Integer batchSize) { this(query, action); this.batchSize = batchSize; }
    global DatabaseJob(String query, Object action, Boolean allOrNone) { this(query, action); this.allOrNone = allOrNone; }
    global DatabaseJob(String query, Object action, Integer batchSize, Boolean allOrNone) { this(query, action); this.batchSize = batchSize; this.allOrNone = allOrNone; }

    /**
    * @description run
    * @return String 
    **/
    global String run() {
        return Database.executeBatch(this, this.batchSize);
    }

    /**
    * @description batchable start
    * @param bc the Batchable Context
    * @return Database.QueryLocator 
    **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('start:' + this.query);
        return Database.getQueryLocator(this.query);
    }

    /**
    * @description batchable execute
    * @param bc the Batchable Context
    * @param scope the scope
    **/
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('execute:' + this.query);
        executeAction(this.action, bc, scope, this.allOrNone, this.exceptions);
        if (!exceptions.isEmpty()) { handleExceptions(exceptions); }
    }

    /**
    * @description batchable finish
    * @param bc the Batchable Context
    **/
    global void finish(Database.BatchableContext bc) { }

    /**
    * @description handle exceptions
    * @param scope the scope
    **/
    global protected virtual void handleExceptions(List<Exception_SObject> scope) { }

    global virtual class Schedule implements Schedulable {
        global String query;
        global Object action;
        global Integer batchSize;
        global Boolean allOrNone = true;
        global final List<Exception_SObject> exceptions = new List<Exception_SObject>();

        global Schedule(String query, Object action) {
            this.query = query;
            this.action = action;
            this.batchSize = action instanceOf FlowAction || action instanceOf FlowRefAction ? 10 : 1000;
        }
        global Schedule(String query, Object action, Integer batchSize) { this(query, action); this.batchSize = batchSize; }
        global Schedule(String query, Object action, Boolean allOrNone) { this(query, action); this.allOrNone = allOrNone; }
        global Schedule(String query, Object action, Integer batchSize, Boolean allOrNone) { this(query, action); this.batchSize = batchSize; this.allOrNone = allOrNone; }

        /**
        * @description run
        * @return String 
        **/
        global String run() {
            execute(null);
            return 'Inline';
        }

        /**
        * @description execute
        * @param sc the schedulable context
        **/
        global void execute(SchedulableContext sc) {
            Database.QueryLocatorIterator it = Database.getQueryLocator(this.query).iterator();
            List<SObject> scope = new List<SObject>();
            while (it.hasNext()) {
                scope.add(it.next());
            }
            executeAction(this.action, sc, scope, this.allOrNone, this.exceptions);
            if (!exceptions.isEmpty()) { handleExceptions(exceptions); }
        }

        /**
        * @description handle exceptions
        * @param scope the scope
        **/
        global protected virtual void handleExceptions(List<Exception_SObject> scope) { }
    }

    global virtual class Queue implements Queueable {
        global String query;
        global Object action;
        global Integer batchSize;
        global Boolean allOrNone = true;
        global final List<Exception_SObject> exceptions = new List<Exception_SObject>();

        global Queue(String query, Object action) {
            this.query = query;
            this.action = action;
            this.batchSize = action instanceOf FlowAction || action instanceOf FlowRefAction ? 10 : 1000;
        }
        global Queue(String query, Object action, Integer batchSize) { this(query, action); this.batchSize = batchSize; }
        global Queue(String query, Object action, Boolean allOrNone) { this(query, action); this.allOrNone = allOrNone; }
        global Queue(String query, Object action, Integer batchSize, Boolean allOrNone) { this(query, action); this.batchSize = batchSize; this.allOrNone = allOrNone; }

        /**
        * @description run
        * @return String 
        **/
        global String run() {
            return System.enqueueJob(this);
        }

        /**
        * @description execute
        * @param qc the queueable context
        **/
        global void execute(QueueableContext qc) {
            Database.QueryLocatorIterator it = Database.getQueryLocator(this.query).iterator();
            List<SObject> scope = new List<SObject>();
            while (it.hasNext()) {
                scope.add(it.next());
            }
            executeAction(this.action, qc, scope, this.allOrNone, this.exceptions);
            if (!exceptions.isEmpty()) { handleExceptions(exceptions); }
        }

        /**
        * @description handle exceptions
        * @param scope the scope
        **/
        global protected virtual void handleExceptions(List<Exception_SObject> scope) { }
    }
 
    global class InsertRefAction {
        global Type record;
        global String recordIdField;
        global Map<String, Object> values;
        global InsertRefAction(Type record, String recordIdField, Map<String, Object> values) {
            this.record = record;
            this.recordIdField = recordIdField;
            this.values = values;
        }
        global void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            Set<SObject> newScope = new Set<SObject>();
            for (SObject s : scope) {
                Id id = (Id)ObjectX.get(s, recordIdField);
                if (id == null) { 
                    System.debug('warning, skipping reference field for record: ' + s.Id);
                    continue;
                }
                SObject obj = (SObject)record.newInstance();
                for (String field : values.keySet()) { ObjectX.put(obj, field, fieldValueReplace(values.get(field), id)); }
                newScope.add(obj);
            }
            if (!newScope.isEmpty()) { Database.insert(new List<SObject>(newScope), allOrNone); }
        }
    }

    global class UpdateAction {
        global Map<String, Object> values;
        global UpdateAction(Map<String, Object> values) {
            this.values = values;
        }
        global UpdateAction(String field, Object value) {
            this(new Map<String, Object> { field => value });
        }
        global void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            for (SObject s : scope) {
                for (String field : values.keySet()) { ObjectX.put(s, field, values.get(field)); }
            }
            if (!scope.isEmpty()) { Database.update(scope, allOrNone); }
        }
    }

    global class UpdateRefAction {
        global Type record;
        global String recordIdField;
        global Map<String, Object> values;
        global UpdateRefAction(Type record, String recordIdField, Map<String, Object> values) {
            this.record = record;
            this.recordIdField = recordIdField;
            this.values = values;
        }
        global UpdateRefAction(Type record, String recordIdField, String field, Object value) {
            this(record, recordIdField, new Map<String, Object> { field => value });
        }
        global void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            Set<SObject> newScope = new Set<SObject>();
            for (SObject s : scope) {
                Id id = (Id)ObjectX.get(s, recordIdField);
                if (id == null) { 
                    System.debug('warning, skipping reference field for record: ' + s.Id);
                    continue;
                }
                SObject obj = (SObject)record.newInstance();
                obj.Id = id;
                for (String field : values.keySet()) { ObjectX.put(obj, field, values.get(field)); }
                newScope.add(obj);
            }
            if (!newScope.isEmpty()) { Database.update(new List<SObject>(newScope), allOrNone); }
        }
    }

    global class DeleteAction {
        global void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            List<Id> newScope = new List<Id>();
            for (SObject s : scope) {
                newScope.add(s.Id);
            }
            if (!newScope.isEmpty()) { Database.delete(newScope, allOrNone); }
        }
    }

    global class DeleteRefAction {
        global Type record;
        global String recordIdField;
        global DeleteRefAction(Type record, String recordIdField) {
            this.record = record;
            this.recordIdField = recordIdField;
        }
        global void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            Set<Id> newScope = new Set<Id>();
            for (SObject s : scope) {
                Id id = (Id)ObjectX.get(s, recordIdField);
                if (id == null) { 
                    System.debug('warning, skipping reference field for record: ' + s.Id);
                    continue;
                }
                newScope.add(id);
            }
            if (!newScope.isEmpty()) { Database.delete(new List<Id>(newScope), allOrNone); }
        }
    }

    global class FlowAction {
        global String flowField;
        global Map<String, Object> values;
        global FlowAction(String flowField) { this(flowField, null); }
        global FlowAction(String flowField, Map<String, Object> values) {
            this.flowField = flowField;
            this.values = values;
        }
        global FlowAction(String flowField, String field, Object value) {
            this(flowField, new Map<String, Object> { field => value });
        }
        global void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            String[] flowFields = flowField.split('\\.', 2);
            if (flowFields.size() != 2) { throw new HandledException('Invalid flowField format'); }
            for (SObject s : scope) {
                try {
                    Flow.Interview.createInterview(flowFields[0], new Map<String, Object> {
                        flowFields[1] => s.Id
                    }).start();
                } catch (Exception e) { System.debug(e); exceptions.add(new Exception_SObject(e, s)); }
                if (values != null) {
                for (String field : values.keySet()) { ObjectX.put(s, field, values.get(field)); }
            }
            }
            if (values != null && !scope.isEmpty()) { Database.update(scope, allOrNone); }
        }
    }

    global class FlowRefAction {
        global Type record;
        global String recordIdField;
        global String flowField;
        global Map<String, Object> values;
        global FlowRefAction(Type record, String recordIdField, String flowField) { this(record, recordIdField, flowField, null); }
        global FlowRefAction(Type record, String recordIdField, String flowField, Map<String, Object> values) {
            this.record = record;
            this.recordIdField = recordIdField;
            this.flowField = flowField;
            this.values = values;
        }
        global FlowRefAction(Type record, String recordIdField, String flowField, String field, Object value) {
            this(record, recordIdField, flowField, new Map<String, Object> { field => value });
        }
        global void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            Set<SObject> newScope = new Set<SObject>();
            String[] flowFields = flowField.split('\\.', 2);
            if (flowFields.size() != 2) { throw new HandledException('Invalid flowField format'); }
            for (SObject s : scope) {
                Id id = (Id)ObjectX.get(s, recordIdField);
                if (id == null) { 
                    System.debug('warning, skipping reference field for record: ' + s.Id);
                    continue;
                }
                try {
                    Flow.Interview.createInterview(flowFields[0], new Map<String, Object> {
                        flowFields[1] => id
                    }).start();
                } catch (Exception e) { System.debug(e); exceptions.add(new Exception_SObject(e, s)); }
                SObject obj = (SObject)record.newInstance();
                obj.Id = id;
                if (values != null) {
                for (String field : values.keySet()) { ObjectX.put(obj, field, values.get(field)); }
                newScope.add(obj);
            }
            }
            if (values != null && !newScope.isEmpty()) { Database.update(new List<SObject>(newScope), allOrNone); }
        }
    }

    global abstract class CustomAction {
        global abstract void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions);
    }

    static Object fieldValueReplace(Object value, Id id) {
        return value instanceOf String && (String)value == '{{id}}'
            ? id
            : value;
    }

    static void executeAction(Object action, Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
        if (action instanceOf InsertRefAction) { ((InsertRefAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else if (action instanceOf UpdateAction) { ((UpdateAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else if (action instanceOf UpdateRefAction) { ((UpdateRefAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else if (action instanceOf DeleteAction) { ((DeleteAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else if (action instanceOf DeleteRefAction) { ((DeleteRefAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else if (action instanceOf FlowAction) { ((FlowAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else if (action instanceOf FlowRefAction) { ((FlowRefAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else if (action instanceOf CustomAction) { ((CustomAction)action).execute(ctx, scope, allOrNone, exceptions); }
        else { throw new HandledException('Unknown action: ' + action); }
    }
 }