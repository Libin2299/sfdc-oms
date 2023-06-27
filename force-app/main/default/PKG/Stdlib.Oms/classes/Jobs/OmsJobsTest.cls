@isTest
class OmsJobsTest {
    static final String CRON_EXP = '0 0 23 * * ?';

    static OrderSummary setup(Boolean needsChangeOrder) {
        OmsOrderDataFactory.get.preamble();
        OrderSummary orderSummary = OmsOrderDataFactory.get.createOrderSummary('Standard');
        if (needsChangeOrder) {
            FulfillmentOrder fulfillment = OmsOrderDataFactory.get.createFulfillmentOrders('Standard', orderSummary.Id, null)[0];
            OmsOrderDataFactory.get.invoiceFulfillmentOrder(fulfillment, 0);
            Order changeOrder = OmsOrderDataFactory.get.createOrderAdjust(orderSummary, fulfillment);
        }
        return orderSummary;
    }

    @isTest static void shouldJobsCapture() {
        OrderSummary orderSummary = setup(false);
        orderSummary.Status = 'Ready to Capture';
        update orderSummary;

		Test.startTest();
        OmsJobsCapture action = new OmsJobsCapture();
        action.exceptions.add(new Exception_SObject(new HandledException('exception'), new OrderSummary()));
        action.setArgs(new Map<String, Object> {
            'flowField' => 'Capture_Upon_Order_Acceptance.OrderSummaryId',
            'values' => ((DatabaseJob.FlowRefAction)action.action).values
        });
        OmsJobsCapture.Queue action2 = new OmsJobsCapture.Queue();
        action2.exceptions.add(new Exception_SObject(new HandledException('exception'), new OrderSummary()));
        action2.setArgs(new Map<String, Object> {
            'flowField' => 'Capture_Upon_Order_Acceptance.OrderSummaryId',
            'values' => ((DatabaseJob.FlowRefAction)action2.action).values
        });
        OmsJobsCapture.Schedule action3 = new OmsJobsCapture.Schedule();
        action3.exceptions.add(new Exception_SObject(new HandledException('exception'), new OrderSummary()));
        action3.setArgs(new Map<String, Object> {
            'flowField' => 'Capture_Upon_Order_Acceptance.OrderSummaryId',
            'values' => ((DatabaseJob.FlowRefAction)action3.action).values
        });
        action.run();
        action2.run();
        action3.run();
		Test.stopTest();
    }

    @isTest(SeeAllData=true) static void shouldJobsChangeOrder() {
        OrderSummary orderSummary = setup(true);

		Test.startTest();
        OmsJobsChangeOrder action = new OmsJobsChangeOrder();
        action.exceptions.add(new Exception_SObject(new HandledException('exception'), new OrderSummary()));
        String actualQuery = action.query;
        action.run();
		Test.stopTest();
        System.assertEquals(actualQuery, 'SELECT Id, RelatedOrderId FROM Order WHERE RelatedOrderId != Null And Id Not In (SELECT Order__c FROM ChangeOrder__c)', 'Should be value');
    }

    @isTest(SeeAllData=true) static void shouldJobsPayment() {
        OrderSummary orderSummary = setup(true);

		Test.startTest();
        OmsJobsPayment action = new OmsJobsPayment();
        action.execute(null);
		Test.stopTest();
    }

    @isTest static void shouldJobsRemorse() {
        OrderSummary orderSummary = setup(false);
        orderSummary.Status = 'Remorse';
        update orderSummary;

		Test.startTest();
        OmsJobsRemorse action = new OmsJobsRemorse();
        action.exceptions.add(new Exception_SObject(new HandledException('exception'), new OrderSummary()));
        action.setArgs(new Map<String, Object> {
            'remorsePeriodMinutes' => 0
        });
        String actualQuery = action.query;
        action.run();
		Test.stopTest();
        System.assertEquals(actualQuery, 'SELECT Id, OrderedDate, (SELECT Id, ScheduleStatus FROM OrderSummaryRoutingSchedules WHERE ScheduleStatus=\'SCHEDULED\') FROM OrderSummary WHERE PickedupByRemorse__c = False And Status = \'Remorse\' And OrderedAgeInMinutes__c >= 0 LIMIT 500', 'Should be value');
    }
}