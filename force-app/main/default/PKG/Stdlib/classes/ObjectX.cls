global class ObjectX {
    /**
    * @description decodes an object
    * @param value the value
    * @return Object
    **/
    global static Object decodeOf(String value) {
        String name = value.substring(0, value.indexOf(':'));
        String body = value.substring(value.indexOf(':') + 1);
        Type type = Type.forName(name);
        return JSON.deserialize(body, type);
    }

    /**
    * @description encodes an object
    * @param type the Type of value
    * @param value the value
    * @return String
    **/
    global static String encodeOf(Type type, Object value) {
        return type.getName() + ':' + JSON.serialize(value);
    }

    /**
    * @description gets a sobject's value
    * @param obj the SObject
    * @param field the field
    * @return Object
    **/
    global static Object get(SObject obj, String field) {
        if (obj == null) { return null; }
        String[] arg = field.split('\\.', 2);
        return arg.size() > 1
            ? get(obj.getSObject(arg[0]), arg[1])
            : obj.get(field);
    }

    /**
    * @description gets all sobject's values
    * @param fields the fields
    * @return Map<String, Object>
    **/
    global static Map<String, Object> getAll(SObject obj, List<String> fields) {
        if (obj == null) { return null; }
        Map<String, Object> values = new Map<String, Object>();
        for (String field : fields) {
            values.put(field, get(obj, field));
        }
        return values;
    }

    /**
    * @description gets all sobject's values
    * @param fields the fields
    * @return Map<String, Object>
    **/
    global static Map<String, Object> getAll(SObject obj, String fields) {
        return getAll(obj, fields.split(','));
    }

    /**
    * @description sets a sobject's value
    * @param obj the SObject
    * @param field the field
    * @param value the value
    * @return Object
    **/
    global static Object put(SObject obj, String field, Object value) {
        if (obj == null) { return null; }
        String[] arg = field.split('\\.', 2);
        return arg.size() > 1
            ? put(obj.getSObject(arg[0]), arg[1], value)
            : obj.put(field, value);
    }

    /**
    * @description sets all sobject's values
    * @param obj the SObject
    * @param values the values
    * @return SObject
    **/
    global static SObject putAll(SObject obj, Map<String, Object> values) {
        if (obj == null) { return null; }
        for (String field : values.keySet()) {
            put(obj, field, values.get(field));
        }
        return obj;
    }

    /**
    * @description sets all sobject's values
    * @param obj the SObject
    * @param values the values
    * @return SObjects
    **/
    global static SObject putAll(SObject obj, String values) {
        return putAll(obj, StringX.decodeMap(values));
    }
}