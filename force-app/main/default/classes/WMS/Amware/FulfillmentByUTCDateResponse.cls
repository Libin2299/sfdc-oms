public class FulfillmentByUTCDateResponse {
    public List<ShipConfirms> shipConfirms;
	public Integer recordCount;
    
    public class ShipConfirms {
		public Integer internalOrderId;
		public String externalOrderId;
		public String clientReference;
		public Integer clientId;
		public String orderSource;
		public String shipType;
		public List<Packages> packages;
	}
    
    public class Packages {
		public String facilityId;
		public Integer shipmentId;
		public Object shipConfirmReceived;
		public String carrier;
		public String service;
		public Integer shipmentgGroupId;
		public String trackingNumber;
		public String trackingURI;
		public Object proNumber;
		public String description;
		public Integer packageType;
		public Double length;
		public Double width;
		public Double depth;
		public Double volume;
		public Double weight;
		public String shipDate;
		public Object internalLicensePlate;
		public Object externalLicensePlate;
		public List<LineItems> lineItems;
	}

    public class LineItems {
		public String sku;
		public Integer quantity;
		public Integer lineNo;
		public String lotNumber;
		public String externalLineId;
		public String serialNumber;
		public String pass01;
		public String pass02;
		public String pass03;
		public String pass04;
		public Object pass05;
	}
    
	public static FulfillmentByUTCDateResponse parse(String json) {
        FulfillmentByUTCDateResponse fulfillmentResObj;
        try {
            fulfillmentResObj = (FulfillmentByUTCDateResponse) System.JSON.deserialize(json, FulfillmentByUTCDateResponse.class);
        } catch(JSONException ex) {
            System.debug('Exception ' + ex.getMessage() + 'Line Number' + ex.getTypeName() + 'StackTrace Details ' + ex.getStackTraceString());
        }
        return fulfillmentResObj;
	}
}