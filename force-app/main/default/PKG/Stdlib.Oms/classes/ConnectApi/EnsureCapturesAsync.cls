global class EnsureCapturesAsync implements Queueable {
    static final String PEE_DESCRIPTION = 'Payment Failed';
    static final String PEE_SEVERITY = 'High';
    final Id orderSummaryId;
    final EnsureCapturesAsyncInputRepresentation ensureCapturesInput;

    global class FlowInput {
        @InvocableVariable(label = 'Order Summary Id') global Id orderSummaryId;
        @InvocableVariable(label = 'Ensure Captures Async Input') global EnsureCapturesAsyncInputRepresentation ensureCapturesInput;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'backgroundOperationId') global String backgroundOperationId;
    }

    global EnsureCapturesAsync(Id orderSummaryId, EnsureCapturesAsyncInputRepresentation ensureCapturesInput) {
        if (orderSummaryId == null) { throw new HandledException('orderSummaryId is required'); }
        if (ensureCapturesInput == null) { throw new HandledException('ensureCapturesInput is required'); }
        this.orderSummaryId = orderSummaryId;
        this.ensureCapturesInput = ensureCapturesInput;
    }

    /**
    * @description invocable - Ensure Captures Async
    * @param inputs the inputs
    * @return List<FlowOutput>
    **/
    @InvocableMethod(label='Ensure Captures Async')
    global static List<FlowOutput> invocable(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            output.backgroundOperationId = ConnectApiXOrderSummary.ensureCapturesAsync(input.orderSummaryId, input.ensureCapturesInput).backgroundOperationId;
            outputs.add(output);
        }
        return outputs;
    }

    /**
    * @description capture Payment Authorizations
    * @param context the context
    **/
    global void execute(QueueableContext context) {
        List<SObject> updates = new List<SObject>();
        Double remainingAmount = ensureCapturesInput.amount;
        Boolean capture = true;
        for (PaymentAuthorization s : [SELECT Id, Balance, AccountId, OrderPaymentSummaryId, CurrencyIsoCode FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId = :orderSummaryId And Balance > 0]) {
            if (remainingAmount <= 0) { break; }
            else if (s.Balance <= 0) { continue; }
            Double amount = Math.min(remainingAmount, s.Balance);
            remainingAmount -= amount;

            // capture
            ConnectApi.CaptureRequest request = new ConnectApi.CaptureRequest();
            request.accountId = s.AccountId;
            request.amount = amount;
            request.comments = ensureCapturesInput.comments;
            request.effectiveDate = Datetime.now();
            try {
                ConnectApi.CaptureResponse response = null;
                if (!Test.isRunningTest()) {
                    response = ConnectApi.Payments.capture(request, s.Id);
                    updates.add(new Payment(Id = response.payment.id, OrderPaymentSummaryId = s.OrderPaymentSummaryId));
                    for (ConnectApi.GatewayLogResponse x : response.paymentGatewayLogs) {
                        updates.add(new PaymentGatewayLog(Id = x.id, OrderPaymentSummaryId = s.OrderPaymentSummaryId));
                    }
                    System.debug(response);
                }
                else if (ensureCapturesInput.comments == 'Throw') { throw new HandledException('Exception'); }
                else {
                    Payment payment = new Payment(
                        PaymentAuthorizationId = s.Id,
                        Amount = request.amount,
                        CurrencyIsoCode = s.CurrencyIsoCode,
                        EffectiveDate = request.effectiveDate,
                        Type = 'Capture',
                        Status = 'Processed',
                        ProcessingMode = 'External');
                    insert payment;
                    updates.add(new Payment(Id = payment.id, OrderPaymentSummaryId = s.OrderPaymentSummaryId));
                }
            } catch (Exception e) {
                System.debug('ERR: '+ e.getMessage());
                EventBusX.publish(new List<SObject> { OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, orderSummaryId, orderSummaryId, e.getMessage()) });
                capture = false;
            }
        }
        if (capture) {
            if (!String.isBlank(ensureCapturesInput.onSuccess)) { updates.add(ObjectX.putAll(new OrderSummary(Id = orderSummaryId), ensureCapturesInput.onSuccess)); }
        }
        else {
            if (!String.isBlank(ensureCapturesInput.onFailure)) { updates.add(ObjectX.putAll(new OrderSummary(Id = orderSummaryId), ensureCapturesInput.onSuccess)); }
        }
        if (!updates.isEmpty()) { Database.update(updates, true); }
    }
}