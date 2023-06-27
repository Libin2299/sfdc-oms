global class NopGatewayAdapter implements commercepayments.PaymentGatewayAdapter {
    static final commercepayments.SalesforceResultCodeInfo SUCCESS_SALESFORCE_RESULT_CODE_INFO = new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Success);
    static final commercepayments.SalesforceResultCodeInfo DECLINE_SALESFORCE_RESULT_CODE_INFO = new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Decline);
    
    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        commercepayments.GatewayResponse response;
        try {
            if (requestType == commercepayments.RequestType.Authorize) { response = createAuthorizeResponse((commercepayments.AuthorizationRequest)gatewayContext.getPaymentRequest()); }
            else if (requestType == commercepayments.RequestType.AuthorizationReversal) { response = createAuthorizationReversalReversal((commercepayments.AuthorizationReversalRequest)gatewayContext.getPaymentRequest()); }
            else if (requestType == commercepayments.RequestType.Capture) { response = createCaptureResponse((commercepayments.CaptureRequest)gatewayContext.getPaymentRequest()) ; }
            else if (requestType == commercepayments.RequestType.Sale) { response = createSaleResponse((commercepayments.SaleRequest)gatewayContext.getPaymentRequest()) ; }
            else if (requestType == commercepayments.RequestType.ReferencedRefund) { response = createReferencedRefundResponse((commercepayments.ReferencedRefundRequest)gatewayContext.getPaymentRequest()); }
            else if (requestType == commercepayments.RequestType.Tokenize) { response = createTokenizeResponse((commercepayments.PaymentMethodTokenizationRequest)gatewayContext.getPaymentRequest()); }
            return response;
        } catch (NopGatewayAdapterException e) {
            commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse('400', e.getMessage());
            return error;
        }
    }
    
    commercepayments.GatewayResponse createAuthorizeResponse(commercepayments.AuthorizationRequest request) {
        commercepayments.AuthorizationResponse response = new commercepayments.AuthorizationResponse();
        commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
        if (request.amount != null) { response.setAmount(request.amount); }
        else { throw new NopGatewayAdapterException('Required Field Missing : Amount'); }
    
        response.setGatewayResultCode('00');
        response.setGatewayResultCodeDescription('Transaction Normal');
        response.setGatewayAuthCode('SF'+getRandomNumber(6));
        response.setGatewayReferenceNumber(getRandomNumber(10));
        response.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        response.setGatewayDate(system.now());
        paymentMethodTokenizationResponse.setGatewayToken(getRandomNumber(8)+getRandomNumber(8));
        response.setPaymentMethodTokenizationResponse(paymentMethodTokenizationResponse);
        return response;
    }
    
    commercepayments.GatewayResponse createAuthorizationReversalReversal(commercepayments.AuthorizationReversalRequest request) {
        commercepayments.AuthorizationReversalResponse response = new commercepayments.AuthorizationReversalResponse();
        commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
        if (request.amount != null) { response.setAmount(request.amount); }
        else { throw new NopGatewayAdapterException('Required Field Missing : Amount'); }
    
        response.setGatewayResultCode('00');
        response.setGatewayResultCodeDescription('Transaction Normal');
        response.setGatewayReferenceNumber(getRandomNumber(10));
        response.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        response.setGatewayDate(system.now());
        return response;
    }

    commercepayments.GatewayResponse createCaptureResponse(commercepayments.CaptureRequest request) {
        commercepayments.CaptureResponse response = new commercepayments.CaptureResponse();
        if (request.amount != null) { response.setAmount(request.amount); }
        else { throw new NopGatewayAdapterException('Required Field Missing : Amount'); }
   
        system.debug('Response - success');
        response.setGatewayDate(system.now());
        response.setGatewayResultCode('00');
        response.setGatewayResultCodeDescription('Transaction Normal');
        response.setGatewayReferenceNumber('SF'+getRandomNumber(6));
        response.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        return response;
    }
    
    commercepayments.GatewayResponse createSaleResponse(commercepayments.SaleRequest request) {
        commercepayments.SaleResponse response = new commercepayments.SaleResponse();
        commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
        if (request.amount != null) { response.setAmount(request.amount); }
        else { throw new NopGatewayAdapterException('Required Field Missing : Amount'); }
   
        system.debug('Response - success');
        response.setGatewayDate(system.now());
        response.setGatewayResultCode('00');
        response.setGatewayResultCodeDescription('Transaction Normal');
        response.setGatewayReferenceNumber('SF'+getRandomNumber(6));
        response.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        paymentMethodTokenizationResponse.setGatewayToken(getRandomNumber(8)+getRandomNumber(8));
        response.setPaymentMethodTokenizationResponse(paymentMethodTokenizationResponse);
        return response;
    }
    
    commercepayments.GatewayResponse createReferencedRefundResponse(commercepayments.ReferencedRefundRequest request) {
        commercepayments.ReferencedRefundResponse response = new commercepayments.ReferencedRefundResponse();
        if (request.amount != null) { response.setAmount(request.amount); }
        else { throw new NopGatewayAdapterException('Required Field Missing : Amount'); }
        response.setGatewayResultCode('00');
        response.setGatewayDate(system.now());
        response.setGatewayResultCodeDescription('Transaction Normal');
        response.setGatewayReferenceNumber('SF'+getRandomNumber(6));
        response.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        return response;
    }

    commercepayments.GatewayResponse createTokenizeResponse(commercepayments.PaymentMethodTokenizationRequest request) {
        commercepayments.PaymentMethodTokenizationResponse response = new commercepayments.PaymentMethodTokenizationResponse();
        response.setGatewayToken(getRandomNumber(8)+getRandomNumber(8));
        response.setGatewayTokenDetails(getRandomNumber(8)+getRandomNumber(8));
        response.setGatewayAvsCode(getRandomNumber(8)+getRandomNumber(8));
        response.setGatewayMessage(getRandomNumber(8)+getRandomNumber(8));
        response.setGatewayResultCode(getRandomNumber(8)+getRandomNumber(8));
        response.setGatewayResultCodeDescription(getRandomNumber(8)+getRandomNumber(8));
        response.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
        response.setGatewayToken(getRandomNumber(8)+getRandomNumber(8));
        response.setGatewayDate(system.now());
        return response;
    }

    String getRandomNumber(integer stringLength) {
        final integer MAX = integer.valueOf(Math.pow(10,stringLength) - 1);
        return String.valueOf(Math.Round(Math.Random() * MAX)).leftPad(stringLength,'0');
    }
}