public class SapOrdersExportJob implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
	public String shipFrom = 'LA';
    public String unitOfMeasure = 'EA';
    public Integer totalNoOfOrdersUS = 0;
    public Integer totalNoOfLineItemsUS = 0;
    public Decimal totalValueOfOrdersUS = 0;
    public Integer totalNoOfOrdersCA = 0;
    public Integer totalNoOfLineItemsCA = 0;
    public Decimal totalValueOfOrdersCA = 0;
    public List<String> ordersUS = new List<String>();
    public List<String> ordersCA = new List<String>();
    public String startDateTime;
    public String endDateTime;
    public String orderSummaryIds;
    public Boolean reRunPreviousDayJob = false;
    public Boolean isCPIExport = false;
    List<Id> osIdsToUpdate = new List<Id>();
    public String className = SapOrdersExportJob.class.getName();
    public Set<String> gwpOrderItemSummaries = new Set<String>();
    public final String SALESCHANNEL_US = 'viviscal';
    public final String SALESCHANNEL_CA = 'viviscal-ca';
    public final String ORDER_LIFECYCLE_TYPE = 'MANAGED';
    public Integer usSplitCount = 0;
    public Integer caSplitCount = 0;

    public SapOrdersExportJob() { }

    public SapOrdersExportJob(Boolean reRunPreviousDayJob, Boolean isCPIExport) {
        this.reRunPreviousDayJob = reRunPreviousDayJob;
        this.isCPIExport = isCPIExport;
    }

    public SapOrdersExportJob(String startDateTime, String endDateTime, Boolean isCPIExport) {
        this.startDateTime = String.valueOf(startDateTime).replace(' ','T') + 'Z';
      	this.endDateTime = String.valueOf(endDateTime).replace(' ','T') + 'Z';
        this.isCPIExport = isCPIExport;
    }

    public SapOrdersExportJob(String startDateTime, String endDateTime) {
        this.startDateTime = String.valueOf(startDateTime).replace(' ','T') + 'Z';
      	this.endDateTime = String.valueOf(endDateTime).replace(' ','T') + 'Z';
    }

    public SapOrdersExportJob(String orderSummaryIds, Boolean isCPIExport) {
        this.orderSummaryIds = orderSummaryIds;
        this.isCPIExport = isCPIExport;
    }

    public SapOrdersExportJob(String orderSummaryIds) {
        this.orderSummaryIds = orderSummaryIds;
    }
    
	//The start method gets all the OrderSummary records and corresponding OrderItemSummary records whose shipments were created yesterday  
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator queryResult;
        TimeZone tz = Timezone.getTimeZone('America/Los_Angeles');
        Integer offSet = tz.getOffSet(DateTime.now())/(60*60*1000);//offSet in hours
        DateTime todayDT = DateTime.now();
        String yesterdayStartDateTime = Datetime.newInstanceGmt(todayDT.yearGmt(), todayDT.monthGmt(),todayDT.dayGmt() - 1, 0 + Math.abs(offset), 0, 0).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String yesterdayEndDateTime = Datetime.newInstanceGmt(todayDT.yearGmt(), todayDT.monthGmt(), todayDT.dayGmt() - 1, 23 + Math.abs(offset), 59, 59).formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String shipmentWhereClause = Test.isRunningTest() ? 'WHERE CreatedDate >= TODAY' : 'WHERE CreatedDate >= ' + yesterdayStartDateTime + ' AND CreatedDate <= ' + yesterdayEndDateTime;
        String osWhereClause;
        if (Test.isRunningTest()) {
            if(!String.isBlank(this.orderSummaryIds)) {
                osWhereClause = 'WHERE OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND Id IN (' + orderSummaryIds + ')';
            } else if (!String.isBlank(startDateTime) && !String.isBlank(endDateTime)) {
            	osWhereClause = 'WHERE OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND CreatedDate >= ' + startDateTime + ' AND CreatedDate <= ' + endDateTime + ' LIMIT 2';
            } else {
                osWhereClause = 'WHERE OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND IsExportedToSAP__c = false ORDER BY CreatedDate DESC LIMIT 2';
            }
        } else {
            if(!String.isBlank(this.orderSummaryIds)) {
                osWhereClause = 'WHERE OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND Id IN (' + orderSummaryIds + ')';
                shipmentWhereClause = ' ';
            } else if (!String.isBlank(startDateTime) && !String.isBlank(endDateTime)) {
            	osWhereClause = 'WHERE OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE ';
                shipmentWhereClause = 'WHERE CreatedDate >= ' + startDateTime + ' AND CreatedDate <= ' + endDateTime;
            } else {
                if (reRunPreviousDayJob) {
                    osWhereClause = 'WHERE OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND IsExportedToSAP__c = true';
                } else {
                    osWhereClause = 'WHERE OrderLifeCycleType = :ORDER_LIFECYCLE_TYPE AND IsExportedToSAP__c = false';
                }
            }
        }
        String query = 'SELECT Id, OrderNumber, CurrencyIsoCode, GrandTotalAmount, TotalTaxAmount, TotalDeliveryAmount, TotalDeliveryTaxAmount, TotalAdjustedDeliveryAmount ,' +
            'TotalAdjustedDeliveryTaxAmount, NumberOfPaymentTypes__c, sfcc_sourceChannel__c, SalesChannel.SalesChannelName, OriginalOrder.TotalAmount, OriginalOrder.TotalTaxAmount, ' +
            '(SELECT Id, StockKeepingUnit, ProductCode, Quantity, UnitPrice, TotalPrice, TotalAmtWithTax, TotalLineTaxAmount, ' + 
            'TotalAdjustmentAmtWithTax, Status, sfcc_SAPMaterialCode__c, sfcc_BundleProductGUID__c, LotNumber__c, ' +
            'sfcc_ThreePayUnitPrice__c, sfcc_ThreePayDiscount__c ' +
        	'FROM OrderItemSummaries WHERE IsMarketingProduct__c = false AND Type = \'Order Product\' AND Status IN (\'FULFILLED\', \'RETURNINITIATED\', \'3-Pay Fulfilled\') ), ' +
            '(SELECT Id, AmwareShipDate__c FROM Shipments '+ shipmentWhereClause + ') FROM OrderSummary ' + osWhereClause;
        try {
            queryResult = Database.getQueryLocator(query);
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return queryResult;
    }

    /* This method takes list of OrderSummary and corresponding OrderItemSummary records as input and 
    * creates list of string which contains the order and order item data that needs to be added to the text file
    * Text file format:
    * Ship From| OrderMethod| Ecomm Order Number| Ship Date| Material| Batch| Quantity| UOM| Unit Price|
    * Currency| Item Total Amount OrderTotalAmount| Order Tax| Shipping| Ship Tax| Multi-pay|
    */
    public void execute(Database.BatchableContext bc, List<OrderSummary> orderSummaryList) {
        try {
            filterGWPOrderItemSummaries(orderSummaryList);
            for (Integer i = 0; i<orderSummaryList.size(); i++) {
                OrderSummary os = orderSummaryList.get(i);
            	if (!os.Shipments.isEmpty()) {
                    Boolean isFirstItem = true;
                    String salesChannel = os.SalesChannel.SalesChannelName;
                    Map<String, ProductBundle> productBundleMap = new Map<String, ProductBundle>();
                    Map<String, List<BundledProduct>> bundledProductMap = new Map<String, List<BundledProduct>>();
                    for (OrderItemSummary ois : os.OrderItemSummaries) {
                        Boolean isGWPItem = this.gwpOrderItemSummaries.contains(ois.ID);
                        if (ois.sfcc_SAPMaterialCode__c == null) {
                            productBundleMap.put(ois.ProductCode, new ProductBundle(os, ois));
                        } else if (ois.sfcc_BundleProductGUID__c != null) {
                            if (bundledProductMap.containsKey(ois.sfcc_BundleProductGUID__c)) {
                                bundledProductMap.get(ois.sfcc_BundleProductGUID__c).add(new BundledProduct(os, ois));
                            } else {
                                List<BundledProduct> bp = new List<BundledProduct>();
                                bp.add(new BundledProduct(os, ois));
                                bundledProductMap.put(ois.sfcc_BundleProductGUID__c, bp);
                            }
                        } else {
                            if (isFirstItem) {
                                String content = getContent(os, ois, true, isGWPItem);
                                if(salesChannel == SALESCHANNEL_US) {
                                    totalNoOfLineItemsUS++;
                                    totalNoOfOrdersUS++;
                                    totalValueOfOrdersUS += os.GrandTotalAmount;
                                    ordersUS.add(content);
                                    osIdsToUpdate.add(os.Id);
                                    isFirstItem = false;
                                } else if(salesChannel == SALESCHANNEL_CA) {
                                    totalNoOfLineItemsCA++;
                                    totalNoOfOrdersCA++;
                                    totalValueOfOrdersCA += os.GrandTotalAmount;
                                    ordersCA.add(content);
                                    osIdsToUpdate.add(os.Id);
                                    isFirstItem = false;
                                }
                            } else {
                                String content = getContent(os, ois, false, isGWPItem);
                                if(salesChannel == SALESCHANNEL_US) {
                                    totalNoOfLineItemsUS++;
                                    ordersUS.add(content);
                                } else if(salesChannel == SALESCHANNEL_CA) {
                                    totalNoOfLineItemsCA++;
                                    ordersCA.add(content);
                                }
                            }
                        }
                    }
                    for (String key : productBundleMap.keySet()) {
                        if (bundledProductMap.containsKey(key)) {
                            Boolean isFirstBundledProduct = true;
                            ProductBundle pb = productBundleMap.get(key);
                            List<BundledProduct> bpList = bundledProductMap.get(key);
                            Decimal totalChildLineItemQty = 0;
                            for(BundledProduct childLineItem : bpList) {
                                totalChildLineItemQty += childLineItem.ois.Quantity;
                            }
                            Integer totalBundledProducts = bpList.size();
                            for (BundledProduct bp : bpList) {
                                if (isFirstItem && isFirstBundledProduct) {
                                    List<String> content = getContentForBundledProduct(pb, bp, totalBundledProducts, totalChildLineItemQty, true, true, salesChannel);
                                    Decimal oisDiscount = (pb.ois.sfcc_ThreePayDiscount__c != null && pb.ois.sfcc_ThreePayDiscount__c > 0) ? 
                                        pb.ois.sfcc_ThreePayDiscount__c : Math.abs(pb.ois.TotalAdjustmentAmtWithTax);
                                    Decimal grandTotalAmt =
                                        (pb.ois.sfcc_ThreePayUnitPrice__c != null && pb.ois.sfcc_ThreePayUnitPrice__c > 0) ?
                                        (pb.ois.sfcc_ThreePayUnitPrice__c * pb.ois.Quantity) + pb.ois.TotalLineTaxAmount - oisDiscount :
                                        os.GrandTotalAmount;
                                    if (salesChannel == SALESCHANNEL_US) {
                                        totalNoOfLineItemsUS++;
                                        totalNoOfOrdersUS++;
                                        totalValueOfOrdersUS += grandTotalAmt;
                                        ordersUS.addAll(content);
                                        osIdsToUpdate.add(os.Id);
                                        isFirstBundledProduct = false;
                                        isFirstItem = false;
                                    } else if (salesChannel == SALESCHANNEL_CA) {
                                        totalNoOfLineItemsCA++;
                                        totalNoOfOrdersCA++;
                                        totalValueOfOrdersCA += grandTotalAmt;
                                        ordersCA.addAll(content);
                                        osIdsToUpdate.add(os.Id);
                                        isFirstBundledProduct = false;
                                        isFirstItem = false;
                                    }
                                } else if (isFirstBundledProduct) {
                                    List<String> content = getContentForBundledProduct(pb, bp, totalBundledProducts, totalChildLineItemQty,  false, true, salesChannel);
                                    if (salesChannel == SALESCHANNEL_US) {
                                        totalNoOfLineItemsUS++;
                                        ordersUS.addAll(content);
                                        isFirstBundledProduct = false;
                                    } else if (salesChannel == SALESCHANNEL_CA) {
                                        totalNoOfLineItemsCA++;
                                        ordersCA.addAll(content);
                                        isFirstBundledProduct = false;
                                    }
                                } else {
                                    List<String> content = getContentForBundledProduct(pb, bp, totalBundledProducts, totalChildLineItemQty,  false, false, salesChannel);
                                    if (salesChannel == SALESCHANNEL_US) {
                                        totalNoOfLineItemsUS++;
                                        ordersUS.addAll(content);
                                    } else if (salesChannel == SALESCHANNEL_CA) {
                                        totalNoOfLineItemsCA++;
                                        ordersCA.addAll(content);
                                    }  
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
    }
   
    //Here we are creating SAP Order export file for exporting to CPI
    public void finish(Database.BatchableContext bc) {
        List<ContentVersion> cvList = new List<ContentVersion>();
        String currentDT = System.now().format('yyyyMMddhhmmss', 'America/Los_Angeles');
        Set<Set<Id>> setOfIdSet;
        try {
            if (!ordersUS.isEmpty()) {
                ordersUS.add(0, totalNoOfOrdersUS + '|' + (totalNoOfLineItemsUS + usSplitCount) + '|' + totalValueOfOrdersUS);
            }
            ordersUS.add('EOF');
            String fileContentUS = String.join(ordersUS, '\n');
            String titleUS = 'ORDERS_VIVISCAL_' + currentDT;
            ContentVersion cvUS = new ContentVersion(
                ContentLocation = 'S',
                Title = titleUS,
                VersionData = Blob.valueOf(fileContentUS),
                PathOnClient = titleUS + '.txt');
            cvList.add(cvUS);
            
            if (!ordersCA.isEmpty()) {
                ordersCA.add(0, totalNoOfOrdersCA + '|' + (totalNoOfLineItemsCA + caSplitCount) + '|' + totalValueOfOrdersCA);
            }
            ordersCA.add('EOF');
            String fileContentCA = String.join(ordersCA, '\n');
            String titleCA = 'ORDERS_VIVISCALCA_' + currentDT;
            ContentVersion cvCA = new ContentVersion(
                ContentLocation = 'S',
                Title = titleCA,
                VersionData = Blob.valueOf(fileContentCA),
                PathOnClient = titleCA + '.txt');
            cvList.add(cvCA);
            
            if (!cvList.isEmpty()) {
                // if (!String.isBlank(startDateTime) && !String.isBlank(endDateTime)) {
                if (isCPIExport) {
                    SapFilesExport.exportFilesToCpi(cvList);
                }
                insert cvList;
            }
            
            if (!osIdsToUpdate.isEmpty()) {
                setOfIdSet = CustomCommonUtil.getIdSet(osIdsToUpdate);
                for (Set<Id> osIds : setOfIdSet) {
                    List<OrderSummary> osList = [SELECT Id, IsExportedToSAP__c FROM OrderSummary WHERE Id IN :osIds FOR UPDATE];
                    for (OrderSummary os : osList) {
                        os.IsExportedToSAP__c = true;
                    }
                    Database.SaveResult[] srList = Database.update(osList, false);
                    CustomCommonUtil.logDmlException(srList, className);
                }
            }
        } catch (Exception ex) {
             CustomCommonUtil.logException(className, ex);
        }
    }

    private String getContent(OrderSummary os, OrderItemSummary ois, Boolean isFirstItem, Boolean isGWPItem) {
        String content;
        String isMultiplePaymentTypes = os.NumberOfPaymentTypes__c > 1 ? 'Y' :  'N';
        String orderSource = os.sfcc_sourceChannel__c == 'Viviscal-WEB' ? 'WEB': os.sfcc_sourceChannel__c == 'TryViviscal-WEB' ? 'DTM' : 'WEB';
        String lotNumber = ois.LotNumber__c != null ? ois.LotNumber__c : '';
        String amwareShipDate = os.Shipments?.get(0)?.AmwareShipDate__c?.format('yyyyMMdd');
        Decimal unitPrice = isGWPItem ? 0.0 : ois.UnitPrice;
        Decimal quantity = ois.Quantity;
        Decimal grandTotalAmt = os.GrandTotalAmount;
        Decimal totalAdjustmentAmtWithTax = isGWPItem ? 0.0 : Math.abs(ois.TotalAdjustmentAmtWithTax);
        Decimal orderItemTotalAmt = quantity * unitPrice;
        Decimal orderTaxExcludingShippingTax = isGWPItem ? 0.0 : ois.TotalLineTaxAmount;//os.OriginalOrder.TotalTaxAmount - os.TotalDeliveryTaxAmount;
        if (isFirstItem) {
           	content = shipFrom + '|' + orderSource + '|' + os.OrderNumber + '|' + amwareShipDate + '|' +  
                ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + quantity + '|' + unitOfMeasure + '|' + unitPrice + '|' + os.CurrencyIsoCode + '|' + 
                orderItemTotalAmt + '|' + grandTotalAmt + '|' + orderTaxExcludingShippingTax + '|' + os.TotalAdjustedDeliveryAmount + '|' +
                os.TotalAdjustedDeliveryTaxAmount + '|' + totalAdjustmentAmtWithTax + '|' + isMultiplePaymentTypes;
        } else {
           	content = shipFrom +'|'+ orderSource +'|'+ os.OrderNumber + '|' + amwareShipDate + '|' + 
                ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + quantity + '|' + unitOfMeasure + '|' + unitPrice + '|' + os.CurrencyIsoCode + '|' +
                orderItemTotalAmt + '||'+orderTaxExcludingShippingTax+'|||' + totalAdjustmentAmtWithTax + '|' + isMultiplePaymentTypes;
        }
        return content;
    }
    
    private List<String> getContentForBundledProduct(ProductBundle pb, BundledProduct bp, Integer totalBundledProducts, Decimal totalChildLineItemQty, Boolean isFirstItem, Boolean isFirstBundledProdcut, String salesChannel) {
        List<String> content = new List<String>();
        String isMultiplePaymentTypes = pb.ois?.sfcc_ThreePayUnitPrice__c > 0  ? 'Y' :  'N';
        String orderSource = bp.os.sfcc_sourceChannel__c == 'Viviscal-WEB' ? 'WEB': bp.os.sfcc_sourceChannel__c == 'TryViviscal-WEB' ? 'DTM' : 'WEB';
        String lotNumber = bp.ois.LotNumber__c != null ? bp.ois.LotNumber__c : '';
        String amwareShipDate = bp.os.Shipments?.get(0)?.AmwareShipDate__c?.format('yyyyMMdd');
        Decimal quantity = bp.ois.Quantity;
        //if bundle qty is 2 and child line qty is 3 then total child line item qty is 6
        Decimal childToParentquantityRatio = bp.ois.Quantity/pb.ois.Quantity;
        //Decimal unitPrice = pb.ois.UnitPrice - (totalBundledProducts - 1);
        Decimal unitPrice;
        if (isFirstBundledProdcut) {
            if (quantity > 1) {
                unitPrice = (pb.ois.Quantity * pb.ois.UnitPrice) - (totalChildLineItemQty - bp.ois.Quantity) - (quantity - 1);
            } else {
                unitPrice = pb.ois.UnitPrice - (totalChildLineItemQty - bp.ois.Quantity);
            }
        } else {
            unitPrice = 1.00 * bp.ois.Quantity;
        }
        Decimal totalAdjustmentAmtWithTax = pb.ois.TotalAdjustmentAmtWithTax == 0 ? Math.abs(pb.ois.TotalAdjustmentAmtWithTax) : (isFirstBundledProdcut ?  Math.abs(pb.ois.TotalAdjustmentAmtWithTax) : 0.00);
        //3-pay changes
        unitPrice = pb.ois?.sfcc_ThreePayUnitPrice__c > 0 ? pb.ois.sfcc_ThreePayUnitPrice__c - (totalBundledProducts - 1) : unitPrice;
        
        if (isFirstBundledProdcut && pb.ois?.sfcc_ThreePayUnitPrice__c > 0) {
            if (quantity > 1) {
                unitPrice = (pb.ois.Quantity * pb.ois.sfcc_ThreePayUnitPrice__c) - (totalChildLineItemQty - bp.ois.Quantity) - (quantity - 1);
            } else {
                unitPrice = pb.ois.sfcc_ThreePayUnitPrice__c - (totalChildLineItemQty - bp.ois.Quantity);
            }
        } else if (pb.ois?.sfcc_ThreePayUnitPrice__c > 0) {
            unitPrice = 1.00;
        }

        totalAdjustmentAmtWithTax = (pb.ois?.sfcc_ThreePayDiscount__c > 0 && isFirstBundledProdcut) ? pb.ois.sfcc_ThreePayDiscount__c : totalAdjustmentAmtWithTax;
        Decimal orderItemTotalAmt =  unitPrice * (pb.ois.Quantity);
        Decimal orderTaxExcludingShippingTax =  pb.ois.TotalLineTaxAmount;
        Decimal grandTotalAmt = pb.ois?.sfcc_ThreePayUnitPrice__c > 0 ? (pb.ois.sfcc_ThreePayUnitPrice__c * pb.ois.Quantity) + orderTaxExcludingShippingTax - totalAdjustmentAmtWithTax : bp.os.GrandTotalAmount;

        if (isFirstItem && isFirstBundledProdcut) {//first child of the parent bundle and first line item of the order
            if(quantity > 1) {
                //split the first child line item into two line items.
                //The first line item will have 1 quantity and the second line item will hold the remaining quantity
                content.add(shipFrom +'|'+ orderSource +'|'+ bp.os.OrderNumber + '|' +  amwareShipDate + '|' + 
                    bp.ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + 1 + '|' + unitOfMeasure + '|' + 
                    unitPrice + '|' + bp.os.CurrencyIsoCode + '|' + unitPrice + 
                    '|' + grandTotalAmt + '|' + orderTaxExcludingShippingTax + '|' + bp.os.TotalAdjustedDeliveryAmount + 
                    '|' + bp.os.TotalAdjustedDeliveryTaxAmount + '|' + totalAdjustmentAmtWithTax + '|' + isMultiplePaymentTypes);

                content.add(shipFrom +'|'+ orderSource +'|'+ bp.os.OrderNumber + '|' +  amwareShipDate + '|' + 
                    bp.ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + (quantity - 1) + 
                    '|' + unitOfMeasure + '|' + 1.00 + '|' + bp.os.CurrencyIsoCode + '|' + 
                    (1.00 * (quantity - 1)) + '|||||0.00|' + isMultiplePaymentTypes);
                if(salesChannel == SALESCHANNEL_US) {
                    usSplitCount++;
                } else if(salesChannel == SALESCHANNEL_CA) {
                    caSplitCount++;
                }
            } else {
                content.add(shipFrom +'|'+ orderSource +'|'+ bp.os.OrderNumber + '|' +  amwareShipDate + '|' + 
                    bp.ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + quantity + '|' + unitOfMeasure + '|' + (unitPrice/childToParentquantityRatio) + '|' + bp.os.CurrencyIsoCode + '|' + 
                    orderItemTotalAmt + '|' + grandTotalAmt + '|' + orderTaxExcludingShippingTax + '|' + 
                    bp.os.TotalAdjustedDeliveryAmount + '|' + bp.os.TotalAdjustedDeliveryTaxAmount + '|' + 
                    totalAdjustmentAmtWithTax + '|' + isMultiplePaymentTypes);
            }
        } else if (isFirstBundledProdcut) {//first child of the parent bundle
            if(quantity > 1) {
                content.add(shipFrom +'|'+ orderSource +'|'+ bp.os.OrderNumber + '|' + amwareShipDate + '|' + 
                    bp.ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + 1 + '|' + unitOfMeasure + '|' + 
                    unitPrice + '|' + bp.os.CurrencyIsoCode + '|' + unitPrice + '||' + 
                    orderTaxExcludingShippingTax+'|||'+ totalAdjustmentAmtWithTax +'|' + isMultiplePaymentTypes);
                
                content.add(shipFrom +'|'+ orderSource +'|'+ bp.os.OrderNumber + '|' + amwareShipDate + '|' + 
                    bp.ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + (quantity - 1) + '|' + 
                    unitOfMeasure + '|' + 1.00 + '|' + bp.os.CurrencyIsoCode + '|' +
                    (1.00 * (quantity - 1)) + '|||||0.00|' + isMultiplePaymentTypes);
                if(salesChannel == SALESCHANNEL_US) {
                    usSplitCount++;
                } else if(salesChannel == SALESCHANNEL_CA) {
                    caSplitCount++;
                }
            } else {
                content.add(shipFrom +'|'+ orderSource +'|'+ bp.os.OrderNumber + '|' + amwareShipDate + '|' + 
                    bp.ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + quantity + '|' + unitOfMeasure + '|' + 
                    (unitPrice/childToParentquantityRatio) + '|' + bp.os.CurrencyIsoCode + '|' + orderItemTotalAmt + 
                    '||'+orderTaxExcludingShippingTax+'|||'+ totalAdjustmentAmtWithTax +'|' + isMultiplePaymentTypes);
            }
        } else {
            content.add(shipFrom +'|'+ orderSource +'|'+ bp.os.OrderNumber + '|' + amwareShipDate + '|' + 
            	bp.ois.sfcc_SAPMaterialCode__c + '|' + lotNumber + '|' + quantity + '|' + unitOfMeasure + 
                '|' + 1.00 + '|' + bp.os.CurrencyIsoCode + '|' + (1.00 * bp.ois.Quantity) + 
                '|||||' + totalAdjustmentAmtWithTax + '|' + isMultiplePaymentTypes);
        }

        return content;
    }
    
    class ProductBundle {
        OrderSummary os;
        OrderItemSummary ois;
        public ProductBundle(OrderSummary os, OrderItemSummary ois) {
            this.os = os;
            this.ois = ois;
        }
    }
    
    class BundledProduct {
        OrderSummary os;
        OrderItemSummary ois;
        public BundledProduct(OrderSummary os, OrderItemSummary ois) {
            this.os = os;
            this.ois = ois;
        }
    }

    private void filterGWPOrderItemSummaries(List<OrderSummary> orderSummaryList){
        Set<OrderItemSummary> orderItemSummaryList = new Set<OrderItemSummary>();
        for (OrderSummary os : orderSummaryList) {
            for (OrderItemSummary ois : os.OrderItemSummaries) {
                orderItemSummaryList.add(ois);
            }
        }
        if(orderItemSummaryList.size() > 0) {
            List<OrderItemAdjustmentLineSummary> gwpItemAdjList = new List<OrderItemAdjustmentLineSummary>();
            gwpItemAdjList = [SELECT OrderItemSummaryId 
                                FROM OrderItemAdjustmentLineSummary 
                                WHERE Name LIKE '%gwp%' AND OrderItemSummaryId IN :orderItemSummaryList];
            for(OrderItemAdjustmentLineSummary oials: gwpItemAdjList){
                this.gwpOrderItemSummaries.add(oials.OrderItemSummaryId);
            }
        }
    }
}