@isTest
class NopGatewayAdapterTest {
	@isTest static void createException() {
		Test.startTest();
		NopGatewayAdapterException e = new NopGatewayAdapterException();
		Test.stopTest();
		System.assert(e != null, 'Should not be empty');
	}
    
    @isTest static void testAuthorizationRequest() {
        PaymentAuthorization auth = initializeAuthObject();

        Test.startTest();
        // Create a PaymentMethod instance
        commercepayments.AuthApiPaymentMethodRequest paymentMethod = createAuthPaymentMethodRequest();
        paymentMethod.cardPaymentMethod.cardHolderLastName = 'Re-Authorization';
        paymentMethod.cardPaymentMethod.cardHolderName = auth.Id;

        // Create an auth request
        commercepayments.AuthorizationRequest request = new commercepayments.AuthorizationRequest((Double)199.99);
        request.paymentMethod = paymentMethod;
        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(request, commercepayments.RequestType.Authorize);
        NopGatewayAdapter adapter = new NopGatewayAdapter();
        commercepayments.GatewayResponse response = adapter.processRequest(p);
        System.assert(response != null, 'Response is not null');
        System.assert(response instanceOf commercepayments.AuthorizationResponse, 'Response is not a valid Authorization response');
        Test.stopTest();
    }
    
    @isTest static void testAuthReversalRequest() {
        PaymentAuthorization auth = initializeAuthObject();

        Test.startTest();
        // Create an auth reversal request
        commercepayments.AuthorizationReversalRequest request = new commercepayments.AuthorizationReversalRequest(150, auth.id);
        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(request, commercepayments.RequestType.AuthorizationReversal);
        NopGatewayAdapter adapter = new NopGatewayAdapter();
        
        commercepayments.GatewayResponse response = adapter.processRequest(p);
        System.assert(response != null, 'Response is not null');
        System.assert(response instanceOf commercepayments.AuthorizationReversalResponse, 'Response is not a valid Capture response');
        Test.stopTest();
    }

    @isTest static void testCaptureRequest() {
        PaymentAuthorization auth = initializeAuthObject();
        
        Test.startTest();
        // Create an capture request
        commercepayments.CaptureRequest captureRequest = new commercepayments.CaptureRequest((Double)199.99, auth.id);
        
        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(captureRequest, commercepayments.RequestType.capture);
        NopGatewayAdapter adapter = new NopGatewayAdapter();
        
        commercepayments.GatewayResponse captureResponse = adapter.processRequest(p);
        System.assert(captureResponse != null, 'Response is not null');
        System.assert(captureResponse instanceOf commercepayments.CaptureResponse, 'Response is not a valid Capture response');
        Test.stopTest();
    }
    
    @isTest static void testReferencedRefundRequest() {
        Payment pmt = initializePaymentObject();

        Test.startTest();
        // Create an capture request
        commercepayments.ReferencedRefundRequest request = new commercepayments.ReferencedRefundRequest(80, pmt.id);
        
        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(request, commercepayments.RequestType.referencedrefund);
        NopGatewayAdapter adapter = new NopGatewayAdapter();
        
        commercepayments.GatewayResponse response = adapter.processRequest(p);
        System.assert(response != null, 'Response is not null');
        System.assert(response instanceOf commercepayments.ReferencedRefundResponse, 'Response is not a valid Refund response');
        Test.stopTest();
    }

    @isTest static void testSaleRequest() {
        Test.startTest();
        // Create a PaymentMethod instance
        commercepayments.SaleApiPaymentMethodRequest paymentMethod = createSalePaymentMethodRequest();

        // Create an auth request
        commercepayments.SaleRequest request = new commercepayments.SaleRequest(80);
        request.paymentMethod = paymentMethod;
        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(request, commercepayments.RequestType.Sale);
        NopGatewayAdapter adapter = new NopGatewayAdapter();

        commercepayments.GatewayResponse response = adapter.processRequest(p);
        System.assert(response != null, 'Response is null');
        System.assert(response instanceOf commercepayments.SaleResponse, 'Response is not a valid Sale response');
        Test.stopTest();
    }
    
    @isTest static void testPaymentMethodTokenizationRequest() {
        Test.startTest();
        // Create an auth request
        commercepayments.PaymentMethodTokenizationRequest request = new commercepayments.PaymentMethodTokenizationRequest(null);
        request.cardPaymentMethod = getCardPaymentMethod();

        commercepayments.PaymentGatewayContext p = new commercepayments.PaymentGatewayContext(request, commercepayments.RequestType.Tokenize);
        NopGatewayAdapter adapter = new NopGatewayAdapter();

        commercepayments.GatewayResponse response = adapter.processRequest(p);
        System.assert(response != null, 'Response is not null');
        // System.assert(response instanceOf commercepayments.PaymentMethodTokenizationResponse, 'Response is not a valid Tokenize response');
        Test.stopTest();
    }
    
    static PaymentAuthorization initializeAuthObject() {
        PaymentAuthorization result = new PaymentAuthorization(
            Amount = 150,
            Status = 'Processed',
            ProcessingMode = 'External',
            GatewayRefNumber = '6533262562566577203004'
        );
        insert result;
        return result;
    }

    static Payment initializePaymentObject() {
        Payment result = new Payment(
            amount = 1500,
            Status = 'Processed',
            ProcessingMode = 'External',
            GatewayRefNumber = 'testreferencenumber',
            Type = 'Capture',
            GatewayRefDetails = '{"method":"credit_card","transaction_id":"ET119982"}'
        );
        insert result;
        return result;
    }
    
    static commercepayments.AuthApiPaymentMethodRequest createAuthPaymentMethodRequest() {
        return new commercepayments.AuthApiPaymentMethodRequest(getCardPaymentMethod());
    }
    
    static commercepayments.SaleApiPaymentMethodRequest createSalePaymentMethodRequest() {
        return new commercepayments.SaleApiPaymentMethodRequest(getCardPaymentMethod());
    }
    
    static commercepayments.CardPaymentMethodRequest getCardPaymentMethod() {
        commercepayments.CardPaymentMethodRequest cardPaymentMethod = new commercepayments.CardPaymentMethodRequest(commercepayments.CardCategory.CreditCard);
        cardPaymentMethod.cardType = commercepayments.CardType.Visa;
        cardPaymentMethod.cardHolderFirstName = 'Test';
        cardPaymentMethod.cardHolderLastName = 'Test';
        cardPaymentMethod.cardHolderName = 'Test Test';
        cardPaymentMethod.cardNumber = '4443434343284111';
        cardPaymentMethod.cvv = '123';
        cardPaymentMethod.email = 'h@test.com';
        cardPaymentMethod.expiryMonth = 2;
        cardPaymentMethod.expiryYear = 1111;
        cardPaymentMethod.startMonth = 2;
        cardPaymentMethod.startYear = 1333;
        return cardPaymentMethod;
    }
}