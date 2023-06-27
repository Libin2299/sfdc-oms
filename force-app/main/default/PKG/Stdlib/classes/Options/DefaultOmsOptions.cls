global virtual class DefaultOmsOptions implements IOmsOptions {
    /**
    * @description gets the factory TestOrder name
    * @return String
    **/
    global virtual String factoryTestOrder() { return 'TestOrder'; }

    /**
    * @description gets the factory SalesChannel name
    * @return String
    **/
    global virtual String factorySalesChannel() { return 'JSS'; }

    /**
    * @description gets the factory DeliveryMethod name
    * @return String
    **/
    global virtual String factoryDeliveryMethod() { return 'ABC'; }

    /**
    * @description gets the factory PaymentGateway name
    * @return String
    **/
    global virtual String factoryPaymentGateway() { return 'NOP'; }

    /**
    * @description gets the createFulfillmentOrdersFlow name
    * @return String
    **/
    global virtual String createFulfillmentOrdersFlow() { return 'Create_Fulfillment_Orders'; }

    /**
    * @description gets the createInvoiceAndEnsureFundsFlow name
    * @return String
    **/
    global virtual String createInvoiceAndEnsureFundsFlow() { return 'Create_Invoice_and_Ensure_Funds'; }
}