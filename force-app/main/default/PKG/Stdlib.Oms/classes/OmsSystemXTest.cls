@isTest
class OmsSystemXTest {
   	static OrderSummary setup() {
        OmsOrderDataFactory.get.preamble();
        OrderSummary orderSummary = OmsOrderDataFactory.get.createOrderSummary('Standard');
        return orderSummary;
    }

    @isTest static void shouldPublishProcessException() {
        OrderSummary orderSummary = setup();
        Test.startTest();
        List<SObject> exceptions = new List<SObject> { OmsSystemX.createProcessException('message', 'High', orderSummary.Id, orderSummary.Id, 'description') };
        Boolean actual = EventBusX.publish(exceptions);
        Test.stopTest();
        System.assert(actual, 'Should Publish');
    }

    @isTest static void shouldDeleteOrderSummaries() {
        OrderSummary orderSummary = setup();
        Test.startTest();
        OmsSystemX.deleteOrderSummaries(new List<Id> { orderSummary.Id }, 'iamsure');
        Test.stopTest();
    }

    @isTest static void shouldFixOrphanPayments() {
        OrderSummary orderSummary = setup();
        Test.startTest();
        OmsSystemX.fixOrphanPayments('iamsure');
        Test.stopTest();
    }

    @isTest static void shouldOptions() {
        Test.startTest();
        IOmsOptions actual = OmsSystemX.options;
        Test.stopTest();
        System.assert(actual != null, 'Should be value');
    }
}