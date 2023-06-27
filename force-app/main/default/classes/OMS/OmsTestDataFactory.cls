@isTest 
public class OmsTestDataFactory {
    static Id salesChannelId ;
    static Boolean isNoSapMaterialSku = false;
    
    public static OrderSummary getTestOrderSummaryRecord () {
        Id osId = createOrderSummary();
        return [
            SELECT Id, Status, OrderNumber, SalesChannel.SalesChannelName, AccountId, OriginalOrderId, OrderedDate,
            (SELECT Id, Type, Quantity, QuantityAvailableToReturn, Product2Id FROM OrderItemSummaries)
            FROM OrderSummary WHERE Id = :osId LIMIT 1];
    }
    
    
    public static String createOrderSummary () {
        Order testOrder = createRecordsforOrderSummaryCreation();
        testOrder.Status = 'Activated';
        update testOrder;
        System.debug('testOrder id: ' + testOrder.Id);
        OrderSummary osRecord = [SELECT Id, OrderNumber, OriginalOrderId, Status, TotalTaxAmount FROM OrderSummary where OriginalOrderId =: testOrder.Id ];
        system.debug('osRecord :'+osRecord);
        /*ConnectApi.OrderSummaryInputRepresentation orderSummaryInput = new ConnectApi.OrderSummaryInputRepresentation();
        orderSummaryInput.orderId = testOrder.id;
        orderSummaryInput.businessModel = 'B2C';
        orderSummaryInput.orderLifeCycleType = 'MANAGED';
        System.debug('Order Summary Already creadted');
        ConnectApi.OrderSummaryOutputRepresentation OrderSummaryOutput = ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInput);
        System.debug('OrderSummaryOutput ' + OrderSummaryOutput); */
       return osRecord.Id;
    }
    
    
    public static Order createRecordsforOrderSummaryCreation ()
    {
        Id pricebookId = Test.getStandardPricebookId();
        //Id pricebookId = [SELECT Id, Name, IsDeleted, CurrencyIsoCode, CreatedDate FROM Pricebook2 where name = 'Standard Price Book'].Id;
 		//Id saleschannelId =  [SELECT Id, IsDeleted, OwnerId, SalesChannelName, CurrencyIsoCode, CreatedDate, CreatedById FROM SalesChannel where SalesChannelName =:salesChannelName1].Id;
       	
        Account acc = new Account();
    	acc.Name = 'Test Account';
        acc.Business_Unit__c = 'US';
    	insert acc;

        List<Product2> productList = new List<Product2>();

        // Insert Product
        Product2 testProduct = new Product2();
        String sku = 'Normal Product ' + Integer.valueof((Math.random() * 1000));
        testProduct.Name = 'Test Product';
        testProduct.Description='Test Product Entry 1';
        testProduct.productCode = sku;
        testProduct.isActive = true;
        testProduct.StockKeepingUnit = sku;
        productList.add(testProduct);
        
        Product2 testProduct2 = new Product2();
        String sku2 = 'Normal Product ' + Integer.valueof((Math.random() * 1000));
        testProduct2.Name = ' Test Product 2';
        testProduct2.Description='Test Product Entry 2';
        testProduct2.productCode = sku2;
        testProduct2.isActive = true;
        testProduct.StockKeepingUnit = sku2;
        productList.add(testProduct2);
        
        Product2 testProduct3 = new Product2();
        String sku3 = 'Bundled Product ' + Integer.valueof((Math.random() * 1000));
        testProduct3.Name = 'Test Bundle Product';
        testProduct3.Description='Test Bundle Product';
        testProduct3.productCode = sku3;
        testProduct3.isActive = true;
		testProduct3.StockKeepingUnit = sku3;
        productList.add(testProduct3);
        
        Product2 testProduct4 = new Product2();
        String sku4 = 'Bundled Product ' + Integer.valueof((Math.random() * 1000));
        testProduct4.Name = 'Test Bundled Product 1';
        testProduct4.Description='Test Bundle Product 1';
        testProduct4.productCode = sku4;
        testProduct4.isActive = true;
        testProduct4.StockKeepingUnit = sku4;
        productList.add(testProduct4);
        
        Product2 testProduct5 = new Product2();
        String sku5 = 'Bundled Product ' + Integer.valueof((Math.random() * 1000));
        testProduct5.Name = 'Test Bundled Product 2';
        testProduct5.Description='Test Bundle Product 2';
        testProduct5.productCode = sku5;
        testProduct5.isActive = true;
        testProduct5.StockKeepingUnit = sku5;
        productList.add(testProduct5);
        
        // Insert Delivery Charge Product
        Product2 deliveryChargeProduct = new Product2();
        deliveryChargeProduct.Name = 'Test Delivery Method';
        deliveryChargeProduct.Description='Test Delivery Method Entry 1';
        deliveryChargeProduct.productCode = 'DCP';
        deliveryChargeProduct.isActive = true;
        productList.add(deliveryChargeProduct);
        
        insert productList;
        System.debug('productList ' + productList);


        //Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();

        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = testProduct.Id;
        standardPrice.UnitPrice = 200;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        pricebookEntryList.add(standardPrice);
        
        PricebookEntry standardPrice2 = new PricebookEntry();
        standardPrice2.Pricebook2Id = pricebookId;
        standardPrice2.Product2Id = testProduct2.Id;
        standardPrice2.UnitPrice = 200;
        standardPrice2.IsActive = true;
        standardPrice2.UseStandardPrice = false;
        pricebookEntryList.add(standardPrice2);
        
        PricebookEntry standardPrice3 = new PricebookEntry();
        standardPrice3.Pricebook2Id = pricebookId;
        standardPrice3.Product2Id = deliveryChargeProduct.Id;
        standardPrice3.UnitPrice = 5;
        standardPrice3.IsActive = true;
        standardPrice3.UseStandardPrice = false;
        pricebookEntryList.add(standardPrice3);
        
        PricebookEntry standardPrice4 = new PricebookEntry();
        standardPrice4.Pricebook2Id = pricebookId;
        standardPrice4.Product2Id = testProduct3.Id;
        standardPrice4.UnitPrice = 150;
        standardPrice4.IsActive = true;
        standardPrice4.UseStandardPrice = false;
        pricebookEntryList.add(standardPrice4);
        
        PricebookEntry standardPrice5 = new PricebookEntry();
        standardPrice5.Pricebook2Id = pricebookId;
        standardPrice5.Product2Id = testProduct4.Id;
        standardPrice5.UnitPrice = 150;
        standardPrice5.IsActive = true;
        standardPrice5.UseStandardPrice = false;
        pricebookEntryList.add(standardPrice5);
        
        PricebookEntry standardPrice6 = new PricebookEntry();
        standardPrice6.Pricebook2Id = pricebookId;
        standardPrice6.Product2Id = testProduct5.Id;
        standardPrice6.UnitPrice = 150;
        standardPrice6.IsActive = true;
        standardPrice6.UseStandardPrice = false;
        pricebookEntryList.add(standardPrice6);
        insert pricebookEntryList;
        
		// Insert Order
        Order testOrder = new Order();
        testOrder.Name = 'testOrder1234';
        testOrder.Status = 'Draft';
        testOrder.OrderReferenceNumber = 'testOrder1234cv';
        testOrder.EffectiveDate = system.today();
        testOrder.AccountId = acc.id;
        testOrder.Pricebook2Id =  pricebookId;
      	testOrder.SalesChannelId=saleschannelId;
      	insert testOrder;
     	
        CardPaymentMethod paymentMethod = new CardPaymentMethod();
        paymentMethod.CardType = 'visa';
        paymentMethod.CardHolderName = 'John Doe';
        paymentMethod.ExpiryYear = 2020;
        paymentMethod.ExpiryMonth = 1;
        paymentMethod.CardCategory = 'CreditCard';
        paymentMethod.Status = 'Active';
        paymentMethod.AccountId = acc.Id;
        paymentMethod.ProcessingMode = 'External';
    	insert paymentMethod;

       OrderDeliveryMethod odm = new OrderDeliveryMethod();
        odm.Name = 'Test Delivery Method';
        odm.Product = deliveryChargeProduct;
        odm.Carrier = 'CUSTOM7';
        odm.IsActive = true;
        insert odm;
        
        //inserting OrderDeliveryGroup
        OrderDeliveryGroup odg = new OrderDeliveryGroup();
        odg.OrderId = testOrder.id;
        odg.DeliverToName = 'Test Customer';
        odg.DeliverToStreet = '4055 Executive Park Dr';
        odg.DeliverToCity = 'Cincinnati';
        odg.DeliverToPostalCode = '45241-4029';
        odg.DeliverToState = 'Hawaii';
        odg.DeliverToCountry = 'United States';
        odg.OrderDeliveryMethodId =odm.Id;
        odg.EmailAddress = 'a@z.com';
        insert odg;
       
        // Insert Order Item
        List<OrderItem> orderItemList = new List<OrderItem>();
		OrderItem orderItemProduct = new OrderItem();
        orderItemProduct.OrderId = testOrder.id;
        orderItemProduct.Quantity = 1;
        orderItemProduct.UnitPrice = 200;
        orderItemProduct.TotalLineAmount = 200;
        orderItemProduct.Product2id = testProduct.id;
        orderItemProduct.PricebookEntryId=standardPrice.id;
        orderItemProduct.OrderDeliveryGroupId = odg.id;
        orderItemProduct.Type = 'Order Product';
        orderItemProduct.sfcc_SAPMaterialCode__c = !isNoSapMaterialSku ? '123121' : null;
      	orderItemList.add(orderItemProduct);

        // Insert Order Item 2
        OrderItem orderItemProduct2 = new OrderItem();
        orderItemProduct2.OrderId = testOrder.id;
        orderItemProduct2.Quantity = 2;
        orderItemProduct2.UnitPrice = 200;
        orderItemProduct2.TotalLineAmount = 200;
        orderItemProduct2.Product2id = testProduct2.id;
        orderItemProduct2.PricebookEntryId=standardPrice2.id;
        orderItemProduct2.OrderDeliveryGroupId = odg.id;
        orderItemProduct2.Type = 'Order Product';
        orderItemProduct.sfcc_SAPMaterialCode__c = !isNoSapMaterialSku ? '123122' : null;
        orderItemList.add(orderItemProduct2);
        
        // Insert Order Item 3
        OrderItem orderItemProduct3 = new OrderItem();
        orderItemProduct3.OrderId = testOrder.id;
        orderItemProduct3.Quantity = 3;
        orderItemProduct3.UnitPrice = 150;
        orderItemProduct3.TotalLineAmount = 150;
        orderItemProduct3.Product2id = testProduct3.id;
        orderItemProduct3.PricebookEntryId=standardPrice4.id;
        orderItemProduct3.OrderDeliveryGroupId = odg.id;
        orderItemProduct3.Type = 'Order Product';
        orderItemList.add(orderItemProduct3);
        
        // Insert Order Item 4
        OrderItem orderItemProduct4 = new OrderItem();
        orderItemProduct4.OrderId = testOrder.id;
        orderItemProduct4.Quantity = 3;
        orderItemProduct4.UnitPrice = 0;
        orderItemProduct4.TotalLineAmount = 0;
        orderItemProduct4.Product2id = testProduct4.id;
        orderItemProduct4.PricebookEntryId=standardPrice5.id;
        orderItemProduct4.OrderDeliveryGroupId = odg.id;
        orderItemProduct4.Type = 'Order Product';
        orderItemProduct4.sfcc_BundleProductGUID__c = testProduct3.StockKeepingUnit;
        orderItemProduct4.sfcc_SAPMaterialCode__c = !isNoSapMaterialSku ? '123124' : null;
        orderItemList.add(orderItemProduct4);
        
        // Insert Order Item 5
        OrderItem orderItemProduct5 = new OrderItem();
        orderItemProduct5.OrderId = testOrder.id;
        orderItemProduct5.Quantity = 3;
        orderItemProduct5.UnitPrice = 0;
        orderItemProduct5.TotalLineAmount = 0;
        orderItemProduct5.Product2id = testProduct5.id;
        orderItemProduct5.PricebookEntryId=standardPrice6.id;
        orderItemProduct5.OrderDeliveryGroupId = odg.id;
        orderItemProduct5.Type = 'Order Product';
        orderItemProduct5.sfcc_BundleProductGUID__c = testProduct3.StockKeepingUnit;
        orderItemProduct5.sfcc_SAPMaterialCode__c = !isNoSapMaterialSku ? '123125' : null;
        orderItemList.add(orderItemProduct5);
             
        // insert delivery charge
        OrderItem orderDeliveryCharge = new OrderItem();
        orderDeliveryCharge.OrderId = testOrder.id;
        orderDeliveryCharge.Type = 'Delivery Charge';
        orderDeliveryCharge.Quantity = 1;
        orderDeliveryCharge.UnitPrice = 5;
        orderDeliveryCharge.TotalLineAmount = 5;
        orderDeliveryCharge.Product2id = deliveryChargeProduct.id;
        orderDeliveryCharge.PricebookEntryId=standardPrice3.id;
        orderDeliveryCharge.OrderDeliveryGroupId = odg.id;
        orderItemList.add(orderDeliveryCharge);
        insert orderItemList;
       
        PaymentGroup pg = new PaymentGroup();
        pg.SourceObjectId = testOrder.id;
        insert pg;
        
        PaymentAuthorization auth = new PaymentAuthorization();
        auth.amount = 100;
        auth.Status = 'Processed';
        auth.ProcessingMode = 'External';
        auth.GatewayRefNumber = 'testreferencenumber';
      	auth.PaymentMethodId=paymentMethod.Id;
        auth.AccountId = acc.Id;
        auth.paymentGroupId = pg.Id;       	
        insert auth;
        
       	Payment pmt = new Payment();
        pmt.amount = 100;
        pmt.Status = 'Processed';
        pmt.ProcessingMode = 'External';
        pmt.GatewayRefNumber = 'testreferencenumber';
        pmt.GatewayRefDetails = '{"transactionId":"62711013","amount":"200.0","giftCardId":"6003930050004631","orderID":"'+ testOrder.id+'","transactionsStatus":"success"}';
        pmt.Type = 'Capture';
        pmt.PaymentMethodId=paymentMethod.Id;
        pmt.PaymentAuthorizationId = auth.Id;
        pmt.AccountId = acc.Id;
        pmt.paymentGroupId = pg.Id;
        insert pmt;
        return testOrder;
    }
    
    
    //This method will create fulfillment
    
