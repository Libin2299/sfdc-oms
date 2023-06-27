global class ApplyInvoicePaymentsAsync implements Queueable {
    public String CLASS_NAME = ApplyInvoicePaymentsAsync.class.getName();
    final Id orderSummaryId;
    final ApplyInvoicePaymentsAsyncInputRepre applyInvoicePaymentsInput;

    global class FlowInput {
        @InvocableVariable(label = 'Order Summary Id') global Id orderSummaryId;
        @InvocableVariable(label = 'Apply Invoice Payments Async Input') global ApplyInvoicePaymentsAsyncInputRepre applyInvoicePaymentsInput;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'backgroundOperationId') global String backgroundOperationId;
    }

    global ApplyInvoicePaymentsAsync(Id orderSummaryId, ApplyInvoicePaymentsAsyncInputRepre applyInvoicePaymentsInput) {
        if (orderSummaryId == null) { throw new HandledException('orderSummaryId is required'); }
        if (applyInvoicePaymentsInput == null) { throw new HandledException('applyInvoicePaymentsInput is required'); }
        this.orderSummaryId = orderSummaryId;
        this.applyInvoicePaymentsInput = applyInvoicePaymentsInput;
    }

    /**
    * @description invocable - Apply Invoice Payments Async
    * @param inputs the inputs
    * @return List<FlowOutput>
    **/
    @InvocableMethod(label='Apply Invoice Payments Async')
    global static List<FlowOutput> invocable(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            output.backgroundOperationId = ConnectApiXOrderSummary.applyInvoicePaymentsAsync(input.orderSummaryId, input.applyInvoicePaymentsInput).backgroundOperationId;
            outputs.add(output);
        }
        return outputs;
    }

    /**
    * @description reauth Payment Authorization
    * @param context the context
    **/
    global void execute(QueueableContext context) {
        Id invoiceId = applyInvoicePaymentsInput.invoiceId;
        Invoice invoice = [SELECT ReferenceEntityId, TotalAmountWithTax FROM Invoice WHERE Id = :invoiceId];
        Id orderSummaryId = invoice.ReferenceEntityId;
        Double amount = invoice.TotalAmountWithTax;
        List<PaymentLineInvoice> inserts = new List<PaymentLineInvoice>();
        for (Payment s : [SELECT Id, Balance, CurrencyIsoCode From Payment WHERE OrderPaymentSummary.OrderSummaryId = :orderSummaryId And Balance > 0]) {
            if (amount <= 0) { break; }
            Double newAmount = Math.min(amount, s.Balance);
            amount -= newAmount;
            inserts.add(new PaymentLineInvoice(
                InvoiceId = invoiceId,
                PaymentId = s.Id,
                Amount = newAmount,
                CurrencyIsoCode = s.CurrencyIsoCode,
                Type = 'Applied'));
        }
        if (!inserts.isEmpty()) { Database.SaveResult[] srList = Database.insert(inserts, false); CustomCommonUtil.logDmlException(srList, CLASS_NAME); }
    }
}