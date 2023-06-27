public class AmwareReturnsImportJob implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    public static final String GATEWAY_SUCCESS = 'AmwareReturnsImportJob Success';
	public static final String GATEWAY_FAIL = 'AmwareReturnsImportJob Failed';
    public Integer requestCount = 0;
    public String className = AmwareReturnsImportJob.class.getName();
    public List<WmsGatewayLog__c> wmsGatewayList = new List<WmsGatewayLog__c>();
    String sinceDateTime = String.valueOf(Datetime.newInstanceGMT(Date.today().year(), Date.today().month(), Date.today().day(), 0, 0, 0).formatGmt('yyyy-MM-dd HH:mm'));//public String sinceDateTime = String.valueOf(Datetime.now().addMinutes(-60).formatGmt('yyyy-MM-dd HH:mm'));
    public Integer rowsPerPage = 200;

    //constructors
    public AmwareReturnsImportJob() {}
    public AmwareReturnsImportJob(String sinceDateTime) {
        this.sinceDateTime = sinceDateTime;
    }
    
    public List<Integer> start(Database.BatchableContext bc) {
        List<Integer> requestCountList = new List<Integer>();
        try {
            List<Object> amwareRoReqRes = AmwareServices.getReturns(rowsPerPage, 0, sinceDateTime);
            if(amwareRoReqRes != null) {
                HttpResponse res = (HttpResponse) amwareRoReqRes[1];
                AmwareReturnsResponse amwareRoResObj = AmwareReturnsResponse.parse(res.getBody());
                if (amwareRoResObj?.recordCount > 0) {
                    requestCount = Integer.valueOf(Math.ceil(Decimal.valueOf(amwareRoResObj.recordCount) / Decimal.valueOf(200)));
                    for (Integer i = 0; i < requestCount; i++) {
                        requestCountList.add(i);
                    }
                }
            }
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return requestCountList;        
    }
    
    public void execute(Database.BatchableContext bc, List<Integer> requestCountList) {
        List<ReturnOrder> returnOrderList;
        String gatewayMessage = GATEWAY_SUCCESS;
        String errorMessage = null;
        HttpRequest req;
        HttpResponse res;
        Set<String> orderNumbers = new Set<String>();
        List<AmwareReturnsResponse> amwareReturnOrderList = new List<AmwareReturnsResponse>();
        List<ReturnOrderLineItem> roLineItemListToUpdate = new List<ReturnOrderLineItem>();
        Map<String, AmwareReturnsResponse.Returns> amwareRoMap = new Map<String, AmwareReturnsResponse.Returns>();
        List<SObject> events = new List<SObject>();
        Integer totalRecordCount = 0;
        try {
            for (Integer i = 0; i < requestCountList.size(); i++) {
                try {
                    //String amwareRoReqRes = AmwareServices.getReturns(200, requestCountList.get(i));
                    List<Object> amwareRoReqRes = AmwareServices.getReturns(rowsPerPage, requestCountList.get(i), sinceDateTime);
                    if(amwareRoReqRes != null) {
                        req = (HttpRequest) amwareRoReqRes[0];
                        res = (HttpResponse) amwareRoReqRes[1];
                        if (!String.isBlank(res.getBody()) && res.getStatusCode() == 200) {
                            AmwareReturnsResponse amwareReturnResObj = AmwareReturnsResponse.parse(res.getBody());
                            if (amwareReturnResObj?.recordCount > 0 && !amwareReturnResObj?.returns.isEmpty()) {
                                totalRecordCount = amwareReturnResObj.recordCount;
                                for(AmwareReturnsResponse.Returns returnObj : amwareReturnResObj.returns) {
                                    String orderNumber = returnObj.clientReference;
                                    orderNumbers.add(orderNumber);
                                    if(amwareRoMap.containsKey(orderNumber)) {
                                        amwareRoMap.get(orderNumber).returnLines.addAll(returnObj.returnLines);
                                    } else  {
                                        amwareRoMap.put(orderNumber, returnObj);
                                    }
                                }
                            }
                        } else {
                            errorMessage = String.format(' Service encounterd {0} response or empty response',new Object[] { res.getStatusCode() });
                            gatewayMessage = GATEWAY_FAIL;
                        }
                    } else {
                        errorMessage = 'Auth Token service encounterd empty response';
                        gatewayMessage = GATEWAY_FAIL;
                    }
                } catch(Exception e) {
                    if (res.getStatusCode() != 200) {
                        errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
                        gatewayMessage = GATEWAY_FAIL;
                    }
                } finally {
                    wmsGatewayList.add(new WMSGatewayLog__c(InteractionType__c = 'FulfillmentExport', Request__c = req?.toString(), Response__c = !String.isBlank(res.getBody()) ? 'Total Record Count: ' + totalRecordCount : (res?.toString()), ErrorMessage__c = errorMessage, GatewayMessage__c = gatewayMessage, ResultCode__c = res?.getStatusCode()));
                }
            }
            System.debug('amwareRoMap: ' + amwareRoMap.toString());
            returnOrderList = [SELECT Id, OrderSummaryId, Description, OrderSummary.Ordernumber,
                               (SELECT Id, OrderItemSummaryId, QuantityReceived, QuantityExpected, OrderItemSummary.sfcc_BundleProductGUID__c,  
                                OrderItemSummary.sfcc_SAPMaterialCode__c, OrderItemSummary.ProductCode, OrderItemSummary.Type 
                                FROM ReturnOrderLineItems ORDER BY  OrderItemSummary.sfcc_BundleProductGUID__c ASC)
                               FROM ReturnOrder WHERE Ordersummary.Ordernumber IN :orderNumbers AND Status NOT IN ('Closed', 'Canceled' , 'Refund_Initiated')];
            for (ReturnOrder returnOrder : returnOrderList) {
                Boolean isRoClosed = true;
                AmwareReturnsResponse.Returns amwareRoList =  amwareRoMap.get(returnOrder.OrderSummary.Ordernumber);
                Map<String, ReturnOrderLineItem> bundleProductRoMap = new Map<String, ReturnOrderLineItem>();
                Map<String, Boolean> isBundleProductRoMap = new Map<String, Boolean>();
                for (ReturnOrderLineItem roLine : returnOrder.ReturnOrderLineItems) {
                    if (roLine.OrderItemSummary.Type == 'Delivery Charge') {
                        roLine.QuantityReceived = roLine.QuantityExpected;
                    } else if (roLine.OrderItemSummary.sfcc_SAPMaterialCode__c == null && roLine.OrderItemSummary.Type == 'Order Product') {
                        bundleProductRoMap.put(roLine.OrderItemSummary.ProductCode, roLine);
                    } else {
                        for (AmwareReturnsResponse.ReturnLines amwareRoLine : amwareRoList.returnLines) {
                            if (roLine.OrderItemSummary.sfcc_SAPMaterialCode__c != null && roLine.OrderItemSummary.sfcc_BundleProductGUID__c != null && roLine.OrderItemSummary.Type == 'Order Product') {
                                ReturnOrderLineItem bundleRoLine = bundleProductRoMap.get(roLine.OrderItemSummary.sfcc_BundleProductGUID__c);
                                if (roLine.OrderItemSummary.sfcc_SAPMaterialCode__c == amwareRoLine.sku && roLine.QuantityExpected == amwareRoLine.quantity) {
                                    roLine.QuantityReceived = amwareRoLine.quantity;
                                    if (!isBundleProductRoMap.containsKey(roLine.OrderItemSummary.sfcc_BundleProductGUID__c)) {
                                        bundleRoLine.QuantityReceived = bundleRoLine.QuantityExpected;
                                        isBundleProductRoMap.put(roLine.OrderItemSummary.sfcc_BundleProductGUID__c, true);
                                    }
                                    break;
                                }
                            } else if (roLine.OrderItemSummary.sfcc_SAPMaterialCode__c != null && roLine.OrderItemSummary.sfcc_BundleProductGUID__c == null && roLine.OrderItemSummary.Type == 'Order Product') {
                                if (roLine.OrderItemSummary.sfcc_SAPMaterialCode__c == amwareRoLine.sku && roLine.QuantityExpected == amwareRoLine.quantity) {
                                    roLine.QuantityReceived = amwareRoLine.quantity;
                                    break;
                                }
                            }
                        }
                        if (roLine.QuantityReceived == 0) {
                            isRoClosed = false;
                        }
                    }
                    roLineItemListToUpdate.add(roLine);
                }
                if (isRoClosed) {
                    returnOrder.Status = 'Refund_Initiated';
                } else {
                    events.add(OmsSystemX.createProcessException('Partial Return Order', 'HIGH', returnOrder.OrderSummaryId , returnOrder.Id, 'Partial Return Order'));
                }
            }
            
    		//Updating ReturnOrderLineItem records	
            if(!roLineItemListToUpdate.isEmpty()) {
                update roLineItemListToUpdate;
            }
       
            //Updating ReturnOrder
            if (!returnOrderList.isEmpty()) {
                update returnOrderList;
            }
            
            //Publishing 
            if (!events.isEmpty()) {
                EventBusX.publish(events);
            }
            if (!wmsGatewayList.isEmpty()) {
                insert wmsGatewayList;
            }
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}