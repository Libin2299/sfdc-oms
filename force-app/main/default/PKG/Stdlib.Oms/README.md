# Standard Library (Stdlib.Oms) 

A general purpose standard library for the Salesforce Core Platform which includes functions involving DML, scheduling, conversions and others.

## Member functions
---
Stdlib.Oms provides the following static functions:

**OmsPaymentX** | **Description**
-- | --
`assignCreditMemoReferenceRefund()` | assign the CreditMemo ReferenceRefund field
`assignCreditMemoReferenceRefund(List<Payment> items)` | assign the CreditMemo ReferenceRefund field
**OmsSystemX** | **Description**
-- | --
`createProcessException(String message, String severity, Id orderSummaryId, Id attachedToId, String description)` | creates a process exception
`deleteOrderSummary(List<Id> scope, String password)` | deletes order summaries
`fixOrphanPayments(String password)` | fixes orphan payments
`options` | the options

## Connect Api
---
Stdlib.Oms provides Connect Api type core actions:


### ApplyInvoicePaymentsAsync
Applies payment to an invoice, this replaces ensure funds.

**FlowInput** | **Type** | **Label**
-- | -- | --
orderSummaryId | Id | Order Summary Id
applyInvoicePaymentsInput | ApplyInvoicePaymentsAsyncInputRepre | Apply Invoice Payments Async Input
**FlowOutput** | **Type** | **Label**
backgroundOperationId | String | backgroundOperationId

#### ApplyInvoicePaymentsAsyncInputRepre
* invoiceId - the invoice to apply payments to


### EnsureCapturesAsync
Ensures captures are performed.

**FlowInput** | **Type** | **Label**
-- | -- | --
orderSummaryId | Id | Order Summary Id
ensureCapturesInput | EnsureCapturesAsyncInputRepresentation | Ensure Captures Async Input Input
**FlowOutput** | **Type** | **Label**
backgroundOperationId | String | backgroundOperationId

#### EnsureCapturesAsyncInputRepresentation
* amount - the amount to capture
* comments - the comments to use
* onSuccess - the values to apply on success
* onFailure - the values to apply on failure


### EnsureReauthsAsync
Re-authorize payment

**FlowInput** | **Type** | **Label**
-- | -- | --
orderSummaryId | Id | Order Summary Id
ensureReauthsInput | EnsureReauthsAsyncInputRepresentation | Ensure Reauths Async Input
**FlowOutput** | **Type** | **Label**
backgroundOperationId | String | backgroundOperationId

#### EnsureReauthsAsyncInputRepresentation
* paymentAuthId - the payment authorization id
* comments - the comments to use


### EnsureReversalsAsync
Reverse authorizations

**FlowInput** | **Type** | **Label**
-- | -- | --
orderSummaryId | Id | Order Summary Id
ensureReversalsInput | EnsureReversalsAsyncInputRepresentation | Ensure Reversals Async Input
**FlowOutput** | **Type** | **Label**
backgroundOperationId | String | backgroundOperationId

#### EnsureReversalsAsyncInputRepresentation
* comments - the comments to use


### Additional classes

#### ConnectApiX.AuthorizationResponse
* error - Error representation for Payment Authorization.
* gatewayResponse - Gateway response representation for payment authorization.
* paymentAuthorization - Payment authorization representation.

#### ConnectApiX.ErrorResponse
* errorCode - Error code.
* message - More error detail, if available.

#### ConnectApiX.AuthorizationGatewayResponse
* gatewayAuthorizationCode - Authorization code for the payment gateway.
* gatewayAvsCode - Address verification system used for tokenization in the payment gateway.
* gatewayDate - The date that the payment gateway processed the payment transaction.
* gatewayMessage - Optional method that the payment gateway returns to provide more information on the status of a payment transaction.
* gatewayReferenceDetails - Gateway reference details.
* gatewayReferenceNumber - Gateway reference number.
* gatewayResultCode - Gateway result code. Indicates the result of the gateway processing the payment transaction. Result codes for between different gateway providers. Must be mapped to a Salesforce result code.
* gatewayResultCodeDescription - Provides more information about the result code.
* salesforceResultCode - Salesforce result code. Must be set based on the value of the gateway result code.

#### ConnectApiX.PaymentAuthorizationResponse
* id - ID of the payment authorization record.


## Factories
---
Factories generate test data.

