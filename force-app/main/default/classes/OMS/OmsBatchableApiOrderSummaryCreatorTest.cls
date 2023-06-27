@isTest
public class OmsBatchableApiOrderSummaryCreatorTest {
    @IsTest(SeeAllData=true)
    static void testOmsBatchableApiOrderSummaryCreator() {
    Order orderData = OmsTestDataFactory.createRecordsforOrderSummaryCreation();
        OrderData.IsHistorical__c = true;
        update orderData;
        system.debug('orderData :'+orderData);
        Test.startTest();
        Database.executeBatch(new OmsBatchableApiOrderSummaryCreator(), 2000);
        Test.stopTest();
        Order oredrrecord = [SELECT Id, HistoricalProcessingStatus__c, CreatedDate FROM Order where id =: orderData.Id];
        system.assertEquals('Processed',oredrrecord.HistoricalProcessingStatus__c);
    }
    @IsTest(SeeAllData=true)
    static void testOmsBatchableApiOrderSummaryforerror() {
        String salesChannelName = 'Viviscal';
        Id pricebookId = [SELECT Id, Name, IsDeleted, CurrencyIsoCode, CreatedDate FROM Pricebook2 where name = 'Standard Price Book'].Id;
 		Id saleschannelId =  [SELECT Id, IsDeleted, OwnerId, SalesChannelName, CurrencyIsoCode, CreatedDate, CreatedById FROM SalesChannel where SalesChannelName =:salesChannelName].Id;
        Account acc = new Account();
    	acc.Name = 'Test Account';
        acc.Business_Unit__c = 'AE';
    	insert acc;
        
    	Order testOrder = new Order();
        testOrder.Name = 'testOrder1234';
        testOrder.Status = 'Draft';
        testOrder.OrderReferenceNumber = 'testOrder1234cv';
        testOrder.EffectiveDate = system.today();
        testOrder.AccountId = acc.id;
        testOrder.Pricebook2Id =  pricebookId;
      	testOrder.SalesChannelId=saleschannelId;
        testOrder.IsHistorical__c = True;
      	insert testOrder;
        
        Product2 testProduct = new Product2();
        String sku = 'Normal Product ' + Integer.valueof((Math.random() * 1000));
        testProduct.Name = 'Test Product';
        testProduct.Description='Test Product Entry 1';
        testProduct.productCode = sku;
        testProduct.isActive = true;
        testProduct.StockKeepingUnit = sku;
        insert testProduct;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = testProduct.Id;
        standardPrice.UnitPrice = 200;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice;
        
		OrderItem orderItemProduct = new OrderItem();
        orderItemProduct.OrderId = testOrder.Id;
        orderItemProduct.Quantity = 1;
        orderItemProduct.UnitPrice = 200;
        orderItemProduct.TotalLineAmount = 200;
        orderItemProduct.Product2id = testProduct.id;
        orderItemProduct.PricebookEntryId=standardPrice.id;
        orderItemProduct.Type = 'Order Product';
        Insert orderItemProduct;
        Test.startTest();
        Database.executeBatch(new OmsBatchableApiOrderSummaryCreator());
        Test.stopTest();
        OmsHistoricalProcessingError__c error = [SELECT Id, OrderID__c, Error_Message__c FROM OmsHistoricalProcessingError__c where OrderID__c =: testOrder.Id  ];
        system.assertEquals(testOrder.Id, error.OrderID__c);
    }
}