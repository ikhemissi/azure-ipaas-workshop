---
published: true
type: workshop
title: Build an event-driven data processing application using Azure iPaaS services
short_title: Event-driven application using Azure iPaaS
description: In this workshop you will learn how to build an event-driven application which will process e-commerce orders. You will leverage Azure iPaaS services to prepare, queue, process, and serve data.
level: intermediate # Required. Can be 'beginner', 'intermediate' or 'advanced'
navigation_numbering: false
authors: # Required. You can add as many authors as needed
  - Guillaume David
  - Alexandre Dejacques
  - Iheb Khemissi
  - Louis-Guillaume Morand
  - Julien Strebler
  - Lucile Jeanneret

contacts: # Required. Must match the number of authors
  - "guillaume.david@cellenza.com"
  - "alexandre.dejacques@cellenza.com"
  - "@ikhemissi"
  - "@lgmorand"
  - "@justrebl"
  - "@ljeanner"
duration_minutes: 180
tags: azure, ipaas, functions, logic apps, apim, service bus, event grid, entra, cosmosdb, codespace, devcontainer
navigation_levels: 3
---

# Introduction

Welcome to this Azure iPaaS Workshop. You'll be experimenting with multiple integration services to build an event-driven data processing application.

You should ideally have a basic understanding of Azure, but if not, do not worry, you will be guided through the whole process.

During this workshop you will have the instructions to complete each step. The solutions are placed under the 'Toggle solution' panels.

<div class="task" data-title="Task">

