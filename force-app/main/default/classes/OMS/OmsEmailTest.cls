@isTest
public class OmsEmailTest {
    
	@isTest(SeeAllData=true)	
    public static void shouldCanceled() {
        String itemIds = '';
        String osId = OmsTestDataFactory.createOrderSummaryUS();
        Order changeOrderId = OmsTestDataFactory.createOrderChange(osId, null, 'Cancel');
        List<OrderItemSummary> itemList = [SELECT Id FROM OrderItemSummary WHERE OrderSummaryId = :osId];
        for(OrderItemSummary item : itemList) {
            itemIds += item.Id + ', ';
        }
		Test.startTest();
        String response = OmsEmailCanceled.newInstance(OmsEmailCanceled.class, null, new Map<String, Object> {
            'entityId' => osId,
            'entityChildIds' => itemIds
        }).run();
		Test.stopTest();
        System.assertEquals('OK', response);
	}

    @isTest(SeeAllData=true)
    public static void shouldRefundInitiated() {
        String osId = OmsTestDataFactory.createOrderSummaryUS();
        String foIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id =: foIds];
        for(FulfillmentOrder fo: foList) {
            OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        }
        String roId = OmsTestDataFactory.createRMAReturnOrder(osId);
		Test.startTest();
        String response = OmsEmailRefundInitiated.newInstance(OmsEmailRefundInitiated.class, null, new Map<String, Object> {
            'entityId' => roId
        }).run();
		Test.stopTest();
        System.assertEquals('OK', response);
	}

    @isTest(SeeAllData=true)
    public static void shouldRefundComplete() {
        String response = '';
        String osId = OmsTestDataFactory.createOrderSummaryUS();
        String foIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id =: foIds];
        for(FulfillmentOrder fo: foList) {
            OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        }
        String roId = OmsTestDataFactory.createRMAReturnOrder(osId);
        String changeOrderId = OmsTestDataFactory.RetunRMAReturnOrder(roId);
        CreditMemo cm = OmsTestDataFactory.createCreditMemo(osId, changeOrderId);
		Test.startTest();
        response = OmsEmailRefundComplete.newInstance(OmsEmailRefundComplete.class, null, new Map<String, Object> {
            'entityId' => cm.Id
        }).run();
		Test.stopTest();
        System.assertEquals('OK', response);
	}

    @isTest(SeeAllData=true)
    public static void shouldShipped() {
        List<String> responseList = new List<String>();
        String osId = OmsTestDataFactory.createOrderSummaryUS();
        String foIds = OmsTestDataFactory.createFulfillmentOrder(osId, 'Warehouse');
        List<FulfillmentOrder> foList = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE Id =: foIds];
        for (FulfillmentOrder fo: foList) {
            OmsTestDataFactory.invoiceFulfillmentOrder(fo);
        }
        List<Shipment> shipmentList = [SELECT Id FROM Shipment WHERE FulfillmentOrderId =:foIds];
		Test.startTest();
        for (Shipment ship:shipmentList) {
            String response = OmsEmailShipped.newInstance(OmsEmailShipped.class, null, new Map<String, Object> {
            	'entityId' => ship.Id
        	}).run();
            responseList.add(response);
        }
		Test.stopTest();
        for (String response : responseList) {
            System.assertEquals('OK', response);
        }
	}
}