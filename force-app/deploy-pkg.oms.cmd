sfdx force:source:deploy -p "./main/default/PKG/Stdlib.Oms/,./main/default/classes/AppQuickSchedule.cls,./main/default/classes/AppQuickScheduleTest.cls" -l RunSpecifiedTests -r ConnectApiXTest,OmsOrderDataFactoryTest,NopGatewayAdapterTest,OmsImportsTest,OmsJobsTest,OmsPaymentXTest,OmsSystemXTest,AppQuickScheduleTest
pause