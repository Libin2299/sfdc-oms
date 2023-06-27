global class EnsureCapturesAsyncInputRepresentation {
    /**
    * @description the amount to capture
    **/
    @AuraEnabled global Double amount;
    /**
    * @description the comments to use
    **/
    @AuraEnabled global String comments;
    /**
    * @description the values to apply on success
    **/
    @AuraEnabled global String onSuccess;
    /**
    * @description the values to apply on failure
    **/
    @AuraEnabled global String onFailure;
}