public class YotpoService implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public static final String GATEWAY_SUCCESS = 'Send: Yotpo sent successfully';
	public static final String GATEWAY_FAIL = 'Send: Yotpo failed to send';
	public static String interactionType = '';
    public class Refund {
        public String id;
        public String order_id;
        public Integer total_amount_cents;
        public List<RefundItem> items;
        public String currencyx;
    }

    public class RefundItem {
        public String id;
        public Integer quantity;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Action__c, Amount__c, OrderSummary__c, OrderSummary__r.OrderNumber FROM LoyaltyTransaction__c WHERE GatewayStatus__c = null');
    }

    public void execute(Database.BatchableContext bc, List<LoyaltyTransaction__c> scope) {
        List<SObject> logs = new List<SObject>();
        NamedCredential__mdt cred = NamedCredential__mdt.getInstance('Yotpo');
        for (LoyaltyTransaction__c s : scope) {
            interactionType = s.Action__c;
            String gatewayMessage = null;
            String errorMessage = null;
            HttpResponse res = null;
            Map<String, Object> req;
            try {
                switch on s.Action__c {
                    // https://loyaltyapi.yotpo.com/reference/create-refund
                    when 'Refund', 'Cancel', 'Discount' {
                        Refund obj = new Refund();
                        obj.id = s.Id;
                        obj.order_id = s.OrderSummary__r.OrderNumber;
                        obj.total_amount_cents = (Integer)(s.Amount__c * 100).round(System.RoundingMode.CEILING);
                        req = new Map<String, Object> {
                            'x-api-key' => cred.ClientId__c,
                            'x-guid' => cred.ClientSecret__c,
                            'method' => 'POST',
                            'endpoint' => '/refunds',
                            'body' => JSON.serializePretty(obj)
                        };
                    }
                }
                res = CloudX.callout('yotpo/api/v2', null, req);
                if (res.getStatusCode() == 201) {
					gatewayMessage = GATEWAY_SUCCESS;
					s.GatewayStatus__c = 'Sent';
                    s.GatewaySentOn__c = Datetime.now();
                } else {
					gatewayMessage = GATEWAY_FAIL;
					s.GatewayStatus__c = 'Failed';
				}
                System.debug(res.getBody());
            } catch (Exception e) {
                gatewayMessage = GATEWAY_FAIL;
                errorMessage = e.getMessage() + '\n' + e.getStackTraceString();
                System.debug(System.LoggingLevel.ERROR, errorMessage);
                s.GatewayStatus__c = 'Failed';
                errorMessage = String.format('Exception Type:  {0},   Error Message:  {1},  LineNumber:  {2}, StackTrace: {3}',
                                                   new Object[] { e.getTypeName() , e.getMessage(), e.getLineNumber(), e.getStackTraceString() });
                insert new GenericGatewayLog__c(InteractionType__c = 'LoyaltyTransaction__c', ErrorMessage__c = errorMessage);
            } finally {
                req.remove('x-api-key');
                req.remove('x-guid');
                logs.add(new LoyaltyGatewayLogBuilder()
                    .interactionType(interactionType)
                    .relatedTo(s.OrderSummary__c)
                    .withRequest(req)
                    .withResponse(res)
                    .withErrorMessage(errorMessage)
                    .withGatewayMessage(gatewayMessage)
                    .build());
            }
        }

        if (!scope.isEmpty()) { Database.update(scope, false); }
        if (!logs.isEmpty()) { insert logs; }
	}

    public void finish(Database.BatchableContext bc) {}
}