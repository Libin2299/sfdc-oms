@isTest
class ConnectApiXTest {
    static OrderSummary setup(String body) {
        Test.setMock(HttpCalloutMock.class, new HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
            'callout:OmsLink/xxx/OmsLink' => new HttpCalloutServiceMock(200, body)
        }));
        OmsOrderDataFactory.get.preamble();
        return OmsOrderDataFactory.get.createOrderSummary('Standard');
    }

    @isTest static void shouldCreate() {
        ConnectApiX.AuthorizationResponse response = new ConnectApiX.AuthorizationResponse();
        response.error = new ConnectApiX.ErrorResponse();
        response.gatewayResponse = new ConnectApiX.AuthorizationGatewayResponse();
        response.paymentAuthorization = new ConnectApiX.PaymentAuthorizationResponse();
    }

    //#region EnsureCaptureAsync

    @isTest(SeeAllData=true) static void shouldEnsureCapturesAsyncInvokable() {
        OrderSummary orderSummary = setup('{}');
        FulfillmentOrder fulfillment = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', orderSummary.Id, null)[0];
        OmsOrderDataFactory.get.invoiceFulfillmentOrder(fulfillment, 0);

        Test.startTest();
        EnsureCapturesAsyncInputRepresentation ensureCapturesInput = new EnsureCapturesAsyncInputRepresentation();
        ensureCapturesInput.amount = 1.0;
        ensureCapturesInput.comments = null;
        ensureCapturesInput.onSuccess = 'sStatus=Approved';
        EnsureCapturesAsync.FlowInput input = new EnsureCapturesAsync.FlowInput();
        input.orderSummaryId = orderSummary.Id;
        input.ensureCapturesInput = ensureCapturesInput;
        EnsureCapturesAsync.FlowOutput output = EnsureCapturesAsync.invocable(new List<EnsureCapturesAsync.FlowInput> { input })[0];
        
        // apply invoice-payment
        ApplyInvoicePaymentsAsyncInputRepre applyInvoicePaymentsInput = new ApplyInvoicePaymentsAsyncInputRepre();
        applyInvoicePaymentsInput.invoiceId = fulfillment.invoiceId;
        ApplyInvoicePaymentsAsync.FlowInput input3 = new ApplyInvoicePaymentsAsync.FlowInput();
        input3.orderSummaryId = orderSummary.Id;
        input3.applyInvoicePaymentsInput = applyInvoicePaymentsInput;
        ApplyInvoicePaymentsAsync.FlowOutput output3 = ApplyInvoicePaymentsAsync.invocable(new List<ApplyInvoicePaymentsAsync.FlowInput> { input3 })[0];
        Test.stopTest();
        System.assert(output.backgroundOperationId != null, 'Should be value');
    }

    @isTest(SeeAllData=true) static void shouldEnsureCapturesAsync() {
        OrderSummary orderSummary = setup('{}');
        FulfillmentOrder fulfillment = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', orderSummary.Id, null)[0];
        OmsOrderDataFactory.get.invoiceFulfillmentOrder(fulfillment, 0);
        
        Test.startTest();
        EnsureCapturesAsyncInputRepresentation ensureCapturesInput = new EnsureCapturesAsyncInputRepresentation();
        ensureCapturesInput.amount = 1.0;
        ensureCapturesInput.comments = null;
        ensureCapturesInput.onSuccess = 'sStatus=Approved';
        EnsureCapturesAsyncOutputRepresentation ensureCapturesOutput = ConnectApiXOrderSummary.ensureCapturesAsync(orderSummary.Id, ensureCapturesInput);
        
        // apply invoice-payment
        ApplyInvoicePaymentsAsyncInputRepre applyInvoicePaymentsInput = new ApplyInvoicePaymentsAsyncInputRepre();
        applyInvoicePaymentsInput.invoiceId = fulfillment.invoiceId;
        ApplyInvoicePaymentsAsyncOutputRepre applyInvoicePaymentsOutput = ConnectApiXOrderSummary.applyInvoicePaymentsAsync(orderSummary.Id, applyInvoicePaymentsInput);
        Test.stopTest();
        System.assert(ensureCapturesOutput.backgroundOperationId != null, 'Should be value');
        System.assert(applyInvoicePaymentsOutput.backgroundOperationId != null, 'Should be value');
    }

    @isTest static void shouldEnsureCapturesAsyncThrow() {
        OrderSummary orderSummary = setup('{}');
        
        Test.startTest();
        EnsureCapturesAsyncInputRepresentation ensureCapturesInput = new EnsureCapturesAsyncInputRepresentation();
        ensureCapturesInput.amount = 1.0;
        ensureCapturesInput.comments = 'Throw';
        ensureCapturesInput.onSuccess = 'sStatus=Approved';
        EnsureCapturesAsyncOutputRepresentation ensureCapturesOutput = ConnectApiXOrderSummary.ensureCapturesAsync(orderSummary.Id, ensureCapturesInput);
        Test.stopTest();
        System.assert(ensureCapturesOutput.backgroundOperationId != null, 'Should be value');
    }

    //#endregion

    //#region EnsureReauthsAsync

    @isTest static void shouldEnsureReauthsAsyncInvokable() {
        OrderSummary orderSummary = setup('{"authorizationCode":"authorizationCode","transactionID":"transactionID","error":false}');
        PaymentAuthorization paymentAuth = [SELECT Id FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId = :orderSummary.Id LIMIT 1];

        Test.startTest();
        EnsureReauthsAsyncInputRepresentation ensureReauthsInput = new EnsureReauthsAsyncInputRepresentation();
        ensureReauthsInput.paymentAuthId = paymentAuth.Id;
        ensureReauthsInput.comments = 'comments';
        EnsureReauthsAsync.FlowInput input = new EnsureReauthsAsync.FlowInput();
        input.orderSummaryId = orderSummary.Id;
        input.ensureReauthsInput = ensureReauthsInput;
        EnsureReauthsAsync.FlowOutput output = EnsureReauthsAsync.invocable(new List<EnsureReauthsAsync.FlowInput> { input })[0];
        Test.stopTest();
        System.assert(output.backgroundOperationId != null, 'Should be value');
    }

	@isTest static void shouldEnsureReauthsAsync() {
        OrderSummary orderSummary = setup('{"authorizationCode":"authorizationCode","transactionID":"transactionID","error":false}');
        PaymentAuthorization paymentAuth = [SELECT Id FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId = :orderSummary.Id LIMIT 1];

        Test.startTest();
        EnsureReauthsAsyncInputRepresentation ensureReauthsInput = new EnsureReauthsAsyncInputRepresentation();
        ensureReauthsInput.paymentAuthId = paymentAuth.Id;
        ensureReauthsInput.comments = 'comments';
        EnsureReauthsAsyncOutputRepresentation ensureReauthsOutput = ConnectApiXOrderSummary.ensureReauthsAsync(orderSummary.Id, ensureReauthsInput);
        Test.stopTest();
        System.assert(ensureReauthsOutput.backgroundOperationId != null, 'Should be value');
	}

    @isTest static void shouldEnsureReauthsAsyncError() {
        OrderSummary orderSummary = setup('{"authorizationCode":"authorizationCode","transactionID":"transactionID","error":true}');
        PaymentAuthorization paymentAuth = [SELECT Id FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId = :orderSummary.Id LIMIT 1];

        Test.startTest();
        EnsureReauthsAsyncInputRepresentation ensureReauthsInput = new EnsureReauthsAsyncInputRepresentation();
        ensureReauthsInput.paymentAuthId = paymentAuth.Id;
        ensureReauthsInput.comments = 'error';
        EnsureReauthsAsyncOutputRepresentation ensureReauthsOutput = ConnectApiXOrderSummary.ensureReauthsAsync(orderSummary.Id, ensureReauthsInput);
        Test.stopTest();
        System.assert(ensureReauthsOutput.backgroundOperationId != null, 'Should be value');
	}

    @isTest static void shouldEnsureReauthsAsyncThrow() {
        OrderSummary orderSummary = setup('{"authorizationCode":"authorizationCode","transactionID":"transactionID","error":false}');
        PaymentAuthorization paymentAuth = [SELECT Id FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId = :orderSummary.Id LIMIT 1];

        Test.startTest();
        EnsureReauthsAsyncInputRepresentation ensureReauthsInput = new EnsureReauthsAsyncInputRepresentation();
        ensureReauthsInput.paymentAuthId = paymentAuth.Id;
        ensureReauthsInput.comments = 'Throw';
        EnsureReauthsAsyncOutputRepresentation ensureReauthsOutput = ConnectApiXOrderSummary.ensureReauthsAsync(orderSummary.Id, ensureReauthsInput);
        Test.stopTest();
        System.assert(ensureReauthsOutput.backgroundOperationId != null, 'Should be value');
	}

    //#endregion

    //#region EnsureReversalsAsync

    @isTest static void shouldEnsureReversalsAsyncInvokable() {
        OrderSummary orderSummary = setup(null);
        PaymentAuthorization paymentAuth = [SELECT Id FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId = :orderSummary.Id LIMIT 1];

        Test.startTest();
        EnsureReversalsAsyncInputRepresentation ensureReversalsInput = new EnsureReversalsAsyncInputRepresentation();
        ensureReversalsInput.comments = 'comments';
        EnsureReversalsAsync.FlowInput input = new EnsureReversalsAsync.FlowInput();
        input.orderSummaryId = orderSummary.Id;
        input.ensureReversalsInput = ensureReversalsInput;
        EnsureReversalsAsync.FlowOutput output = EnsureReversalsAsync.invocable(new List<EnsureReversalsAsync.FlowInput> { input })[0];
        Test.stopTest();
        System.assert(output.backgroundOperationId != null, 'Should be value');
    }

	@isTest static void shouldEnsureReversalsAsync() {
        OrderSummary orderSummary = setup(null);

        Test.startTest();
        EnsureReversalsAsyncInputRepresentation ensureReversalsInput = new EnsureReversalsAsyncInputRepresentation();
        ensureReversalsInput.comments = 'comments';
        EnsureReversalsAsyncOutputRepresentation ensureReversalsOuput = ConnectApiXOrderSummary.ensureReversalsAsync(orderSummary.Id, ensureReversalsInput);
        Test.stopTest();
        System.assert(ensureReversalsOuput.backgroundOperationId != null, 'Should be value');
	}

	@isTest static void shouldEnsureReversalsAsyncThrow() {
        OrderSummary orderSummary = setup(null);

        Test.startTest();
        EnsureReversalsAsyncInputRepresentation ensureReversalsInput = new EnsureReversalsAsyncInputRepresentation();
        ensureReversalsInput.comments = 'Throw';
        EnsureReversalsAsyncOutputRepresentation ensureReversalsOuput = ConnectApiXOrderSummary.ensureReversalsAsync(orderSummary.Id, ensureReversalsInput);
        Test.stopTest();
        System.assert(ensureReversalsOuput.backgroundOperationId != null, 'Should be value');
	}

    //#endregion
}