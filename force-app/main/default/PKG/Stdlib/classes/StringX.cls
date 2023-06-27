global class StringX {
    /**
    * @description clamps a string
    * @param source the string to chunk
    * @param length the max length
    * @return String
    **/
    global static String clamp(String source, Integer length) {
        return source != null && source.length() > length ? source.substring(0, length - 4) + '...' : source;
    }

    /**
    * @description chunks a string at index
    * @param source the string to chunk
    * @param index the chunk index
    * @param size the chunk size
    * @return String
    **/
    global static String chunkStringAt(String source, Integer index, Integer size) {
        if (size == null) { size = 3950; }
        Integer l = source?.length(), f = (index * size), t = ((index + 1) * size);
        return source == null || l < f ? null : source.substring(f, (t > l ? l : t));
    }

    /**
    * @description decodes a map
    * @param value the value
    * @return Map<String, Object>
    **/
    global static Map<String, Object> decodeMap(String values) {
        if (String.isEmpty(values)) { return null; }
        Map<String, Object> newValues = new Map<String, Object>();
        for (String value : values.split(',')) {
            String type = value.substring(0, 1);
            String name = value.substring(1, value.indexOf('='));
            String str = value.substring(value.indexOf('=') + 1);
            switch on type {
                when 's' { newValues.put(name, str); }
                when 'b' { newValues.put(name, Boolean.valueOf(str)); }
                when 'i' { newValues.put(name, Integer.valueOf(str)); }
                when 'l' { newValues.put(name, Long.valueOf(str)); }
                when 'd' { newValues.put(name, Double.valueOf(str)); }
                when 'y' { newValues.put(name, Date.valueOf(str)); }
                when 'z' { newValues.put(name, Datetime.valueOf(str)); }
                when else { throw new HandledException('Unknown type for: ' + type + name); }
            }
        }
        return newValues;
    }

    /**
    * @description encodes a map
    * @param values the values
    * @return String
    **/
    global static String encodeMap(Map<String, Object> values) {
        if (values == null) { return null; }
        List<String> builder = new List<String>();
        for (String key : values.keySet()) {
            Object value = values.get(key);
            if (value == null) { throw new HandledException('Null value for: ' + key); }
            else if (value instanceOf String) { builder.add('s' + key + '=' + value); }
            else if (value instanceOf Boolean) { builder.add('b' + key + '=' + String.valueOf(value)); }
            else if (value instanceOf Integer) { builder.add('i' + key + '=' + String.valueOf(value)); }
            else if (value instanceOf Long) { builder.add('l' + key + '=' + String.valueOf(value)); }
            else if (value instanceOf Double || value instanceOf Decimal) { builder.add('d' + key + '=' + String.valueOf(value)); }
            else if (value instanceOf Date) { builder.add('y' + key + '=' + String.valueOf(value).removeEnd(' 00:00:00')); }
            else if (value instanceOf Datetime) { builder.add('z' + key + '=' + String.valueOf(value)); }
            else { throw new HandledException('Unknown type for: ' + key); }
        }
        return String.join(builder, ',');
    }
}