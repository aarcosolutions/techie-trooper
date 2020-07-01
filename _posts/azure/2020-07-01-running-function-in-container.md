---
layout: post
title: "Running Azure Function in Container"
date: 2020-07-01
categories: azure azure-functions
author:
- Amit Rai Sharma
tags: azure azure-functions
toc: true
---

## Overview
Function version 2 onward the runtime is cross-platform, which means that the Azure Function runtime can be hosted in a docker container as well.

Micrsoft has created docker images which allow to host Azure Function in a container. These images are available on [docker hub](https://hub.docker.com/_/microsoft-azure-functions-base).

```bash
#v2
docker pull mcr.microsoft.com/azure-functions/dotnet:2.0

#v3
docker pull mcr.microsoft.com/azure-functions/dotnet:3.0
```
There are also images available for functions written in [JavaScript](https://hub.docker.com/_/microsoft-azure-functions-node), [Java](https://hub.docker.com/_/microsoft-azure-functions-java), [Python](https://hub.docker.com/_/microsoft-azure-functions-python) or [PowerShell](https://hub.docker.com/_/microsoft-azure-functions-powershell).

## Advantages & Disadvantages of running function in container

### Advantages 

1. Functions packaged into containers can be deployed to other environments
   - Running functions in an on-premise data center
   - Hosting on other cloud providers such as AWS
   - Tasking advantage of Azure Container offering such as AKS
2. To have a consistent deployment model for all the application.
3. To have flexibility of configuring network security as needed by the application.

### Disadvantages 

There are some disadvantages of containerising functions:
1. Consumption plan benefits are no longer available, such as
   - Automatic scaling. 
   - Pay only when function is running. 

## Containerising a Reward Platfrom function app
### Prerequisite

Install docker on you development environment. You will find the installation instruction for your OS on [Install Docker Engine](https://docs.docker.com/engine/install/).

### Creating DockerFile

You can use Azure Functions Core Tools to create a dockerfile while creating a function app.
```
func init <function-app-name> 
  --worker-runtime <runtime such as dotnet> 
  --docker
```

I will work with the **Reward Platform** example which is described in [Function chaining]({% link _posts/azure/2020-06-24-function-chaining-using-triggers-bindings.md %}) article. Reward Platform function app didn't have a dockerfile. I will use Azure Functions Core Tools to generate a dockerfile for this function app:

```bash
func init --docker-only
```
This will create dockerfile and .dockerignore files.

```docker
# This is a multi-stage file dockerfile
# Stage 1 uses dotnet code sdk 3.1 base image to build and publish
FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS installer-env

COPY . /src/reward-platform
RUN cd /src/reward-platform && \
    mkdir -p /home/site/wwwroot && \
    dotnet publish *.csproj --output /home/site/wwwroot

# Stage 2 uses azure function base image to host the function.
# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/dotnet:3.0-appservice
FROM mcr.microsoft.com/azure-functions/dotnet:3.0
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]
```

### Generating docker container image

Use docker build command to create a docker image

```bash
# docker build -t <image-name>:<tag> <dockerfile path>
docker build -t reward-platform:v1 . 
```

Output

```bash
Sending build context to Docker daemon  10.05MB
Step 1/6 : FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS installer-env
3.1: Pulling from dotnet/core/sdk
e9afc4f90ab0: Pull complete
989e6b19a265: Pull complete
af14b6c2f878: Pull complete
5573c4b30949: Pull complete
45c472847dce: Pull complete
e20a494a7210: Pull complete
3397d6436f99: Pull complete
Digest: sha256:5b1ac826f436502c0218473ae569fd1e68233c37b6a5d7b652f152138e4e0499
Status: Downloaded newer image for mcr.microsoft.com/dotnet/core/sdk:3.1
 ---> 006ded9ddf29
Step 2/6 : COPY . /src/dotnet-function-app
 ---> 91596398921d
Step 3/6 : RUN cd /src/dotnet-function-app &&     mkdir -p /home/site/wwwroot &&     dotnet publish *.csproj --output /home/site/wwwroot
 ---> Running in 48b9e6ec9d2b
Microsoft (R) Build Engine version 16.6.0+5ff7b0c9e for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Determining projects to restore...
  Restored /src/dotnet-function-app/RewardPlatform.csproj (in 14.54 sec).
  RewardPlatform -> /src/dotnet-function-app/bin/Debug/netcoreapp3.1/bin/RewardPlatform.dll
  RewardPlatform -> /home/site/wwwroot/
Removing intermediate container 48b9e6ec9d2b
 ---> ddfabf30da5e
Step 4/6 : FROM mcr.microsoft.com/azure-functions/dotnet:3.0
3.0: Pulling from azure-functions/dotnet
8559a31e96f4: Pull complete
dc08029e21f9: Pull complete
24716c4a9540: Pull complete
d63b5219dec7: Pull complete
Digest: sha256:2bc96fd31394e2c9180ce8e4608b0eb7fbee7cbd56be40b9224d0c515fbd2e39
Status: Downloaded newer image for mcr.microsoft.com/azure-functions/dotnet:3.0
 ---> 0431ac042764
Step 5/6 : ENV AzureWebJobsScriptRoot=/home/site/wwwroot     AzureFunctionsJobHost__Logging__Console__IsEnabled=true
 ---> Running in cbdaa0aac196
Removing intermediate container cbdaa0aac196
 ---> a70e204c861e
Step 6/6 : COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]
 ---> 31b042d6f30b
Successfully built 31b042d6f30b
Successfully tagged reward-platform:v1
```
Check the docker image by running docker images command

```bash
docker images


REPOSITORY                                 TAG                                              IMAGE ID            CREATED             SIZE
reward-platform                            v1                                               31b042d6f30b        5 minutes ago       492MB
<none>                                     <none>                                           ddfabf30da5e        5 minutes ago       1.01GB
mcr.microsoft.com/dotnet/core/sdk          3.1                                              006ded9ddf29        12 days ago         705MB
mcr.microsoft.com/azure-functions/dotnet   3.0                                              0431ac042764        2 weeks ago         483MB
```

## Deploying function app on docker desktop

You can run a containerised function app by executing docker run command. In case the function app depends on connection string, keep them handy. You can use [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) to retrieve the connection strings from Azure resource like Storage Account or Cosmos Db.

```bash
# Login to your  azure subscription
az login

# In case there are more one subscription linked with your login, select the subscription under which your resource exists
az account list # this will output a list of subscription

# Run following command to select the subscription
az account set --subscription "<subscription-id>" 
```

Here I will be retrieving the connection string for Storage Account and Cosmos Db and assign them to the environment variable when creating a docker container.

```bash
# Retrieve storage account connection string
$storageConnStr = az storage account show-connection-string -g <resource-group-name> -n <storage-account-name> -o tsv

$cosmosDbConnectionString = az cosmosdb keys list -n <cosmos-db-name> -g <resource-group-name>ce --type connection-strings --query connectionStrings[0].connectionString 
# connectionStrings[0].connectionString will return the Primary connection string which is the first connection string in the connectionstring collection of CosmosDb

# Create docker container that will expose port 8080 and set the env variables with connection string 
docker run -e AzureWebJobsStorage=$storageConnStr  -e RewardPlatformCosmosDbConnectionString=$cosmosDbConnectionString -p8080:80 reward-platform:v1
```

## Deploying function app in Azure

Containerised function can be deployed to Azure following ways:
- Virtual Machine with Docker installer
- Azure Kubernetes Services
- Azure Service Fabric
- Azure App Service
- Azure Container Instance

I will be showing how to deploy a containerised function on Azure Container Instance.

### Azure Container Instance
Azure Container Instance is quickest way to host a container in Azure. It provides serverless containers; there is no infrastructure provisioning upfront and you only pay when the container is running. It is a good deployment option for testing single container for short time.

Before the containerised function can be deployed to Azure Container Instance, the docker image needs to be tagged and pushed to a container registry. Use following command to tag and push the image to Azure Container Registry.

```bash
# Tag image
# docker tag reward-platform:v1 <azure container registry server url>:v1
docker tag reward-platform:v1 acrregistryname.azurecr.io/reward-platform:v1

# Login to Azure Container Registry 
# az acr login --name <container registry name>
az acr login --name acrregistryname

# push image
# docker push <azure container registry server url>:v1
docker push acrregistryname.azurecr.io/reward-platform:v1
```

Next I will create a new Azure Container Instance and deploy the docker image uploaded to Azure Container Registry.

```bash
az container create `
>> -n acirewardplatform `  # name of container instance
>> -g rgrewardplatform `   # name of resource group
>> --image acrregistryname.azurecr.io/reward-platform:v1 ` # image name
>> --ip-address public `   # make ip address public
>> --port 80 `             # exposing function on port 80
>> --dns-name-label rewardplatform ` # friendly name to container
>> -e AzureWebJobsStorage=$storageConnStr RewardPlatformCosmosDbConnectionString=$cosmosDbConnectionString SendGridApiKey=$sendGridApiKey # set env variables
```

This command will create a new Azure Container Instance with following configuration:
- Container will be created using acrregistryname.azurecr.io/reward-platform:v1 image
- Container Instance will be exposed over port 80
- A friendly dns name "rewardplatform" is used
- Container instance will be exposed over public IP address
- Environment variable were set

It will take couple of minute for the container instance to be deployed and running.

To check the container logs use following command

```bash
 az container logs -g rgrewardplatform  -n acirewardplatform 
```
Output
```bash
info: Host.Triggers.Warmup[0]
      Initializing Warmup Extension.
info: Host.Startup[503]
      Initializing Host. OperationId: '91cb59df-446a-47c4-8b4d-4211fca388ae'.
info: Host.Startup[504]
      Host initialization: ConsecutiveErrors=0, StartupCount=1, OperationId=91cb59df-446a-47c4-8b4d-4211fca388ae
...
info: Host.Startup[412]
      Host initialized (150ms)
info: Host.Startup[413]
      Host started (169ms)
info: Host.Startup[0]
      Job host started
Hosting environment: Production
Content root path: /
Now listening on: http://[::]:80
Application started. Press Ctrl+C to shut down.
info: Host.General[316]
      Host lock lease acquired by instance ID '000000000000000000000000D98DB272'.
info: Microsoft.Azure.WebJobs.Script.ChangeAnalysis.ChangeAnalysisService[0]
      Initiating breaking change analysis...
info: Microsoft.Azure.WebJobs.Script.ChangeAnalysis.BlobChangeAnalysisStateProvider[0]
      Analysis blob metadata updated with analysis timestamp '2020-07-01T08:34:02.9410434+00:00'.
info: Microsoft.Azure.WebJobs.Script.ChangeAnalysis.ChangeAnalysisService[0]
      Breaking change analysis operation completed.
info: Function.RegisterCustomer[0]
      Executing 'RegisterCustomer' (Reason='This function was programmatically called via the host APIs.', Id=8c600b4d-414e-46cd-a24b-00bf9b58de84)
info: Function.RegisterCustomer.User[0]
      RegisterCustomer invoked
info: Function.RegisterCustomer[0]
      Executed 'RegisterCustomer' (Succeeded, Id=8c600b4d-414e-46cd-a24b-00bf9b58de84)
info: Function.IssueRewardCode[0]
      Executing 'IssueRewardCode' (Reason='New queue message detected on 'customer-registered'.', Id=331bd698-2fb8-44dc-af90-f66e640d439d)
info: Function.IssueRewardCode[0]
      Trigger Details: MessageId: 919a9a2f-d215-40f1-82f9-c92e580b9c37, DequeueCount: 1, InsertionTime: 07/01/2020 08:34:39 +00:00
info: Function.IssueRewardCode.User[0]
      UserRegisteredMessage Received for. Issuing Code.
info: Function.IssueRewardCode.User[0]
      UserRegisteredMessage Received for user3@rewardplatform.com. Issuing Code.
warn: Function.IssueRewardCode.User[0]
      Reward code is not available for allocation. Code not issued to user3@rewardplatform.com
info: Function.IssueRewardCode[0]
      Executed 'IssueRewardCode' (Succeeded, Id=331bd698-2fb8-44dc-af90-f66e640d439d)
info: Function.RegisterCustomer[0]
      Executing 'RegisterCustomer' (Reason='This function was programmatically called via the host APIs.', Id=a3c52628-ee56-4d57-b9e5-f0b3b6e327c1)
info: Function.RegisterCustomer.User[0]
      RegisterCustomer invoked
info: Function.RegisterCustomer[0]
      Executed 'RegisterCustomer' (Succeeded, Id=a3c52628-ee56-4d57-b9e5-f0b3b6e327c1)
info: Function.IssueRewardCode[0]
      Executing 'IssueRewardCode' (Reason='New queue message detected on 'customer-registered'.', Id=aa90d438-a5d2-4006-be41-0f02d6c495fe)
info: Function.IssueRewardCode[0]
      Trigger Details: MessageId: 2ad56faa-34eb-4de8-b2c7-24cc000fc645, DequeueCount: 1, InsertionTime: 07/01/2020 08:34:50 +00:00
info: Function.IssueRewardCode.User[0]
      UserRegisteredMessage Received for. Issuing Code.
info: Function.IssueRewardCode.User[0]
      UserRegisteredMessage Received for user4@rewardplatform.com. Issuing Code.
warn: Function.IssueRewardCode.User[0]
      Reward code is not available for allocation. Code not issued to user4@rewardplatform.com
info: Function.IssueRewardCode[0]
      Executed 'IssueRewardCode' (Succeeded, Id=aa90d438-a5d2-4006-be41-0f02d6c495fe)
info: Function.AddRewardCodeToCustomer[0]
      Executing 'AddRewardCodeToCustomer' (Reason='New queue message detected on 'code-issued'.', Id=fe060276-12e5-42fc-9a48-8c67577f1502)
info: Function.AddRewardCodeToCustomer[0]
      Trigger Details: MessageId: 99d9710d-4c9c-4c6a-b011-aff22d439e78, DequeueCount: 1, InsertionTime: 07/01/2020 08:34:49 +00:00
info: Function.AddRewardCodeToCustomer.User[0]
      UserRegisteredMessage Received for. Issuing Code.
info: Function.AddRewardCodeToCustomer.User[0]
      CodeIssuedMessage Received for user3@rewardplatform.com. Update reward code on customer account.
info: Function.AddRewardCodeToCustomer[0]
      Executing 'AddRewardCodeToCustomer' (Reason='New queue message detected on 'code-issued'.', Id=019d7235-4b6e-42d5-b3ba-e72b90e59491)
info: Function.AddRewardCodeToCustomer[0]
      Trigger Details: MessageId: 9856331f-a813-405a-9caf-baf3b466475e, DequeueCount: 1, InsertionTime: 07/01/2020 08:34:50 +00:00
info: Function.AddRewardCodeToCustomer.User[0]
      UserRegisteredMessage Received for. Issuing Code.
info: Function.AddRewardCodeToCustomer.User[0]
      CodeIssuedMessage Received for user4@rewardplatform.com. Update reward code on customer account.
info: Function.AddRewardCodeToCustomer[0]
      Executed 'AddRewardCodeToCustomer' (Succeeded, Id=019d7235-4b6e-42d5-b3ba-e72b90e59491)
info: Function.AddRewardCodeToCustomer[0]
      Executed 'AddRewardCodeToCustomer' (Succeeded, Id=fe060276-12e5-42fc-9a48-8c67577f1502)
info: Function.NotifyCustomer[0]
      Executing 'NotifyCustomer' (Reason='New queue message detected on 'notify-customer'.', Id=ca6794ad-398f-4610-a03b-4ab5c8c6f6d7)
info: Function.NotifyCustomer[0]
      Trigger Details: MessageId: c102ee6f-7554-45f0-bc53-4ddfe0818847, DequeueCount: 1, InsertionTime: 07/01/2020 08:35:41 +00:00
info: Function.NotifyCustomer.User[0]
      Processing NotifyCustomerMessage. Sending email to : user4@rewardplatform.com
info: Function.NotifyCustomer[0]
      Executing 'NotifyCustomer' (Reason='New queue message detected on 'notify-customer'.', Id=ba744e71-040d-4423-ae44-aab75a28c75e)
info: Function.NotifyCustomer[0]
      Trigger Details: MessageId: 9b807a6e-aaf0-48a9-bbee-7eacc2c27ca6, DequeueCount: 1, InsertionTime: 07/01/2020 08:35:42 +00:00
info: Function.NotifyCustomer.User[0]
      Processing NotifyCustomerMessage. Sending email to : user3@rewardplatform.com
info: Function.NotifyCustomer[0]
      Executed 'NotifyCustomer' (Succeeded, Id=ba744e71-040d-4423-ae44-aab75a28c75e)
info: Function.NotifyCustomer[0]
      Executed 'NotifyCustomer' (Succeeded, Id=ca6794ad-398f-4610-a03b-4ab5c8c6f6d7)
```

## Code Repository
You can clone the Reward Platform using following command
```bash
git clone https://aarcosolution@dev.azure.com/aarcosolution/techie-trooper/_git/reward-platform
```
