global class ConnectApiX {
    global class AuthorizationResponse {
        /**
        * @description Error representation for Payment Authorization.
        **/
        global ErrorResponse error;
        /**
        * @description Gateway response representation for payment authorization.
        **/
        global AuthorizationGatewayResponse gatewayResponse;
        /**
        * @description Payment authorization representation.
        **/
        global PaymentAuthorizationResponse paymentAuthorization;
    }

    global class ErrorResponse {
        /**
        * @description Error code.
        **/
        global String errorCode;
        /**
        * @description More error detail, if available.
        **/
        global String message;
    }
    
    global class AuthorizationGatewayResponse {
        /**
        * @description Authorization code for the payment gateway.
        **/
        global String gatewayAuthorizationCode;
        /**
        * @description Address verification system used for tokenization in the payment gateway.
        **/
        global String gatewayAvsCode;
        /**
        * @description The date that the payment gateway processed the payment transaction.
        **/
        global String gatewayDate;
        /**
        * @description Optional method that the payment gateway returns to provide more information on the status of a payment transaction.
        **/
        global String gatewayMessage;
        /**
        * @description Gateway reference details.
        **/
        global String gatewayReferenceDetails;
        /**
        * @description Gateway reference number.
        **/
        global String gatewayReferenceNumber;
        /**
        * @description Gateway result code. Indicates the result of the gateway processing the payment transaction. Result codes for between different gateway providers. Must be mapped to a Salesforce result code.
        **/
        global String gatewayResultCode;
        /**
        * @description Provides more information about the result code.
        **/
        global String gatewayResultCodeDescription;
        /**
        * @description Salesforce result code. Must be set based on the value of the gateway result code.
        **/
        global String salesforceResultCode;
    }

    global class PaymentAuthorizationResponse {
        /**
        * @description ID of the payment authorization record.
        **/
        global Id id;
    }
}