global class UserInfoX {
    /**
    * @description gets the environment settings
    **/
    static SystemX.Environment s_environment;
    global static SystemX.Environment environment() {
        if (s_environment != null) { return s_environment; }
        Organization org = [SELECT Division, IsSandbox FROM Organization LIMIT 1];
        SystemX.Environs env; String fix;
        if (!org.IsSandbox) { env = SystemX.Environs.PRODUCTION; fix = ''; }
        else {
            switch on org.Division {
                when 'Development', 'Develop' { env = SystemX.Environs.DEVELOPMENT; fix = 'd'; }
                when 'Staging', 'Stage' { env = SystemX.Environs.STAGING; fix = 's'; }
                when 'Production' { env = SystemX.Environs.PRODUCTION; fix = ''; }
                when else { env = SystemX.Environs.UNKNOWN; fix = 'u'; }
            }
        }
        s_environment = new SystemX.Environment(env, fix);
        return s_environment;
    }
    
    /**
    * @description has isMultiCurrencyOrganization
    **/
    // global static Boolean s_isMultiCurrencyOrganization = isMultiCurrencyOrganization();
    // static Boolean isMultiCurrencyOrganization() {
    //     try
    //     {
    //         new PaymentAuthorization().get('CurrencyIsoCode');
    //         return true;
    //     } catch (Exception e) { return false; }
    // }

    /**
    * @description checks if the organization is enabled
    * @return Boolean
    **/
	global static Boolean isEnabledOrganization() {
        String id = UserInfo.getOrganizationId();
        String enabledOrganizationIds = SystemX.options?.enabledOrganizationIds();
		return enabledOrganizationIds != null && enabledOrganizationIds.contains(id);
	}

    /**
    * @description specifies whether the organization has person accounts
    **/
    static Boolean s_isPersonAccountOrganization;
    global static Boolean isPersonAccountOrganization() {
        if (s_isPersonAccountOrganization != null) { return s_isPersonAccountOrganization; }
        s_isPersonAccountOrganization = Schema.SObjectType.Account.fields.getMap().containsKey('IsPersonAccount');
        return s_isPersonAccountOrganization;
    }

    /**
    * @description specifies whether the organization is a sandbox
    **/
    static Boolean s_isSandboxOrganization;
    global static Boolean isSandboxOrganization() {
        if (s_isSandboxOrganization != null) { return s_isSandboxOrganization; }
        s_isSandboxOrganization = [SELECT IsSandbox FROM Organization LIMIT 1]?.IsSandbox == true;
        return s_isSandboxOrganization;
    }

    /**
    * @description specifies whether the organization has state & country picklists
    **/
    static Boolean s_isStateAndCountryPicklistOrganization;
    global static Boolean isStateAndCountryPicklistOrganization() {
        if (s_isStateAndCountryPicklistOrganization != null) { return s_isStateAndCountryPicklistOrganization; }
        s_isStateAndCountryPicklistOrganization = Schema.SObjectType.Account.fields.getMap().containsKey('BillingStateCode');
        return s_isStateAndCountryPicklistOrganization;
    }
}