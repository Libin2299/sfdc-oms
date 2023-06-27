global abstract class CloudXSfccTransfer implements Database.AllowsCallouts {
    // global protected String endpoint;
    
    /**
     * @description BatchContext
     * @param callout the callout
     * @param accessToken the access token
     * @param args the args
     */ 
    global class BatchContext {
        public BatchContext(String callout, Map<String, Object> accessToken, Map<String, Object> args) {
            this.callout = callout;
            this.accessToken = accessToken;
            this.args = args;
            this.batch = new List<Map<String, Object>>();
        }
        public String callout;
        public Map<String, Object> accessToken;
        public Map<String, Object> args;
        public List<Map<String, Object>> batch;
    }

    /**
     * @description QueryContext
     * @param endpoint the endpoint
     * @param query the query
     * @param selectx the selectx
     * @param querySize the querySize
     * @param batchSize the batchSize
     */ 
    global class QueryContext {
        public QueryContext(String endpoint, String query, String selectx) {
            this.endpoint = endpoint;
            this.query = query;
            this.selectx = selectx;
            this.querySize = null;
            this.batchSize = null;
        }
        public String endpoint;
        public String query;
        public String selectx;
        public Integer querySize;
        public Integer batchSize;

        /**
         * @description params
         */ 
        public void params() {
            if (selectx == null || String.isEmpty(selectx)) { selectx = '(**)'; }
            if (querySize == null) { querySize = 50; }
            if (batchSize == null) { batchSize = 100; }
        }

        /**
         * @description makeQuery
         * @param start the start
         */ 
        public String makeQuery(Integer start) {
            return '{ "count": ' + this.querySize + ', "query": ' + this.query + ', "select": "' + this.selectx + '", "start": ' + start + ' }';
        }
    }

    /**
     * @description accessToken support
     * @returns the access token
     */ 
    global protected Map<String, Object> accessToken {
        get { if (this.accessToken == null) { this.accessToken = CloudX.getSfccAccessToken(); } return this.accessToken; }
        set;
    }

    /**
     * @description creates a newInstance
     * @param type the class type
     * @param accessToken the access token
     * @returns the instance
     */ 
    public static CloudXSfccTransfer newInstance(Type type, Map<String, Object> accessToken) {
        CloudXSfccTransfer transfer = (CloudXSfccTransfer)type.newInstance();
        transfer.accessToken = accessToken;
        return transfer;
    }

    /**
     * @description queues callout
     * @param ctx the batch context
     * @param args the args
     */ 
    public static void callout(BatchContext ctx, Map<String, Object> args) {
        HttpResponse[] batch = CloudX.calloutSfccBatch(ctx.callout, ctx.accessToken, ctx.batch, ctx.args, args);
        if (batch == null) { return; }
        for (HttpResponse res : batch) { System.debug(res.getStatus() + ': ' + res.getBody()); }
    }

    /**
     * @description deletes a batch of records
     * @param ctx the batch context
     * @param endpoint the endpoint
     * @param ids the ids
     * @returns the instance
     */
    public static void deleteBatch(BatchContext ctx, String endpoint, String[] ids) {
        ctx.args.put('method', 'DELETE');
        ctx.args.put('endpoint', CloudX.getSfccEndpoint(ctx.accessToken, 'data', endpoint + '/'));

        // execute batch
        for (String id : ids) {
            callout(ctx, new Map<String, Object> {
                'endpoint' => id
            });
        }

        // execute remaining
        callout(ctx, null);
    }

    /**
     * @description query an item
     * @param ctx the batch context
     * @param args the args
     */
    global protected void query(BatchContext ctx, Map<String, Object> args, List<Object> results) {
        HttpResponse[] batch = CloudX.calloutSfccBatch(ctx.callout, ctx.accessToken, ctx.batch, ctx.args, args);
        if (batch == null) { return; }
        for (HttpResponse res : batch) { 
            List<Object> values = querySelect(res);
            if (values != null && !values.isEmpty()) { results.addAll(values); }
        }
    }

    /**
     * @description queries a batch of records
     * @param ctx the batch context
     * @param qtx the query context
     * @param size the batch size
     * @returns the instance
     */
    global protected List<Object> queryBatch(BatchContext ctx, QueryContext qtx, Integer size) {
        ctx.args.put('method', 'POST');
        ctx.args.put('endpoint', CloudX.getSfccEndpoint(ctx.accessToken, 'data', qtx.endpoint + '/'));
        qtx.params();

        // execute batch
        List<Object> results = new List<Object>();
        for (Integer start = 0; start < size; start += qtx.querySize) {
            Map<String, Object> args = new Map<String, Object>();
            args.put('body', qtx.makeQuery(start));
            query(ctx, args, results);
        }

        // execute remaining
        query(ctx, null, results);
        return results;
    }

    /**
     * @description query an item
     * @param ctx the batch context
     * @param args the args
     * returns a set of objects
     */ 
    global protected virtual List<Object> querySelect(HttpResponse res) {
        return null;
    }

    /**
     * @description query list total
     * @param ctx the batch context
     * @param endpoint the endpoint
     * @returns the total
     */ 
    public static Integer queryListTotal(BatchContext ctx, String endpoint) {
        ctx.args.put('method', 'POST');
        ctx.args.put('endpoint', CloudX.getSfccEndpoint(ctx.accessToken, 'data', endpoint + '?select=(total)&size=1&start=0'));

        // execute call
        HttpResponse res = CloudX.callout(ctx.callout, ctx.accessToken, ctx.args);
        String body = res.getBody();
        // System.debug(body);

        // parse result
        JSONParser parser = JSON.createParser(body);
        Integer total = null;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'total') {
                parser.nextToken();
                total = Integer.valueOf(parser.getText());
            }
        }
        return total;
    }
}