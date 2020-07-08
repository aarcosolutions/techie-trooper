---
layout: post
title: "Using Logic App to check negative feedback on Twitter"
date: 2020-07-07
categories: azure logic-apps
author:
- Amit Rai Sharma
tags: azure logic-apps
toc: true
---

In this post I have demonstrated how easy it is to use Logic Apps to build a workflow for analysing negative feedback on Twitter and send a SMS when a negative feedback is received. The entire workflow will be created using Logic app designer on Azure Portal and not code will be written. 

## Prerequisite
1. Two Twitter accounts for testing. You can create Twitter accounts by following [Signing up with Twitter](https://help.twitter.com/en/using-twitter/create-twitter-account). I have used @devtestaccoun16 and @devtestaccoun17 Twitter accounts.
2. Logic App instance
2. Cognitive service instance
3. Twilio account for sending sms. You can setup and configure Twilio account by following [How to Work with your Free Twilio Trial Account](https://www.twilio.com/docs/usage/tutorials/how-to-use-your-free-trial-account)

## Workflow

I have utilised Logic App designer on the Azure portal to create the following workflow:

1. Logic App monitors a twitter account at regular interval.
2. When a tweet is received, Logica App uses Sentiment Analytics from Cognitive Service to determine the score of a tweet.
3. If the sentiment score is less than 0.5, a SMS will be sent using Twillio.

![la-0.png](/assets/images/la-0.png)

## Designing Workflow

### Monitoring a Twitter account
To begin the workflow design, sign-in to Azure portal, open the Logic APP instance and click on _**Logic app designer**_ menu. The Logic Apps Designer opens and shows a page with an introduction video and commonly used triggers. Select "When a new tweet is posted" trigger.

![la-1.png](/assets/images/la-1.png)

This will show the window for connecting with a Twitter account. Click on _**Sign in**_ button.

![la-2.png](/assets/images/la-2.png)

Enter the credential of the Twitter account and click on **_Authorize app_** button. I have used **@devtestaccoun17** Twitter account to be monitored. This will add new API connection to Logic app **_API connections_** 

![la-3.png](/assets/images/la-3.png)

Next I have configured the search text to be monitored on @devtestaccoun17 account. Twitter trigger can monitor a specific #tag or @twitter-account or a string which are part of tweets. I have used @devtestaccoun17 as the search text.

Trigger can be invoked at a regular interval. I have kept the default trigger interval for this demo which is 3 minutes.

![la-4.png](/assets/images/la-4.png)

### Checking tweet sentiment
I have utilised _Text Analytics_ feature of _Azure Cognitive Service_ which can perform sentiment analysis. Body of the tweet is sent to the Cognitive Service to perform sentiment analysis. To do this, I have added a new step to the workflow. Click on _New step_ button, search for Cognitive Service and select _Text Analytics_. Click on the _Actions_ tab and select _Detect Sentiment_.

![la-5.png](/assets/images/la-5.png)

Designer will prompt to create a new API connection to the Cognitive Service. I have given a name to the connection, add the account key from the Cognitive Service and add the endpoint of the Cognitive Service. Click on _Create_ button.

![la-7.png](/assets/images/la-7.png)

Next I have configured the _Detect Sentiment_ step by passing the tweet body which was retrieved in previous step. Click on _Add new parameter_ text box and select _Text_ checkbox.

![la-8.png](/assets/images/la-8.png)

This will open _Dynamic content_ window. Select the “Tweet text” from the list; that’s what will be passed for sentiment analysis. Sentiment Analysis generate a _Score_ which is a decimal value between 0 and 1. 

![la-9.png](/assets/images/la-9.png)

### Decision making step
Once the sentiment analysis is completed, the workflow can decide whether the sentiment is negative on a tweet and send a SMS. This can be done using a _Condition_ action. 

Click on _New step_ button, search and select _Control_. Click on _Actions_ tab and then select _Condition_.

![la-10.png](/assets/images/la-10.png)

_Condition_ represent an _if else_ statement where you can decide based on a criterion. 

![la-11.png](/assets/images/la-11.png)

I have added following condition to this step:
1. Click on _Choose a value_ which will open a _Dynamic content_ window. Select _Score_.
2. Select _is less than_ option from the drop down.
3. Click on _Choose a value_ to add the comparison value which I have set as 0.5. 

> Please note that the value entered in the 3rd step will be considered as a string, so I have casted "0.5" into a float value using expression.

![la-12.png](/assets/images/la-12.png)

If the sentiment score is less than 0.5, the workflow logic will send a SMS message using Twilio. Click on _Add an action_ under _If true_. Search _Twilio_ in _Choose an action_ window and select _Send Text Message (SMS)_

![la-12-1.png](/assets/images/la-12-1.png)

Like before a new API connection will be created for Twilio. Enter a connection name, Twilio account id,  access token and click on _Create_ button.

![la-12-2.png](/assets/images/la-12-2.png)

Add following configuration in _Send Text Message (SMS)_ window: 
1. Select _From Phone Number_ from the drop down list which list the available number in Twilio account.
2. Add the _To Phone Number_ which can be any valid mobile number on which you want to send the SMS.
3. I have specified the message which needs to included in the SMS sent out. Click on _Text_ textbox, this will open a _Dynamic content_ window. 

![la-13.png](/assets/images/la-13.png)

Workflow design is complete. Finally save the Logic App.

### Testing
I have configured the workflow to be triggered every 3 minutes but for testing I have used _Logic app Run_ feature.

For testing the workflow, I have posted a positive and a negative tweet from @devtestaccoun16 to @devtestaccoun17 Twitter account.

**Test 1: Positive tweet: I love the content posted on @devtestaccoun17.**
Expected Outcome: No SMS should be sent out.

1. Post "Positive tweet: I love the content posted on @devtestaccoun17." tweet from @devtestaccoun16.
2. Go to Logic app, click on _Run Trigger_ menu and select _When_a_new_tweet_is_posted_ 

   ![la-15.png](/assets/images/la-15.png)

This action generates a run history item and an entry will be added to _Run history_ grid. Click on the latest entry to see the details of the execution. _Run history_ details will be loaded in a new window where you can see the data processed by every workflow step. Following image show positive tweet body, 0.991 score assigned by the sentiment analyser and the condition expression set as false. 

![la-16-positive-test.png](/assets/images/la-16-positive-test.png)


**Test 2: Negative tweet: I did not like the content posted on @devtestaccoun17.**
Expected Outcome: SMS with score and tweet body should be sent out.

1. Post "Negative tweet: I did not like the content posted on @devtestaccoun17." tweet from @devtestaccoun16.
2. Go to Logic app, click on _Run Trigger_ menu and select _When_a_new_tweet_is_posted_. Click on the latest entry from the _Run history_ grid. The sentiment analyser assigns a score of 0.0742 to the negative tweet. This result is condition expression being evaluated as true and a SMS message is sent out.

![la-17-negative-test.png](/assets/images/la-17-negative-test.png)

**Content of the SMS message:** 
Sent from your Twilio trial account - Negitive tweet received.. Score: 0.0742229521274567 Tweet: Negative tweet: I did not like to content posted on @devtestaccoun17 #devtestaccoun17