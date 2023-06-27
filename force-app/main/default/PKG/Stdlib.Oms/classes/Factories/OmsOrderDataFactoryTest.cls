@isTest
class OmsOrderDataFactoryTest {
    static void setup() {
        OmsOrderDataFactory.get.preamble();
    }
    
    @isTest static void shouldCreateSalesChannel() {
        setup();
        Test.startTest();
        SalesChannel actual = OmsOrderDataFactory.get.createSalesChannel('default');
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
    
    @isTest static void shouldCreateOrder() {
        setup();
        Test.startTest();
        Order actual = OmsOrderDataFactory.get.createOrder('Standard', null, 'TestOrder');
        Order actual2 = OmsOrderDataFactory.get.getOrder(actual.Id);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
    }
    
    @isTest static void shouldCreateOrderSummary() {
        setup();
        Test.startTest();
        OrderSummary actual = OmsOrderDataFactory.get.createOrderSummary('Standard');
        OrderSummary actual2 = OmsOrderDataFactory.get.createOrderSummary('Standard', null, 'TestOrder2');
        OrderSummary actual3 = OmsOrderDataFactory.get.getOrderSummary(actual.Id);
        OrderSummary actual4 = OmsOrderDataFactory.get.getOrderSummaryByOrder(actual.OriginalOrderId);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
        System.assert(actual3 != null, 'Should be value');
        System.assert(actual4 != null, 'Should be value');
    }

    @isTest(SeeAllData=true) static void shouldCreateOrderChange() {
        setup();
        OrderSummary order = OmsOrderDataFactory.get.createOrderSummary('Standard');
        FulfillmentOrder fulfillment = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', order.Id, null)[0];
        OmsOrderDataFactory.get.invoiceFulfillmentOrder(fulfillment, 0);
        Test.startTest();
        Order actual = OmsOrderDataFactory.get.createOrderAdjust(order, fulfillment);
        Order actual2 = OmsOrderDataFactory.get.createOrderChange(order, fulfillment);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
    }

    @isTest(SeeAllData=true) static void shouldCreateCreditMemo() {
        setup();
        OrderSummary order = OmsOrderDataFactory.get.createOrderSummary('Standard');
        FulfillmentOrder fulfillment = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', order.Id, null)[0];
        OmsOrderDataFactory.get.invoiceFulfillmentOrder(fulfillment, 0);
        Order changeOrder = OmsOrderDataFactory.get.createOrderAdjust(order, fulfillment);
        Test.startTest();
        CreditMemo actual = OmsOrderDataFactory.get.createCreditMemo(order.Id, changeOrder.Id);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }

    @isTest static void shouldCreateFulfillmentOrder() {
        setup();
        OrderSummary order = OmsOrderDataFactory.get.createOrderSummary('Standard');
        Test.startTest();
        FulfillmentOrder actual = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', order.Id, null)[0];
        FulfillmentOrder actual2 = OmsOrderDataFactory.get.getFulfillmentOrders(order.Id)[0];
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
    }

    @isTest(SeeAllData=true) static void shouldCreatePayment() {
        setup();
        OrderSummary order = OmsOrderDataFactory.get.createOrderSummary('Standard');
        FulfillmentOrder fulfillment = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', order.Id, null)[0];
        OmsOrderDataFactory.get.invoiceFulfillmentOrder(fulfillment, 0);
        Test.startTest();
        PaymentLineInvoice actual = OmsOrderDataFactory.get.createPayment(1.0, fulfillment.InvoiceId, order.Id);
        RefundLinePayment actual2 = OmsOrderDataFactory.get.createRefund(1.0, actual);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual2 != null, 'Should be value');
    }
    
    @isTest(SeeAllData=true) static void shouldInvoiceFulfillmentOrder() {
        setup();
        OrderSummary order = OmsOrderDataFactory.get.createOrderSummary('Standard');
        FulfillmentOrder fulfillment = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', order.Id, null)[0];
        Test.startTest();
        FulfillmentOrder actual = OmsOrderDataFactory.get.invoiceFulfillmentOrder(fulfillment, 0);
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
        System.assert(actual.invoiceId != null, 'Should be value');
    }
}