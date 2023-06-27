public class AmwareReturnsResponse {
	static String className = AmwareReturnsImportJobTest.class.getName();
	public class Returns {
		public String dateReceived;
		public String facility;
		public String clientReference;
		public Boolean blindReturn;
		public String internalOrderId;
		public String reasonForReturn;
		public String firstName;
		public String lastName;
		public String company;
		public String streetAddress1;
		public String streetAddress2;
		public String city;
		public String state;
		public String zip;
		public String country;
		public String carrier;
		public String trackingNumber;
		public String comments;
		public String createdAt;
		public List<ReturnLines> returnLines;

	}

	public List<Returns> returns;
	public Integer recordCount;

	public class ReturnLines {
		public String sku;
		public String lot;
		public String serialNumber;
		public Integer quantity;
		public String dispositionCode;
		public String disposition;
		public String notes;
	}
	
	public static AmwareReturnsResponse parse(String json) {
		//return (AmwareReturnsResponse) System.JSON.deserialize(json, AmwareGetReturnsResponse.class);
        AmwareReturnsResponse returnResObj;
        try {
            returnResObj = (AmwareReturnsResponse) System.JSON.deserialize(json, AmwareReturnsResponse.class);
        } catch(Exception ex) {
            CustomCommonUtil.logException(className, ex);
        }
        return returnResObj;
	}
}