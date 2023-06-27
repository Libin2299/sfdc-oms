public class CaptureAsynRefunds implements Schedulable {
    public static String className = CaptureAsynRefunds.class.getName();

    public void execute(SchedulableContext context) {
		linkRefundToChangeOrder();
	}
    /**
    * @description assign the Refund to the Custom Refund record
    **/
    public static void linkRefundToChangeOrder() {
        Map<String, List<Custom_Refund__c>> customRefundMap = new Map<String, List<Custom_Refund__c>>();
        List<Custom_Refund__c> customRefundListToUpdate = new List<Custom_Refund__c>();
        List<Refund> refundListToUpdate = new List<Refund>();
        try {
            List<Refund> refundList = [SELECT Id, OrderPaymentSummaryId, TotalApplied, Amount FROM Refund WHERE IsLinkedToCustomRefund__c = false ORDER BY CreatedDate DESC];
            List<Custom_Refund__c> customRefundList = [SELECT Id, Reference_Refund__c, Reference_Order_Payment_Summary__c, Reference_ChangeOrder__c, Reference_ChangeOrder__r.GrandTotalAmount  FROM Custom_Refund__c WHERE Reference_Refund__c = null ORDER BY CreatedDate DESC];
            for (Custom_Refund__c customRefund : customRefundList) {
                if (customRefundMap.containsKey(customRefund.Reference_Order_Payment_Summary__c)) {
                    customRefundMap.get(customRefund.Reference_Order_Payment_Summary__c).add(customRefund);
                } else {
                    customRefundMap.put(customRefund.Reference_Order_Payment_Summary__c, new List<Custom_Refund__c>{customRefund});
                }
            }
            for (Refund ref : refundList) {
                if (!customRefundMap.containsKey(ref.OrderPaymentSummaryId)) { break; }
                List<Custom_Refund__c> crList = customRefundMap.get(ref.OrderPaymentSummaryId);
                for (Custom_Refund__c cr : crList) {
                    if (cr.Reference_Refund__c == null) {
                        Decimal grandTotalAmount = Math.abs(cr.Reference_ChangeOrder__r.GrandTotalAmount);
                        if (grandTotalAmount == ref.Amount) {
                            cr.Reference_Refund__c = ref.Id;
                            customRefundListToUpdate.add(cr);
                            ref.IsLinkedToCustomRefund__c = true;
                            refundListToUpdate.add(ref);
                            break;
                        }
                    }
                }
            }
            
            if (!customRefundListToUpdate.isEmpty()) {
                update customRefundListToUpdate;
            }
            
            if (!refundListToUpdate.isEmpty()) {
                update refundListToUpdate;
            }
        } catch (Exception ex) {
        	CustomCommonUtil.logException(className, ex);
    	}
    } 
}