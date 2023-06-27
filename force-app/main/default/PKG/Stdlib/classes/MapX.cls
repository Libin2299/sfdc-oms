global class MapX {
    /**
    * @description puts a value
    * @param source the source
    * @param key the key
    * @param value the value
    * @return Map<String, String>
    **/
    global static Map<String, String> put(Map<String, String> source, String key, Object value) {
        source.put(key, value != null ? value instanceOf String ? (String)value : String.valueOf(value) : null);
        return source;
    }

    /**
    * @description puts a value
    * @param source the source
    * @param key the key
    * @param value the value
    * @return Map<String, Object>
    **/
    global static Map<String, Object> put(Map<String, Object> source, String key, Object value) {
        source.put(key, value);
        return source;
    }

    /**
    * @description puts all values
    * @param source the source
    * @param key the key
    * @param value the value
    * @return Map<String, String>
    **/
    global static Map<String, String> putAll(Map<String, String> source, Map<String, String> fromMap) {
        if (fromMap != null) { source.putAll(fromMap); }
        return source;
    }

    /**
    * @description puts all values
    * @param source the source
    * @param key the key
    * @param value the value
    * @return Map<String, Object>
    **/
    global static Map<String, Object> putAll(Map<String, Object> source, Map<String, Object> fromMap) {
        if (fromMap != null) { source.putAll(fromMap); }
        return source;
    }

    /**
    * @description puts a value if a condition
    * @param source the source
    * @param key the key
    * @param predicate the predicate
    * @param value the value
    * @return Map<String, String>
    **/
    global static Map<String, String> putIf(Map<String, String> source, Boolean predicate, String key, Object value) {
        if (predicate) { source.put(key, value != null ? value instanceOf String ? (String)value : String.valueOf(value) : null); }
        return source;
    }

    /**
    * @description puts a value if a condition
    * @param source the source
    * @param key the key
    * @param predicate the predicate
    * @param value the value
    * @return Map<String, Object>
    **/
    global static Map<String, Object> putIf(Map<String, Object> source, Boolean predicate, String key, Object value) {
        if (predicate) { source.put(key, value); }
        return source;
    }

     /**
    * @description puts a value if not null
    * @param source the source
    * @param key the key
    * @param value the value
    * @return Map<String, String>
    **/
    global static Map<String, String> putIfNotNull(Map<String, String> source, String key, Object value) {
        if (value != null) { source.put(key, value instanceOf String ? (String)value : String.valueOf(value)); }
        return source;
    }

    /**
    * @description puts value if not null
    * @param source the source
    * @param key the key
    * @param value the value
    * @return Map<String, Object>
    **/
    global static Map<String, Object> putIfNotNull(Map<String, Object> source, String key, Object value) {
        if (value != null) { source.put(key, value); }
        return source;
    }
}