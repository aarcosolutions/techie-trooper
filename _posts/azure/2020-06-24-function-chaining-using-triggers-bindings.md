---
layout: post
title: "Azure Functions chaining using triggers and bindings"
date: 2020-06-24
categories: azure azure-functions
author:
- Amit Rai Sharma
tags: azure azure-functions
---


## Context
Azure Functions allows developers to take action when an event occurs. It connects to various data sources or messaging solutions which makes it easy to process and handle events. Developers can leverage Azure Functions to build HTTP-based API endpoints or can develop functions which reacts to a message inserted in a queue. Azure Functions scales automatically and you only pay for compute resources when your functions are running. 


This article revolves around _Reward Platform_ which is a sample application based on Serverless Architecture and is developed using Azure Functions. Here I have utilised triggers and bindings to chain various functions to develop the registration flow.

## Highlevel Flow
User registers with Reward Platform and receives an email with an unique reward code. The platform is divided into multiple functions:

1. User is registered via _RegisterCustomer_ function which is a HttpTrigger function. 
   -  This function creates a user document in _Customers_ collection of _RewardPlatform_ CosmosDB database.
   - Add _CustomerRegisteredMessage_ to _customer-registered_ Storage Queue

2. Reward code is issued for the new customer by _IssueRewardCode_ function. This is a QueueTrigger function which monitor _customer-registered_ Storage Queue.
   - Reads first unused reward code from _RewardCodes_ collection.
   - Update reward code document and set IsUsed property
   - Add _CodeIssuedMessage_ to _code-issued_ Storage Queue

3. Reward code is update in the new customer document by _AddRewardCodeToCustomer_ function. This is a QueueTrigger function monitor _code-issued_ Storage Queue.
   - Retrieves customer document from _Customers_ collection
   - Update customer document with reward code
   - Add -NotifyCustomerMessage- to _notify-customer_ Storage Queue

3. User is notified via email which contains the reward code _NotifyCustomer_ function. This is a QueueTrigger function monitor _code-issued_ Storage Queue and has SendGrid output binding.

![reward-platform-highlevel.png](/assets/images/reward-platform-highlevel.png)

## Development Environment
- Visual Studio 2019 / Visual Studio Code
- [Storage Account Emulator](https://azure.microsoft.com/downloads/) (deployed as part of Azure SDK)
- [Cosmos DB Emulator](https://aka.ms/cosmosdb-emulator)
- Nuget Dependencies
   - Microsoft.Azure.WebJobs.Extensions.CosmosDB - 3.0.7
   - Microsoft.Azure.WebJobs.Extensions.SendGrid - 3.0.0
   - Microsoft.Azure.WebJobs.Extensions.Storage - 3.0.10
   - Microsoft.NET.Sdk.Functions - 3.0.7

## Configuration
### Storage Queues
Create following queues on your Storage Account / Storage Emulator
- customer-registered
- code-issued
- notify-customer

### Cosmos Db
- Create Database Name: RewardPlatform
- Create following collections:
  - Customers
  - RewardCodes
- Create and insert data into RewardCodes based on following json

```json
{
    "id": "GUID",
    "RewardCodeValue": "GUID",
    "IsUsed": false
}
```

### SendGrid

You will need a SendGrid account to send emails. I have utilised the free SendGrid account which came with Microsoft Partner Action Pack Subscription. 

## Code Repository
```bash
git clone https://aarcosolution@dev.azure.com/aarcosolution/techie-trooper/_git/reward-platform
```