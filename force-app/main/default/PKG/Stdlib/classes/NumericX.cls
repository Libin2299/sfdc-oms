global class NumericX {
    /**
    * @description formats a currency value
    * @param value the currency
    * @param currencyCode the currency code
    * @return String
    **/
    global static String formatCurrency(Object value, String currencyCode) {
        if (value == null) { return null; }
        Decimal d = (Decimal)Double.valueOf(value);
        String s;
        switch on currencyCode {
            when 'USD' { s = '$' + d.longValue().format(); }
            when 'EUR' { s = '€' + d.longValue().format(); }
            when 'GBP' { s = '£' + d.longValue().format(); }
            when 'AUD' { s = '$' + d.longValue().format(); }
            when 'CAD' { s = '$' + d.longValue().format(); }
            when else { s = d.longValue().format(); }
        }
        return s + '.' + d.setScale(2).toPlainString().split('\\.')[1];
    }

    /**
    * @description formats a datetime value
    * @param value the datetime
    * @param format the format
    * @return String
    **/
    global static String formatDatetime(Object value, String format, String arg1) {
        if (value == null) { return null; }
        Datetime d = Datetime.valueOf(value);
        String s;
        switch on format {
            when 'iso' { s = d.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'SSS', arg1); } //: PST/GMT
            when else  { s = d.format(format, arg1); }
        }
        return s;
    }
}