global virtual class DefaultOptions implements IOptions {
    /**
    * @description gets enabled organization ids
    * @return String
    **/
    global virtual String enabledOrganizationIds() { return UserInfo.getOrganizationId(); }
    
    /**
    * @description gets the environment
    * @return SystemX.Environment
    **/
    global virtual SystemX.Environment environment() { return UserInfoX.environment(); }
    
    /**
    * @description gets the service actions
    * @return Map<String, ServiceX.IServiceAction>
    **/
    global virtual Map<String, ServiceX.IServiceAction> serviceActions() {
        return new Map<String, ServiceX.IServiceAction> {
            ServiceX.EchoServiceAction_Name => new ServiceX.EchoServiceAction(),
            EventBusX.PublishServiceAction_Name => new EventBusX.PublishServiceAction()
        };
    }

    /**
    * @description gets the service user
    * @return String
    **/
    global virtual String serviceUserAlias(String type) { return null; }
}