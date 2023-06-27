@isTest
public class PositiveMockResponseTest {
    
    public static String getOrdersStatusResponse(Set<String> osIds) {
        String ordersStatusResponse;
        PositiveGetOrderStatusResponse orders;
        PositiveGetOrderStatusResponse.Items item;
        List<PositiveGetOrderStatusResponse.Items> itemList;
        List<OrderSummary> osList = [SELECT Id, OrderNumber FROM OrderSummary WHERE Id IN :osIds];
        if (!osList.isEmpty()) {
            orders = new PositiveGetOrderStatusResponse();
            itemList = new List<PositiveGetOrderStatusResponse.Items>();
            if(Test.isRunningTest()) {
                orders.totalCount = 201; //Hard Coding totalCount value
            } else {
                orders.totalCount = osList.size();
            }
            for (OrderSummary os : osList) {
                item = new PositiveGetOrderStatusResponse.Items();
                item.referenceNumber = os.OrderNumber;
                itemList.add(item);
            }
            orders.items = itemList;
            ordersStatusResponse = JSON.serialize(orders, true);
        }
        return ordersStatusResponse;
    }

    public static String getOrderStatusResponse(String foId) {
        String orderStatusResponse;
        PositiveOrderStatusResponse pos = new PositiveOrderStatusResponse();
        PositiveOrderStatusResponse.Carrier carrier = new PositiveOrderStatusResponse.Carrier();
        List<PositiveOrderStatusResponse.Products> itemList = new List<PositiveOrderStatusResponse.Products>();
        FulfillmentOrder foList = [SELECT Id, OrderSummary.OrderNumber, (SELECT Id, Quantity, OrderItemSummary.sfcc_SAPMaterialCode__c 
                                   FROM FulfillmentOrderLineItems WHERE Type = 'Order Product' AND OrderItemSummary.sfcc_SAPMaterialCode__c != null) 
                                   FROM FulfillmentOrder WHERE Id = :foId];
        if (foList != null) {
            pos.customersOrderNumber = foList.OrderSummary.OrderNumber;
            pos.offDockedOn = String.valueOf(Datetime.now());
            carrier.trackingUrl = 'https://PositiveTrack.com/'+foList.OrderSummary.OrderNumber;
            pos.carrier = carrier;
            for (Integer i = 0; i<foList.FulfillmentOrderLineItems.size(); i++) {
                FulfillmentOrderLineItem foLine = foList.FulfillmentOrderLineItems[i];
                PositiveOrderStatusResponse.Products item = new PositiveOrderStatusResponse.Products();
                PositiveOrderStatusResponse.InventoryDetails inventory = new PositiveOrderStatusResponse.InventoryDetails();
                inventory.lotNumber = 'LOTNUMBER' + i;
                item.customerProductCode = foLine.OrderItemSummary.sfcc_SAPMaterialCode__c;
                item.quantityShipped = Integer.valueOf(foLine.Quantity);
                item.inventoryDetails = new List<PositiveOrderStatusResponse.InventoryDetails> { inventory };
                itemList.add(item);
            }
            pos.products = itemList;
            orderStatusResponse = JSON.serialize(pos, true);
        }
        return orderStatusResponse;
    }
}