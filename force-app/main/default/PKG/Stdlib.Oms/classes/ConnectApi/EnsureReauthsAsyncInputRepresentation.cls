global class EnsureReauthsAsyncInputRepresentation {
    /**
    * @description the payment authorization id
    **/
    @AuraEnabled global Id paymentAuthId; 
    /**
    * @description the comments to use
    **/
    @AuraEnabled global String comments;
}