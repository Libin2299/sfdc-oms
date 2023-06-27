global class EnsureReversalsAsync implements Queueable, Database.AllowsCallouts {
    static final String PEE_DESCRIPTION = 'Payment Failed';
    static final String PEE_SEVERITY = 'High';
    final Id orderSummaryId;
    final EnsureReversalsAsyncInputRepresentation ensureReversalsInput;

    global class FlowInput {
        @InvocableVariable(label = 'Order Summary Id') global Id orderSummaryId;
        @InvocableVariable(label = 'Ensure Reversals Async Input') global EnsureReversalsAsyncInputRepresentation ensureReversalsInput;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'backgroundOperationId') global String backgroundOperationId;
    }

    global EnsureReversalsAsync(Id orderSummaryId, EnsureReversalsAsyncInputRepresentation ensureReversalsInput) {
        if (orderSummaryId == null) { throw new HandledException('orderSummaryId is required'); }
        if (ensureReversalsInput == null) { throw new HandledException('ensureReversalsInput is required'); }
        this.orderSummaryId = orderSummaryId;
        this.ensureReversalsInput = ensureReversalsInput;
    }

    /**
    * @description invocable - Ensure Reversals Async
    * @param inputs the inputs
    * @return List<FlowOutput>
    **/
    @InvocableMethod(label='Ensure Reversals Async')
    global static List<FlowOutput> invocable(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            output.backgroundOperationId = ConnectApiXOrderSummary.ensureReversalsAsync(input.orderSummaryId, input.ensureReversalsInput).backgroundOperationId;
            outputs.add(output);
        }
        return outputs;
    }

    global void execute(QueueableContext context) {
        List<PaymentAuthorization> auths = [
            SELECT Id, Status, AccountId, Balance, Date
            FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId = :orderSummaryId And Status != 'Canceled'];
        if (auths.isEmpty()) { return; }

        List<SObject> events = new List<SObject>();
        for (PaymentAuthorization s : auths) {
            ConnectApi.AuthorizationReversalRequest request = new ConnectApi.AuthorizationReversalRequest();
            request.amount = s.Balance;
            request.accountId = s.AccountId;
            request.comments = ensureReversalsInput.comments;
            try {
                if (!Test.isRunningTest()) {
                    System.debug('Reversing Payment: '+ request);
                    ConnectApi.AuthorizationReversalResponse response = ConnectApi.Payments.reverseAuthorization(request, s.Id);
                    System.debug('Payment Reversed: '+ response);
                }
                else if (ensureReversalsInput.comments == 'Throw') { throw new HandledException('Throw'); }
                s.Status = 'Canceled';
            } catch (Exception e) {
                System.debug('ERR: '+ e.getMessage());
                events.add(OmsSystemX.createProcessException(PEE_DESCRIPTION, PEE_SEVERITY, orderSummaryId, orderSummaryId, e.getMessage()));
            }
        }
        if (!events.isEmpty()) { EventBusX.publish(events); }
        if (!auths.isEmpty()) { Database.update(auths, false); }
    }
}