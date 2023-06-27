global class OmsSystemX {
    /**
    * @description creates a process exception
    * @param message the message
    * @param severity the severity (high)
    * @param orderSummaryId the orderSummaryId
    * @param attachedToId the attachedToId
    * @param description the description
    * @return SObject
    **/
    global static SObject createProcessException(String message, String severity, Id orderSummaryId, Id attachedToId, String description) {
        return new ProcessExceptionEvent(
            ExceptionType = 'OM Apply Failed',
            Message = StringX.clamp(message, 255),
            Severity = severity,
            OrderSummaryId = orderSummaryId,
            AttachedToId = attachedToId,
            Description = StringX.clamp(description, 2000)
        );
    }

    /**
    * @description deletes the order summaries
    * @param scope the scope or OrderSummary ids
    * @param password the password
    **/
    global static void deleteOrderSummaries(List<Id> scope, String password) {
        if (password != 'iamsure') { throw new HandledException('are you sure?'); }

        // get order object
        List<OrderSummary> orderSummaries = new List<OrderSummary>();
        List<Order> orders = new List<Order>();
        List<Id> originalOrderScope = new List<Id>();
        for (OrderSummary s : [SELECT Id, OriginalOrderId, OrderNumber FROM OrderSummary WHERE Id In :scope]) {
            System.debug(s.OrderNumber);
            orderSummaries.add(new OrderSummary(Id = s.Id, Status = 'Cancelled'));
            orders.add(new Order(Id = s.OriginalOrderId, Status = 'Draft'));
            originalOrderScope.add(s.OriginalOrderId);
        }
        List<Order> changeOrders = new List<Order>([SELECT Id FROM Order WHERE RelatedOrderId In :originalOrderScope]);
        for (Order s : changeOrders) {
            s.Status = 'Draft';
        }
        List<FulfillmentOrder> fulfillments = new List<FulfillmentOrder>([SELECT Id FROM FulfillmentOrder WHERE OrderSummaryId In :scope]);

        // get payment objects
        List<Id> paymentMethodScope = new List<Id>();
        List<PaymentGroup> paymentGroups = new List<PaymentGroup>([SELECT Id FROM PaymentGroup WHERE SourceObjectId In :originalOrderScope]);
        List<PaymentAuthorization> paymentAuthorizations = new List<PaymentAuthorization>([SELECT Id, PaymentMethodId FROM PaymentAuthorization WHERE OrderPaymentSummary.OrderSummaryId In :scope]);
        for (PaymentAuthorization s : paymentAuthorizations) {
            s.Status = 'Canceled';
            paymentMethodScope.add(s.PaymentMethodId);
        }
        List<CardPaymentMethod> cardPaymentMethods = new List<CardPaymentMethod>([SELECT Id FROM CardPaymentMethod WHERE Id In :paymentMethodScope]);
        for (CardPaymentMethod s : cardPaymentMethods) {
            s.Status = 'Canceled';
        }

        // delete objects
        Database.update(cardPaymentMethods, false);
        Database.delete(cardPaymentMethods, false);
        Database.update(paymentAuthorizations, false);
        Database.delete(paymentGroups, true);
        Database.delete(fulfillments, true);
        Database.delete(orderSummaries, true);
        Database.update(changeOrders, true);
        Database.update(orders, true);
        Database.delete(changeOrders, true);
        Database.delete(orders, true);
    }
    
    /**
    * @description fixes orphan payments
    * @param password the password
    **/
    global static void fixOrphanPayments(String password) {
        if (password != 'iamsure') { throw new HandledException('are you sure?'); }

        // fix payments
        List<Payment> payments = [
            SELECT Id, PaymentAuthorization.OrderPaymentSummaryId FROM Payment WHERE OrderPaymentSummaryId = Null];
        for (Payment s : payments) {
            s.OrderPaymentSummaryId = s.PaymentAuthorization.OrderPaymentSummaryId;
        }
        Database.update(payments, false);

        // fix paymentgatewaylog
        List<PaymentGatewayLog> logs = [
            SELECT Id, TYPEOF ReferencedEntity
                WHEN PaymentAuthorization THEN OrderPaymentSummaryId
                WHEN Payment THEN OrderPaymentSummaryId
            END
            FROM PaymentGatewayLog WHERE ReferencedEntityId != Null And OrderPaymentSummaryId = Null];
        for (PaymentGatewayLog s : logs) {
            if (s.ReferencedEntity instanceOf PaymentAuthorization) {
                s.OrderPaymentSummaryId = ((PaymentAuthorization)s.ReferencedEntity).OrderPaymentSummaryId;
            }
            else if (s.ReferencedEntity instanceOf Payment) {
                s.OrderPaymentSummaryId = ((Payment)s.ReferencedEntity).OrderPaymentSummaryId;
            }
        }
        Database.update(logs, false);
    }

    /**
    * @description the options
    **/
    global static IOmsOptions options = (IOmsOptions)SystemX.getOptions(DefaultOmsOptions.class);
}