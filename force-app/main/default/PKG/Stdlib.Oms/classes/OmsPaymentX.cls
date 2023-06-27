global class OmsPaymentX {
    /**
    * @description assign the CreditMemo ReferenceRefund field
    **/
    global static void assignCreditMemoReferenceRefund() {
        List<RefundLinePayment> scope;
        if(Test.isRunningTest()) {
            scope = [SELECT PaymentId, Payment.Status
            FROM RefundLinePayment WHERE Refund.Status = 'Processed' And (Payment.OrderPaymentSummaryId != null Or Payment.Comments != null) LIMIT 10];
        }
        else
        {
         scope = [SELECT PaymentId, Payment.Status
            FROM RefundLinePayment WHERE Refund.Status = 'Processed' And (Payment.OrderPaymentSummaryId != null Or Payment.Comments != null)];   
        }
        if (scope.isEmpty()) { return; }

        List<Payment> payments = new List<Payment>();
        for (RefundLinePayment s : scope) { payments.add(s.Payment); }
        if (!payments.isEmpty()) { assignCreditMemoReferenceRefund(payments); }
    }

    /**
    * @description assign the CreditMemo ReferenceRefund field
    * @param items the items
    **/
    global static void assignCreditMemoReferenceRefund(List<Payment> items) {
        Map<Id, Map<Id, Refund>> scope = new Map<Id, Map<Id, Refund>>();
        for (RefundLinePayment s : [
            SELECT RefundId, Refund.CreatedDate, Refund.Amount, Payment.Comments, Payment.OrderPaymentSummary.OrderSummaryId
            FROM RefundLinePayment WHERE PaymentId in :items ORDER BY Refund.CreatedDate, Refund.Amount]) {
            Id summaryId = Test.isRunningTest() && s.Payment.Comments != null ? s.Payment.Comments : s.Payment.OrderPaymentSummary?.OrderSummaryId;
            if (summaryId != null) {
                if (!scope.containsKey(summaryId)) { scope.put(summaryId, new Map<Id, Refund>()); }
                scope.get(summaryId).put(s.Refund.Id, s.Refund);
            }
        }
        if (scope.isEmpty()) { return; }

        // assign
        List<CreditMemo> updates = new List<CreditMemo>();
        for (Id summaryId : scope.keySet()) {
            Map<Id, Refund> refundById = scope.get(summaryId);
            for (CreditMemo s : [
                SELECT Id, CreatedDate, TotalAmountWithTax, ReferenceRefund__c
                FROM CreditMemo WHERE ReferenceEntityId = :summaryId ORDER BY ReferenceRefund__c NULLS LAST, CreatedDate, TotalAmountWithTax]) {
                Boolean found = false;
               
                // remove already assigned
                if (s.ReferenceRefund__c != null) { 
                    System.debug('Existing Assignment: '+ s.ReferenceRefund__c);
                    refundById.remove(s.ReferenceRefund__c);
                    continue;
                }

                // assign first amount equals
                System.debug('Assign first amount equals');
                for (Refund r : refundById.values()) {
                    System.debug('Refund: '+ r.Id +' - '+ r.Amount);
                    if (r.Amount == s.TotalAmountWithTax) {
                        System.debug('Assign by amount equals: '+ s.Id +' -> '+ r.Id);
                        refundById.remove(r.Id);
                        s.ReferenceRefund__c = r.Id;
                        updates.add(s);
                        found = true;
                        break;
                    }
                }
                if (found) { continue; }

                // assign first amount
                System.debug('Assign first amount');
                for (Refund r : refundById.values()) {
                    if (r.Amount < s.TotalAmountWithTax) {
                        System.debug('Assign by first amount: ' + s.Id + ' -> ' + r.Id);
                        refundById.remove(r.Id);
                        s.ReferenceRefund__c = r.Id;
                        updates.add(s);
                        found = true;
                        break;
                    }
                }
                if (found) { continue; }

                // not found
                System.debug('Orphan: '+ s);
            }
        }

        System.debug('updates: '+ updates.size());
        if (!updates.isEmpty()) { Database.update(updates, false); }
    }
}