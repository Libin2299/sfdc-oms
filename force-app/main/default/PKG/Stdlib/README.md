# Standard Library (stdlib) 

A general purpose standard library for the Salesforce Core Platform which includes functions involving DML, scheduling, conversions and others.


## Member functions
---
Stdlib provides the following static functions:

**EventBusX** | **Description**
-- | --
`publish(List<SObject> sobjects)` | publishes events
`publish(String endpoint, String accessToken, List<SObject> sobjects)` | publishes events remotely
`publishFeedItem(Id parentId, String body)` | publishes a feed item
**MapX** | **Description**
`put(Map<String, String> source, String key, Object value)` | puts a value
`put(Map<String, Object> source, String key, Object value)` | puts a value
`putAll(Map<String, String> source, Map<String, String> fromMap)` | puts all values
`putAll(Map<String, Object> source, Map<String, Object> fromMap)` | puts all values
`putIf(Map<String, String> source, Boolean predicate, String key, Object value)` | puts a value if a condition
`putIf(Map<String, Object> source, Boolean predicate, String key, Object value)` | puts a value if a condition
`putIfNotNull(Map<String, String> source, String key, Object value)` | puts a value if not null
`putIfNotNull(Map<String, Object> source, String key, Object value)` | puts a value if not null
**NumericX** | **Description**
`formatCurrency(Object value, String currencyCode)` | formats a currency value
`formatDatetime(Object value)` | formats a datetime value
**ObjectX** | **Description**
`decodeOf(String value)` | decodes an object
`encodeOf(Type type, Object value)` | encodes an object
`get(SObject obj, String field)` | gets a sobject's value
`getAll(SObject obj, List<String> fields)` | gets all sobject's values
`getAll(SObject obj, String fields)` | gets all sobject's values
`put(SObject obj, String field, Object value)` | sets a sobject's value
`putAll(SObject obj, Map<String, Object> values)` | sets all sobject's values
`putAll(SObject obj, String values)` | sets all sobject's values
**StringX** | **Description**
`clamp(String source, Integer length)` | clamps a string
`chunkStringAt(String source, Integer index, Integer size)` | chunks a string at index
`decodeMap(String values)` | decodes a map
`encodeMap(Map<String, Object> values)` | encodes a map
**SystemX** | **Description**
`debug(Object o)` | debugs a value
`getFactory(Type klass)` | gets the factory (singleton)
`getOption(Type klass)` | gets the options (singleton)
`getServiceUser(String type)` | gets the service user
`getTimestamp()` | gets a timestamp
`ifNull(String value, String defaultValue)` | if null ternary
`ifNull(Object value, Object defaultValue)` | if null ternary
`options` | the options
`threadSleep(Integer milliseconds)` | spinlocks the thread
**UserInfoX** | **Description**
`environment()` | gets the environment settings
`isEnabledOrganization()` | checks if the organization is enabled
`isPersonAccountOrganization()` | specifies whether the organization has person accounts
`isSandboxOrganization()` | specifies whether the organization is a sandbox
`isStateAndCountryPicklistOrganization()` | specifies whether the organization has state & country picklists

## CalloutServices
---
Easily register multiple http callout mocks in your test classes:
```java
Test.setMock(HttpCalloutMock.class, new stx.HttpCalloutServiceMultiMock(new Map<String, HttpCalloutServiceMock> {
    'https://domain/access_token' => new stx.HttpCalloutServiceMock(200, '{"access_token":"L2qIkgWTl8TJQz_MGjMZUQ_g7Fo"}'),
    'callout:MYCALLOUT/myurl' => new stx.HttpCalloutServiceMock(200, '{"body": null}')
}));
```

**ServiceX** | **Description**
-- | --
`submit(String endpoint, String accessToken, String action, Type type, Object std)` | submits a request


## Clouds
---
Clouds connect to SFMC, SFCC or other Oauth Services

**CloudX** | **Description**
-- | --
`getSfccAccessToken()` | gets a SFCC access token
`getSfmcAccessToken()` | gets a SFMC access token
`getOauthAccessToken(String format, String endpoint, String grantType, String clientId, String clientSecret, String scope)` | gets an OAuth access token
`getSfmcEndpoint(Map<String, Object> accessToken, String type, string endpoint)` | gets a SFMC endpoint
`getSfccEndpoint(Map<String, Object> accessToken, String type, string endpoint)` | gets a SFCC endpoint
`options` | the options
`callout(String callout, Map<String, Object> accessToken, Map<String, Object> args)` | makes a callout
`calloutSfccBatch(String callout, Map<String, Object> accessToken, List<Map<String, Object>> batch, Map<String, Object> headerArgs, Map<String, Object> args)` | makes a SFCC batched callout


## DatabaseJob
---
Simply apply DML batched updates.

`DatabaseJob` is a `Database.Batchable<SObject>` with the following constructor:

