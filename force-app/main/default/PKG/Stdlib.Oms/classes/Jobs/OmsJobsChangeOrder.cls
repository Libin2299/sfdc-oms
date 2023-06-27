global class OmsJobsChangeOrder extends DatabaseJob {
    static final String QUERYX = 'SELECT Id, RelatedOrderId FROM Order WHERE RelatedOrderId != Null And Id Not In (SELECT Order__c FROM ChangeOrder__c)';

    class CustomAction extends DatabaseJob.CustomAction {
        OmsJobsChangeOrder parent;
        public CustomAction(OmsJobsChangeOrder parent) {
            this.parent = parent;
        }

        public override void execute(Object ctx, List<SObject> scope, Boolean allOrNone, List<Exception_SObject> exceptions) {
            this.parent.execute((List<Order>)scope, exceptions);
        }
    }

    global OmsJobsChangeOrder() {
        super(QUERYX, null);
        action = new CustomAction(this);
    }

    /**
    * @description batchable exception
    * @param scope the scope
    **/
    public override void handleExceptions(List<Exception_SObject> scope) { }

    /**
    * @description batchable execute
    * @param scope the scope
    * @param exceptions the exceptions
    **/
    void execute(List<Order> scope, List<Exception_SObject> exceptions) {
        // get summaryByRelatedOrderId
        Set<Id> relatedScope = new Set<Id>();
        for (Order s : [SELECT RelatedOrderId FROM Order WHERE Id in :scope]) {
            if (!relatedScope.contains(s.RelatedOrderId)) { relatedScope.add(s.RelatedOrderId); }
        }
        Map<Id, Id_String> tupleByRelatedOrderId = new Map<Id, Id_String>();
        for (Order s : [
            SELECT Id, (SELECT Id, Status FROM OrderSummaries LIMIT 1)
            FROM Order WHERE Id in :relatedScope
        ]) {
            OrderSummary orderSummary = !s.OrderSummaries.isEmpty() ? s.OrderSummaries[0] : null;
            tupleByRelatedOrderId.put(s.Id, new Id_String(orderSummary?.Id, orderSummary?.Status));
        }

        // insert change orders
        List<ChangeOrder__c> inserts = new List<ChangeOrder__c>();
        for (Order s : getChangeOrders(scope)) {
            if (!tupleByRelatedOrderId.containsKey(s.RelatedOrderId)) { continue; }
            Id_String tuple = tupleByRelatedOrderId.get(s.RelatedOrderId);
            String changeType = getChangeType(tuple.item2, s.OrderItems);
            String changeName = getChangeName(changeType, s);
            inserts.add(createChangeOrder(tuple.item1, changeName, changeType, s));
        }
        if (!inserts.isEmpty()) { Database.insert(inserts, false); }

        // execute flows
        // if (!inserts.isEmpty()) { executeFlow(inserts); }
    }

    // static void executeFlow(List<ChangeOrder__c> scope) {
    //     for (ChangeOrder__c s : scope) {
    //         try {
    //             if (Test.isRunningTest()) { continue; }
    //             Flow.Interview.createInterview('Change_Order_Event_Flow_A', new Map<String, Object> {
    //                 'OrderId' => s.Id,
    //                 'OrderSummaryId' => s.OrderSummary__c
    //             }).start();
    //         }
    //         catch (Exception e) { }
    //     }
    // }

    /**
    * @description gets the change orders
    * @param scope the scope
    * @return List<Order>
    **/
    virtual List<Order> getChangeOrders(List<Order> scope) {
        return [
            SELECT Id, OrderNumber, RelatedOrderId, (SELECT Quantity FROM OrderItems)
            FROM Order WHERE Id in :scope
        ];
    }

    /**
    * @description gets the change type
    * @param summaryStatus the order summary status
    * @param items the order items
    * @return String
    **/
    virtual String getChangeType(String summaryStatus, List<OrderItem> items) {
        OrderItem item = items != null && items.size() > 0 ? items[0] : null;
        return summaryStatus == 'Canceled' ? 'Canceled'
            : summaryStatus == 'Created' || summaryStatus == 'Remorse' || summaryStatus == 'Activated' ? 'Remorse'
            : item != null && item.Quantity == 0 ? 'Refund'
            : 'Change';
    }

    /**
    * @description gets the change name
    * @param summaryStatus the order summary status
    * @param items the order item
    * @return String
    **/
    virtual String getChangeName(String type, Order order) {
        String fix = SystemX.options.environment().fix;
        switch on type {
            when 'Change' { fix += 'RX'; }
            when 'Refund' { fix += 'RS'; }
            when 'Canceled' { fix += 'RX'; }
            when else { fix += 'RX'; }
        }
        return fix + order.OrderNumber;
    }

    /**
    * @description creates a change order
    * @param orderSummaryId the orderSummaryId
    * @param name the name
    * @param type the type
    * @param order the order
    * @return String
    **/
    virtual ChangeOrder__c createChangeOrder(Id orderSummaryId, String name, String type, Order order) {
        return new ChangeOrder__c(
            Name = name,
            Type__c = type,
            OrderSummary__c = orderSummaryId,
            Order__c = order.Id,
            RelatedOrder__c = order.RelatedOrderId
        );
    }
}
