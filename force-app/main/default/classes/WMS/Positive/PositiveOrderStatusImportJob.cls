public class PositiveOrderStatusImportJob implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    public Integer requestCount;
    public DateTime currentDt = DateTime.now();
    public String fromDT = Datetime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(), currentDt.dayGmt(), 0, 0, 0).formatGmt('yyyy-MM-dd HH:mm:ss');
    public String toDT = Datetime.newInstanceGmt(currentDt.yearGmt(), currentDt.monthGmt(), currentDt.dayGmt(), 23, 59, 59).formatGmt('yyyy-MM-dd HH:mm:ss');
    public Integer rowsPerPage = 200;
    public String sorting = 'Ascending';
    public Boolean isInitialRequest = true;
    public PositiveGetOrderStatusResponse ordersRespObj;
    public final String className = PositiveOrderStatusImportJob.class.getName();
    public final String GATEWAY_SUCCESS = 'Success: Positive Get orders request was successful';
    public final String GATEWAY_ERROR = 'Failed: Positive Get orders request was failed';
    public final String NO_RECORDS_FOUND = 'No Records Found';
    
    public PositiveOrderStatusImportJob() {}
    
    public PositiveOrderStatusImportJob(String fromDt, String toDt, Integer rowsPerPage, String sorting) {
        this.fromDt = fromDt;
        this.toDt = toDt;
        this.rowsPerPage = rowsPerPage;
        this.sorting = sorting;
    }
    public List<Integer> start(Database.BatchableContext bc) {
        String gateWayMessage;
        String errorMessage;
        HttpResponse getOrdersResponse;
        Map<String, Object> reqResMap;
        List<Integer> requestCountList;
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        try {
            requestCountList = new List<Integer>();
            logs = new List<WmsGatewayLog__c>();
            reqResMap = PositiveServices.getOrders(fromDT, toDT, 0, rowsPerPage, sorting);
            if (!reqResMap.isEmpty()) {
                getOrdersResponse = (HttpResponse)reqResMap.get('response');
                if (getOrdersResponse?.getStatusCode() == 200) {
                    gateWayMessage = GATEWAY_SUCCESS;
                    ordersRespObj = PositiveGetOrderStatusResponse.parse(getOrdersResponse.getBody());
                    if (ordersRespObj.totalCount > 0) {
                        requestCount = Integer.valueOf(Math.ceil(Decimal.valueOf(ordersRespObj.totalCount) / Decimal.valueOf(rowsPerPage)));
                        for (Integer i = 0; i < requestCount; i++) {
                            requestCountList.add(i);
                        }
                    }
                } else if (getOrdersResponse?.getStatusCode() == 204) {
                    gateWayMessage = NO_RECORDS_FOUND;
                } else {
                    gateWayMessage = GATEWAY_ERROR;
                }
            }
        } catch (Exception ex) {
            errorMessage = 'Exception Type: ' + ex.getTypeName() + ', Error Message: ' + ex.getMessage() + ', LineNumber: ' + ex.getLineNumber() + ', StackTrace: ' + ex.getStackTraceString();
        } finally {
            logs.add(new WMSGatewayLog__c(InteractionType__c = 'FulfillmentImport', Request__c = ((HttpRequest)reqResMap?.get('request'))?.toString(), 
                                          Response__c = getOrdersResponse?.getBody(), ErrorMessage__c = errorMessage,
                                          GatewayMessage__c = gateWayMessage, ResultCode__c = getOrdersResponse?.getStatusCode()));
            insert logs;
        }
        return requestCountList;
    }
    
    public void execute(Database.BatchableContext bc, List<Integer> requestCountList) {
        String gatewayMessage;
        String errorMessage;
        PositiveGetOrderStatusResponse ordersResObj;
        HttpResponse getOrdersResponse;
        Map<String, Object> reqResMap;
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        List<FulfillmentOrder> foList;
        List<FulfillmentOrder> foListToUpdate = new List<FulfillmentOrder>();
        List<OrderSummary> osListToUpdate = new List<OrderSummary>();
        List<PositiveOrderStatus__c> posList = new List<PositiveOrderStatus__c>();
        Map<String, String> orderNumberMap = new Map<String, String>();
        try {
            for (Integer i = 0; i < requestCountList.size(); i++) {
                try {
                    if (isInitialRequest) {
                        for (PositiveGetOrderStatusResponse.Items item : ordersRespObj.items) {
                            orderNumberMap.put(item.referenceNumber, item.orderId);
                        }
                    } else {
                        reqResMap = PositiveServices.getOrders(fromDT, toDT, requestCountList[i], rowsPerPage, sorting);
                        if (!reqResMap.isEmpty()) {
                            getOrdersResponse = (HttpResponse)reqResMap.get('response');
                            if (getOrdersResponse?.getStatusCode() == 200) {
                                gateWayMessage = GATEWAY_SUCCESS;
                                ordersResObj = PositiveGetOrderStatusResponse.parse(getOrdersResponse.getBody());
                                for (PositiveGetOrderStatusResponse.Items item : ordersResObj.items) {
                                    orderNumberMap.put(item.referenceNumber, item.orderId);
                                }
                            } else {
                                gateWayMessage = GATEWAY_ERROR;
                            }
                        }
                    }
                } catch (Exception ex) {
                    errorMessage = 'Exception Type: ' + ex.getTypeName() + ', Error Message: ' + ex.getMessage() + ', LineNumber: ' + ex.getLineNumber() + ', StackTrace: ' + ex.getStackTraceString();                
                } finally {
                    if (!isInitialRequest) {
                        logs.add(new WMSGatewayLog__c(InteractionType__c = 'FulfillmentImport', Request__c = ((HttpRequest)reqResMap.get('request'))?.toString(), 
                                              Response__c = getOrdersResponse?.getBody(), ErrorMessage__c = errorMessage,
                                              GatewayMessage__c = errorMessage, ResultCode__c = getOrdersResponse?.getStatusCode()));
                        errorMessage = null;
                        gateWayMessage = null;
                        ordersResObj = null;
                        getOrdersResponse = null;
                        reqResMap = null;
                    }
                }
                if (isInitialRequest) {
                    isInitialRequest = false;
                }
            }
            foList = [SELECT Id, Status, OrderSummaryId, OrderSummary.Status, OrderSummary.OrderNumber FROM FulfillmentOrder WHERE Status != 'Fulfill' AND OrderSummary.OrderNumber IN :orderNumberMap.keySet()];
            for (FulfillmentOrder fo : foList) {
                if (orderNumberMap.containsKey(fo.OrderSummary.OrderNumber)) {
                    posList.add(new PositiveOrderStatus__c(FulfillmentOrder__c = fo.Id, OrderId__c = orderNumberMap.get(fo.OrderSummary.OrderNumber)));
                }
            }

            if (!posList.isEmpty()) {
                insert posList;
            }

        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        /* PFS Fulfilled order Ids will be stored in the Positive Order Status object, 
         * PositiveOrderDetailsStatusImportJob job will make separate api call for each fulfilled orders 
         * and will update the corresponding orders accordingly.
        */
        Database.executeBatch(new PositiveOrderDetailsStatusImportJob(), 50);
    }
}