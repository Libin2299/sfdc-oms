global abstract class CloudXSfmcTrigger implements Database.AllowsCallouts, SystemX.HasRun {
    // global protected String endpoint;
    
    class Payload {
        PayloadTo To;
        PayloadOptions OPTIONS;
    }

    class PayloadTo {
        String Address;
        String SubscriberKey;
        Object ContactAttributes;
    }

    class PayloadOptions {
        String RequestType = 'ASYNC';
    }

    /**
     * @description TriggerContext
     * @param endpoint the endpoint
     * @param accessToken the accessToken
     * @param args the args
     */  
    global class TriggerContext {
        public TriggerContext(String endpoint, Map<String, Object> accessToken, Map<String, Object> args) {
            this.endpoint = endpoint;
            this.accessToken = accessToken;
            this.args = args != null ? args : new Map<String, Object>();
        }
        public String endpoint;
        public Map<String, Object> accessToken;
        public Map<String, Object> args;
        public String address;
        public String subscriberKey;
        public Object contactAttributes;
    }

    /**
     * @description accessToken support
     * @returns the access token
     */ 
    global protected Map<String, Object> accessToken {
        get { if (this.accessToken == null) { this.accessToken = CloudX.getSfmcAccessToken(); } return this.accessToken; }
        set;
    }

    /**
     * @description creates a newInstance
     * @param type the class type
     * @param accessToken the access token
     * @returns the instance
     */ 
    public static CloudXSfmcTrigger newInstance(Type type, Map<String, Object> accessToken, Map<String, Object> args) {
        CloudXSfmcTrigger obj = (CloudXSfmcTrigger)type.newInstance();
        obj.accessToken = accessToken;
        if (obj instanceOf CloudX.HasArgs) { ((CloudX.HasArgs)obj).setArgs(args); }
        return obj;
    }

    /**
    * @description run
    * @return String 
    **/
    global String run() {
        TriggerContext ctx = new TriggerContext(null, accessToken, null);
        return execute(ctx);
    }

    /**
     * @description posts an item
     * @param ctx the trigger context
     */ 
    public static HttpResponse post(TriggerContext ctx) {
        Payload p = new Payload();
        p.To = new PayloadTo();
        p.To.Address = ctx.address;
        p.To.SubscriberKey = ctx.subscriberKey;
        p.To.ContactAttributes = ctx.contactAttributes;
        p.OPTIONS = new PayloadOptions();
        System.debug(JSON.serialize(p));

        // send
        ctx.args.put('method', 'POST');
        ctx.args.put('endpoint', CloudX.getSfmcEndpoint(ctx.accessToken, 'trigger', ctx.endpoint));
        ctx.args.put('body', p);
        HttpResponse res = CloudX.callout((String)ctx.accessToken.get('rest_instance_url'), ctx.accessToken, ctx.args);
        if (res != null) { System.debug(res.getStatus() + ': ' + res.getBody()); }
        return res;
    }

    /**
     * @description query an item
     * @param ctx the trigger context
     */ 
    global protected virtual String execute(TriggerContext ctx) { return null; }
}