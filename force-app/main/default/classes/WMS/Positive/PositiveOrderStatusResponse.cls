public class PositiveOrderStatusResponse {

	public class Products {
		public String productCode;
		public String productDescription;
		public Integer quantityOrdered;
		public Integer quantityBackOrdered;
		public Integer quantityShipped;
		public String customerProductCode;
		public List<InventoryDetails> inventoryDetails;
	}

	public Integer orderNumber;
	public String customersOrderNumber;
	public String orderReceivedOn;
	public String processedOn;
	public String waybilledOn;
	public String offDockedOn;
	public String waybillNumber;
	public String poNumber;
	public ShippingAddress shippingAddress;
	public Carrier carrier;
	public List<Products> products;
	public String orderStatus;
	public String deliveryDate;

	public class InventoryDetails {
		public String inventoryCode;
		public String lotNumber;
		public String expiryDate;
		public Integer quantityShipped;
	}

	public class ShippingAddress {
		public String contact;
		public String clientName;
		public String address1;
		public String address2;
		public String city;
		public String province;
		public String postalCode;
		public String countryCode;
	}

	public class Carrier {
		public String name;
		public String code;
		public String shippingModule;
		public String trackingUrl;
	}

	public static PositiveOrderStatusResponse parse(String json) {
		return (PositiveOrderStatusResponse) System.JSON.deserialize(json, PositiveOrderStatusResponse.class);
	}
}