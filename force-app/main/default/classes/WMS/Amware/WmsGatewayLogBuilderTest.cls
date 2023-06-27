@isTest
public class WmsGatewayLogBuilderTest {
    @isTest static void getAmwareAuthTokenTest() {
        WmsGatewayLogBuilder builder = new WmsGatewayLogBuilder();
        builder.makeRelatedMap();
        builder.createLog();
    }
}