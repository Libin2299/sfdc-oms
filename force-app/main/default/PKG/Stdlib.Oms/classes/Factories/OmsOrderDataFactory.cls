global virtual class OmsOrderDataFactory implements IOmsOrderDataFactory {
    /**
    * @description get instance
    * @return IOmsOrderDataFactory
    **/
    global static IOmsOrderDataFactory get = (IOmsOrderDataFactory)SystemX.getFactory(OmsOrderDataFactory.class);

    global String ORDERNUMER = OmsSystemX.options.factoryTestOrder();
    global String SALESCHANNEL = OmsSystemX.options.factorySalesChannel();
    global String DELIVERYMETHOD = OmsSystemX.options.factoryDeliveryMethod();
    global String PAYMENTGATEWAY = OmsSystemX.options.factoryPaymentGateway();

    /**
    * @description preamble - call before tests
    **/
    global virtual void preamble() {
        List<OrderDeliveryMethod> deliveryMethods = [SELECT Id FROM OrderDeliveryMethod WHERE ReferenceNumber = :DELIVERYMETHOD LIMIT 1];
        if (deliveryMethods.isEmpty()) { insert new OrderDeliveryMethod(Name = DELIVERYMETHOD, ReferenceNumber = DELIVERYMETHOD, IsActive = true); }
        List<Schema.Location> locations = [SELECT Id FROM Location WHERE LocationType = 'Warehouse'];
        if (locations.isEmpty()) { insert new Schema.Location(Name = 'Test Location', LocationType = 'Warehouse'); }
    }

    /**
    * @description creates a sales channel
    * @param name the name
    * @return SalesChannel
    **/
    global virtual SalesChannel createSalesChannel(String name) {
        SalesChannel salesChannel;
        List<SalesChannel> salesChannels = [SELECT Id, SalesChannelName FROM SalesChannel WHERE SalesChannelName = :name];
        if (salesChannels.isEmpty()) {
            salesChannel = new SalesChannel(Description = name, ExternalChannelNumber = name, SalesChannelName = name);
            insert salesChannel;
        } else { salesChannel = salesChannels[0]; }
        return salesChannel;
    }

    /**
    * @description creates an order
    * @param orderType the orderType
    * @param account the account
    * @param orderNumber the orderNumber
    * @return Order
    **/
    global virtual Order createOrder(String orderType, Account account, String orderNumber) {
        String prefix = Test.isRunningTest() ? 'Test-' : '';
        if (account == null) { account = AccountDataFactory.get.createAccount('John Doe'); }
        String[] orderNumberArgs = orderNumber.split(':');
        String[] orderTypeArgs = orderType.split(':');
        String orderTypeModifier = orderTypeArgs.size() > 1 && orderTypeArgs[1] != '' ? orderTypeArgs[1] : '';
        String paymentGatewayRef = orderNumberArgs.size() > 1 && orderNumberArgs[1] != '' ? orderNumberArgs[1] : PAYMENTGATEWAY;
        List<PaymentGateway> paymentGateways = [SELECT Id FROM PaymentGateway WHERE ExternalReference = :paymentGatewayRef LIMIT 1];
        PaymentGateway paymentGateway = paymentGateways.isEmpty() ? new PaymentGateway() : paymentGateways[0];
        SalesChannel salesChannel = createSalesChannel(SALESCHANNEL);

        // get pricebook
        List<Pricebook2> pricebooks = [SELECT Id, Name FROM Pricebook2 WHERE IsActive = true And IsStandard = true LIMIT 1];
        Id pricebook2Id = pricebooks.isEmpty() ? Test.getStandardPricebookId(): pricebooks[0].Id;

        // make order
        Datetime orderedDate
        = orderTypeModifier == 'Month' ? Datetime.now().addMonths(-1)
        : orderTypeModifier == 'Future' ? Datetime.now().addMonths(1)
        : Datetime.now();
        Order order = new Order (
            Pricebook2Id = pricebook2Id,
            Name = 'John Doe',
            Status = 'Draft',
            EffectiveDate = orderedDate.date(),
            OrderReferenceNumber = orderNumberArgs[0],
            Description = 'Test',
            BillingStreet = '1166 W Newport Center Dr',
            BillingCity = 'Deerfield Beach',
            BillingPostalCode = '33442',
            BillingCountry = 'United States',
            BillingPhoneNumber = '3333333333',
            OrderedDate = orderedDate,
            BillingEmailAddress = 'john@doe.com',
            AccountId = account.Id,
            SalesChannelId = salesChannel.Id
        );
        if (UserInfoX.isStateAndCountryPicklistOrganization()) {
            order.put('BillingStateCode', 'FL');
        } else {
            order.put('BillingState', 'FL');
        }
        order.put('BillingCountryCode', 'US');
        insert order;

        PaymentGroup paymentGroup = new PaymentGroup(SourceObjectId = order.Id);
        insert paymentGroup;

        List<String> productSkus = new List<String> { prefix + 'T1', prefix + 'T2', prefix + 'S1' };
        List<Product2> products = [SELECT Id, Name, StockKeepingUnit FROM Product2 WHERE StockKeepingUnit In :productSkus];
        if (products.isEmpty()) {
            products = new List<Product2>();
            products.Add(new Product2(
                Description = 'WOMEN\'S TORPEDO JACKET',
                Name = 'WOMEN\'S TORPEDO JACKET',
                StockKeepingUnit = productSkus[0],
                ProductCode = 'T1',
                IsActive = true
            ));
            products.Add(new Product2(
                Description = 'MICA FL 1',
                Name = 'MICA FL 1',
                StockKeepingUnit = productSkus[1],
                ProductCode = 'T2',
                IsActive = true
            ));
            products.Add(new Product2(
                Description = 'Shipping',
                Name = 'Shipping',
                StockKeepingUnit = productSkus[2],
                ProductCode = 'S1',
                IsActive = true
            ));
            insert products;
        }

        List<PricebookEntry> pricebookEntrys = [SELECT Id FROM PricebookEntry WHERE Product2Id In (:products[0].Id, :products[1].Id, :products[2].Id)];
        if (pricebookEntrys.isEmpty()) {
            pricebookEntrys = new List<PricebookEntry>();
            pricebookEntrys.add(new PricebookEntry(Pricebook2Id = pricebook2Id, UnitPrice = 79.2, Product2Id = products[0].Id));
            pricebookEntrys.add(new PricebookEntry(Pricebook2Id = pricebook2Id, UnitPrice = 255.2, Product2Id = products[1].Id));
            pricebookEntrys.add(new PricebookEntry(Pricebook2Id = pricebook2Id, UnitPrice = 9.99, Product2Id = products[2].Id));
            insert pricebookEntrys;
        }

        CardPaymentMethod cardPaymentMethod = new CardPaymentMethod(
            CardType = 'Visa',
            CardHolderName = 'John Doe',
            ExpiryYear = 2020,
            ExpiryMonth = 1,
            CardCategory = 'CreditCard',
            Status = 'Active',
            AccountId = account.Id,
            ProcessingMode = 'External',
            PaymentGatewayId = paymentGateway.Id,
            GatewayToken = 'Token'
        );
        insert cardPaymentMethod;

        OrderDeliveryMethod orderDeliveryMethod;
        List<OrderDeliveryMethod> orderDeliveryMethods = [SELECT Id FROM OrderDeliveryMethod WHERE Name = 'Test'];
        if (orderDeliveryMethods.isEmpty()) {
            orderDeliveryMethod = new OrderDeliveryMethod(
                Description = 'Test order delivery method',
                IsActive = true,
                Name = 'Test',
                ProductId = products[0].Id,
                ReferenceNumber = '1'
            );
            insert orderDeliveryMethod;
        } else { orderDeliveryMethod = orderDeliveryMethods[0]; }

        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
            EmailAddress = 'john@doe.com',
            DeliverToCity = 'Deerfield Beach',
            DeliverToCountry = 'United States',
            DeliverToName = 'John Doe',
            DeliverToPostalCode = '33442',
            DeliverToStreet = '1166 W Newport Center Dr',
            PhoneNumber = '3333333333',
            OrderDeliveryMethodId = orderDeliveryMethod.Id,
            OrderId = order.Id
        );
        if (UserInfoX.isStateAndCountryPicklistOrganization()) {
            orderDeliveryGroup.put('DeliverToStateCode', 'FL');
        } else {
            orderDeliveryGroup.put('DeliverToState', 'FL');
        }
        orderDeliveryGroup.put('DeliverToCountryCode', 'US');
        insert orderDeliveryGroup;

        OrderAdjustmentGroup orderAdjustmentGroup = new OrderAdjustmentGroup(
            Name = 'PromotionTest_20%offOrderAmountOver100',
            Description = 'PromotionTest_20%offOrderAmountOver100',
            Type = 'Header',
            OrderId = order.Id
        );
        insert orderAdjustmentGroup;

        PaymentAuthorization paymentAuthorization = new PaymentAuthorization(
            Amount = 291.39,
            ProcessingMode = 'External',
            Status = 'Processed',
            PaymentGroupId = paymentGroup.Id,
            AccountId = account.Id,
            PaymentMethodId = cardPaymentMethod.Id,
            PaymentGatewayId = paymentGateway.Id
        );
        insert paymentAuthorization;

        List<OrderItem> orderItems = new List<OrderItem>();
        orderItems.add(new OrderItem(
            Description = 'WOMEN\'S TORPEDO JACKET',
            Type = 'Order Product',
            Quantity = 1,
            TotalLineAmount = 79.2,
            LineNumber = 1,
            UnitPrice = 79.2,
            OrderId = order.Id,
            OrderDeliveryGroupId = orderDeliveryGroup.Id,
            PricebookEntryId = pricebookEntrys[0].Id,
            Product2Id = products[0].Id
        ));
        orderItems.add(new OrderItem(
            Description = 'MICA FL 1',
            Type = 'Order Product',
            Quantity = 1,
            TotalLineAmount = 255.2,
            LineNumber = 2,
            UnitPrice = 255.2,
            OrderId = order.Id,
            OrderDeliveryGroupId = orderDeliveryGroup.Id,
            PricebookEntryId = pricebookEntrys[1].Id,
            Product2Id = products[1].Id
        ));
        orderItems.add(new OrderItem(
            Description = 'Shipping',
            Type = 'Delivery Charge',
            Quantity = 1,
            TotalLineAmount = 9.99,
            LineNumber = 1000,
            UnitPrice = 9.99,
            OrderId = order.Id,
            OrderDeliveryGroupId = orderDeliveryGroup.Id,
            PricebookEntryId = pricebookEntrys[2].Id,
            Product2Id = products[2].Id
        ));
        insert orderItems;

        PaymentGatewayLog paymentGatewayLog = new PaymentGatewayLog(
            InteractionStatus = 'Success',
            InteractionType = 'Authorization',
            ReferencedEntityId = paymentAuthorization.Id
        );
        insert paymentGatewayLog;

        List<SObject> group3 = new List<SObject>();
        group3.add(new OrderItemTaxLineItem(
            Name = '2072100 - Tax',
            Type = 'Estimated',
            Amount = 3.96,
            Rate = 0.05,
            TaxEffectiveDate = Date.valueOf('2018-09-18 17:15:58'),
            OrderItemId = orderItems[0].Id
        ));
        group3.add(new OrderItemTaxLineItem(
            Name = '4409100 - Tax',
            Type = 'Estimated',
            Amount = 12.76,
            Rate = 0.05,
            TaxEffectiveDate = Date.valueOf('2018-09-18 17:15:58'),
            OrderItemId = orderItems[1].Id
        ));
        group3.add(new OrderItemTaxLineItem(
            Name = 'DeliveryCharge - Tax',
            Type = 'Estimated',
            Amount = 0.5,
            Rate = 0.05,
            TaxEffectiveDate = Date.valueOf('2018-09-18 17:15:58'),
            OrderItemId = orderItems[2].Id
        ));
        group3.add(new OrderItemAdjustmentLineItem(
            Name = '2072100 - 20%offOrderAmountOver100',
            Amount = -15.84,
            OrderItemId = orderItems[0].Id,
            OrderAdjustmentGroupId = orderAdjustmentGroup.Id
        ));
        group3.add(new OrderItemAdjustmentLineItem(
            Name = '4409100 - 20%offOrderAmountOver100',
            Amount = -51.04,
            OrderItemId = orderItems[1].Id,
            OrderAdjustmentGroupId = orderAdjustmentGroup.Id
        ));
        insert group3;

        List<SObject> group4 = new List<SObject>();
        group4.add(new OrderItemTaxLineItem(
            Name = '2072100 - Adjustment Tax',
            Type = 'Estimated',
            Amount = -0.79,
            Rate = 0.05,
            TaxEffectiveDate = Date.valueOf('2018-09-18 17:15:58'),
            OrderItemId = orderItems[0].Id,
            OrderItemAdjustmentLineItemId = group3[3].Id
        ));
        group4.add(new OrderItemTaxLineItem(
            Name = '4409100 - Adjustment Tax',
            Type = 'Estimated',
            Amount = -2.55,
            Rate = 0.05,
            TaxEffectiveDate = Date.valueOf('2018-09-18 17:15:58'),
            OrderItemId = orderItems[1].Id,
            OrderItemAdjustmentLineItemId = group3[4].Id
        ));
        insert group4;

        order.Status = 'Activated';
        update order;
        
        return order;
    }
    /**
    * @description gets an order
    * @param orderId the orderId
    * @return Order
    **/
    global virtual Order getOrder(Id orderId) {
        return [
            SELECT Id, Status, TotalAmount, OrderNumber, RelatedOrderId,
            (SELECT Id, Type, LineNumber, Quantity, UnitPrice, GrossUnitPrice, TotalLineAmount, Product2.ProductCode FROM OrderItems)
            FROM Order WHERE Id = :orderId LIMIT 1];
    }

    /**
    * @description creates an order summary
    * @param orderType the orderType
    * @return OrderSummary
    **/
    global OrderSummary createOrderSummary(String orderType) {
        return createOrderSummary(orderType, null, ORDERNUMER);
        //return OmsTestDataFactory.getTestOrderSummaryRecord();
    }

    /**
    * @description creates an order summary
    * @param orderType the orderType
    * @param account the account
    * @param orderNum the orderNum
    * @return OrderSummary
    **/
    global virtual OrderSummary createOrderSummary(String orderType, Account account, String orderNum) {
        Order order = createOrder(orderType, account, orderNum);
        return getOrderSummaryByOrder(order.Id);
    }

    /**
    * @description gets an order summary
    * @param orderSummaryId the orderSummaryId
    * @return OrderSummary
    **/
    global virtual OrderSummary getOrderSummary(Id orderSummaryId) {
        return [
            SELECT Id, Status, OrderNumber, SalesChannel.SalesChannelName, AccountId, OriginalOrderId, OrderedDate,
            (SELECT Id, Type, Quantity, QuantityAvailableToReturn, Product2Id FROM OrderItemSummaries)
            FROM OrderSummary WHERE Id = :orderSummaryId LIMIT 1];
    }

    /**
    * @description gets an order summary by order
    * @param orderId the orderId
    * @return OrderSummary
    **/
    global virtual OrderSummary getOrderSummaryByOrder(Id orderId) {
        return [
            SELECT Id, Status, OrderNumber, SalesChannel.SalesChannelName, AccountId, OriginalOrderId, OrderedDate,
            (SELECT Id, Type, Quantity, QuantityAvailableToReturn, Product2Id FROM OrderItemSummaries)
            FROM OrderSummary WHERE OriginalOrderId = :orderId LIMIT 1];
    }

    /**
    * @description creates an order adjustment
    * @param summary the summary
    * @param fulfillmentOrder the fulfillmentOrder
    * @return Order
    **/
    global virtual Order createOrderAdjust(OrderSummary summary, FulfillmentOrder fulfillmentOrder) {
        if (fulfillmentOrder.InvoiceId == null) { throw new HandledException('InvoiceId required, please invoiceFulfillmentOrder first.'); }

        List<ConnectApi.AdjustItemInputRepresentation> adjustItems = new List<ConnectApi.AdjustItemInputRepresentation>();
        for (OrderItemSummary oi : summary.orderItemSummaries) {
            if (oi.Type != 'Order Product') { continue; }
        	ConnectApi.AdjustItemInputRepresentation adjustItem = new ConnectApi.AdjustItemInputRepresentation();
            adjustItem.orderItemSummaryId = oi.Id;
		    adjustItem.adjustmentType = 'Percentage';
            adjustItem.amount = -.5;
            adjustItem.reason = 'Other';
            adjustItems.add(adjustItem);
        }

        // submit adjust
        ConnectApi.AdjustOrderItemSummaryInputRepresentation adjustInput = new ConnectApi.AdjustOrderItemSummaryInputRepresentation();
        adjustInput.adjustItems = adjustItems;
        ConnectApi.AdjustOrderSummaryOutputRepresentation adjustOutput = ConnectApi.OrderSummary.adjustSubmit(summary.Id, adjustInput);
        Id orderId = adjustOutput.postFulfillmentChangeOrderId;
        // new OMS_ChangeOrderBatchJob().execute(null, new Order[] { new Order(Id = orderId) });

        // results
        return getOrder(orderId);
    }

    /**
    * @description creates an order change
    * @param summary the summary
    * @param fulfillmentOrder the fulfillmentOrder
    * @return Order
    **/
    global virtual Order createOrderChange(OrderSummary summary, FulfillmentOrder fulfillmentOrder) {
        if (fulfillmentOrder.InvoiceId == null) { throw new HandledException('InvoiceId required, please invoiceFulfillmentOrder first.'); }

        List<ConnectApi.ChangeItemInputRepresentation> changeItems = new List<ConnectApi.ChangeItemInputRepresentation>();
        for (OrderItemSummary oi : summary.orderItemSummaries) {
            if (oi.Type != 'Order Product') { continue; }
            ConnectApi.ChangeItemInputRepresentation changeItem = new ConnectApi.ChangeItemInputRepresentation();
            changeItem.orderItemSummaryId = oi.Id;
            changeItem.quantity = oi.Quantity;
            changeItem.reason = 'Other';
            changeItem.shippingReductionFlag = false;
            changeItems.add(changeItem);
        }

        // submit return
        ConnectApi.ChangeInputRepresentation changeInput = new ConnectApi.ChangeInputRepresentation();
        changeInput.changeItems = changeItems;
        ConnectApi.SubmitReturnOutputRepresentation changeOutput = ConnectApi.OrderSummary.submitReturn(summary.Id, changeInput);
        Id orderId = changeOutput.changeOrderId;
        // new OMS_ChangeOrderBatchJob().execute(null, new Order[] { new Order(Id = orderId) });

        // results
        return getOrder(orderId);
    }

    /**
    * @description creates a credit memo
    * @param orderSummaryId the orderSummaryId
    * @param changeOrderId the changeOrderId
    * @return CreditMemo
    **/
    global virtual CreditMemo createCreditMemo(Id orderSummaryId, Id changeOrderId) {
        // create credit memo
        ConnectApi.CreateCreditMemoInputRepresentation creditMemoInput = new ConnectApi.CreateCreditMemoInputRepresentation();
        creditMemoInput.changeOrderIds = new List<String> { changeOrderId };
        ConnectApi.CreateCreditMemoOutputRepresentation creditMemoOutput = ConnectApi.OrderSummary.createCreditMemo(orderSummaryId, creditMemoInput);

        // results
        CreditMemo creditMemo = new CreditMemo(Id = creditMemoOutput.creditMemoId, ChangeOrder__c = changeOrderId);
        creditMemo.ReferenceEntityId = orderSummaryId;
        return creditMemo;
    }
    
    /**
    * @description creates a fulfillment order
    * @param orderType the orderType
    * @param orderSummaryId the orderSummaryId
    * @param account the account
    * @return List<FulfillmentOrder>
    **/
    global virtual List<FulfillmentOrder> createFulfillmentOrders(String orderType, Id orderSummaryId, Account account) {
        if (String.isBlank((String)orderSummaryId)) { 
            OrderSummary orderSummary = createOrderSummary(orderType, account, ORDERNUMER); 
            orderSummaryId = orderSummary.Id;
        }

        // create fulfillment order
        Flow.Interview.createInterview(OmsSystemX.options.createFulfillmentOrdersFlow(), new Map<String, Object> {
            'OrderSummaryId' => orderSummaryId
        }).start();

        // return
        return getFulfillmentOrders(orderSummaryId);
    }
    
    /**
    * @description gets the fulfillment orders
    * @param orderSummaryId the orderSummaryId
    * @return List<FulfillmentOrder>
    **/
    global virtual List<FulfillmentOrder> getFulfillmentOrders(Id orderSummaryId) {
        return [
            SELECT Id, InvoiceId, OrderSummaryId, OrderSummary.OrderNumber, OrderSummary.SalesChannel.SalesChannelName, FulfilledToName, FulfilledToStreet, FulfilledToCity, FulfilledToState, FulfilledToCountry, FulfilledToPostalCode, AccountId, FulfilledToPhone, DeliveryMethodId, FulfilledToEmailAddress, Status, FulfilledFromLocationId, TotalAmount,
            (SELECT Id, FulfillmentOrderLineItemNumber, Quantity, QuantityUnitOfMeasure, UnitPrice, GrossUnitPrice, TotalLineAmount, OrderItemId, FulfillmentOrderId, OriginalQuantity, Type, TypeCode, OrderItemSummaryId, Product2.ProductCode FROM FulfillmentOrderLineItems)
            FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummaryId];
    }

    /**
    * @description creates a payment
    * @param amount the amount
    * @param invoiceId the invoiceId
    * @param orderSummaryId the orderSummaryId
    * @return PaymentLineInvoice
    **/
    global virtual PaymentLineInvoice createPayment(Decimal amount, Id invoiceId, Id orderSummaryId) {
        if (invoiceId == null) { throw new HandledException('InvoiceId missing'); }
		Payment payment = new Payment(Amount = amount, Status = 'Processed', Type = 'Capture', ProcessingMode = 'External', Comments = orderSummaryId);
		insert payment;
        PaymentLineInvoice paymentLineInvoice = new PaymentLineInvoice(Date = Datetime.now(), EffectiveDate = Datetime.now(), InvoiceId = invoiceId, PaymentId = payment.Id, Amount = payment.Amount / 2, Type = 'Applied', HasBeenUnapplied = 'No');
		insert paymentLineInvoice;
        return paymentLineInvoice;
	}

    /**
    * @description creates a refund
    * @param amount the amount
    * @param paymentLineInvoice the paymentLineInvoice
    * @return RefundLinePayment
    **/
	global virtual RefundLinePayment createRefund(Decimal amount, PaymentLineInvoice paymentLineInvoice) {
		Refund refund = new Refund(Amount = amount / 2, Status = 'Processed', Type = 'Referenced', ProcessingMode = 'External');
		insert refund;
        RefundLinePayment refundLinePayment = new RefundLinePayment(RefundId = refund.Id, PaymentId = paymentLineInvoice.PaymentId, Amount = refund.Amount, Type = 'Applied', HasBeenUnapplied = 'No');
		insert refundLinePayment;
        return refundLinePayment;
	}

    /**
    * @description invoices a fulfillment order
    * @param fulfillmentOrder the fulfillmentOrder
    * @param createInvoiceMode the createInvoiceMode
    * @return FulfillmentOrder
    **/
    global virtual FulfillmentOrder invoiceFulfillmentOrder(FulfillmentOrder fulfillmentOrder, Integer createInvoiceMode) {
        OrderDeliveryMethod deliveryMethod = [SELECT Id FROM OrderDeliveryMethod WHERE ReferenceNumber = :DELIVERYMETHOD LIMIT 1];
        insert new Shipment(
            DeliveryMethodId = deliveryMethod.Id,
            TrackingNumber = '123',
            TrackingUrl = 'https://mocktracking.com?trackingId=123',
            FulfillmentOrderId = fulfillmentOrder.Id,
            OrderSummaryId = fulfillmentOrder.OrderSummaryId,
            ShipToName = 'Account.Name'
        );
        update new FulfillmentOrder(Id = fulfillmentOrder.Id, Status = 'Fulfilled');
        update new OrderSummary(Id = fulfillmentOrder.OrderSummaryId, Status = 'Fulfilled');

        createInvoiceAndEnsureFunds(fulfillmentOrder.Id, createInvoiceMode);

        fulfillmentOrder.InvoiceId = [SELECT InvoiceId FROM FulfillmentOrder WHERE Id = :fulfillmentOrder.Id LIMIT 1].InvoiceId;
        return fulfillmentOrder;
    }

    /**
    * @description creates an invoice and ensures funds
    * @param fulfillmentOrderId the fulfillmentOrderId
    * @param createInvoiceMode the createInvoiceMode
    **/
    global virtual void createInvoiceAndEnsureFunds(Id fulfillmentOrderId, Integer createInvoiceMode) {
        if (createInvoiceMode == -1) {
            Flow.Interview.createInterview(OmsSystemX.options.createInvoiceAndEnsureFundsFlow(), new Map<String, Object> {
                'FulfillmentOrderId' => fulfillmentOrder.Id
            }).start();
            return;
        }

        //ConnectApi.FulfillmentOrderInvoiceInputRepresentation input = new ConnectApi.FulfillmentOrderInvoiceInputRepresentation();
        //ConnectApi.FulfillmentOrderInvoiceOutputRepresentation result = ConnectApi.FulfillmentOrder.createInvoice(fulfillmentOrderId, input);
    }
}