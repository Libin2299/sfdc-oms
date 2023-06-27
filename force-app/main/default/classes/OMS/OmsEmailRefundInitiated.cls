public class OmsEmailRefundInitiated extends CloudXSfmcTrigger implements CloudX.HasArgs {
    public Id returnOrderId;
    public Id osId;
    public final String GATEWAY_SUCCESS = 'Successfully sent SFMC Return Intiated email';
	public final String GATEWAY_FAIL = 'Failed to send SFMC Return Intiated email';
    public final String CLASS_NAME = OmsEmailRefundInitiated.class.getName();
    public final String ERROR_MESSAGE = 'SFMC Return Intiated email failed to send and it\'s Return Order Id: ';
    public HttpResponse res;
    public Integer statusCode;
    
    public void setArgs(Map<String, Object> args) {
        returnOrderId = (Id)args.get('entityId');
    }

    public override String execute(TriggerContext ctx) {
        String reasonCode;
        try {
            List<ReturnOrder> roList = [
                SELECT Id, Account.ContactID__pc, Account.Name, CurrencyIsoCode, TotalAmount, GrandTotalAmount, OrderSummary.SalesChannelId, 
                OrderSummary.SalesChannel.SalesChannelName, OrderSummary.OrderNumber, OrderSummary.BillingEmailAddress, OrderSummary.BillingStreet,
                OrderSummary.BillingCity, OrderSummary.BillingState, OrderSummary.BillingPostalCode, OrderSummary.BillingCountry FROM ReturnOrder WHERE Id = :returnOrderId];
            if (roList.size() == 0) { return 'OK'; }
            ReturnOrder ro = roList[0];
            osId = ro.OrderSummary.Id;
            List<ReturnOrder> roListToUpdate = new List<ReturnOrder>();
            // get lineitems
            List<Map<String, String>> lineItems = new List<Map<String, String>>();
            for (ReturnOrderLineItem roLine : [SELECT Id, OrderItemSummary.Name, OrderItemSummary.ProductCode, ReasonForReturn, QuantityExpected, QuantityReceived,
                TotalLineAmount, TotalLineTaxAmount, TotalLineAmountWithTax, TotalAdjustmentAmount, TotalAdjustmentTaxAmount, TotalAdjustmentAmountWithTax, 
                TotalTaxAmount, TotalAmount FROM ReturnOrderLineItem WHERE ReturnOrderId = :returnOrderId]) {
                    reasonCode = roLine.ReasonForReturn;
                    Map<String, String> item = new Map<String, String>();
                    MapX.putIfNotNull(item, 'Name', roLine.OrderItemSummary.Name);
                    MapX.putIfNotNull(item, 'ProductId', roLine.OrderItemSummary.ProductCode);
                    MapX.putIfNotNull(item, 'Quantity', roLine.QuantityExpected);
                    MapX.putIfNotNull(item, 'TotalPrice', NumericX.formatCurrency(roLine.TotalAmount, ro.CurrencyIsoCode));
                    MapX.putIfNotNull(item, 'Reason', reasonCode);
                    MapX.putIfNotNull(item, 'TotalLineAmount', NumericX.formatCurrency(roLine.TotalLineAmount, ro.CurrencyIsoCode));
                    MapX.putIfNotNull(item, 'TotalLineTaxAmount', NumericX.formatCurrency(roLine.TotalLineTaxAmount, ro.CurrencyIsoCode));
                    MapX.putIfNotNull(item, 'TotalLineAmountWithTax', NumericX.formatCurrency(roLine.TotalLineAmountWithTax, ro.CurrencyIsoCode));
                    MapX.putIfNotNull(item, 'TotalAdjustmentAmount', NumericX.formatCurrency(roLine.TotalAdjustmentAmount, ro.CurrencyIsoCode));
                    MapX.putIfNotNull(item, 'TotalAdjustmentTaxAmount', NumericX.formatCurrency(roLine.TotalAdjustmentTaxAmount, ro.CurrencyIsoCode));
                    MapX.putIfNotNull(item, 'TotalAdjustmentAmountWithTax', NumericX.formatCurrency(roLine.TotalAdjustmentAmountWithTax, ro.CurrencyIsoCode));
                    MapX.putIfNotNull(item, 'TotalTaxAmount', NumericX.formatCurrency(roLine.TotalTaxAmount, ro.CurrencyIsoCode));
                    lineItems.add(item);
            }

            // post value
            ctx.endpoint = 'oms.returnOrderCreated';
            ctx.address = ro.OrderSummary.BillingEmailAddress;
            ctx.subscriberKey = ro.Account.ContactID__pc;
            ctx.contactAttributes = new Map<String, Object> {
                'SubscriberAttributes' => new Map<String, Object> {
                    'EmailAddress' => ro.OrderSummary.BillingEmailAddress,
                    'OrderNumber' => ro.OrderSummary.OrderNumber,
                    'SiteID' => ro.OrderSummary.SalesChannel.SalesChannelName,
                    'AmountCurrencyCode' => ro.CurrencyIsoCode,
                    'AccountName' => ro.Account.Name,
                    'ReasonCode' => reasonCode,
                    'OrderDetailsJSON' => JSON.serialize(new Map<String, Object> {
                        'LineItems' => lineItems
                    }).replace('"','\\"')
                }
            };
            res = post(ctx);
            statusCode = res.getStatusCode();
            if (statusCode == 200 || statusCode == 202) {
                ro.SFMC_RefundInitiated_Email_Sent__c = true;
                update ro; 
            } else {
                CustomCommonUtil.logCallout(CLASS_NAME, ctx.toString(), res.getBody(), statusCode, 
                                                GATEWAY_FAIL, ERROR_MESSAGE + ro.Id, ro.Id);
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(CLASS_NAME, ex);
        }
        return 'OK';
    }
}