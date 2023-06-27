public class PositiveOrderRequest {

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
}