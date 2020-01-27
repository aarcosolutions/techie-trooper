---
layout: post
title: "WordPress on AWS - Part 2: Configure Domain using AWS Route 53"
date: 2018-02-09
categories: aws ec2 wordpress
tags: aws route53
---

In this post I will describe how to register a domain with AWS Route53 and configure a simple routing policy to route traffic to your WordPress site.

# Registering a domain on Amazon Route 53
Amazon Route 53 is highly available and scaleable cloud based Domain Name System (DNS). It translates name like www.sample.com to IP address like 10.0.2.3. Here are some simple steps to register your domain

1. Open [Route 53 console](https://console.aws.amazon.com/route53/home) and navigate to Registered domains section. This section will show a list of previously registered domains. Click on Register Domain.
   ![Register domain](/assets/images/r53-1.png "Register domain")


2. Check the availability of your domain name, add to cart and click Continue.
   ![Domain search](/assets/images/r53-2.png "Domain search")


3. Fill the contact details form and click Continue
   ![Domain contact](/assets/images/r53-3.png "Domain contact")


4. Review and complete the purchase
   ![Review purchase](/assets/images/r53-4.png "Review purchase")


5. If the email address used while registering domain needs to be verified, registrar associate will send an email with a link to that address. Registrar will suspend your domain, if you didn’t verify your email address by clicking the link. Domain registration might take up to three days to complete. In my case it took around 20 minutes to register a domain

6. Check the progress of registration in the Registered domains section of Route 53. You will receive email from Amazon once the domain registration is completed.

7. Once the domain is registered, you can check the Hosted zone by navigating to Dashboard section. You will see Amazon has already created a hosted zones for your domain. NS record and SOA (Start of authority record) are created for any domain registered in Route 53.
   ![Domain hosted zones](/assets/images/r53-5.png "Domain hosted zones")

# Configuring Route 53 to route traffic to your EC2 instance
1. Open the [EC2 console](https://console.aws.amazon.com/ec2/) and find the public IP address of your Amazon EC2 instance.
2. Open the [Route 53 console](https://console.aws.amazon.com/route53/home) and navigate to Hosted Zones section.
3. Click on your Domain Name, you will see list of configured hosted zones. Click on Create Record Set
4. I have configured A record for aarcoder.com as [naked domain](http://www.pcmag.com/encyclopedia/term/62630/naked-domain). If your domain name is example.com and you want to us xyz.example.com to route traffic to your EC2 instance, type xyz in Name field. Select Type as A – IPv4 address, enter the public IP of your EC2 instance in Value  and select Routing Policy as simple. Save the record set.

![Domain A record](/assets/images/r53-6.png "Domain A record")

Record set changes are generally propagated to all Amazon Route 53 servers within 60 seconds. You will be able to route to your EC2 instance using domain name once propagation has completed.

In the next post [Configure SSL for WordPress site]({% link _posts/aws/2019-02-09-aws-wordpress-part-3.md %}) I will take you through the steps for securing your WordPress site by configuring SSL on Apache Web Server running on AWS EC2 Amazon Linux instance.