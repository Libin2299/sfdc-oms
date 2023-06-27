public class OmsEmailRefundComplete extends CloudXSfmcTrigger implements CloudX.HasArgs {
    public Id creditMemoId;
    public final String GATEWAY_SUCCESS = 'Successfully sent SFMC Return Complete email';
	public final String GATEWAY_FAIL = 'Failed to send SFMC Return Complete email';
    public final String CLASS_NAME = OmsEmailRefundComplete.class.getName();
    public final String ERROR_MESSAGE = 'SFMC Return Complete email failed to send and it\'s CreditMemo Id: ';
    public HttpResponse res;
    public Integer statusCode;
    
    public void setArgs(Map<String, Object> args) {
        creditMemoId = (Id)args.get('entityId');
    }

    public override String execute(TriggerContext ctx) {
        try {
            Integer statusCode;
            List<CreditMemo> creditMemoList = [SELECT Id, ReferenceEntityId, CurrencyIsoCode FROM CreditMemo WHERE Id = :creditMemoId];
            Id osId = creditMemoList.get(0).ReferenceEntityId;
            OrderSummary os = [SELECT Account.ContactID__pc, CurrencyIsoCode, Account.Name, SalesChannelId, SalesChannel.SalesChannelName, OrderNumber, BillingEmailAddress, BillingStreet, BillingCity, BillingState, BillingPostalCode, OrderSummary.BillingCountry FROM OrderSummary WHERE Id = :osId];
            if (creditMemoList.size() == 0) { return 'OK'; }
            CreditMemo cm = creditMemoList[0];

            // get lineitems
            List<Map<String, String>> lineItems = new List<Map<String, String>>();
            //List<String> orderItemSummaryIds = orderItemSummaryIdStr.split(',');
            for (CreditMemoLine  cmLine : [SELECT Id, Name, Product2.ProductCode, LineAmount, ChargeAmount, ChargeAmountWithTax, ChargeTaxAmount, Type FROM CreditMemoLine WHERE CreditMemoId = :creditMemoId AND Type = 'Charge']) {
                Map<String, String> item = new Map<String, String>();
                MapX.putIfNotNull(item, 'Name', cmLine.Name);
                MapX.putIfNotNull(item, 'ProductId', cmLine.Product2.ProductCode);
                MapX.putIfNotNull(item, 'LineAmount', NumericX.formatCurrency(cmLine.LineAmount, cm.CurrencyIsoCode));
                MapX.putIfNotNull(item, 'ChargeTaxAmount', NumericX.formatCurrency(cmLine.ChargeTaxAmount, cm.CurrencyIsoCode));
                MapX.putIfNotNull(item, 'ChargeAmountWithTax', NumericX.formatCurrency(cmLine.ChargeAmountWithTax, cm.CurrencyIsoCode));
                lineItems.add(item);
            }

            // post value
            //List<OrderItemSummaryChange> orderItemSummaryChanges = [SELECT Id, Reason FROM OrderItemSummaryChange WHERE OrderSummaryId = :orderSummaryId ORDER BY CreatedDate DESC LIMIT 1];
            ctx.endpoint = 'oms.invoiceProcessed';
            ctx.address = os.BillingEmailAddress;
            ctx.subscriberKey = os.Account.ContactID__pc;
            ctx.contactAttributes = new Map<String, Object> {
                'SubscriberAttributes' => new Map<String, Object> {
                    'EmailAddress' => os.BillingEmailAddress,
                    'OrderNumber' => os.OrderNumber,
                    'SiteID' => os.SalesChannel.SalesChannelName,
                    'AmountCurrencyCode' => os.CurrencyIsoCode,
                    'AccountName' => os.Account.Name,
                    'ReasonCode' => 'Wrong Item',
                    'OrderDetailsJSON' => JSON.serialize(new Map<String, Object> {
                        'LineItems' => lineItems
                    }).replace('"','\\"')
                }
            };
            res = post(ctx);
            statusCode = res.getStatusCode();
            if (statusCode == 200 || statusCode == 202) {
                cm.SFMC_RefundComplete_Email_Sent__c = true;
                update cm;
            } else {
                CustomCommonUtil.logCallout(CLASS_NAME, ctx.toString(), res.getBody(), statusCode, 
                                                 GATEWAY_FAIL, ERROR_MESSAGE + cm.Id, cm.Id);
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return 'OK';
    }
}