@isTest public class AmwareJobExportFulfillmentOrders implements Database.Batchable<sObject> {
    public static final String GATEWAY_SUCCESS = 'Send: Fulfillment Order sent successfully';
	public static final String GATEWAY_FAIL = 'Send: Fulfillment Order failed to send';

    class Order {
        String ReferenceNumber1;
        String PoNumber;
        Address Shipping;
        List<LineItem> LineItems;
    }

    class Address {
        String FirstName;
        String LastName;
        String Company;
        String Address1;
        String Address2;
        String City;
        String State;
        String Zip;
        String Phone;
    }

    class LineItem {
        String Quantity;
        String Item;
        String UnitOfMeasure;
        String Upc;
        String OrderLineNumber;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id ' +
            'FROM FulfillmentOrder WHERE Status = \'Allocated\' And AmwareStatus__c = null'
        );
    }

    public void execute(Database.BatchableContext bc, List<FulfillmentOrder> scope) {
        List<SObject> logs = new List<SObject>();
        List<FulfillmentOrder> updates = new List<FulfillmentOrder>();

		for (FulfillmentOrder s : [
			SELECT Id, FulfillmentOrderNumber,
            OrderSummary.OrderNumber, OrderSummary.SalesChannel.SalesChannelName,
            AccountId, Account.Name, FulfilledToName, FulfilledToStreet, FulfilledToCity, FulfilledToState, FulfilledToPostalCode, FulfilledToPhone, (
                SELECT Quantity, FulfillmentOrderLineItemNumber, OrderItem.Product2.ProductCode
                FROM FulfillmentOrderLineItems)
			FROM FulfillmentOrder WHERE Id In :scope]) {
            OrderSummary orderSummary = s.OrderSummary;

            // send order
            String gatewayMessage = GATEWAY_SUCCESS;
            String errorMessage = null;
            Map<String, Object> req;
            HttpResponse res;
            try {
                // make order
                Order obj = new Order();
                obj.ReferenceNumber1 = s.FulfillmentOrderNumber;
                obj.PoNumber = orderSummary.OrderNumber;
                Address ship = obj.Shipping = new Address();
                //TODO: Which fields for name?
                ship.FirstName = s.FulfilledToName;
                ship.LastName = '';
                ship.Company = s.Account.Name;
                ship.Address1 = s.FulfilledToStreet;
                // ship.Address2 = s.FulfilledToStreet2;
                ship.City = s.FulfilledToCity;
                ship.State = s.FulfilledToState;
                ship.Zip = s.FulfilledToPostalCode;
                ship.Phone = s.FulfilledToPhone;
                ship.City = s.FulfilledToCity;
                ship.Phone = s.FulfilledToPhone;
                List<LineItem> lines = obj.LineItems = new List<LineItem>();
                for (FulfillmentOrderLineItem i : s.FulfillmentOrderLineItems) {
                    LineItem item = new LineItem();
                    item.Quantity = String.valueOf(i.Quantity);
                    item.Item = i.OrderItem.Product2.ProductCode;
                    item.UnitOfMeasure = 'EA';
                    item.Upc = i.OrderItem.Product2.ProductCode;
                    item.OrderLineNumber = String.valueOf(i.FulfillmentOrderLineItemNumber);
                }

                // make http callout
                req = new Map<String, Object> {
                    'method' => 'POST',
                    'endpoint' => '/order/order',
                    'body' => obj
                };
                res = CloudX.callout('Amware', null, req);
                if (res.getStatusCode() == 200) {
					gatewayMessage = GATEWAY_SUCCESS;
					updates.add(new FulfillmentOrder(Id = s.Id, AmwareStatus__c = 'Sent', AmwareSentOn__c = Datetime.now()));
                } else {
					gatewayMessage = GATEWAY_FAIL;
					updates.add(new FulfillmentOrder(Id = s.Id, AmwareStatus__c = 'Failed'));
				}
            } catch (Exception e) {
                gatewayMessage = GATEWAY_FAIL;
                errorMessage = String.format('{0} at: {1} Caused by: {2}, {3}', new Object[] { e.getMessage(), e.getLineNumber(), e.getStackTraceString(), e.getCause() });
                System.debug(System.LoggingLevel.ERROR, errorMessage);
                updates.add(new FulfillmentOrder(Id = s.Id, AmwareStatus__c = 'Failed'));
            } finally {
                logs.add(new WmsGatewayLogBuilder()
                    .interactionType('Fulfillment')
                    .relatedTo(orderSummary.Id)
                    .withRequest(req)
                    .withResponse(res)
                    .withErrorMessage(errorMessage)
                    .withGatewayMessage(gatewayMessage)
                    .build());
            }
		}

        if (!logs.isEmpty()) { insert logs; }
    }    
    
    public void finish(Database.BatchableContext bc) { } 
}