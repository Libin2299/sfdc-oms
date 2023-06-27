@isTest
class NumericXTest {
    @isTest static void shouldFormatCurrency() {
        System.assertEquals(null, NumericX.formatCurrency(null, 'USD'));
        System.assertEquals('$1.50', NumericX.formatCurrency(1.5, 'USD'));
        System.assertEquals('€1.50', NumericX.formatCurrency(1.5, 'EUR'));
        System.assertEquals('£1.50', NumericX.formatCurrency(1.5, 'GBP'));
        System.assertEquals('$1.50', NumericX.formatCurrency(1.5, 'AUD'));
        System.assertEquals('$1.50', NumericX.formatCurrency(1.5, 'CAD'));
        System.assertEquals('1.50', NumericX.formatCurrency(1.5, null));
    }

    @isTest static void shouldFormatDatetime() {
        System.assertEquals('2001-01-01T00:00:00Z000', NumericX.formatDatetime(DateTime.newInstanceGmt(2001, 1, 1), 'iso', 'GMT'));
    }
}