public class PositiveOrderStatusImportJob implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    public static Integer requestCount;
    public static String fromDT;
    public static String toDT;
    public static Integer rowsPerPage = 200;
    public static String sorting = 'Ascending';
    public static final String ACCESS_TOKEN_ERROR = 'No Access Token generated';
    public static final String GATEWAY_SUCCESS = 'Get orders request was successful';
    public static final String GATEWAY_ERROR = 'Get orders request was not successful';
	
    public List<Integer> start(Database.BatchableContext bc) {
        String gateWayMessage;
        String errorMessage;
        PositiveGetOrdersResponse ordersResObj;
        HttpResponse accessTokenResponse;
        HttpResponse getOrdersResponse;
        List<Object> reqResList;
        List<Integer> requestCountList;
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        try {
            requestCountList = new List<Integer>();
            logs = new List<WmsGatewayLog__c>();
            reqResList = PositiveServices.getOrders(fromDT, toDT, 0, rowsPerPage, sorting);
            if (reqResList != null) {
                accessTokenResponse = (HttpResponse)reqResList[1];
                if (accessTokenResponse?.getStatusCode() == 200) {
                    getOrdersResponse = (HttpResponse)reqResList[3];
                    if (getOrdersResponse?.getStatusCode() == 200) {
                        gateWayMessage = GATEWAY_SUCCESS;
                        ordersResObj = PositiveGetOrdersResponse.parse(getOrdersResponse.getBody());
                        if (ordersResObj.totalCount > 0) {
                            requestCount = Integer.valueOf(Math.ceil(Decimal.valueOf(ordersResObj.totalCount) / Decimal.valueOf(rowsPerPage)));
                            for (Integer i = 0; i < requestCount; i++) {
                                requestCountList.add(i);
                            }
                        }
                    } else {
                        gateWayMessage = GATEWAY_ERROR;
                    }
                } else {
                    logs.add(new WMSGatewayLog__c(InteractionType__c = 'Fulfillment', Request__c = ((HttpRequest)reqResList[0])?.toString(), 
                                                  Response__c = accessTokenResponse?.getBody(), ErrorMessage__c = ACCESS_TOKEN_ERROR,
                                                  GatewayMessage__c = ACCESS_TOKEN_ERROR, ResultCode__c = accessTokenResponse?.getStatusCode()));
                }
            }
        } catch (Exception ex) {
            errorMessage = 'Exception Type: ' + ex.getTypeName() + ', Error Message: ' + ex.getMessage() + ', LineNumber: ' + ex.getLineNumber() + ', StackTrace: ' + ex.getStackTraceString();
        } finally {
            logs.add(new WMSGatewayLog__c(InteractionType__c = 'Fulfillment', Request__c = ((HttpRequest)reqResList[2])?.toString(), 
                                          Response__c = getOrdersResponse?.getBody(), ErrorMessage__c = errorMessage,
                                          GatewayMessage__c = errorMessage, ResultCode__c = getOrdersResponse?.getStatusCode()));
            insert logs;
        }
        return requestCountList;
    }
    
    public void execute(Database.BatchableContext bc, List<Integer> requestCountList) {
        String gatewayMessage;
        String errorMessage;
        PositiveGetOrdersResponse ordersResObj;
        HttpResponse accessTokenResponse;
        HttpResponse getOrdersResponse;
        List<Object> reqResList;
        List<WmsGatewayLog__c> logs = new List<WmsGatewayLog__c>();
        List<PositiveGetOrdersResponse> ordersResObjList = new List<PositiveGetOrdersResponse>();
        List<FulfillmentOrder> foList;
        Set<String> orderNumberSet = new Set<String>();
        Map<String, PositiveGetOrdersResponse.Items> positiveOrdersMap = new Map<String, PositiveGetOrdersResponse.Items>();
        List<FulfillmentOrder> foListToUpdate = new List<FulfillmentOrder>();
        List<OrderSummary> osListToUpdate = new List<OrderSummary>();
        try {
            for (Integer i = 0; i < requestCountList.size(); i++) {
                try {
                    reqResList = PositiveServices.getOrders(fromDT, toDT, requestCountList[i], rowsPerPage, sorting);
                    if (!reqResList?.isEmpty()) {
                        accessTokenResponse = (HttpResponse)reqResList[1];
                        if(accessTokenResponse?.getStatusCode() == 200) {
                            getOrdersResponse = (HttpResponse)reqResList[3];
                            if(getOrdersResponse.getStatusCode() == 200) {
                                gateWayMessage = GATEWAY_SUCCESS;
                                ordersResObj = PositiveGetOrdersResponse.parse(getOrdersResponse.getBody());
                                for(PositiveGetOrdersResponse.Items item : ordersResObj.items) {
                                    String orderNumber = String.valueOf(item.orderNumber);
                                    orderNumberSet.add(orderNumber);
                                    positiveOrdersMap.put(orderNumber, item);
                                }
                            } else {
                                gateWayMessage = GATEWAY_ERROR;
                            }
                        } else {
                            logs.add(new WMSGatewayLog__c(InteractionType__c = 'Fulfillment', Request__c = ((HttpRequest)reqResList[0])?.toString(), 
                                                          Response__c = accessTokenResponse?.getBody(), ErrorMessage__c = ACCESS_TOKEN_ERROR,
                                                          GatewayMessage__c = ACCESS_TOKEN_ERROR, ResultCode__c = accessTokenResponse?.getStatusCode()));
                        }
                    }
                } catch(Exception ex) {
                    errorMessage = 'Exception Type: ' + ex.getTypeName() + ', Error Message: ' + ex.getMessage() + ', LineNumber: ' + ex.getLineNumber() + ', StackTrace: ' + ex.getStackTraceString();                
                } finally {
                    logs.add(new WMSGatewayLog__c(InteractionType__c = 'Fulfillment', Request__c = ((HttpRequest)reqResList[2])?.toString(), 
                                              Response__c = getOrdersResponse?.getBody(), ErrorMessage__c = errorMessage,
                                              GatewayMessage__c = errorMessage, ResultCode__c = getOrdersResponse?.getStatusCode()));
                    errorMessage = null;
                    gateWayMessage = null;
                    ordersResObj = null;
                    accessTokenResponse = null;
                    getOrdersResponse = null;
                    reqResList = null;
                }
            }
            foList = [SELECT Id, Status, OrderSummaryId, OrderSummary.Status, OrderSummary.OrderNumber FROM FulfillmentOrder WHERE OrderSummary.OrderNumber IN :orderNumberSet];
            for(FulfillmentOrder fo : foList) {
                fo.Status = 'FULFILLED';
                osListToUpdate.add(new OrderSummary(Id = fo.OrderSummaryId, Status = 'FULFILLED'));
            }

            if(!foList.isEmpty()) {
                update foList;
            }

            if(!osListToUpdate.isEmpty()) {
                update osListToUpdate;
            }
        } catch (Exception ex) {
            
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}