public class AmwareReturnsUtility {
    public static Map<String,AmwareReturnsResponse.Returns> getReturnsResponse(Integer rowsPerPage, Integer pageIndex){
		Map<String, AmwareReturnsResponse.Returns> getReturnsMap = new Map<String, AmwareReturnsResponse.Returns>();
		List<AmwareReturnsResponse> amwareReturnResList = new List<AmwareReturnsResponse>();
        String returnResponse = AmwareServices.getReturns(rowsPerPage, pageIndex);
		AmwareReturnsResponse amwareReturnsResObj = AmwareReturnsResponse.parse(returnResponse);
		System.debug('Response : '+ returnResponse);
		try {
			if (amwareReturnsResObj != null && amwareReturnsResObj.recordCount > 0) {
				amwareReturnResList.add(amwareReturnsResObj);
				Integer requestCount = Integer.valueOf(Math.ceil(Decimal.valueOf(amwareReturnsResObj.recordCount) / Decimal.valueOf(200)));
				for (Integer i = 1; i < requestCount; i++) {
					returnResponse = AmwareServices.getReturns(200, i);
					if (!String.isBlank(returnResponse)) {
						amwareReturnsResObj = AmwareReturnsResponse.parse(returnResponse);
						if (amwareReturnsResObj != null && amwareReturnsResObj.recordCount > 0 && !amwareReturnsResObj.returns.isEmpty()) {
							amwareReturnResList.add(amwareReturnsResObj);
						}
					}
				}
			}
			for (AmwareReturnsResponse amwareRetResObj : amwareReturnResList) {
				for (AmwareReturnsResponse.Returns r : amwareRetResObj.returns) {
					if (!amwareRetResObj.returns.isEmpty() && amwareRetResObj.returns != null ) {
						getReturnsMap.put(r.clientReference, r);
					}
				}
			}
			if(!getReturnsMap.isEmpty()) {
				return getReturnsMap;
			} else {
				return null;
			}
		} catch (Exception e) {
			System.debug('Exception error: '+ e);
			String errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
            insert new GenericGatewayLog__c(InteractionType__c = 'AmwareReturnsUtility', ErrorMessage__c = errorMessage);
			System.debug('exception: '+errorMessage);
			System.debug(System.LoggingLevel.ERROR, errorMessage);
			return null;
		}
	}

	//Method to create Mock Response same as Amware.getReturns();
	public String getResponseMock(String orderNo) {
		Set<String> orderNumberSet = new Set<String>();
		List<ReturnOrder> retOrderList = [SELECT Id, CreatedDate, OrderSummaryId, Description, Ordersummary.Ordernumber,
            (SELECT Id, OrderItemId, Product2Id, Product2.StockKeepingUnit, OrderItemSummaryId, 
            QuantityReturned, QuantityUnitOfMeasure, ReasonForReturn, QuantityReceived, QuantityExpected, ReasonForRejection,Description FROM ReturnOrderLineItems) 
            FROM ReturnOrder WHERE Ordersummary.Ordernumber = :orderNo ];
			//FROM ReturnOrder WHERE Status = 'Submitted' limit 5];
		for(ReturnOrder ro: retOrderList) {
			orderNumberSet.add(String.valueOf(ro.Ordersummary.Ordernumber));
		}

		System.debug('Order Numbers to be Processed: '+orderNumberSet);
		Map<Id,String> mapCollectionBundle = new Map<Id,String>();
		//for(OrderItemSummary oismock : [Select Id, Type, OrderSummaryId, StockKeepingUnit, Quantity, sfcc_SAPMaterialCode__c, sfcc_BundleProductGUID__c  
		//FROM OrderItemSummary Where OrderSummary.OrderNumber =: orderNumberSet]){
		for(OrderItemSummary oismock : [Select Id, Type, OrderSummaryId, StockKeepingUnit, Quantity, sfcc_SAPMaterialCode__c, sfcc_BundleProductGUID__c  
		FROM OrderItemSummary Where OrderSummary.OrderNumber = :orderNo]){
			if(oismock.sfcc_SAPMaterialCode__c == null && oismock.sfcc_BundleProductGUID__c == null && oismock.Type != 'Delivery Charge'){
				mapCollectionBundle.put(oismock.Id,oismock.StockKeepingUnit);
				System.debug(String.format('Id: {0} with SKU: {1} Qty: {2}', new Object[] { oismock.Id,oismock.StockKeepingUnit, oismock.Quantity }));
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
			Datetime createDate = retO.CreatedDate;
			createReturnObj.dateReceived = createDate.format('yyyy-MM-dd\'T\'hh:mm:ss Z');
			for(ReturnOrderLineItem rLineItem :  retO.ReturnOrderLineItems) {
				if(mapCollectionBundle.get(rLineItem.OrderItemSummaryId) != null){
					continue;					
				}
				if(rLineItem.QuantityExpected > 0){
					AmwareReturnsResponse.ReturnLines createReturnLine = new AmwareReturnsResponse.ReturnLines();
					createReturnLine.sku = rLineItem.Product2.StockKeepingUnit;
					createReturnLine.quantity = Integer.valueOf(rLineItem.QuantityExpected);
					createReturnLine.dispositionCode = 'Mock123';
					createReturnLine.disposition = 'Mock Return from Amware';
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
