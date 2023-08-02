public class PositiveOrderDetailsStatusImportJobV2 implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public final String CLASS_NAME = PositiveOrderDetailsStatusImportJobV2.class.getName();
    public final String GATEWAY_SUCCESS = 'Success: Order Number = {0}, Positive Order Id = {1}';
    public final String GATEWAY_ERROR = 'Failed: Order Number = {0}, Positive Order Id = {1}';
    public final String NO_RECORD_FOUND = 'No Record Found: Order Number = {0}, Positive Order Id = {1}';
    public final String FULFILLED = 'Fulfilled';
    public List<String> orderSummaryIds;
    
    public PositiveOrderDetailsStatusImportJobV2() {}
    
    public PositiveOrderDetailsStatusImportJobV2(List<String> orderSummaryIds) {
        this.orderSummaryIds = orderSummaryIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String orderByAndLimitClause = Test.isRunningTest() ? ' ORDER BY CreatedDate DESC LIMIT 1' : ' ORDER BY CreatedDate';
        Database.QueryLocator queryResult;
        try {
            String osIdWhereClause = orderSummaryIds != null && !orderSummaryIds.isEmpty() ? ' AND Id IN ' + orderSummaryIds : '';
            queryResult = Database.getQueryLocator('SELECT Id, PF_Order_ID__c, Status FROM OrderSummary WHERE PF_Order_ID__c != null AND Status = \'Waiting to Fulfill\'' +
                                                   ' AND (Retry_Count__c < 7 OR Retry_Count__c = NULL) AND OrderLifeCycleType = \'MANAGED\' ' + osIdWhereClause + orderByAndLimitClause);
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return queryResult;
    }
    
    public void execute(Database.BatchableContext bc, List<Ordersummary> OrderSumList) {
        String gatewayMessage;
        String errorMessage;
        String osId;
        String orderNumber;
        String positiveOrderId;
        HttpResponse getOrderResponse;
        PositiveOrderStatusResponse orderResObj;
        List<FulfillmentOrder> foList;
        Map<String, Object> reqResMap;
        List<FulfillmentOrder> foListToUpdate = new List<FulfillmentOrder>();
        List<FulfillmentOrderLineItem> foItemListToUpdate = new List<FulfillmentOrderLineItem>();
        List<OrderSummary> osListToUpdate = new List<OrderSummary>();
        List<OrderItemSummary> osItemListToUpdate = new List<OrderItemSummary>();
        List<Shipment> shipmentList = new List<Shipment>();
        List<ShipmentItem> shipItemList;
        Map<Id, List<ShipmentItem>> shipmentItemMap = new Map<Id, List<ShipmentItem>>();
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        Set<Id> foIds = new Set<Id>();
        List<Id> osIds = new List<Id>();
        List<SObject> events = new List<SObject>();
        try {
            for (OrderSummary os : OrderSumList) {
                 osIds.add(os.Id);
            }
            if (osIds != null) {
                List<ProcessException> activePEs = [SELECT Id, OrderSummaryId FROM ProcessException WHERE Message = 'Not Fulfilled' AND Status = 'New' AND OrderSummaryId IN :osIds];
                List<Id> peOsIds = new List<Id>();
                for (ProcessException pe : activePEs) {
                    peOsIds.add(pe.OrderSummaryId);
                }
                List<ProcessException> activePartialFullfilPe = [SELECT Id, OrderSummaryId FROM ProcessException WHERE Message = 'Partial Fulfillment' AND Status = 'New' AND OrderSummaryId IN :osIds];
                Map<Id, Boolean> partialPeIds = new Map<Id, Boolean>();
                for (ProcessException pe : activePartialFullfilPe) {
                    partialPeIds.put(pe.OrderSummaryId, true);
                }
                foList = [SELECT Id, FulfilledToName, OrderSummaryId, OrderSummary.OrderNumber, Status, OrderSummary.PF_Order_ID__c, OrderSummary.Retry_Count__c,
                          (SELECT Id, Quantity, Type, OrderItemSummaryId, OrderItemSummary.sfcc_BundleProductGUID__c, OrderItemSummary.sfcc_SAPMaterialCode__c, OrderItemSummary.ProductCode  
                           FROM FulfillmentOrderLineItems WHERE Type = 'Order Product' ORDER BY  OrderItemSummary.sfcc_BundleProductGUID__c ASC NULLS FIRST)
                           FROM FulfillmentOrder WHERE OrderSummaryId NOT IN :peOsIds AND OrderSummaryId IN :osIds AND Status != 'Fulfilled'];
                for (FulfillmentOrder fo : foList) {
                    if(foList != null){
                        try {
                            orderNumber = fo.OrderSummary.OrderNumber;
                            positiveOrderId = fo.OrderSummary.PF_Order_ID__c;
                            osId = fo.OrderSummaryId;
                            Boolean isItemFulfilled = false;
                            Map<String, FulfillmentOrderLineItem> bundleProductMap = new Map<String, FulfillmentOrderLineItem>();
                            Map<String, Boolean> shipmentCreatedForBundleProductMap = new Map<String, Boolean>();
                            shipItemList = new List<ShipmentItem>();
                            //Callout
                            reqResMap = PositiveServices.getOrderByOrderId(positiveOrderId);
                            if (!reqResMap.isEmpty()) {
                                getOrderResponse = (HttpResponse)reqResMap.get('response');
                                if (getOrderResponse?.getStatusCode() == 200) {
                                    gateWayMessage = String.format(GATEWAY_SUCCESS, new Object[] {orderNumber, positiveOrderId});
                                    orderResObj = PositiveOrderStatusResponse.parse(getOrderResponse.getBody());
                                    if (orderNumber == orderResObj.customersOrderNumber) {
                                        for (FulfillmentOrderLineItem foItem : fo.FulfillmentOrderLineItems) {
                                            String bundleProductGUID = foItem.OrderItemSummary.sfcc_BundleProductGUID__c;
                                            String sapMaterialCode = foItem.OrderItemSummary.sfcc_SAPMaterialCode__c;
                                            Integer foItemQuantity = Integer.valueOf(foItem.Quantity);
                                            if (bundleProductGUID == null && sapMaterialCode == null) {
                                                bundleProductMap.put(foItem.OrderItemSummary.ProductCode, foItem);
                                            } else {
                                                for (PositiveOrderStatusResponse.Products positiveItem : orderResObj.products) {
                                                    if (positiveItem.customerProductCode == sapMaterialCode && positiveItem.quantityShipped == foItemQuantity) {
                                                        isItemFulfilled = true;
                                                        if (bundleProductGUID != null && !shipmentCreatedForBundleProductMap.containsKey(bundleProductGUID) && bundleProductMap.containsKey(bundleProductGUID)) {
                                                            FulfillmentOrderLineItem foLineItem = bundleProductMap.get(bundleProductGUID);
                                                            shipItemList.add(new ShipmentItem(OrderItemSummaryId = foLineItem.OrderItemSummaryId,
                                                                                              Quantity = foItem.Quantity));
                                                            shipmentCreatedForBundleProductMap.put(bundleProductGUID, true);
                                                        }
                                                        shipItemList.add(new ShipmentItem(OrderItemSummaryId = foItem.OrderItemSummaryId, 
                                                                                            Quantity = foItem.Quantity));
                                                        osItemListToUpdate.add(new OrderItemSummary(Id = foItem.OrderItemSummaryId, 
                                                                                                    LotNumber__c = positiveItem.inventoryDetails[0].lotNumber));
                                                        break;
                                                    } else if (positiveItem.quantityShipped != 0 && positiveItem.quantityShipped != foItemQuantity && !partialPeIds.containskey(fo.orderSummaryId)){
                                                        events.add(OmsSystemX.createProcessException('Partial Fulfillment', 'HIGH', fo.orderSummaryId , fo.Id, 'Partial Fulfillment'));
                                                    }
                                                }
                                            }
                                        }
                                        Datetime positiveShipDate = orderResObj.offDockedOn != null ? Datetime.valueOfGmt(orderResObj.offDockedOn.replace('T', ' ')) : null;
                                        if (isItemFulfilled && positiveShipDate != null) {
                                            foIds.add(fo.Id);
                                            fo.Status = FULFILLED;
                                            fo.AmwareShipDate__c = positiveShipDate;
                                            foListToUpdate.add(fo);
                                            osListToUpdate.add(new OrderSummary(Id = fo.OrderSummaryId, Status = FULFILLED));
                                            //creating shipment record and adding them to shipment list
                                            shipmentList.add(new Shipment(FulfillmentOrderId = fo.Id, ShipToName = fo.FulfilledToName,
                                                                            OrderSummaryId = fo.orderSummaryId, 
                                                                            AmwareShipDate__c = positiveShipDate,
                                                                            TrackingNumber =  orderResObj.waybillNumber,
                                                                            TrackingUrl = orderResObj.carrier.trackingUrl));
                                        } else {
                                            osListToUpdate.add(new OrderSummary(Id = fo.OrderSummaryId, Retry_Count__c = fo.ordersummary.Retry_Count__c == Null ? 1 : fo.ordersummary.Retry_Count__c + 1));
                                            if (fo.ordersummary.Retry_Count__c == 6){
                                                events.add(OmsSystemX.createProcessException('Not Fulfilled', 'HIGH', fo.orderSummaryId , fo.Id, 'Not Fulfilled'));
                                            }
                                        }
                                        //Adding all the shipment items into map with the key as fulfillment order id
                                        if(shipItemList != null){
                                            shipmentItemMap.put(fo.Id, shipItemList);
                                        }
                                    }
                                } else if (getOrderResponse?.getStatusCode() == 204) {
                                    gateWayMessage = String.format(NO_RECORD_FOUND, new Object[] {orderNumber, positiveOrderId});
                                } else {
                                    gateWayMessage = String.format(GATEWAY_ERROR, new Object[] {orderNumber, positiveOrderId});
                                }
                            } else {
                                gateWayMessage = String.format(GATEWAY_ERROR, new Object[] {orderNumber, positiveOrderId});
                            }
                        } catch (Exception ex) {
                            errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { ex.getMessage(), ex.getLineNumber(), ex.getStackTraceString(), ex.getCause() });
                            gateWayMessage = String.format(GATEWAY_ERROR, new Object[] {orderNumber, positiveOrderId});
                        } finally {
                            logs.add(new WMSGatewayLog__c(InteractionType__c = 'FulfillmentImport', OrderSummary__c = osId, Request__c = ((HttpRequest)reqResMap?.get('request'))?.toString(),
                                                          Response__c = getOrderResponse?.getBody()?.length()>200 ? getOrderResponse?.getBody().subString(0,200) : getOrderResponse?.getBody(), ResultCode__c = getOrderResponse?.getStatusCode(),
                                                          GatewayMessage__c = gateWayMessage, ErrorMessage__c = errorMessage));
                            errorMessage = null;
                            gateWayMessage = null;
                            orderResObj = null;
                            getOrderResponse = null;
                            reqResMap = null;
                            shipItemList = null;
                        }
                    }
                }
                //Inserting Shipment records
                if (!shipmentList.isEmpty()){
                    insert shipmentList;
                }
                
                // For adding corresponding shipmentId reference in the ShipmentItem records
                List<ShipmentItem> shipItemToInsert = new List<ShipmentItem>();
                for (Shipment ship: shipmentList) {
                    List<ShipmentItem> shipItems = shipmentItemMap.get(ship.FulfillmentOrderId);
                    for (ShipmentItem shipItem : shipItems)  {
                        shipItem.ShipmentId = ship.Id;
                    }
                    shipItemToInsert.addAll(shipItems);
                }
                
                //Inserting Shipment Items
                if (!shipItemToInsert.isEmpty()) {
                    insert shipItemToInsert;
                }
                
                // Updating FulfillmentOrder records
                if (!foListToUpdate.isEmpty()){
                    update foListToUpdate;
                }
                
                //Updating OrderItemSummary records
                if(!osItemListToUpdate.isEmpty()) {
                    update osItemListToUpdate;
                }

                //Updating OrderSummary records
                if (!osListToUpdate.isEmpty()){
                    update osListToUpdate;
                }
    
                //Publishing 
                if (!events.isEmpty()) {
                    EventBusX.publish(events);
                }
    
                //Inserting WMS Gateways logs 
                if (!logs.isEmpty()) {
                    insert logs;
                }
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
    }
    
    public void finish(Database.BatchableContext bc) {}
}