**Constructor** | **Type** | **Description**
--      | --       | -- |
`query` | String   | batchable query
`action`   | Object      | runable actions of types: (Update, UpdateRef, Delete, DeleteRef)
`batchSize` *(optional)*  | Integer | batch size to use
`allOrNone` *(optional)* | Boolean | publishes events remotely

The `run()` method will execute the job.

Action types:

* **InsertRefAction** - A referenced record insert action

    `DatabaseJob.InsertRefAction` has the following constructor:

    **Constructor** | **Type** | **Description**
    -- | -- | --
    `record` | Type  | the referenced record class
    `recordIdField` | String  | the field with the record id
    `values` | Object | the inserted values

    *Example Insert Ref*
    ```java
    new stx.DatabaseJob('SELECT Id, OrderPaymentSummary.OrderSummaryId FROM PaymentAuthorization WHERE Balance > 0',
        new stx.DatabaseJob.InsertRefAction(OrderSummary.class, 'OrderPaymentSummary', TBD)).run();
    ```

* **UpdateAction** - A simple record update action

    `DatabaseJob.UpdateAction` has the following constructor:

    **Constructor** | **Type** | **Description**
    --     | --     | --
    `field` | String  | the updated field
    `value` | Object  | the updated value

    *Example Update*
    ```java
    new stx.DatabaseJob('SELECT Id FROM Account',
        new stx.DatabaseJob.UpdateAction('Description', 'my value')).run();
    ```

* **UpdateRefAction** - A referenced record update action

    `DatabaseJob.UpdateRefAction` has the following constructor:

    **Constructor** | **Type** | **Description**
    --     | --     | --
    `record` | Type  | the referenced record class
    `recordIdField` | String  | the field with the record id
    `field` | String  | the updated field
    `value` | Object  | the updated value

    *Example Update Ref*
    ```java
    new stx.DatabaseJob('SELECT Id, OrderPaymentSummary.OrderSummaryId FROM PaymentAuthorization WHERE Balance > 0',
        new stx.DatabaseJob.UpdateRefAction(OrderSummary.class, 'OrderPaymentSummary.OrderSummaryId', 'Recapture__c', true)).run();
    ```

* **DeleteAction** - A simple record delete action

    `DatabaseJob.DeleteAction` has the following constructor:

    **Constructor** | **Type** | **Description**
    --    | --     | --
    `n/a` |  |

    *Example Delete*
    ```java
    new stx.DatabaseJob('Select Id From FlowInterview',
        new stx.DatabaseJob.DeleteAction()).run();
    ```

* **DeleteRefAction** - A referenced record delete action

    `DatabaseJob.DeleteRefAction` has the following constructor:

    **Constructor** | **Type** | **Description**
    --     | --     | --
    `record` | Type  | the referenced record class
    `recordIdField` | String  | the field with the record id

    *Example Delete Ref*
    ```java
    new stx.DatabaseJob('Select OwnerId From Account',
        new stx.DatabaseJob.DeleteRefAction(User.class, 'OwnerId')).run();
    ```

* **FlowAction** - A simple record flow and update action

    `DatabaseJob.FlowAction` has the following constructor:

    **Constructor** | **Type** | **Description**
    --     | --     | --
    `flowField` | String  | the flow field
    `field` | String  | the updated field
    `value` | Object  | the updated value

    *Example Flow*
    ```java
    new stx.DatabaseJob('SELECT Id FROM Account',
        new stx.DatabaseJob.FlowAction('Account_Flow.AccountId', 'Description', 'my value')).run();
    ```

* **FlowRefAction** - A referenced record flow and update action

    `DatabaseJob.FlowRefAction` has the following constructor:

    **Constructor** | **Type** | **Description**
    --     | --     | --
    `record` | Type  | the referenced record class
    `recordIdField` | String  | the field with the record id
    `flowField` | String  | the flow field
    `field` | String  | the updated field
    `value` | Object  | the updated value

    *Example Flow Ref*
    ```java
    new stx.DatabaseJob('SELECT Id, OrderPaymentSummary.OrderSummaryId FROM PaymentAuthorization WHERE Balance > 0',
        new stx.DatabaseJob.FlowRefAction(OrderSummary.class, 'OrderPaymentSummary.OrderSummaryId', 'Order_Capture_Flow.OrderSummaryId', 'Recapture__c', true)).run();
    ```

* **CustomAction** - A custom action

    `DatabaseJob.CustomAction` must be created and implement `execute(...)`:


## Factories
---
Factories generate test data.

**AccountDataFactory** *(test only)* | **Description**
-- | --
`createAccount(String name)` | creates an account
**UserDataFactory** *(test only)* | **Description**
-- | --
`createUser(Account acc, Contact con, Profile pro)` | creates a user object
`createUser(String name, String lastname, Profile pro)` | creates a user object
`createEmail(String name, String lastname)` | creates an email address
`createAlias(String name, String lastname)` | creates an alias


## LogBuilder
---
A generic transactional log to capture web calls and responses.

