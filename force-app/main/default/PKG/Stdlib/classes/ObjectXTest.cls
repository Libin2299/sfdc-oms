@isTest
class ObjectXTest {
    @isTest static void shouldDecodeOf() {
        Object actual = ObjectX.decodeOf('List<SObject>:[{"attributes":{"type":"BatchApexErrorEvent"}}]');
        System.assert(actual instanceOf List<SObject>, 'Should be value');
    }

    @isTest static void shouldEncodeOf() {
        SObject[] events = new SObject[] { new BatchApexErrorEvent() };
        String actual = ObjectX.encodeOf(List<SObject>.class, events);
        System.assertEquals('List<SObject>:[{"attributes":{"type":"BatchApexErrorEvent"}}]', actual, 'Should be value');
    }

    @isTest static void shouldGet() {
        Account parentObj = new Account(Name='Parent');
        Account obj = new Account(Name='Account', Parent = parentObj);
        String actual = (String)ObjectX.get(obj, 'Name');
        String actual2 = (String)ObjectX.get(obj, 'Parent.Name');
        System.assertEquals('Account', actual, 'Should be value');
        System.assertEquals('Parent', actual2, 'Should be value');
    }

    @isTest static void shouldGetAll() {
        Account parentObj = new Account(Name='Parent');
        Account obj = new Account(Name='Account', Parent = parentObj);
        String actual = (String)ObjectX.getAll(obj, new List<String> { 'Name' }).get('Name');
        String actual2 = (String)ObjectX.getAll(obj, new List<String> { 'Parent.Name' }).get('Parent.Name');
        System.assertEquals('Account', actual, 'Should be value');
        System.assertEquals('Parent', actual2, 'Should be value');
    }

    @isTest static void shouldGetAll2() {
        Account parentObj = new Account(Name='Parent');
        Account obj = new Account(Name='Account', Parent = parentObj);
        String actual = (String)ObjectX.getAll(obj, 'Name').get('Name');
        String actual2 = (String)ObjectX.getAll(obj, 'Parent.Name').get('Parent.Name');
        System.assertEquals('Account', actual, 'Should be value');
        System.assertEquals('Parent', actual2, 'Should be value');
    }


    @isTest static void shouldPut() {
        Account parentObj = new Account(Name='Parent');
        Account obj = new Account(Name='Account', Parent = parentObj);
        ObjectX.put(obj, 'Name', 'Account2');
        ObjectX.put(obj, 'Parent.Name', 'Parent2');
        String actual = obj.Name;
        String actual2 = obj.Parent.Name;
        System.assertEquals('Account2', actual, 'Should be value');
        System.assertEquals('Parent2', actual2, 'Should be value');
    }
    
    @isTest static void shouldPutAll() {
        Account parentObj = new Account(Name='Parent');
        Account obj = new Account(Name='Account', Parent = parentObj);
        ObjectX.putAll(obj, new Map<String, Object> { 'Name' => 'Account2' });
        ObjectX.putAll(obj, new Map<String, Object> { 'Parent.Name' => 'Parent2' });
        String actual = obj.Name;
        String actual2 = obj.Parent.Name;
        System.assertEquals('Account2', actual, 'Should be value');
        System.assertEquals('Parent2', actual2, 'Should be value');
    }

    @isTest static void shouldPutAll2() {
        Account parentObj = new Account(Name='Parent');
        Account obj = new Account(Name='Account', Parent = parentObj);
        ObjectX.putAll(obj, 'sName=Account2');
        ObjectX.putAll(obj, 'sParent.Name=Parent2');
        String actual = obj.Name;
        String actual2 = obj.Parent.Name;
        System.assertEquals('Account2', actual, 'Should be value');
        System.assertEquals('Parent2', actual2, 'Should be value');
    }
}