> - You will find the instructions and expected configurations for each Lab step in these yellow **TASK** boxes.
> - Log into your Azure subscription on the [Azure Portal](https://portal.azure.com) using the credentials provided to you.

</div>

In this lab, you are going to reproduce a real-life scenario from an e-commerce platform:

- Customers will place new orders that will be synchronized asynchronously.
- You are going to leverage Azure Services tailored to simplify this integration.

<br>

![Architecture diagram](./assets/intro/architecture-schema.png)

## Azure iPaaS

Azure iPaaS (Integration Platform as a Service) is a set of services which allow securely connecting apps, systems, and data in the cloud, on-premises, and at the edge.
By leveraging integration services, organizations can bring workflows together so they're consistent and scalable.

Integration services can broadly be categorized into Orchestration, Messaging, APIs, and Eventing services:

- **Azure Logic Apps**: A cloud service that helps you automate workflows and integrate apps, data, and services.
- **Azure Functions**: A serverless compute service that allows you to run event-driven code without managing infrastructure.
- **Azure Service Bus**: A messaging service that enables reliable communication between distributed applications and services.
- **Azure Event Grid**: A highly scalable, fully managed Pub Sub message distribution service that offers flexible message consumption patterns using the MQTT and HTTP protocols.
- **Azure API Management**: A turnkey solution for publishing APIs to external and internal customers, quickly creating consistent and modern API gateways for existing back-end services hosted anywhere and analyzing and optimizing your APIs.

This workshop will focus on these 5 services and how you can leverage them to create a fast, scalabale, secure, and resilient real-world application.

## Tools and workshop environment

To get started quickly, we will be using the following services and tools:

- **GitHub Codespace**: [GitHub Codespaces](https://docs.github.com/en/codespaces/overview) provides a cloud-based development environment that allows you to code, build, test, and collaborate from anywhere. It offers a fully configured development environment that can be accessed directly from your browser or through Visual Studio Code. With Codespaces, you can quickly spin up a development environment with all the necessary tools and dependencies, ensuring a consistent setup across your team.
- **Azure Developer CLI** (azd): [azd](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview?tabs=linux) is a command-line interface designed to simplify the deployment and management of applications on Azure. It provides a unified experience for developers to build, deploy, and monitor their applications using a set of easy-to-use commands. With `azd`, you can streamline your workflow, automate repetitive tasks, and ensure consistent deployments across different environments.
- **HTTP clients**: You will be required to send HTTP requests in many parts of the workshop. To simplify this process, we have already installed both [VSCode Rest Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) and [Postman](https://www.postman.com/) as VS Code extensions in the Github codespace environment. Feel free to use your preferred HTTP client.

## Prepare your dev environment

<div class="task" data-title="Task">

> You have to fork the [GitHub project](https://github.com/ikhemissi/azure-ipaas-workshop/) in order to create your own copy to be edited through the lab and kept after for reference. You can clone it locally, but the lab will leverage GitHub Codespaces to avoid any local dependencies issues/conflicts.

</div>

<details>

<summary> Toggle solution</summary>

1. Open the [lab repository](https://github.com/ikhemissi/azure-ipaas-workshop/)

1. Fork the project by clicking on the `Fork` button on the top right. This step may take a couple of minutes. Once this is done, you will have your own copy of the project which you can use to save your changes.
   ![Project forking](assets/intro/project-forking.png)

1. Click on `Code`, select the `Codespaces` tab, and click `Create codespace on main`.
   ![Create codespace](assets/intro/codespace.png)

1. It should open a new tab in your browser with a full fledged IDE and a terminal that will be exclusively used for the lab. It can take a few minutes for the initial setup as Codespace starts a devcontainer on a dedicated virtual machine, with the initial setup, tools and configurations to successfully achieve the lab.
   ![Codespace editor](assets/intro/codespace2.png)

</details>

### Provision resources in Azure

From the codespace environment opened in previous step, open a terminal (`ctrl+J` if not open in the bottom of the Github Codespace view) and execute the following tasks.
Azure Developer (azd) up will provision the infrastructure needed for the rest of the workshop, as well as deploy the application packages and configurations to help us accelerate on the labs.

<div class="task" data-title="Task">

> - Log into the [Azure Portal](https://portal.azure.com).
> - Use `azd up` from your GH Codespace terminal to provision resources in Azure and deploy the applications described in `azure.yaml` (at the root of the project)

</div>

<div class="tip" data-title="Tips">

> - If you are doing this workshop as part of an instructor-led lab, please use the Azure credentials provided by your instructor. Otherwise, use your usual credentials.

</div>

<details>

<summary> Toggle solution</summary>

Log into the [Azure Portal](https://portal.azure.com)

Then run the following commands in the terminal:

```sh
# Log into azd
azd auth login

# Provision resources and deploy applications
azd up
```

</details>

### Validate the setup on Azure

The provisioning step may take few minutes. Once it has finished, you should have a resource group ready with all the resources `rg-<name>-lab-no-ipa-<random-id>` needed in this workshop.

Moreover, some of the applications (e.g. Azure Functions) should also be deployed and ready to be used.

<div class="task" data-title="Task">

> - Open the Azure Portal and ensure that you can see a resource group with various iPaaS resources
> - Ensure that there are no failed deployments

</div>

<details>

<summary> Toggle solution</summary>

Your terminal should display green messages such as the following:
![azd up command](assets/intro/azdup.png)

In the Azure portal, you should have a new resource group with a lot of sub resources provisionned inside it.

![resources generated](assets/intro/azportal.png)

</details>

---

# Lab 1 : Process and Transform a file (1 hour)

For this first lab, you will focus on the following scope :

![Architecture diagram lab 1](./assets/lab1/architecture-schema-lab1.png)

## Detect a file upload event (15 min)

This labs aims to guide you through building a seamless and secure end-to-end data processing solution using Azure Integration Services. You will learn how to build workflows triggered by file uploads, transform and publish messages, and store them in Cosmos DB, emphasizing best practices for event-driven architectures, integration patterns and security for modern cloud solutions.

### Secure connections between Azure Services with Managed Identities

Managed Identities in Azure allow resources to authenticate securely to other Azure services. This feature eliminates the need to manage secrets or keys, reducing the risk of accidental exposure and simplifying maintenance. By enabling seamless and secure communication between resources, Managed Identities promote a stronger security model that relies on Azure's identity platform ([MS Entra ID](https://www.microsoft.com/fr-fr/security/business/identity-access/microsoft-entra-id)) for authentication.

<div class="info" data-title="Note">

> You can find a detailed article which explains what are managed identities for Azure resources and how to use them [following this link](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview).

</div>

### Event Services

To enable Serverless scenarios, an event-driven approach and architecture is required. Events and messages can be of different forms, and Azure offers several options when it comes to message and event brokers, such as :

- Event Grid is a serverless backplane, an eventing bus that enables event-driven, reactive programming, using the publish-subscribe model.
- Service Bus is a fully managed enterprise message broker with message queues and publish/subscribe topics.
- Event Hub is a event ingestion and streaming platform. It can fuel high throughput scenarios and manage millions of events per second.

<div class="info" data-title="Note">

> Each of these services offer their own set of capabilities and will be preferred depending on the expected architecture design and requirements. You can find a detailed article which compares the pros and cons of each of these solutions [following this link](https://learn.microsoft.com/en-us/azure/service-bus-messaging/compare-messaging-services).

</div>

For the purpose of the lab, we'll start by using Event Grid to integrate applications while subscribing to event sources. Azure Services, First and Third-Party SaaS services or custom apps can be the source (publishers) of events that are delivered to subscribers such as applications, Azure services, or any accessible HTTP endpoint to be consumed and acted upon.

### Check Logic App permissions

#### Check Logic App permission to access Event Grid

Event Grid enables event-driven scenarios by reacting to events/changes (like uploading a blob to Azure Storage Account for example) in Azure resources, and gives a trigger option for workflows or functions.
This simplifies integration and real-time processing across services without the need for constant polling.

In the lab, you will use it to trigger the `wf_orders_from_sa_to_sb` Logic App workflow when a blob will be uploaded in the `inputfiles` container of the Storage Account.

The Logic App needs to access the Event Grid service through the Storage Account as it will create an Event Grid System Topic when the Event Grid trigger connector is created. Since we want to use Managed Identities to secure the connection between our Azure Resources, let's check the identity has the proper configuration in the Storage Account.

<div class="task" data-title="Tasks">

> - Check that the `loa-proc-lab-no-ipa-[randomid]` logic app has the `EventGrid Contributor` role for the Event Grid System Topic on the Storage Account `stdatalabnoipa[randomid]`.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Storage Account `stdatalabnoipa[randomid]`.
> - In the left-hand menu, click on `Access Control (IAM)`.
> - From the top-menu bar, click on `Role Assignment` and check that Logic App `loa-proc-lab-no-ipa-[randomid]` system managed identity has the **EventGrid Contributor** role.

You should see the following RBAC configuration in your Storage Account :

![IAM](assets/lab1/image-1.png)

A Logic App triggered by Event Grid for blob uploads needs the `EventGrid Contributor` role on the storage account to subscribe to Event Grid blob-created events and to validate the webhook endpoint during setup.

</details>

#### Check Logic App permission to access Storage Account

With a Storage Account, it is possible to store various data objects, including blobs, file shares, messages in a queue, table formatted data, and disks. In our lab, we will use it to store the sample order JSON file inside an `inputfiles` container.

The Logic App needs to access the Storage Account to retrieve the JSON file, and for the Event Grid trigger connector to list the available Storage Accounts in the Subscription.
Since we want to use Managed Identities to secure the connection between our Azure Resources, let's check how it is configured in the Storage Account.

<div class="task" data-title="Tasks">

> - Check that `loa-proc-lab-no-ipa-[randomid]` has the `Storage Blob Data Reader` RBAC applied on the Storage Account `stdatalabnoipa[randomid]`:

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Storage Account `stdatalabnoipa[randomid]`.
> - In the left-hand menu, click on `Access Control (IAM)`.
> - From the top-menu bar, click on `Role Assignment` and check that Logic App `loa-proc-lab-no-ipa-[randomid]` has the **Storage Blob Data Reader** role.

You should see the following RBAC configuration in your Storage Account :

![Storage Account IAM](assets/lab1/image-3.png)

</details>

### Check the Logic App Workflows

A **workflow** is a series of operations that define a task, business process, or workload. Each workflow always starts with a single **trigger**, after which you must add one or more **actions**.

#### Check the Event Grid trigger in Logic App

<div class="info" data-title="Note">

Azure Logic Apps offers different components which can be used to define the steps of a flow as a chain of actions and controls. Here are the main ones :

> - **Operations** : `Triggers` and `Actions` are the main building blocks of a Logic App. A trigger is the event that starts the workflow and an action is a step in this workflow.
> - A **trigger** is the first operation in any workflow that specifies the criteria to meet before running any subsequent **action** in that workflow. In this lab, we want to **trigger an event when a new file is uploaded in a storage account**.
> - **Actions** are the building blocks actually responsible for doing the work in the flow : They are used to connect to Azure Services, 3rd party solutions, control the flow or manipulate data thanks to **connectors**.
> - **Connectors** : Connectors are used to connect to different first of third party services and applications. These connectors abstract the complexities of interacting with these services by defining their required and optional inputs as well as deserializing their outputs to dynamic objects usable in the rest of the flow steps.
> - **Controls** : Switch, Loop, Condition, Scope are used to control the flow of the steps composing the actual logic of the workflow.

</div>

Next step is to actually trigger the Logic App `loa-proc-lab-no-ipa-[randomid]` based on the event raised by your Event Grid System Topic when a file is uploaded to the `inputfiles` container.

Since we want the Logic App to be triggered when an event is published in the Event Grid System Topic, we will be using the Event Grid Built-In connector available in Logic App.
It comes with the `When a resource event occurs` action, that is triggered when an Azure Event Grid subscription receives the subscribed event.

<div class="info" data-title="Note">

> When we save the Logic App workflow for the first time, the Event Grid Trigger will create automatically an Event Grid subscription in the Storage Account, following default naming conventions.
> The subscription will initially remain in the `Creating` state.

</div>

<div class="task" data-title="Tasks">

> - Check the Logic App `loa-proc-lab-no-ipa-[randomid]`, and confirm the configuration of the Event Grid trigger is ready for the workflow `wf_orders_from_sa_to_sb` from the Workflow designer.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Logic App `loa-proc-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Workflows` from the `Workflows` section.
> - Open the workflow `wf_orders_from_sa_to_sb`.
> - In the left-hand menu, click on `Designer` from the `Developer` section.
> - Select the `When a resource event occurs` trigger.
> - Make sure that the Resource Id corresponds to your Storage Account where the file will be uploaded and that the Event type is **Microsoft.Storage.BlobCreated**

You should see the following :

![LogicApp Designer Trigger](assets/lab1/image-2.png)

</details>

### Check the Event Grid subscription in the Event Grid System Topic

We will see in the next step why and how to validate the subscription.
In the meatime, let's have a look at the Event Grid subscription.

<div class="info" data-title="Note">

> A **subscription** tells Event Grid which events on a topic you're interested in receiving. When creating a subscription, you provide an endpoint for handling the event. Endpoints can be a webhook or an Azure service resource.

</div>

<div class="task" data-title="Tasks">

> - Check an Event Grid subscription is set on the Storage Account `stdatalabnoipa[randomid]` for `loa-proc-lab-no-ipa-[randomid]`.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Storage Account `stdatalabnoipa[randomid]`.
> - In the left-hand menu, click on `Events`.
> - Click on the name of the Logic App's subscription on the bottom of the page.

You should see the following configurations in Event Grid Subscription :

![Event Grid Subscription Overview](assets/lab1/image-8.png)
![Event Grid Subscription Details](assets/lab1/image-9.png)

</details>

### Check the Webhook validation condition

We will now be able to receive new events coming from the Event Grid System Topic when new blobs are uploaded, and trigger the Logic Apps workflow accordingly.

Before processing the Event Grid event, it is essential to validate the webhook to ensure that our workflow is the correct subscriber to the events in the Storage Account and to establish a trusted connection.
Until we do not validate this event, the subscription will remain in the 'Creating' state.
To validate the event, we are using the Response action: `Response Validation Webhook`.

We will add an action to parse the json event with the event grid schema. We can get the schema from [here](https://learn.microsoft.com/en-us/azure/event-grid/event-schema#event-schema).
Adding the `Parse JSON` helps us validating the structure of the incoming Event Grid event and makes it easier to reference specific properties in subsequent steps.

The input to `Parse JSON` step is :
`@triggerBody()`

After that `Parse JSON` step, we have a condition step, to check whether the event is a subscription Validation event or not. Condition is:

`"equals": [
          "@body('Parse_JSON')[0]?['eventType']",
          "Microsoft.EventGrid.SubscriptionValidationEvent"
        ]`

<div class="task" data-title="Tasks">

> - Check the configuration of the `Parse JSON` to ensure the JSON schema referenced in the step is matching the documentation [here](https://learn.microsoft.com/en-us/azure/event-grid/event-schema#event-schema)
> - Check the configuration of the `Condition` action in the Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sa_to_sb`.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Logic App `loa-proc-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Workflows` from the `Workflows` section.
> - Open the workflow `wf_orders_from_sa_to_sb`.
> - In the left-hand menu, click on `Designer` from the `Developer` section.
> - Click on the step `Parse JSON`
> - Click on the condition `Condition`

You should see the following configuration in your `Parse JSON` step :

![Logic App Parse JSON](assets/lab1/image-21.png)

You should see the following configuration in your `Condition` step :

![Logic App Condition](assets/lab1/image-4.png)

</details>

## Process the event (5 min)

### Retrieve file content

To retrieve the content of the file that will be uploaded in the `inputfiles` container, we are using the `Azure Blob Storage` connector and `Read blob content` action.

<div class="task" data-title="Tasks">

> - Check the configuration of the `Read blob content` action in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sa_to_sb`:

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Logic App `loa-proc-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Workflows` from the `Workflows` section.
> - Open the workflow `wf_orders_from_sa_to_sb`.
> - In the left-hand menu, click on `Designer` from the `Developer` section.
> - Click on the action `Read blob content`.
> - Confirm the Container Name is set to `inputfiles` and that the Blob Name is set to `last(split(items('For_each')['subject'], '/'))`.

You should see the following configuration in your action :

![Read blob content](assets/lab1/image-5.png)

</details>

## Publish the message (10 min)

### Publish/Subscribe design pattern

The Publish/Subscribe (Pub/Sub) design pattern enables a decoupled communication model where publishers send messages to a central broker, and subscribers receive only the messages they are interested in, based on topics subscriptions.

This approach is well-suited for systems requiring loosely coupled components, such as event-driven architectures. It enables scenarios with applications broadcasting information to multiple consumers, particularly if they operate independently, use different technologies, or have varying availability and response time requirements.

<div class="info" data-title="Note">

> You can find a detailed article which explains what is the Publisher-Subscriber design pattern and when to use it [following this link](https://learn.microsoft.com/en-us/azure/architecture/patterns/publisher-subscriber).

</div>

![Pub Sub pattern](assets/lab1/image-6.png)

Azure Service Bus is a good solution for implementing the Publish/Subscribe pattern as it provides robust messaging capabilities, including topic-based subscriptions, reliable message delivery, and support for diverse protocols and platforms.
The built-in features of this Message broker, such as message filtering, dead-letter queues, and transactional processing, make it ideal for building scalable, decoupled, and fault-tolerant systems guaranteeing the message processing.

### Check Logic App permission to access Service Bus

The Logic App needs to access the Service Bus resource to publish the message (content of the file). Since we want to use Managed Identities to secure the connection between our Azure Resources, let's check how it is configured in the Service Bus.

<div class="task" data-title="Tasks">

> - Confirm the Logic App `loa-proc-lab-no-ipa-[randomid]` has the **Service Bus Data Receiver** and **Service Bus Data Sender** roles on the Service Bus `sb-lab-no-ipa-[randomid]`:

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Service Bus `sb-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Access Control (IAM)`.
> - From the top-menu bar, click on `Role Assignment` and confirm that Logic App `loa-proc-lab-no-ipa-[randomid]` has the **Service Bus Data Receiver** and **Service Bus Data Sender** roles.

You should see the following RBAC configuration in your Service Bus Namespace :

![Service Bus IAM](assets/lab1/image-7.png)

</details>

### Check the action to Publish the message to Service Bus

Next step is to publish the message (i.e. content of the file) in the Service Bus topic `topic-flighbooking`.
To do that, we are using the `Service Bus` connector and `Send message to a queue or topic` action.

<div class="task" data-title="Tasks">

> - Check the configuration of the `Send message to a queue or topic` action in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sa_to_sb`
> - It should reference `inputfiles` as the container name and extract the Blob Name from the previous action.

</div>

<div class="info" data-title="Note">

> - To easily check the content of a function in a Logic App Action, you can check the **Code view** after clicking an `action`.
> - It will provide with a plain text version of a `fx` function to ease the verifications.

![Logic Apps Code View](assets/lab1/image-22.png)

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Logic App `loa-proc-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Workflows` from the `Workflows` section.
> - Open the workflow `wf_orders_from_sa_to_sb`.
> - In the left-hand menu, click on `Designer` from the `Developer` section.
> - Click on the action `Send message`.
> - Make sure that the Container Name is set to `inputfiles` and that the Blob Name is set to `last(split(items('For_each')['subject'], '/'))`.

You should see the following configuration in your action :

![Send message](assets/lab1/image-10.png)

</details>

At the end of this first section, we have a Logic App workflow that is triggered by an event when a new file is uploaded in the `inputfiles` container of our Storage Account, that reads the file content and publish it in a Service Bus topic.
The next section will focus on the subscription to this message and its processing, before sending it to the target system.

## Subscribe to the message (5 min)

Next step is to subscribe to the Service Bus topic where the messages are published to be able to process them later.
We will build a workflow that will be triggered when a new message is available in the dedicated Service Bus topic, containing our message.

### Configure the Service Bus trigger in Logic App

In this step, we will configure the Logic App `Service Bus` connector and trigger `When messages are available in a topic`.
As the Service Bus connection configuration is already done, we will focus on the creation and configuration of the trigger itself.

<div class="task" data-title="Tasks">

> - Create and configure the Service Bus trigger in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sb_to_cdb`:

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Logic App `loa-proc-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Workflows` from the `Workflows` section.
> - Open the workflow `wf_orders_from_sb_to_cdb`.
> - In the left-hand menu, click on `Designer` from the `Developer` section.
> - Click on the `Add a trigger` button.
> - In the `triggers` list search for `Service Bus` and select the `When messages are available in a topic` trigger.
> - In the Topic Name dropdown list, select the `topic-orders` topic.
> - In the Subscription Name dropdown list, select the `sub-orders-cdb` subscription.
> - Once everything is set, click on the `Save` button on the top left corner.

The trigger operation should look like this :

![Service Bus Trigger](assets/lab1/image-11.png)

</details>

## Transform the message (10 min)

### Message Transformation

Message transformation in orchestration workflows is essential to ensure interoperability between systems that may use different data formats, structures, or conventions.
Target systems often have specific requirements for how data should be presented, such as field naming, value types, or schema validation.
Transformations also help enrich messages by adding necessary data or filtering out unnecessary information, optimizing the payload for the target system.
This step ensures seamless integration, reduces errors, and improves the reliability of communication across disparate systems.

In Logic Apps, you can transform messages using built-in connectors (e.g., JSON, XML, or flat file parsing), Liquid templates for complex JSON mapping, Data Mapper or Transform XML for complex XML mapping and Azure Functions or Inline Code for custom transformations.
Additionally, Logic Apps supports external tools like Azure API Management for preprocessing.

<div class="info" data-title="Note">

> [Follow this link](https://learn.microsoft.com/en-us/azure/logic-apps/create-maps-data-transformation-visual-studio-code) for more details about message transformation in Logic Apps.

</div>

### Configure the transform action in Logic App

We need to transform the initial message to a simplified JSON schema that is expected by the target system.
By consolidating passenger names into a list and focusing on key flight and payment details, we make the data more compact and easier for the target system to process.

This is the message in JSON format sent by the source system:

```json
{
  "booking": {
    "bookingId": "B12345678",
    "bookingDate": "2022-02-08T12:00:00Z",
    "passengers": [
      {
        "firstName": "John",
        "lastName": "Doe",
        "email": "johndoe@example.com",
        "dob": "1990-01-01",
        "gender": "M",
        "address": {
          "street": "123 Main St",
          "city": "Anytown",
          "state": "CA",
          "postalCode": "12345",
          "country": "USA"
        },
        "phoneNumber": "+1 555-555-5555"
      },
      {
        "firstName": "Jane",
        "lastName": "Doe",
        "email": "janedoe@example.com",
        "dob": "1992-03-15",
        "gender": "F",
        "address": {
          "street": "456 Second St",
          "city": "Anycity",
          "state": "CA",
          "postalCode": "67890",
          "country": "USA"
        },
        "phoneNumber": "+1 555-555-5556"
      }
    ],
    "flight": {
      "flightNumber": "UA123",
      "origin": "SFO",
      "destination": "JFK",
      "departureDate": "2022-02-15T08:00:00Z",
      "arrivalDate": "2022-02-15T16:00:00Z",
      "airline": "United Airlines",
      "fareClass": "Economy",
      "farePrice": 250.0
    },
    "payment": {
      "cardType": "Visa",
      "cardNumber": "**** **** **** 1234",
      "expirationDate": "03/24",
      "billingAddress": {
        "street": "789 Third St",
        "city": "Anyvillage",
        "state": "CA",
        "postalCode": "24680",
        "country": "USA"
      },
      "totalPrice": 500.0
    }
  }
}
```

This is the message JSON format expected by the target system:

```json
{
  "transformedBooking": {
    "bookingId": "B12345678",
    "passengerNames": {
      "name": ["John Doe", "Jane Doe"]
    },
    "flightDetails": {
      "flightNumber": "UA123",
      "departure": "SFO",
      "arrival": "JFK",
      "departureDate": "2022-02-15T08:00:00Z"
    },
    "payment": {
      "cardType": "Visa",
      "amountPaid": "500"
    }
  }
}
```

While there are many solutions to transform a JSON object in Logic Apps, we want to showcase the use of the `Transform XML` action, which leverages the powerful capabilities of XSLT—a widely used language in the integration world—to manipulate and restructure data effectively.

The use of XSLT requires to manipulate XML data, so we'll need to first transform the Json to an XML format, to apply the XSLT transformation, and back to a Json formatted data for the target system.

We will use a `Compose` action to transform the JSON message into an XML format.

<div class="task" data-title="Tasks">

> - Configure a `Compose` action to transform JSON into XML in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sb_to_cdb`:

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Logic App `loa-proc-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Workflows` from the `Workflows` section.
> - Open the workflow `wf_orders_from_sb_to_cdb`.
> - In the left-hand menu, click on `Designer` from the `Developer` section.
> - Click on the `+` button, select `Add an action` and search for `Compose` from the list of actions (in the **Data Operations** connector).
> - In the `Inputs` field of the `Compose` action, click on the `fx` icon and enter the following function: `xml(json(triggerBody()?['contentData']))`.
> - Rename the action `JSON to XML`. It not obvious, but you have to click on the title "Compose" to do so.
> - Once everything is set, click on the `Save` button at the top left corner.

The Compose action should look like this :

![Transform JSON to XML](assets/lab1/image-12.png)

</details>

We will then use a `Transform XML` action to transform the XML message into the desired format.

<div class="task" data-title="Tasks">

> - Configure a `Transform XML` action, with the `transformation_orders` XSLT Map in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sb_to_cdb`:

</div>

<details>

<summary> Toggle solution</summary>

> - Click on the `+` button, select `Add an action` and search for `Transform XML` from the list of actions.
> - In the Content field, click on the `fx` icon and enter the following text: `outputs('JSON_to_XML')`.
> - In the Map Source dropdown list, select `LogicApp`.
> - In the Map Name dropdown list, select `transformation_orders`.
> - Rename the action `Transform XML`
> - Once everything is set, click on the `Save` button at the top left corner.

The Transform XML action should look like this :

![Transform XML](assets/lab1/image-13.png)

</details>

We will now use a `Compose` action to transform the XML message back to a lighter JSON format before sending it to the target.

<div class="task" data-title="Tasks">

> - Configure a `Compose` action to transform XML back to a lighter JSON in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sb_to_cdb`:

</div>

<details>

<summary> Toggle solution</summary>

> - Click on the `+` button, select `Add an action` and search for `Compose` from the list of actions.
> - In the Inputs field of the Compose action, click on the `fx` icon and enter the following function: `json(body('Transform_XML'))`.
> - Rename the action `XML to JSON`
> - Once everything is set, click on the `Save` button at the top left corner.

The Compose action should look like this :

![Transform XML to JSON](assets/lab1/image-14.png)

</details>

## Store the message in Cosmos DB (10 min)

Once the message has been transformed to match the format of the target system, we want to send it to our target system, in our case a container in CosmosDB, so that it can be processed later.
Azure Cosmos DB is a fully managed NoSQL database which offers Geo-redundancy and multi-region write capabilities.
It currently supports NoSQL, MongoDB, Cassandra, Gremlin, Table and PostgreSQL APIs and offers a serverless option which is perfect for our use case.

Before creating the document in Cosmos DB, we need to add a unique `id` property to the document, as it is mandatory.
We will use a `Compose` action to generate a unique identifier and append an `id` property to our message.

<div class="task" data-title="Tasks">

> - Configure a `Compose` action to generate a UUID and append the id property in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sb_to_cdb`.

</div>

<details>

<summary> Toggle solution</summary>

> - Click on the `+` button, select `Add an action` and search for `Compose`.
> - In the Inputs textbox, click on the `fx` icon and enter the following text : `addProperty(outputs('XML_to_JSON'), 'id', guid())`
> - Rename the action `Append id property and generate UUID`
> - Once everything is set, click on the `Save` button on the top left corner.

The Compose action should look like this :

![Generate UUID](assets/lab1/image-15.png)

</details>

### Retrieve Cosmos DB Primary Connection String

To use the Cosmos DB connector in our Logic App workflow and write to the Cosmos DB container, you can use the Primary Connection String for authentication.
This key grants the Logic App access to the Cosmos DB account and allows it to perform the required actions.
We will now see how to retrieve this key for integration into our configuration.

<div class="task" data-title="Tasks">

> - Retrieve the Cosmos DB Primary Connection String from `cos-lab-no-ipa-[randomid]` Cosmos DB account.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Cosmos DB account `cos-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Keys` under the Settings section.
> - In the Keys section, locate the **Primary connection string**.
> - Copy the **Primary connection string** by clicking the copy icon next to it.
> - The key is now ready to be used in your Logic App configuration.

You should see the following Credentials :

![CosmosDB Credentials](assets/lab1/image-17.png)

</details>

### Store data to Cosmos DB

Now we can add the last step of the Logic App flow that will store the transformed message in the Cosmos DB database using the Create or update item `action`.
First, we need to configure the connection to our CosmosDB account.

<div class="task" data-title="Tasks">

> - Configure the connection to CosmosDB for using the `Create or update item` connector in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sb_to_cdb`.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Logic App `loa-proc-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Workflows` from the `Workflows` section.
> - Open the workflow `wf_orders_from_sb_to_cdb`.
> - In the left-hand menu, click on `Designer` from the `Developer` section.
> - Click on the `+` button, select `Add an action` and search for `Cosmos DB`.
> - Select `Create or update item`
> - Set the connection with your Cosmos Db Instance: Select the the primary connection string that you retrieved in the previous step

The configuration should look like that:

![Logic App Create Connection](assets/lab1/image-18.png)

</details>

Once the connection is set up, we can configure the action.
We are now ready to send our message to our CosmosDB account.  
To do so, we need to configure the `Create or update item` connector.

<div class="task" data-title="Tasks">

> - Configure the `Create or update item` action to create a new document in CosmosDB in Logic App `loa-proc-lab-no-ipa-[randomid]` workflow `wf_orders_from_sb_to_cdb`.

</div>

<details>

<summary> Toggle solution</summary>

> - In the **Database Id** textbox, enter the following text : `orders`
> - In the **Container Id** textbox, enter the following text : `toprocess`
> - In the **Item** textbox, click on the `lightning` button and select `Outputs` from the previous action `Append id property and generate UUID`
> - Once everything is set, click on the `Save` button on the top left corner.

The action should look like this:

![Create Or Update Item](assets/lab1/image-16.png)

</details>

## Trigger the workflow (5 min)

We are now ready to test our workflow.

### Check the message stored in the CosmosDB

First, let's upload a new file to the `inputfiles` container of the `cos-lab-no-ipa-[randomid]` Storage Account to simulate a booking.
You can download the JSON file from here: [Download sample JSON file](assets/sample_order.json)

<div class="task" data-title="Tasks">

> - Upload the file in the Storage Account `stdatalabnoipa[randomid]`.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Storage Account `stdatalabnoipa[randomid]`.
> - In the left-hand menu, click on `Storage browser` and select `Blob containers`.
> - Click on the `inputfiles` container.
> - From the top-menu bar, click on the `Upload` button, click on `Browse for files` and select the `sample_order.json` file from your Storage Explorer.
> - Click on the `Upload` button below.

You should see your file in the container:

![Storage Account Container](assets/lab1/image-19.png)

</details>

Finally, let's check if our message is stored in our CosmosDB container.

<div class="task" data-title="Tasks">

> - Check the document created in CosmosDB `cos-lab-no-ipa-[randomid]`.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Cosmos DB account `cos-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Data explorer` and click on `orders` to open the database
> - Click on `toprocess` to open the container
> - Click on `Items` and select the first line

You should see your transformed message in the `toprocess` container:

![CosmosDB Container](assets/lab1/image-20.png)

</details>

---

# Lab 2 : Sync and async patterns with Azure Functions and Service Bus (45m)

In the previous lab, you have prepared orders using a Logic App and you have stored these orders to the `toprocess` container in CosmosDB.

In this lab, you will focus on processing and fetching these orders by implementing two workflows using Azure Functions (Flex Consumption) and Service Bus:

1. **Data processing**: Now that you have order details in the `toprocess` container, you will need to process these orders using Azure Functions, and store processed orders in the `processed` container of Cosmos DB. In order to make the workflow resilient, you will also need to use Service Bus to allow retrying and recovery following transient failures.
2. **Data serving**: Once you have stored the processed orders in Cosmos DB, you will need to provide access to them via an API. You will be using Azure Functions and its built-in HTTP trigger to implement this.

<br>

![Architecture diagram lab 2](./assets/lab2/architecture-schema-lab2.png)

## Knowledge refresh

### Azure Functions

A serverless compute service that allows you to run event-driven code without managing infrastructure.

### Flex Consumption plan

A Linux-based Azure Functions hosting plan that builds on the Consumption pay for what you use serverless billing model. It gives you more flexibility and customizability by introducing private networking, instance memory size selection, and fast/large scale-out features still based on a serverless model.

### Azure Function bindings and triggers

Azure Functions are event-driven: they must be triggered by an event coming from a variety of sources. This model is based on a set of triggers and bindings which let you avoid hard-coding access to other services. Your function receives data (for example, the content of a queue message) in function parameters. You send data (for example, to create a queue message) by using the return value of the function :

- **Binding** to a function is a way of connecting another resource to the function in a declarative way; bindings can be used to fetch data (input bindings), write data (output bindings), or both. Azure services such as Azure Storage blobs and queues, Service Bus queues, Event Hubs, and Cosmos DB provide data to the function as parameters.

- **Triggers** are a specific kind of binding that causes a function to run. A trigger defines how a function is invoked, and a function must have exactly one trigger. Triggers have associated data, which is often provided as a parameter payload to the function.

### Azure Service Bus

A messaging service that enables reliable communication between distributed applications and services.

### Cosmos DB

A fully managed, distributed NoSQL, relational, and vector database service designed for modern app development. It offers high performance, high availability, and support for various data models, including document, key-value, graph, and table.

## Queueing orders in Service Bus

Asynchronous operations are **essential** in modern applications to ensure that tasks are processed without blocking the main execution flow, improving overall performance and user experience. A message broker like Azure Service Bus enhances resiliency by decoupling application components, allowing them to communicate reliably even if one component is temporarily unavailable. Service Bus supports operation retries, ensuring that messages are eventually processed even in the face of transient failures, thus maintaining the integrity and reliability of the system.

The data processing function app (`func-proc-lab-[randomid]`) should already have 2 functions deployed `QueueOrders` and `ProcessOrders`like this
!["Functions deployed'](./assets/lab2/functions_deployed.png)

<div class="task" data-title="Task">

> - Edit the code from your codespace environment (not in the Azure Portal)
> - Open the `src/dataprocessing/src/functions/QueueOrders.js` file
> - Update the `QueueOrders` function to queue messages in Service Bus for every new document in CosmosDb.
> - Deploy the code change to the Azure Function `func-proc-lab-[randomid]`

</div>

<div class="tip" data-title="Tips">

> - You can use the environment variables `SERVICEBUS_QUEUE`, and `SB_ORDERS__fullyQualifiedNamespace` to send messages to Service Bus using the managed identity of the Function App `func-proc-lab-[randomid]`. Both environment variables have already been set on the Function App when you have provisioned the resources at the beginning on the workshop.
>
> - You can leverage the [Service Bus output binding](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus-output?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cextensionv5&pivots=programming-language-javascript) to easily add order messages to Service Bus.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the file `src/dataprocessing/src/functions/QueueOrders.js`.
> - Uncomment the lines 3 to 6, and line 13 by removing `//` from each line beginning.

Your code should look like:

```js
const { app, output } = require("@azure/functions");

const serviceBusOutput = output.serviceBusQueue({
  queueName: "%SERVICEBUS_QUEUE%",
  connection: "SB_ORDERS",
});

app.cosmosDB("QueueOrders", {
  databaseName: "%COSMOS_DB_DATABASE_NAME%",
  containerName: "%COSMOS_DB_TO_PROCESS_CONTAINER_NAME%",
  connection: "COSMOS_DB",
  createLeaseContainerIfNotExists: true,
  return: serviceBusOutput,
  handler: (orders, context) => {
    context.log(`Queueing ${orders.length} orders to process`);
    context.log(`Orders: ${JSON.stringify(orders)}`);
    return orders;
  },
});
```

Once you have updated the code, re-deploy the Function App code to get your updates running on Azure:

> - From your `codespace` environment terminal : Ctrl+J to reopen if closed in the meantime
> - Execute the following command :

```sh
azd deploy dataprocessing
```

</details>

Once you have deployed your updated Function App, you need to test your new changes by retriggering the data ingestion workflow with Logic Apps.

<div class="task" data-title="Task">

> - From the Azure Portal, trigger your logic app once again and make sure `QueueOrders` is queueing a message in Service Bus.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the Storage Account `stdatalabnoipa[randomid]`.
> - In the left-hand menu, click on `Storage browser` and select `Blob containers`.
> - Click on the `inputfiles` container.
> - From the top-menu bar, click on the `Upload` button, click on `Browse for files` and select the `sample_order.json` file from your Storage Explorer.
> - Click on the `Upload` button below.
> - Navigate to your data processing Function App (`func-proc-lab-[randomid]`).
> - Click on the function `ProcessOrders`.
> - Check the `Invocations` tab.

You should see a new recent invocation (this may take a while).
// TO DO : Add screenshot of the invocation tab
Check the logs of the invocation to get more details.

</details>

## Processing orders asynchronously

In this step, we will update the `ProcessOrders` function to process orders while being able to retry automatically if order processing fails.

<div class="task" data-title="Task">

> - Edit the code from your codespace environment (not in the Azure Portal)
> - Open the `src/dataprocessing/src/functions/ProcessOrders.js` file
> - Update the `ProcessOrders` function to store processed orders retrieved from Service Bus in CosmosDB
> - Deploy the code change to the Azure Function `func-proc-lab-[randomid]`

</div>

<div class="tip" data-title="Tips">

> - You can use the environment variables `COSMOS_DB_DATABASE_NAME`, `COSMOS_DB_PROCESSED_CONTAINER_NAME`, and `COSMOS_DB__accountEndpoint` to send messages to Service Bus using the managed identity of the Function App `func-proc-lab-[randomid]`. These environment variables have already been set on the Function App when you provisioned resources on Azure at the beginning of the workshop.
>
> - You can leverage the [CosmosDB output binding](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-cosmosdb-v2-output?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cextensionv4&pivots=programming-language-javascript)

</div>

<details>

<summary> Toggle solution</summary>

In the file `src/dataprocessing/src/functions/ProcessOrders.js`, uncomment the lines 3 to 7, and line 12 by removing `//` from each line beginning.

Your code should look like:

```js
const { app, output } = require("@azure/functions");

const cosmosOutput = output.cosmosDB({
  databaseName: "%COSMOS_DB_DATABASE_NAME%",
  containerName: "%COSMOS_DB_PROCESSED_CONTAINER_NAME%",
  connection: "COSMOS_DB",
});

app.serviceBusQueue("ProcessOrders", {
  queueName: "%SERVICEBUS_QUEUE%",
  connection: "SB_ORDERS",
  return: cosmosOutput,
  handler: async (order, context) => {
    context.log(`Order to process: ${JSON.stringify(order)}`);

    const processedOrder = {
      ...order,
      status: "processed",
      processedAt: new Date().toISOString(),
    };

    context.log(`Processed order: ${JSON.stringify(processedOrder)}`);

    return processedOrder;
  },
});
```

Once you have updated the code, re-deploy the Function App code to get your updates running on Azure:

> - From your `codespace` environment terminal : Ctrl+J to reopen if closed in the meantime
> - Execute the following command :

```sh
azd deploy dataprocessing
```

</details>

Now that you have implemented the full order processing pipeline, you will need to test it and make sure everything works.

<div class="task" data-title="Task">

> - From the Azure Portal, trigger your logic app once again and make sure `ProcessOrders` is writing orders in the `processed` container in CosmosDB.

</div>

<details>

<summary> Toggle solution</summary>

> - Re-test your Logic App by adding a new file like we did in the previous step
> - Navigate to the Cosmos DB account `cos-lab-no-ipa-[randomid]`.
> - In the left-hand menu, click on `Data explorer` and click on `orders` to open the database
> - Click on `processed` to open the container
> - Click on `Items` and select the first line

You should be able to see new entries with the test data which you have used with Logic Apps.
!['Processed item in CosmoDB'](./assets/lab2/cosmosdb-processed.png)

</details>

## Serving orders via HTTP

In addition to reacting to events (e.g. message in Service Bus), Azure Functions also allows you to implement APIs and serve HTTP requests.

In this last exercice of Lab2, you need to update the data fetching Function App (`func-ftch-lab-[randomid]`) to have the `FetchOrders` return the latest processed orders.

<div class="task" data-title="Task">

> - Edit the code from your codespace environment (not in the Azure Portal)
> - Open the `src/datafetching/src/functions/FetchOrders.js` file
> - Update the `FetchOrders` function to fetch the latest processed orders from CosmosDB.
> - Deploy the code change to the Azure Function `func-ftch-lab-[randomid]`

</div>

<div class="tip" data-title="Tips">

> - You can leverage the data returned from the [CosmosDB input binding](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus-output?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cextensionv5&pivots=programming-language-javascript). This binding allows you to easily fetch data from Cosmos DB.

</div>

<details>

<summary> Toggle solution</summary>

> - Navigate to the file `src/datafetching/src/functions/FetchOrders.js`,
> - Uncomment the line 18 by removing `//` from the line beginning.

Your code should look like:

```js
const { app, input } = require("@azure/functions");

const cosmosInput = input.cosmosDB({
  databaseName: "%COSMOS_DB_DATABASE_NAME%",
  containerName: "%COSMOS_DB_CONTAINER_NAME%",
  connection: "COSMOS_DB",
  sqlQuery: "SELECT * FROM c ORDER BY c._ts DESC OFFSET 0 LIMIT 50",
});

app.http("FetchOrders", {
  methods: ["GET"],
  authLevel: "anonymous",
  extraInputs: [cosmosInput],
  handler: async (request, context) => {
    let orders = [];
    context.log("Fetching orders...");

    orders = context.extraInputs.get(cosmosInput);

    context.log(`Found ${orders?.length} orders...`);

    return {
      jsonBody: orders,
    };
  },
});
```

Once you have updated the code, re-deploy the Function App code to get your updates running on Azure:

> - From your `codespace` environment terminal : Ctrl+J to reopen if closed in the meantime
> - Execute the following command:

```sh
azd deploy datafetching
```

</details>

Once you have deployed your updated Function App, you need to test your new changes by calling the HTTP endpoint of `FetchOrders`.

<div class="task" data-title="Task">

> - Open the postman extension in your codespace environment
> - Call the HTTP endpoint of `FetchOrders` and make sure it returns the latest processed orders.

</div>

<details>

<summary> Toggle solution</summary>

> - Go to the Azure Portal
> - Navigate to your fecth order Function App (`func-ftch-lab-[randomid]`).
> - Click on the `FetchOrders` function
> - Click on `Get function URL`. A side panel should open.
> - As this is a Lab, you can take any of the 3 URLs that are proposed.

![Get function's URL](assets/lab2/getfunctionurl.png)

</details>

## Summary Lab 2

In this lab, you learned how to process and fetch orders using Azure Functions and Service Bus. You implemented asynchronous order processing to improve performance and resiliency, leveraging Service Bus for reliable communication and automatic retries. Additionally, you created an HTTP endpoint to fetch the latest processed orders from CosmosDB, demonstrating how to build event-driven and API-based workflows with Azure services.

---

# Lab 3 : Exposing and monetizing APIs (45m)

For this Lab, we will focus on exposing and monetizing APIs using Azure API Management (APIM). The steps will guides you through the process of creating and managing APIs, setting up products, and securing the APIs using subscription keys and OAuth 2.0. The goal is to demonstrate how to publish APIs, manage access, and define usage plans to monetize the APIs effectively within the the following scope :

![Architecture diagram lab 3](./assets/lab3/architecture-schema-lab3.png)

## About Azure API Management 
Azure API Management (APIM) is a fully managed service that enables organizations to publish, secure, transform, maintain, and monitor APIs. It provides a comprehensive set of features to manage the entire API lifecycle, from creation to retirement.

Key features of APIM include:

**API Gateway**: Acts as a facade for backend services, providing a single entry point for API consumers.
Developer Portal: A customizable portal where developers can discover, learn about, and consume APIs.

**Security**: Supports various authentication and authorization mechanisms, including subscription keys, OAuth 2.0, and JWT validation.

**Rate Limiting and Throttling**: Controls API usage to prevent abuse and ensure fair usage.

**Analytics and Monitoring**: Provides insights into API usage, performance, and health.

**Transformation and Enrichment**: Allows modification of requests and responses, such as format conversion and data enrichment.

**Policy Management**: Enables the application of policies to APIs for security, caching, transformation, and more.


<div class="info" data-title="Note">

> You can find a detailed article how APIM helps organizations expose their services as APIs, manage access, enforce policies, and gain insights into API usage, ultimately enabling them to monetize their APIs effectively. [following this link](https://learn.microsoft.com/en-us/azure/api-management/api-management-key-concepts).

</div>

## Expose an API (5 minutes)

<div class="info" data-title="Note">

> **APIs**: An API in APIM represents a set of operations that can be invoked by applications. Each API can have multiple operations, which correspond to the different endpoints exposed by the backend service. APIs can be versioned and configured with policies to control their behavior.

</div>

In this first step, we will learn how to expose an API on Azure APIM. We will publish the API to fetch orders deployed in Lab 2.

1. Go the Azure APIM (name should start with `apim-lab-no-ipa-[randomid]`)
2. On the left pane click on `APIs`
3. Then, click on `+ Add API` and on the group `Create from Azure resource` select the tile `Function App`

   ![Add an API](assets/lab3/part1-step3.jpg)

4. In the window that opens :

   - For the field `Function App`, click on `Browse`
   - Then on the windows that opens :
   - On _Configure required settings_, click on `Select` and choose your **Function App**

     ![Function settings](assets/lab3/part1-step4_2.jpg)

   - Be sure the function `FetchOrders` is select and click on `Select`

     ![Function selection](assets/lab3/part1-step4_3.jpg)

5. Replace the values for the fields with the following values :

   - **Display name**: `Orders API`
   - **API URL suffix**: `orders`

6. Click on `Create`

✅ **Now the API is ready.**

<div class="task" data-title="Task">

> - Test the operation `FetchOrders` and make sure it returns the latest processed orders.

</div>

<details>

<summary> Toggle solution</summary>

> Test it by clicking on the `Test` tab. On the displayed screen, select your operation and click on `Send` >![Test the API](assets/lab3/part1.jpg)

</details>

## Manage your API with Product (5 minutes)

<div class="info" data-title="Note">

**Products**: Products are a way to group one or more APIs and manage their access. Products can be configured with usage quotas, rate limits, and terms of use. Developers subscribe to products to gain access to the APIs contained within them. This allows for better control and monetization of API access.

</div>

Now the API is published, we will learn how to create a **Product** we will use to manage access and define usage plans.

1. On the APIM screen, in the menu on the left, click on `Products`, then click on `+ Add`.

   ![Product](assets/lab3/part2-step1.jpg)

2. In the window that opens, fill in the fields with the following values and then click `Create`:

   - **Display name**: `Basic`
   - **Description**: Enter your description.
   - **Check the following boxes**:
     - `Published`
     - `Requires Subscription`

   ![Product creation](assets/lab3/part2-step2.jpg)

3. Select the created product from the list and click on it.

4. On the next screen, click on `+ Add API`. In the right-hand menu that appears, select the API `Orders API` (the one created on the step 1) and then click `Select`.

   ![Product - Add an API](assets/lab3/part2-step4.jpg)


<div class="task" data-title="Task">

> Create a product named `Premium` and link it to the `Orders API`.

</div>

<details>

<summary> Toggle solution</summary>

> Repeat steps 1 to 4 to create another product named `Premium`

</details>

## Secure your API (15 minutes)

Now that we have created our products, we will learn how to secure it. We will see two methods for this: Subscription Keys and the OAuth 2.0 standard.

### Subscription Key

We will below how create the subscription keys.

1. On the APIM screen, in the menu on the left, click on `Subscriptions`, then click on `+ Add subscription`.

   ![Create a subscription](assets/lab3/part3_1-step1.jpg)

2. In the window that opens, fill in the fields with the following values and then click `Create`:

   - **Name**: `Basic-Subscription`
   - **Display name**: `Basic-Subscription`
   - **Scope**: `Product`
   - **Product**: `Basic`

   ![See subscription details](assets/lab3/part3_1-step2.jpg)

3. For the purpose of the part 4, repeat steps 1 and 2 to create another subscription linked to the product `Premium`, with the following fields value :
   - **Name**: `Premium-Subscription`
   - **Display name**: `Premium-Subscription`
   - **Scope**: `Product`
   - **Product**: `Premium`

Now that we have created two subscriptions, each corresponding to one of our products, we can view their values by right-clicking on them and selecting `Show/hide keys`

![See subscriptions keys](assets/lab3/part3_1.jpg)

<div class="info" data-title="Note">

> Be sure to note down the values of your keys to use them in the tests we will perform.

</div>

We will now test our API with the subscription key.

<div class="tip" data-title="Tips">

> Before continuing, go back to the `Settings` of your API and make sure the `Subscription required` checkbox is checked.

</div>

<div class="task" data-title="Task">

> - On the APIM screen, in the menu on the left, click on APIs, then click on the `Orders API`.
> - Next, click on the `Test` tab and copy the value under `Request URL`.
> - Open Postman (or any other tool to post requests), create a new request, paste the value copied in the previous step, and click on `Send`.

</div>

<details>

<summary> Toggle solution</summary>

> ![Subscription Result Failed](assets/lab3/part3_1_ResultF.jpg)
>
> 🔴 The result of this test is negative. A 401 Access Denied error is returned by the APIM. The error message states that the subscription key is missing.

</details>

<div class="task" data-title="Task">

> Redo a test using the subscription with the header `Ocp-Apim-Subscription-Key`

</div>

<details>

<summary> Toggle solution</summary>

> In the Postman request, under the Headers tab, add the header `Ocp-Apim-Subscription-Key` and specify the value as the key retrieved during the creation of our subscription key. Then click on `Send`.
>
> ![Subscription Result Success](assets/lab3/part3_1_ResultG.jpg)
>
> ✅ The call is now successful with a 200 OK response.

</details>

### OAuth 2.0

We will now see how to secure our API with the OAuth 2.0 standard

<details>

<summary>OAuth Configuration on Entra ID (👨‍🎓 skip if instructor-led session)</summary>

In this section, we will learn how to configure EntraId to enable OAuth security using your identity provider, Azure Entra ID. We will create two App Registrations: one representing the API in Azure Entra ID and another representing the API caller.

First the App Registrations for the API.

- Navigate to the directory hosting the relevant Azure Entra ID.
- From the portal, search for the Azure Entra ID instance and click on the found resource.
- In the left-hand menu, click on `App registrations`, then click on `+ New registration`

  ![Add App Registration](assets/lab3/Add-AppRegistration.jpg)

- In the displayed window, fill in the fields with the following values, then click on `Register`:

  - **Name**: `Orders-api`
  - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
  - **Redirect URL**: `Leave blank`

  ![Register App Registration](assets/lab3/Register-AppRegistration.jpg)

- If the App Registration window does not open automatically, click on the application you just created in the list.
- From the Overview tile, locate the `Application (client) ID` value and note it down for later use.
- In the left-hand menu, click on `Expose an API`, then at the top of the page, click on `Set` next to `Application ID URI`. Confirm with the default value.

  ![Configure Scope](assets/lab3/Add-Audience.jpg)

Then, the App Registration for the caller of the API.

- In the left-hand menu, click on `App registrations`, then click on `+ New registration`
- In the displayed window, fill in the fields with the following values, then click on `Register`:
  - **Name**: `Caller App`
  - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
  - **Redirect URL**: `Leave blank`
- From the Overview tile, locate the Application (client) ID value and note it down for later use.
- In the left-hand menu, click on `Certificates & secrets` and Click on `+ New client secret`

  ![Create Secret](assets/lab3/Add-Secret.jpg)

- In the displayed window, enter `caller-registration-key` as the description, then click on `Add`.

  ![Configure Secret](assets/lab3/Configure-Secret.jpg)

<div class="info" data-title="Note">

> Be careful, make sure to note down the `Value` because it will not be visible again later.

</div>

The Azure EntraId configuration is ready. Let's move on to the API Management section.

</details>

1. On the APIM screen, in the menu on the left, click on APIs, then click on the `Orders API`.
2. Go to `All operations`. On the right, in the `Inbound processing` section, click on the `</>` icon to access the policy editing mode.

   ![Add a policy](assets/lab3/part3_2-step2.jpg)

3. In the `<inbound>` section and under the `<base />` tag, add the following code and click on `Save`

```xml

  <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid." require-scheme="Bearer">
            <openid-config url="https://login.microsoftonline.com/{{tenant}}/.well-known/openid-configuration" />
            <issuers>
                <issuer>https://login.microsoftonline.com/{{tenant}}/v2.0</issuer>
                <issuer>https://sts.windows.net/{{tenant}}/</issuer>
            </issuers>
        </validate-jwt>

```

![Validate JWT Token Policy](assets/lab3/part3_2-step3.jpg)

<div class="task" data-title="Task">

> We will now see how to test our API secure by the OAuth 2.0 standard
>
> Open Postman, on our previous request and click on `Send`.

</div>

<details>

<summary> Toggle solution</summary>

> ![image](assets/lab3/part3_2_ResultF.jpg)
>
> 🔴 The API Manager returns a 401 error. Indeed, it is now necessary to pass the token in order to be authorized to call the API.

</details>

On Postman, create a new request with the following information

- Method : POST
- Url : `https://login.microsoftonline.com/{{tenant}}/oauth2/v2.0/token` **TBD : how we get the tenant ??**
- Under the Headers tab, choose the option x-www-form-urlencoded and add the following attributes with the values :
  - **grant_type**: client_credentials
  - **client_id**: **TBD**
  - **client_secret**:**TBD**
  - **scope**: **TBD**/.defaut
- Click on Send
- Retrieve the `access_token` returned by the identity provider.

![Generate Token Request](assets/lab3/part3_2_ResultToken.jpg)

<div class="task" data-title="Task">

> - Go back add the Bearer token to the `FetchOrders` request.
> - Send the request and observe the result.

</div>

<details>

<summary> Toggle solution</summary>

> In the `Authorization` section, choose in the `Auth Type` list the value `Bearer Token` and copy/paste the value retrieved during the request to generate a token.
>
> ![Request OAuth Success](assets/lab3/part3_2_ResultG.jpg)
>
> ✅ The Orders API is now secured using the OAuth 2.0 protocol !

</details>

## Change the behaviour of your API with APIM Policies (15 minutes)

In this final part of the lab, we will learn how to apply APIM policies to dynamically customize API behavior.

### Rate Limiting

To begin, let's simulate a **free tier usage** that should be limited to a few calls per minute to leave compute for the paying users of our API.
We'll use the `Basic` Product for this free tier to ensure a control on the call `rate` of these users and limit up to 5 api calls per minute.

- On the APIM screen, in the menu on the left, click on `Products`, then select the product `Basic` from the list and click on it.
- Go to `Policies`. On the right, in the `Inbound processing` section, click on the `+ Add policy` access the policy catalog.

![Add Policy Product](assets/lab3/part4_1-step2.jpg)

- Click on the tile `rate-limit-by-key`

<div class="task" data-title="Task">

> Configure the rate-limit-by-key policy to limit at 5 calls per minute per subscription.

</div>

<details>

<summary> Toggle solution</summary>

In the window that opens, fill in the fields with the following values and then click `Save`:

- **Number of calls**: `5`
- **Renewal period**: `60` (seconds)
- **Counter Key**: `API subscription`
- **increment condition**: `Any request`

![Configure RateLimit policy](assets/lab3/part4_1-step4.jpg)

</details>

<div class="task" data-title="Task">

> From your postman client, call your API endpoint more than 5 times in less than a minute.

</div>

<div class="tip" data-title="Tip">

> Make sure to test using the subscription key corresponding to the `Basic` product.

</div>

<details>

<summary> Toggle solution</summary>

> ![Result RateLimit Policy](assets/lab3/part4_1-Result.jpg)
>
> 💡After the first 5 calls, subsequent calls are blocked. After 1 minutes, calls become possible again.

</details>

### Monetize API

To conclude, we will simulate the monetization of an API using a custom policy that we will now implement.

- On the APIM screen, in the menu on the left, click on `Products`, then select the product `Premium` from the list and click on it.
- Go to `All operations`. On the right, in the `Inbound processing` section, click on the `</>` icon to access the policy editing mode.

![Add Policy Premium Product](assets/lab3/part4_2-step2.jpg)

- In the `<inbound>` section and under the `<base />` tag, add the following code and click on `Save`

```xml

<set-variable name="creditValue" value="{{credit}}" />
        <!-- Check if the credit value is greater than 0 -->
        <choose>
            <when condition="@(int.Parse((string)context.Variables.GetValueOrDefault("creditValue")) > 0)">
                <set-variable name="newCreditValue" value="@(int.Parse((string)context.Variables.GetValueOrDefault("creditValue")) - 1)" />
                <send-request mode="new" response-variable-name="credit" timeout="60" ignore-error="false">
                    <set-url>https://management.azure.com/subscriptions/{{subscription}}/resourceGroups/{{resourcegroup}}/providers/Microsoft.ApiManagement/service/{{apim}}/namedValues/credit?api-version=2024-05-01</set-url>
                    <set-method>PATCH</set-method>
                    <set-header name="Content-Type" exists-action="override">
                        <value>application/json</value>
                    </set-header>
                    <set-body template="liquid">
                    {
                        "properties": {
                        "value": "{{context.Variables["newCreditValue"]}}"
                        }
                    }
                    </set-body>
                    <authentication-managed-identity resource="https://management.azure.com" />
                </send-request>
            </when>
            <otherwise>
                <return-response>
                    <set-status code="429" reason="Too Many Requests" />
                    <set-header name="Content-Type" exists-action="override">
                        <value>application/json</value>
                    </set-header>
                    <set-body>{"error": {"code": "CREDIT_LIMIT_EXCEEDED","message": "Your credit limit is insufficient. Please check your account or contact support."}}</set-body>
                </return-response>
            </otherwise>
        </choose>

```

- On the APIM screen, in the menu on the left, click on `Named values`, then ensure that the value of the named value `Credit` is set to `0`.

<div class="task" data-title="Task">

> From your Postman client and send another http request
> Observe the result

</div>

<details>

<summary> Toggle solution</summary>

> ![Request Result Failed](assets/lab3/part4_2-ResultF.jpg)
>
> 🔴 The API Manager returns a 429 error. Indeed, the credit value is 0 so we don't have credit to make API request.

</details>

- Go back on the APIM screen, in the menu on the left, click on `Named values`, then select the named value `Credit` from the list and click on it and set the Value to `1` and click on `Save`.

![Configure Named Value](assets/lab3/part4_2-step5.jpg)

<div class="task" data-title="Task">

> Go back to Postman and send another http request
> Observe the result

</div>

<details>

<summary> Toggle solution</summary>

![Request Result Success](assets/lab3/part4_2-ResultG.jpg)

> ✅ Now we have credit, so the call is successful.

</details>

<div class="tip" data-title="Tip">

> You can send another http request to use up all your credit
> Observe the result

</div>

## Summary Lab 3

In this lab, we learn how to use Azure APIM in a four-step process:

1. **Expose an API:** Understand how to publish APIs on the Azure APIM platform, enabling seamless integration and accessibility for external and internal consumers.
2. **Manage Your API with Products:** Organize APIs into products to streamline access and define usage plans, making API consumption structured and manageable.
3. **Secure Your API:** Implement robust security measures, including subscription keys for controlled access and OAuth for modern authentication and authorization.
4. **Modify API Behavior Using Policies:** Explore the policy catalog and apply APIM policies to dynamically customize API behavior, by implementing rate limiting. Additionally, create a custom policy through a use case focused on monetizing APIs.

---

# Closing the workshop

Once you're done with this lab you can delete all the resources which you have created at the beginning using the following command:

<div class="task" data-title="Tasks">

> - From your `codespace` environment terminal : Ctrl+J to reopen if closed in the meantime
> - Execute the following command :

```bash
azd down
```

</div>
