@isTest
class EventBusXTest {
    @isTest static void shouldPublish() {
        SObject[] events = new SObject[] { new BatchApexErrorEvent() };
        EventBusX.publish(events);
    }

    @isTest static void shouldPublishByEndpoint() {
        SObject[] events = new SObject[] { new BatchApexErrorEvent() };
        EventBusX.publish('endpoint', null, events);
    }

    @isTest static void shouldPublishFeedItem() {
        Id parentId = UserInfo.getUserId();
        EventBusX.publishFeedItem(parentId, 'body');
    }
}