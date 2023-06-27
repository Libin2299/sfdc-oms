global class ConnectApiXOrderSummary {
    /*
    * Apply invoice payment by adding payment invoice lines.
    * This method inserts a background operation into an asynchronous job queue and returns the ID of that operation so you can track its status.
    */
    global static ApplyInvoicePaymentsAsyncOutputRepre applyInvoicePaymentsAsync(Id orderSummaryId, ApplyInvoicePaymentsAsyncInputRepre applyInvoicePaymentsInput) {
        ApplyInvoicePaymentsAsyncOutputRepre result = new ApplyInvoicePaymentsAsyncOutputRepre();
        result.backgroundOperationId = System.enqueueJob(new ApplyInvoicePaymentsAsync(orderSummaryId, applyInvoicePaymentsInput));
        return result;
    }

    /*
    * Ensure payment capture by sending a request to a payment provider.
    * This method inserts a background operation into an asynchronous job queue and returns the ID of that operation so you can track its status.
    * Payment gateway responses appear in the payment gateway log and do not affect the background operation status.
    */
    global static EnsureCapturesAsyncOutputRepresentation ensureCapturesAsync(Id orderSummaryId, EnsureCapturesAsyncInputRepresentation ensureCapturesInput) {
        EnsureCapturesAsyncOutputRepresentation result = new EnsureCapturesAsyncOutputRepresentation();
        result.backgroundOperationId = System.enqueueJob(new EnsureCapturesAsync(orderSummaryId, ensureCapturesInput));
        return result;
    }

    /*
    * Ensure payment re-authorization by sending a request to a payment provider.
    * This method inserts a background operation into an asynchronous job queue and returns the ID of that operation so you can track its status.
    * Payment gateway responses appear in the payment gateway log and do not affect the background operation status.
    */
    global static EnsureReauthsAsyncOutputRepresentation ensureReauthsAsync(Id orderSummaryId, EnsureReauthsAsyncInputRepresentation ensureReauthsInput) {
        EnsureReauthsAsyncOutputRepresentation result = new EnsureReauthsAsyncOutputRepresentation();
        result.backgroundOperationId = System.enqueueJob(new EnsureReauthsAsync(orderSummaryId, ensureReauthsInput));
        return result;
    }

    /*
    * Ensure reversal for a payment authorization by sending a request to a payment provider.
    * This method inserts a background operation into an asynchronous job queue and returns the ID of that operation so you can track its status.
    * Payment gateway responses appear in the payment gateway log and do not affect the background operation status.
    */
    global static EnsureReversalsAsyncOutputRepresentation ensureReversalsAsync(Id orderSummaryId, EnsureReversalsAsyncInputRepresentation ensureReversalsInput) {
        EnsureReversalsAsyncOutputRepresentation result = new EnsureReversalsAsyncOutputRepresentation();
        result.backgroundOperationId = System.enqueueJob(new EnsureReversalsAsync(orderSummaryId, ensureReversalsInput));
        return result;
    }
}