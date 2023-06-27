@isTest
public class AmwareMockResponse {
    static String className = AmwareMockResponse.class.getName();
    
    public static string getfulfillmentResponse(List<Id> fulfillmentIds) {
        String amwareResponse;
        JSONGenerator jsonGen = JSON.createGenerator(true);
        try {
            List<FulfillmentOrder> fulfillmentOrders =  [SELECT Id, OrderSummaryId,(SELECT Id, Quantity, OrderItemSummaryId 
                                                         FROM FulfillmentOrderLineItems WHERE OrderItemSummary.sfcc_SapMaterialCode__c != null) 
                                                         FROM FulfillmentOrder WHERE Id IN :fulfillmentIds];
            System.debug('fulfillmentOrders ' + fulfillmentOrders);
            jsonGen.writeStartObject();
            jsonGen.writeFieldName('shipConfirms');
            jsonGen.writeStartArray();
            for (Integer i = 0; i<fulfillmentOrders.size(); i++) {
                FulfillmentOrder fo = fulfillmentOrders.get(i);
                jsonGen.writeStartObject();
                jsonGen.writeStringField('clientReference', fo.ID);
                jsonGen.writeFieldName('packages');
                jsonGen.writeStartArray();
                jsonGen.writeStartObject();
                jsonGen.writeStringField('trackingNumber', String.valueOf(i));
                jsonGen.writeStringField('trackingURI', 'https://mocktracking.com?trackingId='+String.valueOf(i));
                jsonGen.writeStringField('description', 'Testing');
                jsonGen.writeStringField('shipdate', System.now().format('yyyy-MM-dd HH:mm:ss'));
                jsonGen.writeFieldName('lineItems');
                jsonGen.writeStartArray();
                for (FulfillmentOrderLineItem foItem : fo.FulfillmentOrderLineItems) {
					Integer lotNumber = Integer.valueof((Math.random() * 10000));
                    jsonGen.writeStartObject();
                    jsonGen.writeNumberField('quantity', foItem.Quantity);
					jsonGen.writeNumberField('lotNumber', lotNumber);
                    jsonGen.writeStringField('pass01', foItem.OrderItemSummaryId);
                    jsonGen.writeStringField('pass02', fo.ID);
                    jsonGen.writeStringField('pass03', fo.OrderSummaryId);
                    jsonGen.writeStringField('pass04', foItem.Id);
                    jsonGen.writeEndObject();
                }
                jsonGen.writeEndArray();
                jsonGen.writeEndObject();
                jsonGen.writeEndArray();
				jsonGen.writeEndObject();
            }
            
            jsonGen.writeEndArray();
            jsonGen.writeNumberField('recordCount', fulfillmentOrders.size());
            jsonGen.writeEndObject();
            amwareResponse = jsonGen.getAsString();
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return amwareResponse;
    }
    
	public static String getReturnResponse(String orderSummaryId, String returnOrderId) {
        //public static String getReturnResponse(String orderSummaryId) {
		Set<String> orderNumberSet = new Set<String>();
        List<ReturnOrder> retOrderList = [SELECT Id, Status, CreatedDate, OrderSummaryId, Description, Ordersummary.Ordernumber,
                                          Ordersummary.Account.FirstName, Ordersummary.Account.LastName,
            (SELECT Id, OrderItemId, Product2Id, Product2.StockKeepingUnit, Product2.ProductCode, OrderItemSummaryId, OrderItemSummary.sfcc_SAPMaterialCode__c, 
            QuantityReturned, QuantityUnitOfMeasure, ReasonForReturn, QuantityReceived, QuantityExpected, ReasonForRejection,Description FROM ReturnOrderLineItems WHERE OrderItemSummary.Type = 'Order Product') 
            FROM ReturnOrder WHERE Id=:returnOrderId AND Status = 'Submitted'];
		for(ReturnOrder ro: retOrderList) {
			orderNumberSet.add(String.valueOf(ro.Ordersummary.Ordernumber));
		}
		System.debug('Order Numbers to be Processed: '+orderNumberSet);
		Map<Id,String> mapCollectionBundle = new Map<Id,String>();
		for(OrderItemSummary oismock : [Select Id, Type, OrderSummaryId, StockKeepingUnit, ProductCode, Quantity, sfcc_SAPMaterialCode__c, sfcc_BundleProductGUID__c  
		FROM OrderItemSummary Where OrderSummaryId=:orderSummaryId AND Type = 'Order Product']){
			if(oismock.sfcc_SAPMaterialCode__c == null && oismock.sfcc_BundleProductGUID__c == null && oismock.Type != 'Delivery Charge'){
				mapCollectionBundle.put(oismock.Id,oismock.ProductCode);
				System.debug(String.format('Id: {0} with SKU: {1} Qty: {2}', new Object[] { oismock.Id,oismock.ProductCode, oismock.Quantity }));
			}
		}
		System.debug('Order Numbers to be Processed: '+orderNumberSet);
		System.debug('mapCollectionBundle: '+mapCollectionBundle);
		AmwareReturnsResponse retResponseObj = new  AmwareReturnsResponse();
		List<AmwareReturnsResponse.Returns> returnList = new List<AmwareReturnsResponse.Returns>();
		List<AmwareReturnsResponse.ReturnLines> returnLinesList = new List<AmwareReturnsResponse.ReturnLines>();
		Integer recCount=0;
		for(ReturnOrder retO : retOrderList) {
			AmwareReturnsResponse.Returns createReturnObj = new AmwareReturnsResponse.Returns();
			createReturnObj.clientReference=String.valueOf(retO.Ordersummary.Ordernumber);
			createReturnObj.facility='VANNUYS';
			createReturnObj.reasonForReturn='Mock return from Amware';
            createReturnObj.blindReturn=false;
            createReturnObj.internalOrderId='12345';
            createReturnObj.firstName=retO.Ordersummary.Account.FirstName;
            createReturnObj.lastName=retO.Ordersummary.Account.LastName;
            createReturnObj.company='Merkle';              
			Datetime createDate = retO.CreatedDate;
			createReturnObj.dateReceived = createDate.format('yyyy-MM-dd\'T\'hh:mm:ss Z');
			for(ReturnOrderLineItem rLineItem :  retO.ReturnOrderLineItems) {
				if(mapCollectionBundle.get(rLineItem.OrderItemSummaryId) != null){
					continue;					
				}
				if(rLineItem.QuantityExpected > 0){
					AmwareReturnsResponse.ReturnLines createReturnLine = new AmwareReturnsResponse.ReturnLines();
					createReturnLine.sku = rLineItem.OrderItemSummary.sfcc_SAPMaterialCode__c;
					createReturnLine.quantity = Integer.valueOf(rLineItem.QuantityExpected);
					createReturnLine.dispositionCode = 'Mock123';
					createReturnLine.disposition = 'Mock Return from Amware';
                    createReturnLine.lot = '12345';
                    createReturnLine.serialNumber = 'Mocknumber12345';
                    createReturnLine.notes = 'Mock Notes';
					returnLinesList.add(createReturnLine);
				}
			}
			if(returnLinesList.size() > 0){
				createReturnObj.returnLines = returnLinesList;
				returnList.add(createReturnObj);
				recCount++;
			}
		}
		if(returnList.size() > 0){
			retResponseObj.returns = returnList;
			retResponseObj.recordCount = recCount;
		}

		String mockRetResponse = JSON.serializePretty(retResponseObj,true);
		System.debug('Mocked Return Response: ' + mockRetResponse);
		return mockRetResponse;
	}
}