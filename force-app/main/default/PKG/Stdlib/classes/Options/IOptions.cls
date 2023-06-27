global interface IOptions {
    String enabledOrganizationIds();
    SystemX.Environment environment();
    Map<String, ServiceX.IServiceAction> serviceActions();
    String serviceUserAlias(String type);
}