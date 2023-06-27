@isTest
class MapXTest {
    @isTest static void shouldPut() {
        Map<String, String> actual1 = new Map<String, String>();
        Map<String, Object> actual2 = new Map<String, Object>();
        MapX.put(actual1, 'key', 'value');
        MapX.put(actual2, 'key', 'value');
        System.assertEquals('value', actual1.get('key'), 'Should be value');
        System.assertEquals('value', actual2.get('key'), 'Should be value');
    }

    @isTest static void shouldPutIf() {
        Map<String, String> actual1 = new Map<String, String>();
        Map<String, Object> actual2 = new Map<String, Object>();
        MapX.putIf(actual1, true, 'key', 'value');
        MapX.putIf(actual2, true, 'key', 'value');
        System.assertEquals('value', actual1.get('key'), 'Should be value');
        System.assertEquals('value', actual2.get('key'), 'Should be value');
    }
        
    @isTest static void shouldPutIfNotNull() {
        Map<String, String> actual1 = new Map<String, String>();
        Map<String, Object> actual2 = new Map<String, Object>();
        MapX.putIfNotNull(actual1, 'key', 'value');
        MapX.putIfNotNull(actual2, 'key', 'value');
        System.assertEquals('value', actual1.get('key'), 'Should be value');
        System.assertEquals('value', actual2.get('key'), 'Should be value');
    }
}