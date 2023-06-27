@isTest
class StringXTest {
    static final String EXPECTEDMAP = 'sString=Value,bBoolean=true,iInteger=1,lLong=1,dDouble=1.0,dDecimal=1.0,yDate=2020-01-01,zDatetime=2020-01-01 00:00:00';

    @isTest static void shouldDecodeMap() {
        Map<String, Object> actual = StringX.decodeMap(EXPECTEDMAP);
        System.assert(actual.get('String') instanceOf String, 'Should be value');
        System.assert(actual.get('Integer') instanceOf Integer, 'Should be value');
        System.assert(actual.get('Boolean') instanceOf Boolean, 'Should be value');
        System.assert(actual.get('Double') instanceOf Double, 'Should be value');
        System.assert(actual.get('Decimal') instanceOf Decimal, 'Should be value');
        System.assert(actual.get('Datetime') instanceOf Datetime, 'Should be value');
        System.assert(actual.get('Date') instanceOf Date, 'Should be value');
    }

    @isTest static void shouldEncodeMap() {
        Map<String, Object> values = new Map<String, Object> {
            'String' => 'Value',
            'Boolean' => true,
            'Integer' => 1,
            'Long' => 1L,
            'Double' => 1.0,
            'Decimal' => (Decimal)1.0,
            'Date' => Date.newInstance(2020, 1, 1),
            'Datetime' => Datetime.newInstanceGmt(2020, 1, 1, 0, 0, 0)
        };
        String actual = StringX.encodeMap(values);
        System.debug(actual);
        System.assertEquals(EXPECTEDMAP, actual, 'Should be value');
    }

    @isTest static void shouldClamp() {
        StringX.clamp('123', 3);
    }

    @isTest static void shouldChunkStringAt() {
        String body = ''.leftPad(6000, '0');
	    System.assert(StringX.chunkStringAt(body, 0, 4000) != null, 'Should be value');
	    System.assert(StringX.chunkStringAt(body, 1, 4000) != null, 'Should be value');
	    System.assert(StringX.chunkStringAt(body, 2, 4000) == null, 'Should be value');
	    System.assert(StringX.chunkStringAt(body, 3, 4000) == null, 'Should be value');
    }
}