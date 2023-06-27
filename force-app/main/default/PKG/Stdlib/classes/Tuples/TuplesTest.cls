@isTest
class TuplesTest {
    @isTest static void shouldCreate() {
        Test.startTest();
        Exception_SObject actual = new Exception_SObject(new HandledException('exception'), new Account());
        Id_String actual2 = new Id_String(UserInfo.getUserId(), 'string');
        Tuple2 actual3 = new Tuple2(UserInfo.getUserId(), 'string');
        Tuple3 actual4 = new Tuple3(UserInfo.getUserId(), null, 'string');
        Test.stopTest();
    }
}