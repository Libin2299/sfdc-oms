@isTest
class OmsPaymentXTest {
    static SObject[] setup() {
        IOmsOrderDataFactory factory = OmsOrderDataFactory.get;
        factory.preamble();
        OrderSummary orderSummary = factory.createOrderSummary('Standard');
        FulfillmentOrder fulfillmentOrder = factory.createFulfillmentOrders('Standard', orderSummary.Id, null)[0];
        fulfillmentOrder = factory.invoiceFulfillmentOrder(fulfillmentOrder, 0);
        Order order = factory.createOrderChange(orderSummary, fulfillmentOrder);
        CreditMemo creditMemo = factory.createCreditMemo(orderSummary.Id, order.id);

        // create payment + refund
        PaymentLineInvoice paymentLineInvoice = factory.createPayment(fulfillmentOrder.TotalAmount, fulfillmentOrder.InvoiceId, fulfillmentOrder.OrderSummaryId);
        factory.createRefund(fulfillmentOrder.TotalAmount, paymentLineInvoice);

        return new SObject[] { fulfillmentOrder, creditMemo };
    }

    @isTest(SeeAllData=true) static void shouldAssignCreditMemoReferenceRefund() {
        SObject[] args = setup();
        FulfillmentOrder fulfillmentOrder = (FulfillmentOrder)args[0];
        CreditMemo creditMemo = (CreditMemo)args[1];
        System.assertEquals('Allocated', fulfillmentOrder.Status, 'Should be value');
        System.assertNotEquals(null, fulfillmentOrder.InvoiceId, 'Should create an invoice');
        System.assertNotEquals(null, creditMemo, 'Should create a creditMemo');

        Test.startTest();
        OmsPaymentX.assignCreditMemoReferenceRefund();
        Test.stopTest();
    }
}