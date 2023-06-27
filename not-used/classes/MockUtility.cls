public class MockUtility {
    
    public static void updateFoStatusAndCreateShipment(List<String> foIds) {
        DateTime TodayDate =date.today();
        List<Shipment> shipmentList = new List<Shipment>();
        Set<Id> osIds = new Set<Id>();
        List<FulfillmentOrder> fulfillmentOrders = [SELECT Id, FulfilledToName, OrderSummaryId, Status,
            (SELECT Id, Quantity, Type, OrderItemSummaryId, OrderItemSummary.sfcc_BundleProductGUID__c, 
      		OrderItemSummary.sfcc_SAPMaterialCode__c, OrderItemSummary.ProductCode  
      		FROM FulfillmentOrderLineItems WHERE Type = 'Order Product' ORDER BY  
      		OrderItemSummary.sfcc_BundleProductGUID__c ASC)
     		FROM FulfillmentOrder WHERE Id IN :foIds];
        for (FulfillmentOrder fo : fulfillmentOrders) {
            fo.Status = 'FULFILLED';
            shipmentList.add(new Shipment(FulfillmentOrderId = fo.Id, ShipToName = fo.FulfilledToName,
				OrderSummaryId = fo.OrderSummaryId, AmwareShipDate__c = TodayDate,
                TrackingNumber = 'TO-' + fo.Id, Description = 'Shipped'));
            osIds.add(fo.OrderSummaryId);
        }
        if(!fulfillmentOrders.isEmpty()) {
            update fulfillmentOrders;
        }
        if (!shipmentList.isEmpty()){
            insert shipmentList;
        }
        if(!osIds.isEmpty()) {
            updateOrderSummaryStatus(osIds);
        }
    }
    
    public static void updateReturnOrders(List<String> roIds) {
        List<ReturnOrder> roList = [SELECT Id, Status, (SELECT Id, QuantityExpected, QuantityReceived FROM ReturnOrderLineItems) FROM ReturnOrder WHERE Id IN :roIds];
        List<ReturnOrderLineItem> roLineListToUpdate = new List<ReturnOrderLineItem>();
        for(ReturnOrder ro: roList) {
            for(ReturnOrderLineItem roLine: ro.ReturnOrderLineItems) {
                roLine.QuantityReceived = roLine.QuantityExpected;
                roLineListToUpdate.add(roLine);
            }
            ro.Status = 'Refund_Initiated';
        }
        if(!roLineListToUpdate.isEmpty()) {
            update roLineListToUpdate;
        }
        if(!roList.isEmpty()) {
            update roList;
        }
    }
    
    public static void updateOrderSummaryStatus(Set<Id> osIds){
        List<OrderSummary> osList = [SELECT Id, Status FROM OrderSummary WHERE Id IN :osIds];
        for(OrderSummary os : osList) {
            os.Status = 'FULFILLED';
        }
        update osList;
    }
}