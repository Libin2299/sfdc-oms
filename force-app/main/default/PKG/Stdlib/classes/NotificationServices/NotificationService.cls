global class NotificationService {
    global class FlowInput {
        @InvocableVariable(label = 'Event') global Boolean event;
        @InvocableVariable(label = 'Locale') global String locale;
        @InvocableVariable(label = 'Reference') global String reference;
        @InvocableVariable(label = 'Reference Entity Id') global Id referenceEntityId;
        @InvocableVariable(label = 'Reference Entity Child Ids') global String referenceEntityChildIds;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'Result') global String result;
    }

    global class Notification {
        global final Id referenceEntityId;
        global final String reference;
        global final String locale;
        global final String referenceEntityChildIds;
        global Notification(Id referenceEntityId, String reference, String locale, String referenceEntityChildIds) {
            this.referenceEntityId = referenceEntityId;
            this.reference = reference;
            this.locale = locale;
            this.referenceEntityChildIds = referenceEntityChildIds;
        }
    }

    /**
    * @description invocable - Send Notification
    * @param inputs the inputs
    * @return List<FlowOutput>
    **/
    @InvocableMethod(label='Send Notification')
    global static List<FlowOutput> invocable(List<FlowInput> inputs) {
        List<NotificationServiceEvent__e> events = new List<NotificationServiceEvent__e>();
        List<Notification> notifications = new List<Notification>();
        for (FlowInput input : inputs) {
            if (input.event == true) {
                events.add(new NotificationServiceEvent__e(ReferenceEntityId__c = input.referenceEntityId, Reference__c = input.reference, Locale__c = input.locale, ReferenceEntityChildIds__c = input.referenceEntityChildIds));
            } else {
                notifications.add(new Notification(input.referenceEntityId, input.reference, input.locale, input.referenceEntityChildIds)); 
            }
        }
        List<FlowOutput> outputs = new List<FlowOutput>();
        if (!events.isEmpty()) {
            System.debug(events);
            for (Database.SaveResult sr : EventBus.publish(events)) {
                FlowOutput output = new FlowOutput();
                if (sr.isSuccess()) {
                    output.result = 'Successfully published event.';
                } else {
                    output.result = 'Error\n';
                    for (Database.Error err : sr.getErrors()) {
                        output.result += err.getStatusCode() + ' ' + err.getMessage() + '\n';
                    }
                }
                outputs.add(output);
            }
        }
        if (!notifications.isEmpty()) {
            System.debug(notifications);
            for (String result : sendNotifications(notifications)) {
                FlowOutput output = new FlowOutput();
                output.result = result;
                outputs.add(output);
            }
        }
        System.debug(outputs);
        return outputs;
    }
    
    static Map<String, Map<String, NotificationServiceProvider__c>> getProviders(List<Notification> notifications) {
        Set<String> references = new Set<String>();
        for (Notification s : notifications) { references.add(s.reference); }
        Map<String, Map<String, NotificationServiceProvider__c>> providers = new Map<String, Map<String, NotificationServiceProvider__c>>();
        for (NotificationServiceProvider__c s : [SELECT ApexAdapter__c, ApexArgs__c, Locale__c, Reference__c FROM NotificationServiceProvider__c WHERE Reference__c In :references]) {
            if (!providers.containsKey(s.Reference__c)) {
                providers.put(s.Reference__c, new Map<String, NotificationServiceProvider__c> { s.Locale__c => s });
                continue;
            }
            providers.get(s.Reference__c).put(s.Locale__c, s);
        }
        return providers;
    }

    global static List<String> sendNotifications(List<Notification> notifications) {
        if (notifications.isEmpty()) { return new List<String>(); }
        Map<String, Map<String, NotificationServiceProvider__c>> providers = getProviders(notifications);
        List<String> results = new List<String>();
        for (Notification s : notifications) {
            if (s == null) { continue; }
            if (!providers.containsKey(s.reference)) {
                results.add('Missing Reference: ' + s.reference);
                continue;
            }
            Map<String, NotificationServiceProvider__c> locales = providers.get(s.reference);
            NotificationServiceProvider__c provider = locales.containsKey(s.locale) ? locales.get(s.locale)
                : locales.containsKey(null) ? locales.get(null)
                : null;
            if (provider == null) {
                results.add('Missing Locale: ' + s.locale);
                continue;
            }
            Type type = Type.forName(provider.ApexAdapter__c);
            Object obj = type != null ? type.newInstance() : null;
            if (type == null || obj == null) {
                System.debug('Missing ApexAdapter: ' + provider.ApexAdapter__c);
                results.add('Missing ApexAdapter: ' + provider.ApexAdapter__c);
                continue;
            }
            if (!(obj instanceOf SystemX.HasRun)) {
                results.add('Missing SystemX.HasRun: ' + provider.ApexAdapter__c);
                continue;
            }
            Map<String, Object> args = MapX.putAll(new Map<String, Object> {
                'locale' => s.locale,
                'entityId' => s.referenceEntityId,
                'entityChildIds' => s.referenceEntityChildIds
            }, StringX.decodeMap(provider.ApexArgs__c));
            try {
                if (obj instanceOf CloudX.HasArgs) { ((CloudX.HasArgs)obj).setArgs(args); }
                results.add(((SystemX.HasRun)obj).run());
            }
            catch (Exception e) {
                String errorMessage = String.format('ERROR|{0}\n{1}\n{2}', new Object[] { e.getMessage(), e.getCause(), e.getStackTraceString() });
                System.debug(errorMessage);
                results.add(errorMessage);
            }
        }
        return results;
    }
}