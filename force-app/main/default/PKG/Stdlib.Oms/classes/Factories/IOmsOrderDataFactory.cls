global interface IOmsOrderDataFactory {
    void preamble();
    SalesChannel createSalesChannel(String name);
    Order createOrder(String orderType, Account account, String orderNumber);
    Order getOrder(Id orderId);
    OrderSummary createOrderSummary(String orderType);
    OrderSummary createOrderSummary(String orderType, Account account, String orderNum);
    OrderSummary getOrderSummary(Id summaryId);
    OrderSummary getOrderSummaryByOrder(Id orderId);
    Order createOrderAdjust(OrderSummary summary, FulfillmentOrder fulfillmentOrder);
    Order createOrderChange(OrderSummary summary, FulfillmentOrder fulfillmentOrder);
    CreditMemo createCreditMemo(Id summaryId, Id changeOrderId);
    List<FulfillmentOrder> createFulfillmentOrders(String orderType, Id orderSummaryId, Account account);
    List<FulfillmentOrder> getFulfillmentOrders(Id orderSummaryId);
    PaymentLineInvoice createPayment(Decimal amount, Id invoiceId, Id orderSummaryId);
    RefundLinePayment createRefund(Decimal amount, PaymentLineInvoice paymentLineInvoice);
    FulfillmentOrder invoiceFulfillmentOrder(FulfillmentOrder fulfillmentOrder, Integer createInvoiceMode);
}