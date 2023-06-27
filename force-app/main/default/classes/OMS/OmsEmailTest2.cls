@isTest(SeeAllData=true)
public class OmsEmailTest2 {
    static OrderSummary setup(String id) {
        // Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
        //     'https://x.rest.marketingcloudapis.com/messaging/v1/messageDefinitionSends/key:oms.cancel/send' => new HttpCalloutServiceMock(200, '{}'),
        //     'https://x.rest.marketingcloudapis.com/messaging/v1/messageDefinitionSends/key:oms.shipment/send' => new HttpCalloutServiceMock(200, '{}'),
        //     'https://x.rest.marketingcloudapis.com/messaging/v1/messageDefinitionSends/key:oms.returnOrderCreated/send' => new HttpCalloutServiceMock(200, '{}'),
        //     'https://x.rest.marketingcloudapis.com/messaging/v1/messageDefinitionSends/key:oms.invoiceProcessed/send' => new HttpCalloutServiceMock(200, '{}')
        // }));
        OrderSummary orderSummary = [SELECT ID FROM OrderSummary WHERE OrderNumber =: id ];
        return orderSummary;
    }

    @isTest
    public static void shouldCanceled() {
        String orderItemIds = '';
        OrderSummary orderSummary = setup('00001912');
        List<OrderItemSummary> oisList = [SELECT Id FROM OrderItemSummary WHERE OrderSummaryId = :orderSummary.Id];
        for(OrderItemSummary ois : oisList) {
            orderItemIds += ois.Id + ',';
        }
        OmsEmailCanceled.newInstance(OmsEmailCanceled.class, null, new Map<String, Object> {
            'entityId' => orderSummary.Id,
            'entityChildIds' => orderItemIds
        }).run();
	}

    @isTest
    public static void shouldRefundInitiated() {
        OrderSummary orderSummary = setup('00001684');
        OmsEmailRefundInitiated.newInstance(OmsEmailRefundInitiated.class, null, new Map<String, Object> {
            'entityId' => orderSummary.Id
        }).run();
	}

    @isTest
    public static void shouldRefundComplete() {
        OrderSummary orderSummary = setup('00001684');
        OmsEmailRefundComplete.newInstance(OmsEmailRefundComplete.class, null, new Map<String, Object> {
            'entityId' => orderSummary.Id
        }).run();
	}

    @isTest
    public static void shouldShipped() {
        OrderSummary orderSummary = setup('00002042');
        Shipment shipment = [SELECT Id FROM Shipment WHERE OrderSummaryId = :orderSummary.Id LIMIT 1];
        OmsEmailShipped.newInstance(OmsEmailShipped.class, null, new Map<String, Object> {
            'entityId' => shipment.Id
        }).run();
	}
}