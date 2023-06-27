global class SystemX {
    static final Map<Type, Object> singletons = new Map<Type, Object>();

    global interface HasRun {
        String run();
    }

    global enum Environs {
        PRODUCTION, STAGING, DEVELOPMENT, UNKNOWN
    }

    global class Environment {
        global final Environs env;
        global final String fix;
        global Environment(Environs env, String fix) {
            this.env = env;
            this.fix = fix;
        }
    }

    /**
    * @description debugs a value
    * @param o the obj to show
    **/
    global static void debug(Object o) {
        if (o == null) { System.debug('|null'); }
        else if (o instanceOf String) { 
            String str = (String)o;
            Integer l = str.length(), c = 365;
            for (Integer i = 0; i < l; i += c) { System.debug('|' + str.substring(i, Math.min(i + c, l))); }
        }
        else { System.debug(o); }
    }

    /**
    * @description gets the factory (singleton)
    * @return IOptions
    **/
    global static Object getFactory(Type klass) {
        Object r = singletons.get(klass);
        if (r != null) { return r; }
        String klassName = 'App' + klass.getName().replace('stx.', '').replace('Default', '');
        Type t = (Type)ifNull(Type.forName(klassName), klass);
        if (t == null) { throw new HandledException('getDataFactory(type) requires a class named "' + klassName + '" to exist, please create.'); }
        r = t.newInstance();
        singletons.put(klass, r);
        return r;
    }

    /**
    * @description gets the options (singleton)
    * @return Object
    **/
    global static Object getOptions(Type klass) {
        Object r = singletons.get(klass);
        if (r != null) { return r; }
        String klassName = 'App' + klass.getName().replace('stx.', '').replace('Default', '');
        Type t = (Type)ifNull(Type.forName(klassName), klass);
        if (t == null) { throw new HandledException('getOption(type) requires a class named "AppOption" to exist, please create.'); }
        r = t.newInstance();
        return r;
    }

    /**
    * @description gets the service user
    * @param type the type
    * @return User
    **/
    global static User getServiceUser(String type) {
        String alias = options?.serviceUserAlias(type);
        return alias != null ? [SELECT Id, Name FROM User WHERE Alias = :alias LIMIT 1] : null;
    }

    /**
	 * @description gets a timestamp
	 * @returns the timestamp
	 */ 
    global static String getTimestamp() {
        Datetime now = Datetime.now();
        String segment = String.valueOf(now.getTime() - Datetime.newInstance(now.year(), now.month(), 1).getTime()).leftPad(10, '0');
        String month = String.fromCharArray(new Integer[] { now.month() - 1 + 65 });
        String year = String.fromCharArray(new Integer[] { 2022 - now.year() + 65 });
        return year+month+segment;
    }

    /**
    * @description if null ternary
    * @param value the value
    * @param defaultValue the defaultValue
    * @return Object
    **/
    global static String ifNull(String value, String defaultValue) { 
        return value != null ? value : defaultValue;
    }

    /**
    * @description if null ternary
    * @param value the value
    * @param defaultValue the defaultValue
    * @return Object
    **/
    global static Object ifNull(Object value, Object defaultValue) {
        return value != null ? value : defaultValue;
    }

    /**
    * @description the options
    **/
    global static IOptions options = (IOptions)getOptions(DefaultOptions.class);

    /**
    * @description spinlocks the thread
    * @param milliseconds the duration in milliseconds
    **/
    global static void threadSleep(Integer milliseconds) {
        Long timeDiff = 0;
        DateTime firstTime = System.now();
        do { timeDiff = System.now().getTime() - firstTime.getTime(); }
        while (timeDiff <= milliseconds); 
    }
}