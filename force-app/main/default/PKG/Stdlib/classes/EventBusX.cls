global class EventBusX {
    global static final string PublishServiceAction_Name = 'publishEvents';
    global class PublishServiceAction implements ServiceX.IServiceAction {
        global String act(String std) { EventBusX.publish((List<SObject>)ObjectX.decodeOf(std)); return 'OK'; }
        global String get(Type type, Object std) { return ObjectX.encodeOf(List<SObject>.class, std); }
    }

    /**
    * @description publishes events
    * @param sobjects the events
    * @return Boolean
    **/
    global static Boolean publish(List<SObject> sobjects) {
        if (sobjects == null || sobjects.isEmpty()) { return true; }
        Boolean r = true;
        List<Database.SaveResult> results = EventBus.publish(sobjects);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) { System.debug('Successfully published event.'); }
            else { for (Database.Error err : sr.getErrors()) { r = false; System.debug('Error: [' + err.getStatusCode() + ']' + err.getMessage()); } }
        }
        return r;
    }

    /**
    * @description publishes events remotely
    * @param endpoint the endpoint
    * @param accessToken the accessToken
    * @param sobjects the events
    * @return Boolean
    **/
    global static Boolean publish(String endpoint, String accessToken, List<SObject> sobjects) {
        return ServiceX.submit(endpoint, accessToken, PublishServiceAction_Name, List<SObject>.class, sobjects);
    }

    /**
    * @description publishes a feed item
    * @param parentId the parent id
    * @param body the body
    **/
    global static void publishFeedItem(Id parentId, String body) {
        Database.Insert(new FeedItem(
            ParentId = parentId,
            Body = body,
            Type = 'TextPost'), false);
    }
}