    public static String createFulfillmentOrder (String orderSummaryId, String fulfillmentType) {
        list<FulfillmentOrder> folist = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummaryId];
        Flow.Interview.Create_Fulfillment_Orders foFlow = 
            new Flow.Interview.Create_Fulfillment_Orders(new Map<String, Object> { 'OrderSummaryId' => orderSummaryId } );
        foFlow.start();
        FulfillmentOrder fo = [SELECT Id, OrderSummaryId FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummaryId];
        system.debug('FulfillmentOrder :'+fo);
        return fo.Id;
     }
  
    // This method will give order details
   	public static Order getOrder(Id orderId) {
        return [
            SELECT Id, Status, TotalAmount, OrderNumber, RelatedOrderId,
            (SELECT Id, Type, LineNumber, Quantity, UnitPrice, GrossUnitPrice, TotalLineAmount, Product2.ProductCode FROM OrderItems)
            FROM Order WHERE Id = :orderId LIMIT 1];
    }
	 // This method will cretae change_order ,submit the order products to return , change the order product summary status to returned and create the credit memeo. 
     public static Order createOrderChange(String osId, FulfillmentOrder fulfillmentOrder, String process) {
        Id orderId = null;
        OrderSummary osRecord = [ SELECT Id, (SELECT Id, OrderSummaryId, Type, Quantity FROM OrderItemSummaries) FROM OrderSummary where Id =: osId limit 1 ];
       	List<ConnectApi.ChangeItemInputRepresentation> changeItems = new List<ConnectApi.ChangeItemInputRepresentation>();
        for (OrderItemSummary oi : osRecord.OrderItemSummaries ) {
            if (oi.Type != 'Order Product') { continue; }
            ConnectApi.ChangeItemInputRepresentation changeItem = new ConnectApi.ChangeItemInputRepresentation();
            changeItem.orderItemSummaryId = oi.Id;
            changeItem.quantity = oi.Quantity;
            changeItem.reason = 'Other';
            changeItem.shippingReductionFlag = false;
            changeItems.add(changeItem);
        }
        
        // submit order products for return
        ConnectApi.ChangeInputRepresentation changeInput = new ConnectApi.ChangeInputRepresentation();
        changeInput.changeItems = changeItems;
        if (process == 'Return') {
            if (fulfillmentOrder.InvoiceId == null) { throw new HandledException('InvoiceId required, please invoiceFulfillmentOrder first.'); }
            ConnectApi.SubmitReturnOutputRepresentation changeOutput = ConnectApi.OrderSummary.submitReturn(osRecord.Id, changeInput);
            orderId = changeOutput.changeOrderId ;
        }
        else if (process == 'Cancel') {
            ConnectApi.SubmitCancelOutputRepresentation changeOutput = ConnectApi.OrderSummary.submitCancel(osRecord.Id, changeInput);
            orderId = changeOutput.changeOrderId;
        }
        // results
        return getOrder(orderId);
    }
    
    //This method will create shipment, update Order summary and fulfillment status to fulfilled and creating invoice.
    public static FulfillmentOrder invoiceFulfillmentOrder(FulfillmentOrder fulfillmentOrder) {
        Id deliveryMethod = [SELECT Id, Name, CreatedDate FROM OrderDeliveryMethod where Name ='USPS Ground'][0].Id;
        DateTime todayDate = System.now();
        insert new Shipment(
            DeliveryMethodId = deliveryMethod,
            TrackingNumber = '123',
            TrackingUrl = 'https://mocktracking.com?trackingId=123',
            FulfillmentOrderId = fulfillmentOrder.Id,
            OrderSummaryId = fulfillmentOrder.OrderSummaryId,
            AmwareShipDate__c = todayDate,
            ShipToName = 'Account.Name'
        );
        update new FulfillmentOrder(Id = fulfillmentOrder.Id, Status = 'Fulfilled');
        update new OrderSummary(Id = fulfillmentOrder.OrderSummaryId, Status = 'Fulfilled');
		//I am commenting this because in flow we are doing some callouts (emails)
       /* Flow.Interview.createInterview(OmsSystemX.options.createInvoiceAndEnsureFundsFlow(), new Map<String, Object> {
           'FulfillmentOrderId' => fulfillmentOrder.Id
         }).start(); */
        //ConnectApi.FulfillmentOrderInvoiceInputRepresentation input = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
		//ConnectAPI.FulfillmentOrderInvoiceOutputRepresentation result = ConnectApi.FulfillmentOrder.createInvoice(fulfillmentOrder.Id, input);
		//fulfillmentOrder.InvoiceId = [SELECT InvoiceId FROM FulfillmentOrder WHERE Id = :fulfillmentOrder.Id LIMIT 1].InvoiceId;
        return fulfillmentOrder;
    }
    
    //This method is for creating return order and return order lineitem
    public static String createRMAReturnOrder(String orderSummaryId) {
        List<OrderItemSummary> orderItemSummaryList = [Select Id, Quantity, Status,Type FROM OrderItemSummary WHERE OrderSummaryId = :orderSummaryId];
            ConnectApi.ReturnOrderInputRepresentation returnOrder =  new ConnectApi.ReturnOrderInputRepresentation();
            List<ConnectApi.ReturnOrderLineItemInputRepresentation> returnOrderItemList = new List<ConnectApi.ReturnOrderLineItemInputRepresentation>();
            for(OrderItemSummary ois : orderItemSummaryList){
                if(ois.Type == 'Order Product') {
                    ConnectApi.ReturnOrderLineItemInputRepresentation returnOrderItem = new ConnectApi.ReturnOrderLineItemInputRepresentation();
                    returnOrderItem.orderItemSummaryId = ois.Id;
                    returnOrderItem.reasonForReturn = 'Wrong Item';
                    returnOrderItem.canReduceShipping = false;
                    returnOrderItem.quantityExpected = ois.Quantity;
                    returnOrderItemList.add(returnOrderItem);
                }
            }
            returnOrder.returnOrderLineItems = returnOrderItemList;
            returnOrder.orderSummaryId = orderSummaryId;
            returnOrder.returnOrderLifeCycleType = 'MANAGED';
            returnOrder.status = 'Submitted';
            ConnectApi.ReturnOrderOutputRepresentation returnOrderOutput = ConnectApi.ReturnOrder.createReturnOrder(returnOrder);
        	return returnOrderOutput.returnOrderId;
    }  
    
    // This method is for creating creditmemo and CreditMemoLine
    public static CreditMemo createCreditMemo(Id summaryId, Id changeOrderId) {
        ConnectApi.CreateCreditMemoInputRepresentation creditMemoInput = new ConnectApi.CreateCreditMemoInputRepresentation();
        creditMemoInput.changeOrderIds = new List<String> { changeOrderId };
        ConnectApi.CreateCreditMemoOutputRepresentation creditMemoOutput = ConnectApi.OrderSummary.createCreditMemo(summaryId, creditMemoInput);

        // results
        CreditMemo creditMemo = new CreditMemo(Id = creditMemoOutput.creditMemoId); 
        creditMemo.ReferenceEntityId = summaryId;
        return creditMemo;
    }
    
    //This method is for creating Refund 
    public static String createRefund(String osId, CreditMemo creditMemoRecord) {
        ConnectApi.EnsureRefundsAsyncInputRepresentation refundInput = new ConnectApi.EnsureRefundsAsyncInputRepresentation();
        refundInput.creditMemoId = creditMemoRecord.Id;
       	ConnectApi.EnsureRefundsAsyncOutputRepresentation refundOutPut = ConnectApi.OrderSummary.ensureRefundsAsync(osId,refundInput);
        return refundOutPut.toString();
    }
    
    public static String createOrderSummaryUS() {
        SalesChannel sChannl = new SalesChannel();
        sChannl.Description = 'viviscal';
        sChannl.SalesChannelName = 'viviscal';
        insert sChannl;
        salesChannelId = sChannl.Id ;
    return createOrderSummary();
    }
    
    public static String createOrderSummaryCA() {
       	SalesChannel sChannlca = new SalesChannel();
        sChannlca.Description = 'viviscal-ca';
        sChannlca.SalesChannelName = 'viviscal-ca';
        insert sChannlca;
        salesChannelId = sChannlca.Id ;
        return createOrderSummary();
    }
    
    public static String RetunRMAReturnOrder(Id roId) {
        ConnectApi.ReturnItemsInputRepresentation roInput = new ConnectApi.ReturnItemsInputRepresentation();
        List<ConnectApi.ReturnOrderItemInputRepresentation> roLineInputList = new List<ConnectApi.ReturnOrderItemInputRepresentation>();
        List<ConnectApi.ReturnOrderItemDeliveryChargeInputRepresentation> roDeliveryLineInputList = new List<ConnectApi.ReturnOrderItemDeliveryChargeInputRepresentation>();
        List<ReturnOrderLineItem> roLineListToUpdate = new List<ReturnOrderLineItem>();
        ReturnOrder ro = [SELECT Id , OrderSummaryId, Status, 
                          (SELECT Id, QuantityReceived, QuantityExpected, QuantityRejected, 
                           QuantityReturned, ReasonForRejection, Type FROM ReturnOrderLineItems) 
                          FROM ReturnOrder WHERE Id = :roId];
        for(ReturnOrderLineItem roLine : ro.ReturnOrderLineItems) {
            roLine.QuantityReceived = roLine.QuantityExpected;
            roLineListToUpdate.add(roLine);
            if(roLine.Type == 'Order Product') {
                ConnectApi.ReturnOrderItemInputRepresentation roLineInput = new ConnectApi.ReturnOrderItemInputRepresentation();
                roLineInput.quantityReceived = roLine.QuantityExpected;
                roLineInput.quantityRejected = roLine.QuantityRejected;
                roLineInput.quantityReturned = roLine.QuantityExpected;
                roLineInput.quantityToCancel = roLine.QuantityRejected;
                roLineInput.reasonForRejection =  roLine.ReasonForRejection;
                roLineInput.returnOrderLineItemId = roLine.Id;
                roLineInputList.add(roLineInput);
            } else if(roLine.Type == 'Delivery Charge') {
                ConnectApi.ReturnOrderItemDeliveryChargeInputRepresentation roDeliveryLineInput = new ConnectApi.ReturnOrderItemDeliveryChargeInputRepresentation();
                roDeliveryLineInput.returnOrderLineItemId = roLine.Id;
                roDeliveryLineInputList.add(roDeliveryLineInput);
            }
        }
        if(!roLineListToUpdate.isEmpty()) {
            update roLineListToUpdate;
        }
        ro.Status = 'Refund_Initiated';
        update ro;
        roInput.returnOrderItemDeliveryCharges = roDeliveryLineInputList;
        roInput.returnOrderItems = roLineInputList;
        ConnectApi.ReturnItemsOutputRepresentation roOutput = ConnectApi.ReturnOrder.returnItems(ro.Id, roInput);
        return roOutput.changeOrderId;
    }

    public static String createOsWithNoSapMaterialSku() {
        isNoSapMaterialSku = true;
        return createOrderSummaryUS();
    }

    public static Account createAccount() {
        Account acc = new Account(Name = 'Test Account', Business_Unit__c = 'US');
    	insert acc;
        return acc;
    }
}