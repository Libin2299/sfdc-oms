public class PositiveGetOrderStatusResponse {

	public Integer offset;
	public Integer limit_Z;
	public Integer totalCount;
	public String first;
	public String previous;
	public String next;
	public String last;
	public List<Items> items;

	public class Items {
		public String orderNumber; 
		public String orderId; 
		public String consigneeName; 
		public String receivedOn; 
		public String offDocked;
		public String cancelledOn; 
		public String referenceNumber; 
		public String courierWaybillNumber; 
		public String freightWaybillNumber; 
		public String shippingMethod; 
		public String fulfillmentCenter; 
		public String customerCode;
    }

    public static PositiveGetOrderStatusResponse parse(String json) {
        return (PositiveGetOrderStatusResponse) System.JSON.deserialize(json, PositiveGetOrderStatusResponse.class);
    }
}