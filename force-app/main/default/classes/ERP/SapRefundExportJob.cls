public class SapRefundExportJob implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public String tZone = 'PST';
    public Double adjustmentRefund = 0.00;
    public Double adjustmentFee = 0.00;
	public Integer totalOrdersUS = 0;
    public Integer totalOrderLineItemUS = 0;
    public Decimal totalValueOfOrdersUS = 0;
    public Integer totalOrdersCA = 0;
    public Integer totalOrderLineItemCA = 0;
    public Decimal totalValueOfOrdersCA = 0;
    public List<String> refundsUS = new List<String>();
    public List<String> refundsCA = new List<String>();
    public String className = SapRefundExportJob.class.getName();
    public List<Custom_Refund__c> customRefundListToUpdate = new List<Custom_Refund__c>();
    public List<CustomOrderLineItem> customOrderItemList = new List<CustomOrderLineItem>();
    public String customRefundIds;
    public Boolean isExport = false;
    public final String SALESCHANNEL_US = 'viviscal';
    public final String SALESCHANNEL_CA = 'viviscal-ca';

    public SapRefundExportJob() { }

    public SapRefundExportJob(String customRefundIds, Boolean isExport) {
        this.customRefundIds = customRefundIds;
        this.isExport = isExport;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator queryResult;
        TimeZone tz = Timezone.getTimeZone('America/Los_Angeles');
        Integer offSet = tz.getOffSet(DateTime.now())/(60*60*1000);//offSet in hours
        DateTime todayDT = DateTime.now();
        String yesterdayStartDateTime = Datetime.newInstanceGmt(todayDT.yearGmt(), todayDT.monthGmt(),todayDT.dayGmt() - 1, 0 + Math.abs(offset), 0, 0).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String yesterdayEndDateTime = Datetime.newInstanceGmt(todayDT.yearGmt(), todayDT.monthGmt(), todayDT.dayGmt() - 1, 23 + Math.abs(offset), 59, 59).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String query = 'SELECT Id, Reference_Refund__c, Reference_Refund__r.CreatedDate, Reference_Refund__r.RefundNumber, Reference_Refund__r.GatewayRefNumber, Reference_Refund__r.CurrencyIsoCode, Reference_Refund__r.TotalApplied, ' +
            'Reference_ChangeOrder__c, Reference_ChangeOrder__r.RelatedOrderId, Reference_ChangeOrder__r.RelatedOrder.OrderReferenceNumber, Reference_ChangeOrder__r.RelatedOrder.SalesChannel.SalesChannelName, ' +
            'Reference_ChangeOrder__r.TotalAmount, Reference_ChangeOrder__r.TotalTaxAmount, Reference_ChangeOrder__r.GrandTotalAmount, Reference_Order_Payment_Summary__r.OrderSummary.Saleschannel.SalesChannelName ' + 
            'FROM Custom_Refund__c WHERE Reference_Refund__c != null AND IsCancelledRefund__c = false AND IsExportedToSAP__c = false ';
        if (Test.isRunningTest()) {
            query += 'AND Reference_Refund__r.CreatedDate >= Today';
        } else if(!String.isBlank(this.customRefundIds)) {
            query += 'AND ID IN (' + this.customRefundIds + ')';
        } else {
            query += 'AND Reference_Refund__r.CreatedDate >= ' + yesterdayStartDateTime + ' AND  Reference_Refund__r.CreatedDate <= ' + yesterdayEndDateTime;
        }
        try {
            queryResult = Database.getQueryLocator(query);
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return queryResult;
    }
    
    public void execute(Database.BatchableContext bc, List<Custom_Refund__c> customRefundList) {
        Set<Id> relatedOrderIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Map<String, List<OrderItem>> orderItemMap = new Map<String, List<OrderItem>>();
        Map<String, Map<String, List<OrderItem>>> bundleItemMap = new Map<String, Map<String, List<OrderItem>>>();
        try {
            for (Custom_Refund__c cr : customRefundList) {
                relatedOrderIds.add(cr.Reference_ChangeOrder__r.RelatedOrderId);
                orderIds.add(cr.Reference_ChangeOrder__c);
            }
            for (OrderItem originalOrderItem : [SELECT Id, OrderId, Type, Product2.ProductCode, sfcc_SAPMaterialCode__c, sfcc_BundleProductGUID__c, RelatedOrderItem.sfcc_SAPMaterialCode__c,
                RelatedOrderItem.sfcc_BundleProductGUID__c, TotalPrice, TotalTaxAmount, TotalAmtWithTax FROM OrderItem WHERE OrderId IN :relatedOrderIds AND sfcc_BundleProductGUID__c != null]) {
                if (originalOrderItem.Type == 'Order Product' && originalOrderItem.sfcc_BundleProductGUID__c != null) {
                    String orderId = originalOrderItem.OrderId;
                    if (bundleItemMap.containsKey(orderId)) {
                        Map<String, List<OrderItem>> bundledItemMap = bundleItemMap.get(orderId);
                        if (bundledItemMap.containsKey(originalOrderItem.sfcc_BundleProductGUID__c)) {
                            bundleItemMap.get(orderId).get(originalOrderItem.sfcc_BundleProductGUID__c).add(originalOrderItem);
                        } else {
                            bundleItemMap.get(orderId).put(originalOrderItem.sfcc_BundleProductGUID__c, new List<OrderItem>{originalOrderItem});
                        }
                    } else {
                        bundleItemMap.put(orderId, new Map<String, List<OrderItem>>{ originalOrderItem.sfcc_BundleProductGUID__c => new List<OrderItem>{originalOrderItem}});
                    }
                }
            }
            for (OrderItem orderItem : [SELECT Id, OrderId, Order.RelatedOrderId, RelatedOrderItemId, Type, Product2.ProductCode, sfcc_SAPMaterialCode__c, RelatedOrderItem.sfcc_SAPMaterialCode__c, 
                sfcc_BundleProductGUID__c, RelatedOrderItem.sfcc_BundleProductGUID__c, TotalPrice, TotalTaxAmount, TotalAmtWithTax FROM OrderItem WHERE OrderId IN :orderIds AND RelatedOrderItem.sfcc_BundleProductGUID__c = null]) {
                    List<OrderItem> childOrderItemList = null;
                    if (orderItem.Type == 'Order Product' && orderItem.RelatedOrderItem.sfcc_SAPMaterialCode__c == null) {
                        if (bundleItemMap.containsKey(orderItem.Order.RelatedOrderId)) {
                            Map<String, List<OrderItem>> childItemMap = bundleItemMap.get(orderItem.Order.RelatedOrderId);
                            if (childItemMap.containsKey(orderItem.Product2.ProductCode)) {
                                childOrderItemList = childItemMap.get(orderItem.Product2.ProductCode);
                            }
                        }
                    }
                if (orderItemMap.containsKey(orderItem.OrderId)) {
                    orderItemMap.get(orderItem.OrderId).add(orderItem);
                    if (childOrderItemList != null && !childOrderItemList?.isEmpty()) {
                        orderItemMap.get(orderItem.OrderId).addAll(childOrderItemList);
                    }
                    
                } else {
                    orderItemMap.put(orderItem.OrderId, new List<OrderItem>{orderItem});
                    if (childOrderItemList != null && !childOrderItemList?.isEmpty()) {
                        orderItemMap.get(orderItem.OrderId).addAll(childOrderItemList);
                    }
                }
            }
    
            for (Custom_Refund__c cr : customRefundList) {
                Decimal shippingTotal = 0.0;
                Decimal shippingTotalTax = 0.0;
                Integer position = 0;
                Boolean isFirstLineItem = true;
                String firstLineItemId;
                Map<String, BundleProduct> bundledProductMap = new Map<String, BundleProduct>();
                Map<String, Integer> bundledProductCountMap = new Map<String, Integer>();
                String salesChannel = cr.Reference_ChangeOrder__r.RelatedOrder.SalesChannel.SalesChannelName;
                List<OrderItem> orderItemList = orderItemMap.get(cr.Reference_ChangeOrder__c);
                Integer orderItemListSize = orderItemList.size();
                Map<String, CustomOrderLineItem> customOrderItemMap = new Map<String, CustomOrderLineItem>();
                for (Integer i = 0; i < orderItemListSize; i++) {
                    OrderItem orderItem = orderItemList.get(i);
                    if (orderItem.Type == 'Order Product' && orderItem.RelatedOrderItem != null && orderItem.RelatedOrderItem.sfcc_SAPMaterialCode__c == null) {
                        bundledProductMap.put(orderItem.Product2.ProductCode, new BundleProduct(orderItem.TotalPrice, orderItem.TotalTaxAmount));
                    } else if (orderItem.Type == 'Order Product' && (orderItem.sfcc_SAPMaterialCode__c != null || orderItem.RelatedOrderItem?.sfcc_SAPMaterialCode__c != null)) {
                        if (orderItem.sfcc_BundleProductGUID__c != null && orderItem.TotalAmtWithTax == 0) {
                            String bundleProductGUID = orderItem?.sfcc_BundleProductGUID__c;
                            if (bundledProductCountMap.containsKey(bundleProductGUID)) {
                                bundledProductCountMap.put(bundleProductGUID, bundledProductCountMap.get(bundleProductGUID) + 1);
                            } else {
                                bundledProductCountMap.put(bundleProductGUID, 1);
                            }
                        }
                        CustomOrderLineItem customLineItem = new CustomOrderLineItem();
                        String sapMaterialCode = orderItem.RelatedOrderItem?.sfcc_SAPMaterialCode__c != null ? orderItem.RelatedOrderItem?.sfcc_SAPMaterialCode__c : orderItem.sfcc_SAPMaterialCode__c;
                        String productGUID = orderItem.sfcc_BundleProductGUID__c != null ? orderItem?.sfcc_BundleProductGUID__c : '';
                        customLineItem.documentNumber = cr.Reference_Refund__r.RefundNumber;
                        customLineItem.createdDate = cr.Reference_Refund__r.CreatedDate.format('yyyyMMdd');
                        customLineItem.gatewayRefNumber = cr.Reference_Refund__r.GatewayRefNumber;
                        customLineItem.orderNumber = cr.Reference_ChangeOrder__r.RelatedOrder.OrderReferenceNumber;
                        customLineItem.tZone = tZone;
                        customLineItem.sapMaterialCode = sapMaterialCode;
                        customLineItem.CurrencyIsoCode = cr.Reference_Refund__r.CurrencyIsoCode;
                        customLineItem.lineAmount = Math.abs(orderItem.TotalPrice);
                        customLineItem.lineTaxAmount = Math.abs(orderItem.TotalTaxAmount);
                        customLineItem.position = ++position;
                        customLineItem.salesChannel = salesChannel;
                        customLineItem.productGUID = productGUID;
                        if (isFirstLineItem) {
                            Decimal grandTotalAmount = Math.abs(cr.Reference_ChangeOrder__r.GrandTotalAmount);
                            if (salesChannel ==  SALESCHANNEL_US) {
                                totalOrdersUS++;
                                totalValueOfOrdersUS += grandTotalAmount;
                            } else if (salesChannel ==  SALESCHANNEL_CA) {
                                totalOrdersCA++;
                                totalValueOfOrdersCA += grandTotalAmount;
                            }
                            firstLineItemId = orderItem.Id;
                            customLineItem.totalAmountWithTax = grandTotalAmount; 
                            customLineItem.adjustmentRefund = adjustmentFee;
                            customLineItem.adjustmentFee =  adjustmentRefund;
                            customRefundListToUpdate.add(cr);
                            isFirstLineItem = false;
                        }
                        if (salesChannel ==  SALESCHANNEL_US) {
                            totalOrderLineItemUS++;
                        } else if (salesChannel ==  SALESCHANNEL_CA) {
                            totalOrderLineItemCA++;
                        }
                        customOrderItemMap.put(orderItem.Id, customLineItem);
                    } else if (orderItem.Type == 'Delivery Charge') {
                        shippingTotal += Math.abs(orderItem.TotalPrice);
                        shippingTotalTax += Math.abs(orderItem.TotalTaxAmount);
                    }
                    if (i == orderItemListSize - 1) {
                        if (customOrderItemMap.containsKey(firstLineItemId)) {
                            CustomOrderLineItem customLineItem = customOrderItemMap.get(firstLineItemId);
                            customLineItem.shippingTotal = shippingTotal;
                            customLineItem.shippingTotalTax = shippingTotalTax;
                            customOrderItemMap.put(firstLineItemId, customLineItem);
                            for (String productCode : bundledProductMap.keySet()) {
                                Boolean isfirstLine = true;
                                for (String key : customOrderItemMap.keySet()) {
                                    CustomOrderLineItem customLine = customOrderItemMap.get(key);
                                    if (productCode == customLine.productGUID) {
                                        if (isfirstLine) {
                                            BundleProduct bp = bundledProductMap.get(productCode);
                                            Decimal bundleProductLineAmount = Math.abs(bp.totalAmount);
                                            Decimal bundleProductTaxAmount = Math.abs(bp.totalTaxAmount);
                                            Decimal totalBundledItems = Decimal.valueOf(bundledProductCountMap.get(productCode));
                                            //totalBundledItems = totalBundledItems == 1 ? totalBundledItems + 1 : totalBundledItems; 
                                            customLine.lineAmount = bundleProductLineAmount - ((totalBundledItems - 1) / 100);
                                            customLine.lineTaxAmount = bundleProductTaxAmount - ((totalBundledItems - 1) / 100);
                                            customOrderItemMap.put(key, customLine);
                                            isfirstLine = false;
                                        } else {
                                            customLine.lineAmount = 0.01;
                                            customLine.lineTaxAmount = 0.01;
                                            customOrderItemMap.put(key, customLine);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                customOrderItemList.addAll(customOrderItemMap.values());
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        List<ContentVersion> cvList = new List<ContentVersion>();
        String currentDT = System.now().format('yyyyMMddhhmmss', 'America/Los_Angeles');
        try {
            if (!customOrderItemList.isEmpty()) {
                if (totalOrdersUS > 0 && totalOrderLineItemUS > 0 && totalValueOfOrdersUS > 0) {
                    refundsUS.add(totalOrdersUS + '|' + totalOrderLineItemUS + '|' + totalValueOfOrdersUS);
                }
                if (totalOrdersCA > 0 && totalOrderLineItemCA > 0 && totalValueOfOrdersCA > 0) {
                    refundsCA.add(totalOrdersCA + '|' + totalOrderLineItemCA + '|' + totalValueOfOrdersCA);
                }
                for (CustomOrderLineItem customLineItem : customOrderItemList) {
                    String content = getContent(customLineItem);               
                    if (customLineItem.salesChannel == SALESCHANNEL_US) {
                        refundsUS.add(content);
                    } else if (customLineItem.salesChannel == SALESCHANNEL_CA){
                        refundsCA.add(content);
                    }
                }
            }
            
            refundsUS.add('EOF');
            String fileContentUS = String.join(refundsUS, '\n');
            String titleUS = 'REFUNDS_VIVISCAL_' + currentDT;
            ContentVersion cvUS = new ContentVersion(
                ContentLocation = 'S',
                Title = titleUS,
                VersionData = Blob.valueOf(fileContentUS),
                PathOnClient = titleUS + '.txt');
            cvList.add(cvUS);
                
            refundsCA.add('EOF');
            String fileContentCA = String.join(refundsCA, '\n');
            String titleCA = 'REFUNDS_VIVISCALCA_' + currentDT;
            ContentVersion cvCA = new ContentVersion(
                ContentLocation = 'S',
                Title = titleCA,
                VersionData = Blob.valueOf(fileContentCA),
                PathOnClient = titleCA + '.txt');
            cvList.add(cvCA);
                
            if (!cvList.isEmpty()) {
                if (isExport) {
                    SapFilesExport.exportFilesToCpi(cvList);
                }
                insert cvList;
            }
            
            if (!customRefundListToUpdate.isEmpty()) {
                for (Custom_Refund__c cr: customRefundListToUpdate) {
                    cr.IsExportedToSAP__c = true;
                }
                update customRefundListToUpdate;
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
    
    private String getContent(CustomOrderLineItem customLineItem) {
        String content;
        try {
            Decimal totalAmountWithTax = customLineItem.totalAmountWithTax != null && customLineItem.totalAmountWithTax > 0 ? customLineItem.totalAmountWithTax : 0.00;
            Decimal adjustmentRefund = customLineItem.adjustmentRefund != null && customLineItem.adjustmentRefund > 0 ? customLineItem.adjustmentRefund : 0.00;
            Decimal adjustmentFee = customLineItem.adjustmentFee != null && customLineItem.adjustmentFee > 0  ? customLineItem.adjustmentFee : 0.00;
            Decimal shippingTotal = customLineItem.shippingTotal != null && customLineItem.shippingTotal > 0 ? customLineItem.shippingTotal : 0.00;
            Decimal shippingTotalTax = customLineItem.shippingTotalTax != null && customLineItem.shippingTotalTax > 0 ? customLineItem.shippingTotalTax : 0.00;
            content = customLineItem.documentNumber + '|' + customLineItem.position + '|' + customLineItem.createdDate + '|' + customLineItem.gatewayRefNumber + '|' + 
                customLineItem.orderNumber + '|' +  customLineItem.sapMaterialCode + '|' + customLineItem.currencyIsoCode + '|' + totalAmountWithTax + '|' + 
                customLineItem.lineAmount + '|' + customLineItem.lineTaxAmount + '|' + shippingTotal + '|' + shippingTotalTax + '|' + adjustmentRefund + '|' + adjustmentFee;
            System.debug('Content ' + content);
        } catch (Exception ex) {
           CustomCommonUtil.logException(className, ex);
        }
        return content;
    }

    class CustomOrderLineItem {
        String documentNumber;
        String createdDate;
        String gatewayRefNumber;
        String orderNumber;
        String tZone;
        String sapMaterialCode;
        String CurrencyIsoCode;
        Decimal totalAmountWithTax;
        Decimal lineAmount;
        Decimal lineTaxAmount;
        Decimal shippingTotal;
        Decimal adjustmentRefund;
        Decimal adjustmentFee;
        Decimal shippingTotalTax;
        Integer position;
        String salesChannel;
        String productGUID;
	}

    class BundleProduct {
        Decimal totalAmount;
        Decimal totalTaxAmount;

        public BundleProduct(Decimal totalAmount, Decimal totalTaxAmount) {
            this.totalAmount = totalAmount;
            this.totalTaxAmount = totalTaxAmount;
        }
    }
}