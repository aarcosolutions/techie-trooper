---
layout: post
title: "Azure Functions Core Tools"
date: 2020-06-18
categories: azure azure-functions
author:
- Amit Rai Sharma
tags: azure azure-functions
---

## Prerequisite
- Azure Functions Core tools
- Azure Storage Emulator

#### Azure Functions Core Tools

[Install Azure Functions Core tools](https://github.com/Azure/azure-functions-core-tools) which is compatible with the your OS. The toolkit includes:

Command line tools
- For creating new Function App
- Adding functions
- Deploying to Azure

It also includes the Azure Functions runtime

> **_Important_**  
> Install [Azure CLI[(https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) locally to be able to publish functions to Azure from Azure Functions Core Tool


#### <a href="#azure-storage-emulator">Azure Storage Emulator</a>
Azure Storage Emulator is only available on Windows. For other OS, you will need to rely on a real storage account. [Azure Storage Emulator](https://go.microsoft.com/fwlink/?linkid=717179&clcid=0x409) is installed as part of Azure SDK

## Troubleshooting installation
### Azure Functions core tools version 3 : throw er;

Executing **func** command on a Windows OS where Azure Functions core tool version 3 and node.js 13 or above version is installed results in following error:
```
events.js:292
      throw er; // Unhandled 'error' event
      ^

Error: spawn C:\Users\amitr\AppData\Roaming\npm\node_modules\azure-functions-core-tools\bin/func ENOENT
    at Process.ChildProcess._handle.onexit (internal/child_process.js:268:19)
    at onErrorNT (internal/child_process.js:468:16)
    at processTicksAndRejections (internal/process/task_queues.js:84:21)
    at Process.ChildProcess._handle.onexit (internal/child_process.js:274:12)
    at onErrorNT (internal/child_process.js:468:16)
    at processTicksAndRejections (internal/process/task_queues.js:84:21) {
  errno: -4058,
  code: 'ENOENT',
  syscall: 'spawn C:\\Users\\<USER>\\AppData\\Roaming\\npm\\node_modules\\azure-functions-core-tools\\bin/func',
  path: 'C:\\Users\\<USER>\\AppData\\Roaming\\npm\\node_modules\\azure-functions-core-tools\\bin/func',
  spawnargs: []
v14.4.0 
```

This issue occurs due to an issue with unzipper package used in the Azure Functions core tool package.json. Unzip step in the Azure Functions core tool installation process fails silently. Refer [node-unzipper issue #168](https://github.com/ZJONSSON/node-unzipper/issues/168) for more information.

**Follow these steps to resolve this issue:**
```
Go to the installed location.C:\Users\<USER>\AppData\Roaming\nvm\v<node-version-folder>\node_modules\azure-functions-core-tools\ in the example above.

Run npm install unzipper@0.10.7

Run node .\lib\install.js from that directory
```

These steps downloads and extract the core-tools to the bin location and have it setup for executions.

## Using Azure Functions Core Tools

### Create a local Functions project

Open command prompt and execute following command
```
func init Your-Function-Name
```
In version 2.x or higher, you must choose a runtime for your function project.
```
Select a worker runtime:
dotnet
node
python 
powershell
```

> **_Important_**
> By default, version 2.x of the Core Tools will create function app projects for the .NET runtime as C# class projects (.csproj).

### Register extensions
Function bindings in runtime 2.x and higher are implemented as extension packages. HTTP and timer triggers are exceptions and does not require extension packages.

You can install extensions individually or you can add extension bundle reference to host.json file. Adding extension bundles removes the chances of having package compatibility issues when using multiple binding types. Extension bundles are the recommended approach and it also removes the requirement of installing .NET Core 2.x SDK.

```json
// Adding extension bundles to host.json file
{
    "version": "2.0",
    "extensionBundle": {
        "id": "Microsoft.Azure.Functions.ExtensionBundle",
        "version": "[1.*, 2.0.0)"
    }
}
```
The following properties are available in `extensionBundle`:

| Property | Description |
| -------- | ----------- |
| id | The namespace for Microsoft Azure Functions extension bundles. |
| version | The version of the bundle to install. The Functions runtime always picks the maximum permissible version defined by the version range or interval. The version value above allows all bundle versions from 1.0.0 up to but not including 2.0.0. |

Bundle versions increment as packages in the bundle change. Major version changes occur when packages in the bundle increment by a major version. Major version changes in the bundle usually coincide with a change in the major version of the Functions runtime.  

The current set of extensions installed by the default bundle is enumerated in this [extensions.json file](https://github.com/Azure/azure-functions-extension-bundles/blob/dev/src/Microsoft.Azure.Functions.ExtensionBundle/extensions.json).

### Local settings file
The local.settings.json file stores app settings, connection strings, and settings used by local development tools. Settings in the local.settings.json file are used only when you're running projects locally.

```json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "<language worker>",
    "AzureWebJobsStorage": "<connection-string>",
    "AzureWebJobsDashboard": "<connection-string>",
    "MyBindingConnection": "<binding-connection-string>"
  },
  "Host": {
    "LocalHttpPort": 7071,
    "CORS": "*",
    "CORSCredentials": false
  },
  "ConnectionStrings": {
    "SQLConnectionString": "<sqlclient-connection-string>"
  }
}
```

By default, these settings are not migrated automatically when the project is published to Azure. Use the --publish-local-settings switch when you publish to make sure these settings are added to the function app in Azure. Note that values in ConnectionStrings are never published.

### Create a function
Open a command prompt and execute the following command:
```
func new
```
From version 2.x, when you run ```func new``` you will be prompted to choose a template. The code will be generated in the default language based on the runtime you have selected while creating the function app 

```
Select a language: Select a template:
Blob trigger
Cosmos DB trigger
Event Grid trigger
HTTP trigger
Queue trigger
SendGrid
Service Bus Queue trigger
Service Bus Topic trigger
Timer trigger
```

To create a new function in a single command, run:
```
func new --template "Http Trigger" --name newHttpTrigger
```

### Run functions locally
To run a Functions project locally, you will have to run the Functions host. The Functions host enables triggers for all the functions in the project. 

```
//C#
func start --build

//JavaScript
func start

//Python
func start

//TypeScript
npm install
npm start
```
### Publish to Azure
The Azure Functions Core Tools supports two types of deployment: 
- deploying function project files directly to your function app via Zip Deploy
- deploying a custom Docker container. 

As a prerequisite, a function app must be created in your Azure subscription. Function apps that require compilation should be built and binaries should be deployed.

A Function App project folder may contain language-specific files and directories that shouldn't be published. Excluded items are listed in a .funcignore file in the root project folder.

>**Important**
> You must have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed locally to be able to publish to Azure from Core Tools.

To publish your local code to a function app in Azure, use the publish command:
```
func azure functionapp publish <FunctionAppName>
```
This command publishes to an existing function app in Azure. You'll get an error if you try to publish to a <FunctionAppName> that doesn't exist in your subscription. 

You will have to be logged into the Azure subscription for publishing the function app. Use following commands to login

```
// this command will open a browser for you to login your azure subscription

az login

//In case you have more the one subscription associated with the logged in user

az account list  //this command will list the subscription linked to you users

az account set --subscription <subscription-> // select the preferred subscription
```

### Example

```
-----------------------------
//Creating a new Function App
-----------------------------

D:\workspace\personal-projects\azure-functions> func init my-function-app
Use the up/down arrow keys to select a worker runtime:dotnet
dotnet <
node
python
powershell

Writing D:\workspace\personal-projects\azure-functions\my-function-app\.vscode\extensions.json


-----------------------
//Adding a new function
-----------------------

D:\workspace\personal-projects\azure-functions\my-function-app> func new
Use the up/down arrow keys to select a template:Function name: GetItemApi
QueueTrigger
HttpTrigger <
BlobTrigger
TimerTrigger
DurableFunctionsOrchestration
SendGrid
EventHubTrigger
ServiceBusQueueTrigger
ServiceBusTopicTrigger
EventGridTrigger
CosmosDBTrigger
IotHubTrigger

The function "GetItemApi" was created successfully from the "HttpTrigger" template.

------------------------------
//Building and testing locally
------------------------------

D:\workspace\personal-projects\azure-functions\my-function-app> func start --build
Microsoft (R) Build Engine version 16.6.0-preview-20181-02+9f3e4e725 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Determining projects to restore...
  Restored D:\workspace\personal-projects\azure-functions\my-function-app\my-function-app.csproj (in 3.68 sec).
  You are using a preview version of .NET Core. See: https://aka.ms/dotnet-core-preview
  my-function-app -> D:\workspace\personal-projects\azure-functions\my-function-app\bin\output\bin\my-function-app.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:09.52
.....

---------------------
//Deploying to Azure 
---------------------

D:\workspace\personal-projects\azure-functions\my-function-app> func azure functionapp publish fn-uks-app-name
Microsoft (R) Build Engine version 16.6.0-preview-20181-02+9f3e4e725 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Determining projects to restore...
  All projects are up-to-date for restore.
  You are using a preview version of .NET Core. See: https://aka.ms/dotnet-core-preview
  my-function-app -> D:\workspace\personal-projects\azure-functions\my-function-app\bin\publish\bin\my-function-app.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:03.64


Getting site publishing info...
Creating archive for current directory...
Uploading 2.2 MB [################################################################################]
Upload completed successfully.
Deployment completed successfully.
Syncing triggers...
Functions in fn-uks-playground:
    GetItemApi - [httpTrigger]
        Invoke url: https://fn-uks-app-name.azurewebsites.net/api/getitemapi?code=fqtTmj1seJzDg3.....==
```

## Troubleshooting - Azure Functions
### Missing value for AzureWebJobsStorage

When no valid storage connection string is set for AzureWebJobsStorage and the emulator isn't being used, the following error message is shown:

```Missing value for AzureWebJobsStorage in local.settings.json. This is required for all triggers other than HTTP. You can run 'func azure functionapp fetch-app-settings <functionAppName>' or specify a connection string in local.settings.json.```

To resolve this issues:
1. [Install Azure Storage Emulator](#azure-storage-emulator)
2. Use a valid storage account connection string from Azure.

