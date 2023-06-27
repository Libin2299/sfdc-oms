
# Process Builders
Approve Order Summary Process
- on: Order Summary Created Event
- if (true) {
    Status = 'Remorse';
}

QuickJob: OmsJobsRemorse @ 5min
- if (Status == 'Remorse' && OrderedAgeInMinutes >= 30) {
    event: Order Summary Event(Action='Ready to Capture')
}

Activate Order Summary Process
- on: Order Summary Event
- if (event.Action == 'Remorse') {
    Status = 'Ready to Capture';
}

QuickJob: OmsJobsCapture @ 5min
- if (Status == 'Ready to Capture' && !ActiveProcessExceptions && capture.success) {
    Status = 'Approved'
}

Create Fulfillment Orders for One Location Process
- on: Order Summary Status Changed Event
- if (Status == 'Approved') {
    flow('Create Fulfillment Orders for One Location');
}

Create Invoice and Ensure Funds Process
- on: Fulfillment Order Status Changed Event
- if (Status == 'Closed' && InvoiceId == null) {
    flow('Create Invoice and Ensure Funds');
}


# Flows
Cancel an Item - [ScreenFlow] Cancels a item and Cancels Order if last item
Capture Upon Order Acceptance - [Scheduled] Captures Payment
Create Fulfillment Orders for One Location - [Process:CreateFulfillmentOrdersforMultipleLocationsProcess] Create FulfilmentOrder(s)
Create Invoice and Ensure Funds - [Record-FulfillmentOrder.Status=Closed] Creates an Invoice
Create Order Summary Flow A - [Record—Order] Create Standard Order Summary
Create Process Exception Flow A - [PlatformEvent] Create Standard Process Exception
**Credit Memo Trigger Flow A [Record-CreditMemo] Refunds Credit Memo when Refund Status set to Pending
Discount an Item - [ScreenFlow] Adds an Order Adjustment for items and shipping
Return an Item - [ScreenFlow] Initiates an Item Return (nonRMA)


# Emails
Canceled (OmsEmailCanceled) - [flow:Cancel an Item] - Email about canceled item
Shipped (OmsEmailShipped) - [flow:Create Invoice and Ensure Funds] - Email with Shipment notification
<!-- RefundCreated - [Record-CreditMemo created] - Email with RMA #(CreditMemoNumber) and instructions -->
RefundComplete (OmsEmailRefundComplete) - [flow:Credit Memo Trigger Flow] - Email that credit card has been refunded


# Scheduled Jobs

AmwareJob Every 1 hour
- AmwareJobExportFulfillmentOrders - Send Fulfilment order to Wms
- AmwareJobQueryAsn - Create Shipment record, and change fulfilment to fulfilled
- AmwareJobQueryReturn - Insert a record into a WmsProductReturn__c? record
- AmwareJobQueryStatus - Update a WmsStatus__c(text) field on the OrderFulfilment

PositiveJob Every 1 hour
- PositiveJobExportFulfillmentOrders - Send Fulfilment order to Wms
- PositiveJobQueryAsn - Create Shipment record, and change fulfilment to fulfilled
- PositiveJobQueryReturn - Insert a record into a WmsProductReturn__c? record
- PositiveJobQueryStatus - Update a WmsStatus__c(text) field on the OrderFulfilment


# OrderSummary Status
- Created (default)
- Remorse - Set by process:Approve Order Summary Process
- Ready to Capture - Set by process:Activate Order Summary Process
- Approved - Set by apex:OmsJobsCapture
- Waiting to Fulfill - Set by flow:Create Fulfillment for Multiple Locations
- Fulfilled - Set by mulesoft on completion of Order
- Cancelled - Set by flow:Cancel an Item when last item


# FulfilmentOrder Status
- Draft (Draft) - Not used
- Allocated (Activated) - Created by Flow:Create Fulfillment Orders Flow A
- Assigned (Fulfilling) - Set upon successful FullfilmentCalloutService
- Pickpack (Fulfilling) - Set upon successful FullfilmentCalloutService
- Fulfilled (Closed) - Set upon successful InvoiceCalloutService
- Canceled (Canceled)

# Invoice Status (Restricted)
- Canceled
- Draft
- ErrorPosting
- Pending
- Posted

# CreditMemo Status (Restricted)
- Canceled
- Draft - The credit memo is not yet recorded as a financial transaction. Certain fields can still be edited.
- Pending
- Posted - The credit memo has been recorded as a financial transaction. Most fields can’t be edited.

# CreditMemo RefundStatus
- Canceled
- Pending
- Posted


# Start Schedules
new AppQuickSchedule().run();
new WmsQuickSchedule().run();