global class OmsJobsPayment implements Schedulable {
    /**
    * @description execute
    * @param sc the SchedulableContext
    **/
    global void execute(SchedulableContext sc) {
        OmsPaymentX.assignCreditMemoReferenceRefund();
    }
}
