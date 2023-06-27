global abstract class LogBuilder {
    global protected final Map<Schema.SObjectType, String> relatedMap;
    global protected final Map<Field, String> fieldMap;
    global protected Boolean showMoreInfo = false;
    global protected final SObject log;

    global enum Field {
        InteractionType,
        GatewayMessage,
        ErrorMessage,
        Request,
        Response,
        ResultCode
    }

    global LogBuilder() {
        this.relatedMap = makeRelatedMap();
        this.fieldMap = makeFieldMap();
        this.log = createLog();
    }

    global protected virtual Map<Schema.SObjectType, String> makeRelatedMap() {
        return new Map<Schema.SObjectType, String> {};
    }
    
    global protected virtual Map<Field, String> makeFieldMap() {
        return new Map<Field, String> {
            Field.InteractionType => 'InteractionType__c',
            Field.GatewayMessage => 'GatewayMessage__c',
            Field.ErrorMessage => 'ErrorMessage__c',
            Field.Request => 'Request__c',
            Field.Response => 'Response__c',
            Field.ResultCode => 'ResultCode__c'
        };
    }

    global protected virtual SObject createLog() { throw new HandledException('getJobs() must be defined'); }

    /**
    * @description sets show more info
    * @param showMoreInfo the show more info
    * @return LogBuilder
    **/
    global LogBuilder showMoreInfo(Boolean showMoreInfo) {
        this.showMoreInfo = showMoreInfo;
        return this;
    }

    /**
    * @description sets interaction type
    * @param interactionType the interaction type
    * @return LogBuilder
    **/
    global LogBuilder interactionType(String interactionType) {
        if (interactionType == null) { return this; }
        this.log.put(fieldMap.get(Field.InteractionType), interactionType);
        return this;
    }

    /**
    * @description sets related to
    * @param relatedToId the related to Id
    * @return LogBuilder
    **/
    global LogBuilder relatedTo(Id relatedToId) {
        if (relatedToId == null) { return this; }
        String field = relatedMap.get(relatedToId.getSobjectType());
        if (field != null) { this.log.put(field, relatedToId); }
        return this;
    }

    /**
    * @description builds the log without inserting
    * @return SObject
    **/
    global SObject build() {
        if (UserInfoX.isSandboxOrganization()) { System.debug(toString()); }
        return this.log;
    }

    /**
    * @description builds the log with inserting
    * @return SObject
    **/
    global SObject buildAndLog() {
        if (UserInfoX.isSandboxOrganization()) { System.debug(toString()); }
        //Database.insert(this.log);
        return this.log;
    }

    /**
    * @description includes the gateway message
    * @param gatewayMessage the gateway message
    * @return LogBuilder
    **/
    global LogBuilder withGatewayMessage(String gatewayMessage) {
        if (gatewayMessage == null || !String.isNotBlank(gatewayMessage)) { return this; }
        this.log.put(fieldMap.get(Field.GatewayMessage), StringX.clamp(gatewayMessage, 255));
        return this;
    }

    /**
    * @description includes the error message
    * @param errorMessage the error message
    * @return LogBuilder
    **/
    global LogBuilder withErrorMessage(String errorMessage) {
        if (errorMessage == null || !String.isNotBlank(errorMessage)) { return this; }
        this.log.put(fieldMap.get(Field.ErrorMessage), StringX.clamp(errorMessage, 131072));
        return this;
    }

    /**
    * @description includes the request
    * @param req the request
    * @return LogBuilder
    **/
    global LogBuilder withRequest(Map<String, Object> args) {
        if (args == null) { return this; }
        Map<String, String> values = new Map<String, String>();
        if (this.showMoreInfo) {
            values.put('Endpoint:', String.valueOf(args.get('endPoint')));
            values.put('Content-Type:', String.valueOf(args.get('contentType')));
            values.put('HTTP Method:', String.valueOf(args.get('method')));
        }
        values.put('Body', JSON.serialize(args.get('body'))?.remove('\\n')?.remove('\\'));
        this.log.put(fieldMap.get(Field.Request), StringX.clamp(this.showMoreInfo
            ? getMapKeyValue('', values)
            : String.join(values.values(), ''), 131072));
        return this;
    }

    /**
    * @description includes the request
    * @param req the request
    * @return LogBuilder
    **/
    global LogBuilder withRequest(HttpRequest req) {
        if (req == null) { return this; }
        this.log.put(fieldMap.get(Field.Request), StringX.clamp(req.getBody(), 131072));
        return this;
    }

    /**
    * @description includes the request
    * @param req the request
    * @return LogBuilder
    **/
    global LogBuilder withRequest(RestRequest req) {
        if (req == null) { return this; }
        Map<String, String> values = new Map<String,String>();
        if (this.showMoreInfo) {
            values.put('Request URI:', String.valueOf(req.requestURI));
            values.put('Header:', getMapKeyValue('Header:', req.headers));
            values.put('HTTP Method:', req.httpMethod);
            values.put('Remote Address:', req.remoteAddress);
            values.put('Request Parameters:', getMapKeyValue('Params:', req.params));
        }
        values.put('Body', JSON.serialize(req.requestBody?.toString())?.remove('\\n')?.remove('\\'));
        this.log.put(fieldMap.get(Field.Request), StringX.clamp(this.showMoreInfo
            ? getMapKeyValue('', values)
            : String.join(values.values(), ''), 131072));
        return this;
    }

    /**
    * @description includes the request
    * @param res the response
    * @return LogBuilder
    **/
    global LogBuilder withResponse(HttpResponse res) {
        if (res == null) { return this; }
        this.log.put(fieldMap.get(Field.Response), StringX.clamp(res.getBody(), 131072));
        this.log.put(fieldMap.get(Field.ResultCode), res.getStatusCode());
        return this;
    }
    
    /**
    * @description includes the response
    * @param res the response
    * @return LogBuilder
    **/
    global LogBuilder withResponse(RestResponse res) {
        if (res == null) { return this; }
        Map<String, String> values = new Map<String, String>();
        if (this.showMoreInfo) {
            values.put('Headers:', String.valueOf(res.headers));
        }
        values.put('Body', res.responseBody?.toString());
        this.log.put(fieldMap.get(Field.Response), StringX.clamp(this.showMoreInfo
            ? getMapKeyValue('', values)
            : String.join(values.values(), ''), 131072));
        this.log.put(fieldMap.get(Field.ResultCode), res.statusCode);
        return this;
    }

    /**
    * @description return a string
    * @return String 
    **/
    global override String toString() {
        return String.format('[Logger] {0}: {1}', new Object[] { this.log.get(fieldMap.get(Field.InteractionType)), this.log });
    }

    /**
    * @description return all key values in a String
    * @param type the type 
    * @param args the args
    * @return String 
    **/
    String getMapKeyValue(String type, Map<String, String> args) {
        if (args == null || args.isEmpty()) { return 'NULL'; }
        List<String> values = new List<String>();
        for (String key : args.keySet()) {
            values.add(String.format('{0} {1}:{2}', new List<Object> { type, key, args.get(key) }));
        }
        return String.join(values, ',\n');
    }
}