**OmsOrderDataFactory** *(test only)* | **Description**
-- | --
`preamble` | preamble - call before tests
`createSalesChannel(String name)` | creates a sales channel
`createOrder(String orderType, Account account, String orderNumber)` | creates an order
`getOrder(Id orderId)` | gets an order
`createOrderSummary(String orderType)` | creates an order summary
`createOrderSummary(String orderType, Account account, String orderNum)` | creates an order summary
`getOrderSummary(Id orderSummaryId)` | gets an order summary
`getOrderSummaryByOrder(Id orderId)` | gets an order summary by order
`createOrderAdjust(OrderSummary summary, FulfillmentOrder fulfillmentOrder)` | creates an order adjustment
`createOrderChange(OrderSummary summary, FulfillmentOrder fulfillmentOrder)` | creates an order change
`createCreditMemo(Id orderSummaryId, Id changeOrderId)` | creates a credit memo
`createFulfillmentOrders(String orderType, Id orderSummaryId, Account account)` | creates a fulfillment order
`getFulfillmentOrders(Id orderSummaryId)` | gets the fulfillment orders
`createPayment(Decimal amount, Id invoiceId, Id orderSummaryId)` | creates a payment
`createRefund(Decimal amount, PaymentLineInvoice paymentLineInvoice)` | creates a refund
`invoiceFulfillmentOrder(FulfillmentOrder fulfillmentOrder)` | invoices a fulfillment order


## Gateway Adapters
---
Payment gateway adapters.

### NopGatewayAdapter
No operation gateway adapter, accepts all transactions


## Jobs
---

### Imports : OmsImportsOrderSummary
Creates order summaries for Orders with IsHistorical__c not set that have a SalesChannelId defined.

**Name** | **Type** | **Description**
-- | -- | --
phase | Integer | 1: creates order summaries. 2: updates order summaries status to Fulfilled

*Primary Query*
```sql
SELECT Id FROM Order WHERE IsHistorical__c = True And SalesChannelId != Null And Id Not In (SELECT OriginalOrderId FROM OrderSummary)
```

### Jobs : OmsJobsCapture
Captures funds when status is ready to capture.

**Name** | **Type** | **Description**
-- | -- | --
flowField | String | 1 creates
values | Map<String, Object> | 1 creates

*Primary Query*
```sql
SELECT Id FROM OrderSummary WHERE Status = 'Ready to Capture' And ActiveProcessExceptionCount = 0 LIMIT 500
```
*Example QuickSchedule*
```java
public override List<QuickScheduleJob> getJobs() {
    return new List<QuickScheduleJob> {
        new QuickScheduleJob(5, OmsJobsCapture.class, 1),
    };
}
```

### Jobs : OmsJobsChangeOrder
Creates change orders.

*Primary Query*
```sql
SELECT Id, RelatedOrderId FROM Order WHERE RelatedOrderId != Null And Id Not In (SELECT Order__c FROM ChangeOrder__c)
```
*Example QuickSchedule*
```java
public override List<QuickScheduleJob> getJobs() {
    return new List<QuickScheduleJob> {
        new QuickScheduleJob(5, OmsJobsChangeOrder.class),
    };
}
```

### Jobs : OmsJobsPayment
Processes PaymentX methods

*Example QuickSchedule*
```java
public override List<QuickScheduleJob> getJobs() {
    return new List<QuickScheduleJob> {
        new QuickScheduleJob(5, OmsJobsPayment.class),
    };
}
```

### Jobs : OmsJobsRemorse
Imports - Creates order summaries for Orders with IsHistorical__c not set that have a SalesChannelId defined.

**Name** | **Type** | **Description**
-- | -- | --
remorsePeriodMinutes | Integer | defines the remorse period. default is 30 minutes.

*Primary Query*
```sql
SELECT Id, OrderedDate, (SELECT Id, ScheduleStatus FROM OrderSummaryRoutingSchedules WHERE ScheduleStatus='SCHEDULED') FROM OrderSummary WHERE PickedupByRemorse__c = False And Status = 'Remorse' And OrderedAgeInMinutes__c >= {RPIM} LIMIT 500
```
*Example QuickSchedule*
```java
public override List<QuickScheduleJob> getJobs() {
    return new List<QuickScheduleJob> {
        new QuickScheduleJob(5, OmsJobsRemorse.class),
    };
}
```