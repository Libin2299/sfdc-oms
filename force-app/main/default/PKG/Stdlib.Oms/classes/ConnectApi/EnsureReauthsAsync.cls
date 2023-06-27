global class EnsureReauthsAsync implements Queueable {
    static final String PEE_DESCRIPTION = 'Payment Failed';
    static final String PEE_SEVERITY = 'High';
    final Id orderSummaryId;
    final EnsureReauthsAsyncInputRepresentation ensureReauthsInput;

    global class FlowInput {
        @InvocableVariable(label = 'Order Summary Id') global Id orderSummaryId;
        @InvocableVariable(label = 'Ensure Reauths Async Input') global EnsureReauthsAsyncInputRepresentation ensureReauthsInput;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'backgroundOperationId') global String backgroundOperationId;
    }

    global EnsureReauthsAsync(Id orderSummaryId, EnsureReauthsAsyncInputRepresentation ensureReauthsInput) {
        if (orderSummaryId == null) { throw new HandledException('orderSummaryId is required'); }
        if (ensureReauthsInput == null) { throw new HandledException('ensureReauthsInput is required'); }
        this.orderSummaryId = orderSummaryId;
        this.ensureReauthsInput = ensureReauthsInput;
    }

    /**
    * @description invocable - Ensure Reauths Async
    * @param inputs the inputs
    * @return List<FlowOutput>
    **/
    @InvocableMethod(label='Ensure Reauths Async')
    global static List<FlowOutput> invocable(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            output.backgroundOperationId = ConnectApiXOrderSummary.ensureReauthsAsync(input.orderSummaryId, input.ensureReauthsInput).backgroundOperationId;
            outputs.add(output);
        }
        return outputs;
    }

    /**
    * @description reauth Payment Authorization
    * @param context the context
    **/
    global void execute(QueueableContext context) {
        List<PaymentAuthorization> auths = [
            SELECT Id, Balance, AccountId, /*CurrencyIsoCode,*/ PaymentGatewayId, PaymentGroupId, PaymentMethodId
            FROM PaymentAuthorization WHERE Status = 'Processed' And OrderPaymentSummary.OrderSummaryId = :orderSummaryId ORDER BY CreatedDate LIMIT 1];
        if (auths.isEmpty()) { return; }
        PaymentAuthorization auth = auths[0];

        // Dummy CC info
        ConnectApi.CardPaymentMethodRequest cpm = new ConnectApi.CardPaymentMethodRequest();
        cpm.accountId = auth.AccountId;
        cpm.cardCategory = ConnectApi.CardCategory.CREDITCARD;
        cpm.cardHolderFirstName = 'John';
        cpm.cardHolderLastName = 'Re-Authorization';
        cpm.cardHolderName = auth.Id;
        cpm.cardNumber = '0000000000000000';
        cpm.cardType = 'Visa';
        cpm.cvv = '000';
        cpm.email = 'jd@mail.not';
        cpm.expiryMonth = 3;
        cpm.expiryYear = 2099;

        ConnectApi.AuthApiPaymentMethodRequest aapm = new ConnectApi.AuthApiPaymentMethodRequest();
        aapm.cardPaymentMethod = cpm;

        // Authorization
        ConnectApi.AuthorizationRequest request = new ConnectApi.AuthorizationRequest();
        request.paymentGroup = new ConnectApi.PaymentGroupRequest();
        request.amount = auth.Balance;
        request.comments = ensureReauthsInput.comments;
        request.effectiveDate = Datetime.now();
        request.accountId = auth.AccountId;
        /*request.currencyIsoCode = auth.CurrencyIsoCode;*/
        request.paymentGatewayId = auth.PaymentGatewayId;
        request.paymentGroup.id = auth.PaymentGroupId;
        request.paymentMethod = aapm;

        List<SObject> events = new List<SObject>();
        ConnectApiX.AuthorizationResponse response = null;
        String responseCode; String responseMessage;
        try {
            // response = OMS_OmsLink.authorize(request);
            response = new ConnectApiX.AuthorizationResponse();
            if (Test.isRunningTest()) {
                switch on ensureReauthsInput.comments {
                    when 'comments' {
                        response.paymentAuthorization = new ConnectApiX.PaymentAuthorizationResponse();
                        response.paymentAuthorization.id = ensureReauthsInput.paymentAuthId;
                        response.gatewayResponse = new ConnectApiX.AuthorizationGatewayResponse();
                    }
                    when 'error' {
                        response.error = new ConnectApiX.ErrorResponse();
                        response.error.errorCode = 'errorCode';
                        response.error.message = 'message';
                    }
                    when 'Throw' { throw new HandledException('Throw'); }
                }
            }
            if (response.error != null) {
                responseCode = response.error.errorCode != null ? response.error.errorCode : 'ERROR';
                responseMessage = response.error.message;
                events.add(OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, orderSummaryId, orderSummaryId, responseMessage));
            } else if (response.paymentAuthorization != null && response.gatewayResponse != null) {
                transferPaymentAuthorization(response.paymentAuthorization.Id, response.gatewayResponse);
                responseCode = 'Success';
                responseMessage = response.gatewayResponse.gatewayReferenceNumber;
            } else {
                responseCode = 'ERROR';
                responseMessage = 'Unknown';
                events.add(OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, orderSummaryId, orderSummaryId, 'An unknown error has occured'));
            }
        } catch (Exception e) {
            System.debug('ERR: '+ e.getMessage());
            responseCode = 'Exception';
            responseMessage = e.getMessage();
            events.add(OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, orderSummaryId, orderSummaryId, e.getMessage()));
        } finally {
            responseCode = StringX.clamp(responseCode, 255);
            responseMessage = StringX.clamp(responseMessage, 131072);
            String status = responseCode == 'Success' ? 'Approved'
                : responseCode == 'Error' ? 'Failed'
                : 'Failed';
            // if (paymentAuthId != null) {
            //  update new PaymentAuthorization(
            //     Id = recordId,
            //     Status__c = status,
            //     ResponseCode__c = responseCode,
            //     ResponseMessage__c = responseMessage);
            // }
        }

        if (!events.isEmpty()) { EventBusX.publish(events); }
    }

    /**
    * @description transfer Payment Authorization
    * @param paymentAuthId the paymentAuthId
    * @param response the response
    **/
    static void transferPaymentAuthorization(Id paymentAuthId, ConnectApiX.AuthorizationGatewayResponse response) {
        PaymentAuthorization auth = [
            SELECT AccountId, Amount, Comments, /*CurrencyIsoCode,*/ EffectiveDate, Email, ExpirationDate, IpAddress, MacAddress,
            OrderPaymentSummaryId, PaymentGatewayId, PaymentGroupId, PaymentMethodId, Phone, ProcessingMode, SfResultCode, Status
            FROM PaymentAuthorization WHERE Id = :paymentAuthId];
        insert new PaymentAuthorization(
            AccountId = auth.AccountId,
            Amount = auth.Amount,
            Comments = auth.Comments,
            /*CurrencyIsoCode = auth.CurrencyIsoCode,*/
            Date = Date.today(),
            EffectiveDate = auth.EffectiveDate,
            Email = auth.Email,
            ExpirationDate = auth.ExpirationDate,
            GatewayAuthCode = response.gatewayAuthorizationCode,
            GatewayDate = response.gatewayDate != null ? Datetime.valueOf(response.gatewayDate) : null,
            GatewayRefDetails = response.gatewayReferenceDetails,
            GatewayRefNumber = response.gatewayReferenceNumber,
            GatewayResultCode = response.gatewayResultCode,
            GatewayResultCodeDescription = response.gatewayResultCodeDescription,
            IpAddress = auth.IpAddress,
            MacAddress = auth.MacAddress,
            OrderPaymentSummaryId = auth.OrderPaymentSummaryId,
            PaymentGatewayId = auth.PaymentGatewayId,
            PaymentGroupId = auth.PaymentGroupId,
            PaymentMethodId = auth.PaymentMethodId,
            Phone = auth.Phone,
            ProcessingMode = auth.ProcessingMode,
            SfResultCode = auth.SfResultCode,
            Status = auth.Status);
        update new PaymentAuthorization(Id = paymentAuthId, Status = 'Canceled');
    }
}