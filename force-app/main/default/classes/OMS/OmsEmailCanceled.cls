public class OmsEmailCanceled extends CloudXSfmcTrigger implements CloudX.HasArgs {
    public Id orderSummaryId;
    public String orderItemSummaryIdStr;
    public final String GATEWAY_SUCCESS = 'Successfully sent SFMC Cancel email';
	public final String GATEWAY_FAIL = 'Failed to send SFMC Cancel email';
    public final String CLASS_NAME = OmsEmailCanceled.class.getName();
    public final String ERROR_MESSAGE = 'SFMC Cancel email failed to send and it\'s Order Summary Id: ';
    public HttpResponse res;
    public Integer statusCode;
    
    public void setArgs(Map<String, Object> args) {
        orderSummaryId = (Id)args.get('entityId');
        orderItemSummaryIdStr = (String)args.get('entityChildIds');
    }

    public override String execute(TriggerContext ctx) {
        try {
            List<OrderSummary> orderSummarys = [
                SELECT Id, Account.ContactID__pc, Account.Name, CurrencyIsoCode, GrandTotalAmount, SalesChannelId, SalesChannel.SalesChannelName, OrderNumber,
                BillingEmailAddress, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                FROM OrderSummary WHERE Id = :orderSummaryId];
            if (orderSummarys.size() == 0) { return 'OK'; }
            OrderSummary s = orderSummarys[0];

            // get lineitems
            List<Map<String, String>> lineItems = new List<Map<String, String>>();
            List<String> orderItemSummaryIds = orderItemSummaryIdStr.split(',');
            List<OrderItemSummary> updateOrderItemSummary = new List<OrderItemSummary>();
            for (OrderItemSummary x : [
                SELECT Id, Name, ProductCode, QuantityCanceled, OriginalOrderItem.TotalPrice, QuantityReturned, (SELECT Reason FROM OrderItemSummaries)
                FROM OrderItemSummary WHERE OrderSummaryId = :orderSummaryId And QuantityCanceled != 0 AND Id IN :orderItemSummaryIds AND Type = 'Order Product']) {
                Map<String, String> item = new Map<String, String>();
                MapX.putIfNotNull(item, 'Name', x.Name);
                MapX.putIfNotNull(item, 'TotalPrice', NumericX.formatCurrency(x.OriginalOrderItem.TotalPrice, s.CurrencyIsoCode));
                MapX.putIfNotNull(item, 'Quantity', x.QuantityCanceled);
                MapX.putIfNotNull(item, 'ProductId', x.ProductCode);
                lineItems.add(item);
                x.SFMC_Cancel_Email_Sent__c = true;
                updateOrderItemSummary.add(x);
            }

            // post value
            List<OrderItemSummaryChange> orderItemSummaryChanges = [SELECT Id, Reason FROM OrderItemSummaryChange WHERE OrderSummaryId = :orderSummaryId ORDER BY CreatedDate DESC LIMIT 1];
            ctx.endpoint = 'oms.orderCancel';
            ctx.address = s.BillingEmailAddress;
            ctx.subscriberKey = s.Account.ContactID__pc;
            ctx.contactAttributes = new Map<String, Object> {
                'SubscriberAttributes' => new Map<String, Object> {
                    'EmailAddress' => s.BillingEmailAddress,
                    'OrderNumber' => s.OrderNumber,
                    'SiteID' => s.SalesChannel.SalesChannelName,
                    'AmountCurrencyCode' => s.CurrencyIsoCode,
                    'AccountName' => s.Account.Name,
                    'ReasonCode' => !orderItemSummaryChanges.isEmpty() ? orderItemSummaryChanges[0].Reason : null,
                    'OrderDetailsJSON' => JSON.serialize(new Map<String, Object> {
                        'LineItems' => lineItems
                    }).replace('"','\\"')
                }
            };
            res = post(ctx);
            statusCode = res.getStatusCode();
            if (statusCode == 200 || statusCode == 202) {
                if (!updateOrderItemSummary.isEmpty()) { 
                    update updateOrderItemSummary; 
                }
            } else {
                CustomCommonUtil.logCallout(CLASS_NAME, ctx.toString(), res.getBody(), statusCode, 
                                                GATEWAY_FAIL, ERROR_MESSAGE + orderSummaryId, orderSummaryId);
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return 'OK';
    }
}