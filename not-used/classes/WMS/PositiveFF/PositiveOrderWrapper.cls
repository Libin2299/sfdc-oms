public class PositiveOrderWrapper {

    public class Consignee {
        public String consigneeCode;
        public String companyName;
        public String firstName;
        public String lastName;
        public String address1;
        public String address2;
        public String city;
        public String provinceCode;
        public String postalCode;
        public String countryCode;
        public String telephone;
        public Integer telephoneExtension;
        public String email;
        public String languageCode;
    }

    public Consignee consignee;
    public String uniqueOrderReference;
    public String dateOfOrder;
    public String purchaseOrderNumber;
    public String customersOrderNumber;
    public String specialComments;
    public String shippingComments;
    public String carrierCode;
    public String serviceCode;
    public Integer projectCode;
    public String orderType;
    public List<DynamicFields> dynamicFields;
    public List<OrderLineDetails> orderLineDetails;

    public class DynamicFields {
        public String dynamicField;
        public String dynamicValue;
    }

    public class OrderLineDetails {
        public String customerProductCode;
        public Integer quantityOrdered;
        public Integer quantityToShip;
        public Integer unitPrice;
        public String unitOfMeasure;
        public List<DynamicFields> dynamicFields;
    }

    
    public static PositiveOrderWrapper parse(String json) {
        return (PositiveOrderWrapper) System.JSON.deserialize(json, PositiveOrderWrapper.class);
    }

    public static String getStateCode(String state) {
        Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple){
            System.debug(f.getLabel() +'::'+ f.getValue());
            if(state == f.getLabel()){
                return f.getValue();
            }
        }
        return null;
    }

    public static String getCountryCode(String country) {
        Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple){
            System.debug(f.getLabel() +'::'+ f.getValue());
            if(country == f.getLabel()){
                return f.getValue();
            }
        }
        return null;
    }

    public static String getUserLanguage(){
        String language, userLanguage = UserInfo.getLanguage();
        for(PicklistEntry value: User.LanguageLocalekey.getDescribe().getPicklistValues()) {
            if(value.getValue() == userLanguage) {
                language = value.getLabel();
                return language;
            }
        }
        return 'EN';
    }
}