```java
class MyLogBuilder extends stx.LogBuilder {
    global protected override Map<Schema.SObjectType, String> makeRelatedMap() {
        return new Map<Schema.SObjectType, String> { Schema.OrderSummary.SObjectType => 'OrderSummaryId' };
    }
    global protected override SObject createLog() { return new MyGatewayLog__c(); }
}
```

*Example LogBuilder*
```java
List<MyGatewayLog__c> logs = new List<MyGatewayLog__c>();
logs.add(new MyLogBuilder()
    .relatedTo(orderSummary.Id)
    .withRequest(req)
    .withResponse(res)
    .withErrorMessage(errorMessage)
    .setInteractionType('Fulfillment')
    .setGatewayMessage(gatewayMessage)
    .build());
```

## Notification Service
---
Notification Service to initiate Email or other types of notifications

**NotificationService** | **Description**
-- | --
`Class:Notification` | sub-class holding the notification requested
`Invokeable:Send Notification` | invokeable to call to send a notificaiton
`sendNotifications(List<Notification> notifications)` | sendscreates an email address


### NotificationServiceEvent
* Reference - transfer reference
* ReferenceEntityId - transfer reference entityid
* Locale - transfer locale

### NotificationServiceProvider
* ApexAdapter - class name to use
* Reference - reference name for this notification
* Locale - locale supported for this notification or null for default

## Options
---
A simple configuration loader using SystemX.getOptions(). An AppOption instance will be returned if found otherwise the provided class will be returned.

The class name, with App prepended and Default removed, will be searched for and returned if found otherwise the provided class will be returned.

**DefaultOmsOptions** | **Description**
-- | --
`factoryTestOrder()` | gets the factory TestOrder name
`factorySalesChannel()` | gets the factory SalesChannel name
`factoryDeliveryMethod()` | gets the factory DeliveryMethod name
`factoryPaymentGateway()` | gets the factory PaymentGateway name
`createFulfillmentOrdersFlow()` | gets the createFulfillmentOrdersFlow name
`createInvoiceAndEnsureFundsFlow()` | gets the createInvoiceAndEnsureFundsFlow name
**DefaultOptions** | **Description**
-- | --
`enabledOrganizationIds()` | gets enabled organization ids
`environment()` | gets the environment
`serviceActions()` | gets the service actions
`serviceUserAlias(String type)` | gets the service user

*Example implementation in CloudX*
```java
global static ICloudOptions options = (ICloudOptions)SystemX.getOptions(DefaultCloudOptions.class);
```

## QuickSchedule
---
A simple schedule job runner, which allows multiple jobs to run and with sub-hour intervals.

extend `stx.QuickSchedule` and override `getJobs()` with the list of jobs you want to execute:

```java
global class MyQuickSchedule extends stx.QuickSchedule {
    global protected override List<QuickScheduleJob> getJobs() {
        return new List<QuickScheduleJob> {
            new QuickScheduleJob(5, MyJobsClass.class)
        };
    }
}
```


`MyQuickSchedule` can be executed and re-schedule with `run()`: 
```java
new MyQuickSchedule().run();
```

### Jobs
`QuickScheduleJob` is a `Schedulable` with the following constructor:

| **Constructor**  | **Type** | **Description** |
| --      | --       | -- |
| `minutes` | Integer   | publishes events |
| `klass`   | Type      | publishes events remotely |
| `batchSize` *(optional)* | Integer | publishes events remotely |
| `args` *(optional)*    | Object[]  | publishes events remotely |


Job classes must have a default constructor and implement one of the following:
* `Schedulable` - executes inline unless minutes is negative, then job schedules. *(you must abort new job)*
* `Queueable` - queues immediately.
* `Database.Batchable<SObject>` - executes immediately using the batchSize argument *(default: 200)*

Additional arguments can be based with args, if your scheduled class implements `QuickScheduleJob.HasArgs`:
```java
global MyJobClass implements stx.QuickScheduleJob.HasArgs {
    global void setArgs(Object[] args) {
        System.debug('set args');
    }
}
```


## TriggerHandlerX
---
A class framework for managing triggers.

*Extend the stx.TriggerHandler and override the appropriate triggered events*
```java
class MyAccountHandler extends stx.TriggerHandlerX {
    global override void beforeInsert() {
        System.debug('do something');
    }
    global override void afterUpdate() {
        System.debug('do something');
    }
}
```

*Register the trigger in the Salesforce Platform*
```java
trigger MyAccountTrigger on Account (before insert, after update) {
    new MyAccountHandler().run();
}
```


## Tuples
---
Predefined tuples.

Name | Item1 | Item2 | Item3
-- | -- | -- | --
Exception_SObject | Exception | SObject |
Id_String | Id | String |
Tuple2 | Object | Object |
Tuple3 | Object | Object | Object

*Example of Tuple2*
```java
Tuple2 value = new Tuple2(1, 'one');
System.debug(value.item1)
System.debug(value.item2)
```
