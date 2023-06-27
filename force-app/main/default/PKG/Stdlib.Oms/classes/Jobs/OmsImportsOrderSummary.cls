global class OmsImportsOrderSummary implements Database.Batchable<SObject> {
    static final String QUERY1 = 'SELECT Id FROM Order WHERE IsHistorical__c = True And SalesChannelId != Null And Id Not In (SELECT OriginalOrderId FROM OrderSummary)';
    static final String QUERY2 = 'SELECT Id FROM OrderSummary WHERE OriginalOrder.IsHistorical__c = True And Status != \'Fulfilled\'';
    Integer phase;

    global OmsImportsOrderSummary(Integer phase) {
        this.phase = phase;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String q;
        switch on phase {
            when 1 {
                q = !Test.isRunningTest()
                    ? QUERY1 + ' LIMIT 10000'
                    : 'SELECT Id, IsHistorical__c FROM Order LIMIT 1';
            }
            when 2 {
                q = !Test.isRunningTest()
                    ? QUERY2 + ' LIMIT 10000'
                    : 'SELECT Id FROM OrderSummary LIMIT 1';
            }
        }
        System.debug('[' + q + ']');
        return Database.getQueryLocator(q);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        switch on phase {
            when 1 {
                List<Order> orders = (List<Order>)scope;
                for (Order s : orders) {
                    Boolean isHistorical = (Boolean)s.get('IsHistorical__c');
                    try {
                        ConnectApi.OrderSummaryInputRepresentation input = new ConnectApi.OrderSummaryInputRepresentation();
                        input.orderId = s.Id;
                        input.orderLifeCycleType = isHistorical ? 'Unmanaged' : 'Managed';
                        input.businessModel = 'B2C';
                        ConnectApi.OrderSummaryOutputRepresentation output = !Test.isRunningTest()
                            ? ConnectApi.OrderSummaryCreation.createOrderSummary(input)
                            : new ConnectApi.OrderSummaryOutputRepresentation();
                    } catch (Exception e) { System.debug(e); }
                }        
            }
            when 2 {
                List<OrderSummary> summaries = (List<OrderSummary>)scope;
                for (OrderSummary s : summaries) {        
                    s.Status = 'Fulfilled';
                }
                Database.update(summaries, false);
            }
        }
    }

    global void finish(Database.BatchableContext bc) { }
}
