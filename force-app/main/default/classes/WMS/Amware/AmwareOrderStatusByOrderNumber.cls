/**
 * This class accepts the order numbers through the constructor
 * to fetch the order status from amware
 * and if fulfilled, updates the order summary and fulfillment order status to 'Fulfilled'
 * and creates a shipment object.
 */
public class AmwareOrderStatusByOrderNumber implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public String orderNumbers;
    public Boolean createShipment;
	public final String GATEWAY_SUCCESS = 'AmwareOrderStatusByOrderNumber Success';
	public final String GATEWAY_FAIL = 'AmwareOrderStatusByOrderNumber Failed';
	String className = AmwareOrderStatusByOrderNumber.class.getName();

    public AmwareOrderStatusByOrderNumber(String orderNumbers, Boolean createShipment) {
        this.orderNumbers = orderNumbers;
        this.createShipment = createShipment;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, FulfilledToName, OrderSummaryId, Status, OrderSummary.OrderNumber, ' +
                        '(SELECT Id, Quantity, Type, OrderItemSummaryId, OrderItemSummary.sfcc_BundleProductGUID__c, OrderItemSummary.sfcc_SAPMaterialCode__c, '+
                        'OrderItemSummary.ProductCode FROM FulfillmentOrderLineItems WHERE Type = \'Order Product\' ORDER BY  OrderItemSummary.sfcc_BundleProductGUID__c ASC) '+
                        'FROM FulfillmentOrder WHERE OrderSummary.OrderNumber IN (' + this.orderNumbers + ')';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<FulfillmentOrder> foList) {
		Set<String> foIds;
		List<FulfillmentOrder> fulfillmentOrders;
		AmwareFulfillmentOrder amwareFulfillmentOrder = null;
		AmwareFulfillmentOrderItem amwareFulfillmentOrderItem = null;
		String gatewayMessage = GATEWAY_SUCCESS;
		String errorMessage = null;
		HttpRequest req;
		HttpResponse res;
		List<FulfillmentOrder> foToUpdateList = new List<FulfillmentOrder>();
		List<FulfillmentOrderLineItem> foItemToUpdateList = new List<FulfillmentOrderLineItem>();
		List<OrderItemSummary> osItemToUpdateList = new List<OrderItemSummary>();
		List<Shipment> shipmentList = new List<Shipment>();
		Map<String, List<ShipmentItem>> shipmentItemMap = new Map<String, List<ShipmentItem>>();
		List<String> orderSummaryToUpdateList = new List<String>();
		List<FulfillmentbyUTCDateResponse> amwareFulfillmentList = new List<FulfillmentbyUTCDateResponse>();
		Map<String, AmwareFulfillmentOrder> amwareRecords = new Map<String, AmwareFulfillmentOrder>();
		List<SObject> events = new List<SObject>();
		Integer totalRecordCount = 0;
		List<WmsGatewayLog__c> wmsGatewayList = new List<WmsGatewayLog__c>();
		try {
			for (FulfillmentOrder fo : foList) {
				try {
                    //String amwarefulfillResponse = AmwareServices.getFulfillmentByUTCDate(sinceDateTime, 200, requestCountList.get(i));
                    List<Object> amwareFulfillmentReqRes = AmwareServices.getOrderStatusByOrderNumber(fo.OrderSummary.OrderNumber);
                    if(amwareFulfillmentReqRes != null) {
                        req = (HttpRequest) amwareFulfillmentReqRes[0];
                        res = (HttpResponse) amwareFulfillmentReqRes[1];
                        if (!String.isBlank(res.getBody()) && res.getStatusCode() == 200) {
                            FulfillmentbyUTCDateResponse amwareFulfillResObj = FulfillmentbyUTCDateResponse.parse(res.getBody());
                            if (amwareFulfillResObj?.recordCount > 0 && !amwareFulfillResObj?.shipConfirms.isEmpty()) {
                                totalRecordCount = amwareFulfillResObj.recordCount;
                                amwareFulfillmentList.add(amwareFulfillResObj);
                            }
                        } else {
                            errorMessage = String.format(' Service encounterd {0} response or empty response',new Object[] { res.getStatusCode() });
                            gatewayMessage = GATEWAY_FAIL;
                        }
                    } else {
                        errorMessage = 'Auth Token service encounterd empty response';
                        gatewayMessage = GATEWAY_FAIL;
                    } 
                } catch (Exception e) {
                        errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
                        gatewayMessage = GATEWAY_FAIL;
                        CustomCommonUtil.sendEmail(className , e.getStackTraceString());
                } finally {
                    wmsGatewayList.add(new WMSGatewayLog__c(InteractionType__c = 'FulfillmentImport', Request__c = req?.toString(), Response__c = !String.isBlank(res?.getBody()) ? 'Total Record Count: '+ totalRecordCount : res?.toString(), ErrorMessage__c = errorMessage, GatewayMessage__c = gatewayMessage, ResultCode__c = res?.getStatusCode()));
                }
			}
			amwareRecords = getAmwareRecordsMap(amwareFulfillmentList);
            if (!amwareRecords.isEmpty()) {
                foIds = amwareRecords.keySet();
                fulfillmentOrders =  [SELECT Id, FulfilledToName, OrderSummaryId, Status,
                                      (SELECT Id, Quantity, Type, OrderItemSummaryId, OrderItemSummary.sfcc_BundleProductGUID__c, OrderItemSummary.sfcc_SAPMaterialCode__c, OrderItemSummary.ProductCode  
                                       FROM FulfillmentOrderLineItems WHERE Type = 'Order Product' ORDER BY  OrderItemSummary.sfcc_BundleProductGUID__c ASC)
                                      FROM FulfillmentOrder WHERE Id IN : foIds];
                List<ProcessException> activePEs = [SELECT Id, AttachedToId FROM ProcessException WHERE Message = 'Partial Fulfillment' AND Status = 'New' AND AttachedToId IN :foIds];
                Map<Id, Boolean> peIds = new Map<Id, Boolean>();
                for (ProcessException pe : activePEs) {
                    peIds.put(pe.attachedToId, true);
                }
                for (FulfillmentOrder fo : fulfillmentOrders) {
                    if (!peIds.containskey(fo.Id)) {
                    boolean foCompleted = true;
                    List<ShipmentItem> shipItemList = new List<ShipmentItem>();
                    Map<String, FulfillmentOrderLineItem> bundleProductMap = new Map<String, FulfillmentOrderLineItem>();
                    Map<String, Boolean> shipmentCreatedForBundleProductMap = new Map<String, Boolean>();
                    amwareFulfillmentOrder = amwareRecords.get(fo.Id);
                    if (amwareFulfillmentOrder != null) {
                        for (FulfillmentOrderLineItem foItem : fo.FulfillmentOrderLineItems) {
                            if (foItem.OrderItemSummary.sfcc_BundleProductGUID__c == null && foItem.OrderItemSummary.sfcc_SAPMaterialCode__c == null) {
                                bundleProductMap.put(foItem.OrderItemSummary.ProductCode, foItem);
                            } else if (amwareFulfillmentOrder.foItems.containsKey(foItem.Id)) {
                                amwareFulfillmentOrderItem = amwareFulfillmentOrder.foItems.get(foItem.Id);
                                if (amwareFulfillmentOrderItem != null) {
                                    String bundleProductGUID = foItem.OrderItemSummary.sfcc_BundleProductGUID__c;
                                    if (amwareFulfillmentOrderItem.quantity < foItem.Quantity) {
                                        foCompleted = false;
                                    	    /*Need to check if there are any quanities are fulfilled before for this fulfillOrderLineItem
                                             * If there any quantities are fulfilled before get the previously fulfilled quantity add it with quantity received from Amware
                                             * If the added quantity matches with fulfillmentOrderLineItem quantity update the status to fulfilled
                                             */   
                                    } else if (amwareFulfillmentOrderItem.quantity > foItem.Quantity) {
                                        foCompleted = false;
                                    	// If the Amware quantity is more than the expected quantity then we need send an alert to Admin
                                    }
                                    if (bundleProductGUID != null) {
                                        if (!shipmentCreatedForBundleProductMap.containsKey(bundleProductGUID)) {
                                            FulfillmentOrderLineItem foLineItem = bundleProductMap.get(bundleProductGUID);
                                            if(foLineItem != null) {
                                                shipItemList.add(new ShipmentItem(OrderItemSummaryId = foLineItem.OrderItemSummaryId, 
                                                                        Quantity = amwareFulfillmentOrderItem.quantity));
                                                shipmentCreatedForBundleProductMap.put(bundleProductGUID, true);
                                            }
                                        }
                                    }
                                    shipItemList.add(new ShipmentItem(OrderItemSummaryId = foItem.OrderItemSummaryId, 
                                                                    Quantity = amwareFulfillmentOrderItem.quantity));
                                    osItemToUpdateList.add(new OrderItemSummary(Id = foItem.OrderItemSummaryId, 
                                                                                LotNumber__c = amwareFulfillmentOrderItem.lotNumber));
                                }
                            } else {
                                foCompleted = false;
                            }
                        }
                        Datetime amwareShipDate = Datetime.valueOfGmt(amwareFulfillmentOrder.shipDate.replace('T', ' '));
                        if (foCompleted) {
                            fo.Status = 'Fulfilled';
                            fo.AmwareShipDate__c = amwareShipDate;
                            foToUpdateList.add(fo);
                            orderSummaryToUpdateList.add(fo.OrderSummaryId);
                        } else {
                            events.add(OmsSystemX.createProcessException('Partial Fulfillment', 'HIGH', fo.orderSummaryId , fo.Id, 'Partial Fulfillment'));
                        }
                                
                        //Adding all the shipment items into map with the key shipment tracking number
                        shipmentItemMap.put(amwareFulfillmentOrder.trackingNumber, shipItemList);
                        
                        //creating shipment record and adding them to shipment list
                        shipmentList.add(new Shipment(FulfillmentOrderId = fo.Id, ShipToName = fo.FulfilledToName,
                                                    OrderSummaryId = amwareFulfillmentOrder.orderSummaryId, 
                                                    AmwareShipDate__c = amwareShipDate, 
                                                    TrackingNumber = amwareFulfillmentOrder.trackingNumber, 
                                                    TrackingUrl = amwareFulfillmentOrder.trackingUrl, 
                                                    Description = amwareFulfillmentOrder.description));
                    }
                }

                //Inserting Shipment records
                if (!shipmentList.isEmpty()){
                    if (createShipment) {
                        insert shipmentList;
                    }
                }
                
                // For adding corresponding shipmentId reference in the ShipmentItem records
                List<ShipmentItem> shipItemToInsert = new List<ShipmentItem>();
                for (Shipment ship: shipmentList) {
                    List<ShipmentItem> shipItemList = shipmentItemMap.get(String.valueOf(ship.TrackingNumber));
                    for (ShipmentItem shipItem : shipItemList)  {
                        shipItem.ShipmentId = ship.Id;
                    }
                    shipItemToInsert.addAll(shipItemList);
                }
                
                //Inserting Shipment Items
                if (!shipItemToInsert.isEmpty()) {
                    if (createShipment) {
                        insert shipItemToInsert;
                    }
                }
                
                // Updating FulfillmentOrder records
                if (!foToUpdateList.isEmpty()){
                    update foToUpdateList;
                }
                
                if(!osItemToUpdateList.isEmpty()) {
                   update osItemToUpdateList;
                }
                
                //Updating OrderSummary records
                if (!orderSummaryToUpdateList.isEmpty()){
                    updateOrderSummaryStatus(orderSummaryToUpdateList);
                }

                //Publishing 
                if (!events.isEmpty()) {
                    EventBusX.publish(events);
                }
                 if(!wmsGatewayList.isEmpty()) {
                     insert wmsGatewayList;
                 }
            }
            }
		} catch (Exception ex) {
			CustomCommonUtil.logException(className, ex);
		}
		
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
    
     //This gets fulfilled order details from Amware and add thems to the amwareRecords map
    private Map<String, AmwareFulfillmentOrder> getAmwareRecordsMap(List<FulfillmentbyUTCDateResponse> amwareFulfillmentList) {
        AmwareFulfillmentOrder amwareFulfillmentOrder;
        Map<String, AmwareFulfillmentOrderItem> foItemMap;
        Map<String, AmwareFulfillmentOrder> amwareRecords = new Map<String, AmwareFulfillmentOrder>();
        for (FulfillmentbyUTCDateResponse amwareFulfillment : amwareFulfillmentList) {
            for (FulfillmentbyUTCDateResponse.ShipConfirms shipconfirms : amwareFulfillment.shipConfirms) {
                for (FulfillmentbyUTCDateResponse.Packages packages : shipconfirms.packages) {
                    for (FulfillmentbyUTCDateResponse.LineItems lineItems : packages.lineItems) {
                        AmwareFulfillmentOrderItem item = new AmwareFulfillmentOrderItem(String.valueOf(lineItems.pass04), lineItems.quantity, lineItems.lotNumber);
                        if (amwareRecords.containsKey(String.valueOf(lineItems.pass02))){
                            amwareFulfillmentOrder = amwareRecords.get(String.valueOf(lineItems.pass02));
                            if (amwareFulfillmentOrder.foItems.containsKey(item.fulfillmentItemId)){
                                amwareFulfillmentOrder.foItems.get(item.fulfillmentItemId).quantity += item.quantity;
                            } else {
                            amwareFulfillmentOrder.foItems.put(item.fulfillmentItemId, item);
                            }
                        } else {
                            foItemMap = new Map<String, AmwareFulfillmentOrderItem>();
                            foItemMap.put(item.fulfillmentItemId, item);
                            amwareFulfillmentOrder = new AmwareFulfillmentOrder(String.valueOf(lineItems.pass03), String.valueOf(lineItems.pass02), foItemMap, packages.shipDate, packages.trackingNumber, packages.trackingURI, packages.description);
                            amwareRecords.put(String.valueOf(lineItems.pass02), amwareFulfillmentOrder);
                        }
                    }
                }
            }
        }
        return amwareRecords;
    }
    
    private void updateOrderSummaryStatus(List<String> orderSummaryIds) {
        try {
            List<OrderSummary> orderSummaries = [SELECT Id, Status FROM OrderSummary WHERE Id IN :orderSummaryIds]; 
            if(!orderSummaries.isEmpty()) {
                for (OrderSummary orderSummary : orderSummaries) {
                    orderSummary.Status = 'Fulfilled';      
                }
            update orderSummaries;
            }
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    
    class AmwareFulfillmentOrderItem {
        String fulfillmentItemId;
        Integer quantity;
        String lotNumber;
        public AmwareFulfillmentOrderItem(String fulfillmentItemId, Integer quantity, String lotNumber) {
            this.fulfillmentItemId = fulfillmentItemId;
            this.quantity = quantity;
            this.lotNumber = lotNumber;
        }
    }

    class AmwareFulfillmentOrder {
        String orderSummaryId;
        String fulfillmentId;
        Map<String, AmwareFulfillmentOrderItem> foItems;
        String shipDate;
        String trackingNumber;
        String trackingUrl;
        String description;
        public AmwareFulfillmentOrder(String orderSummaryId, String fulfillmentId, Map<String, AmwareFulfillmentOrderItem> foItems, String shipDate, String trackingNumber, String trackingUrl, String description) {
            this.orderSummaryId = orderSummaryId;
            this.fulfillmentId = fulfillmentId;
            this.foItems = foItems;
            this.shipDate = shipDate;
            this.trackingNumber = trackingNumber;
            this.trackingUrl = trackingUrl;
            this.description = description;
        }
    }
}