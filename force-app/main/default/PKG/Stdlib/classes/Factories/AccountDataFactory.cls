global virtual class AccountDataFactory implements IAccountDataFactory {
    /**
    * @description get instance
    * @return IAccountDataFactory
    **/
    global static IAccountDataFactory get {
        get { return (IAccountDataFactory)SystemX.getFactory(AccountDataFactory.class); }
    }

    /**
    * @description creates an account
    * @param name the name
    * @return Account
    **/
    global virtual Account createAccount(String name) {
        String[] fields = new String[] { 'Id', 'BillingStreet', 'BillingCity', 'BillingPostalCode', 'BillingCountry', 'Phone' };
        fields.addAll(UserInfoX.isStateAndCountryPicklistOrganization()
            ? new String[] { 'BillingStateCode' }
            : new String[] { 'BillingState' });
        fields.addAll(UserInfoX.isPersonAccountOrganization()
            ? new String[] { 'FirstName', 'LastName', 'PersonEmail' }
            : new String[] { 'Name' });
        Account account;
        List<Account> accounts = Database.query('SELECT ' + String.join(fields, ', ') + ' FROM Account WHERE Name = :name LIMIT 1');
        if (accounts.isEmpty()) {
            account = new Account(
                BillingStreet = '1166 W Newport Center Dr',
                BillingCity = 'Deerfield Beach',
                BillingPostalCode = '33442',
                BillingCountry = 'United States',
                Phone = '3333333333'
            );
            if (UserInfoX.isStateAndCountryPicklistOrganization()) {
                account.put('BillingStateCode', 'FL');
            } else {
                account.put('BillingState', 'FL');
            }
            if (UserInfoX.isPersonAccountOrganization()) {
                account.put('FirstName', 'John');
                account.put('LastName', 'Doe');
                account.put('PersonEmail', 'john@doe.com');
            } else {
                account.put('Name', 'John Doe');
            }
            account.Business_Unit__c = 'US';
            account.put('BillingCountryCode', 'US');
            insert account;
        } else { account = accounts[0]; }
        return account;
    }
}