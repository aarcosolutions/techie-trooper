---
layout: post
title: "WordPress on AWS - Part 3: Configure SSL"
date: 2018-02-09
categories: apache openssl
---

In this post, I will be explaining the steps for configuring SSL on Apache Web Server running on AWS EC2 Amazon Linux instance. 

# Prerequisites
1. You will need to provision an EBS-backed Amazon Linux instance. For more information, see [Getting started with Amazon EC2 Linux Instances](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html)

2. Make sure the security group attached with your instance allows connections on following TCP ports:
   *  SSH – port 20
   * HTTP – port 80
   * HTTPS – port 443

3. As a best practice, only allow SSH access to your IP address. You can configure this in the security group. For more information, see [Creating a Security Group](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html#creating-security-group)

# Installing Apache web server
1. Connect to your instance
   ```bash
   ssh ec2-user@<instance-public-ip> -i <key-pair-file>
   ```

2. We need to ensure the software packages on your instance is latest. Perform a quick software update.
   ```bash
   sudo yum update -y
   ```
3. Check if  Apache is already installed
   ```bash
   sudo service httpd status
   ```

4. If Apache is missing, install Apache.
   ```bash
   sudo yum install httpd -y
   ```

5. Check if Apache is installed.
   ```bash
   sudo service httpd status
   ```

6. If Apache is not running, start httpd service
   ```bash
   sudo service httpd start
   ```

7. Let us ensure that httpd service starts automatically
   ```bash
   sudo chkconfig httpd on
   ```

8. Add SSL/TLS support to Apache
   ```bash 
   sudo yum install -y mod_ssl
   ```

# Creating Private Key and Certificate Signing Request (CSR)
To obtain a signed certificate from Certificate Authority (CA), you would have to first generated a self-signed SSL/TLS X.509 host certificate.

1. Connect to your instance and navigate to /etc/pki/tls/private. Server’s private key for SSL/TLS is stored in this directory.
   ```bash 
   ssh ec2-user@<instance-public-ip> -i <key-pair-file>
   cd /etc/pki/tls/private/
   ```
2. Create an RSA private key with password protection. This will generate a 2048-bit RSA private key that has been encrypted with AES-128 cipher. Important point to remember, each time you use this key, you would need to supply the password.
   ```bash 
   sudo openssl genrsa -aes128 -passout pass:EnterPasswordHere -out PrivateKeyFileName.key 2048
   ```

3. We need to make sure that the private key has highly restrictive ownership
   ```bash 
   sudo chown root.root PrivateKeyFileName.key
   sudo chmod 0600 PrivateKeyFileName.key
   ls -al PrivateKeyFileName.key
   ```

4. Let us now create CSR using the newly generated private key. OpenSSL req command will prompt you for the information listed in the table below. The details you provide here will be crossed checked by certificate authority. Make sure you enter the correct domain name in **Common Name** property

   |Attribute|Prefix|Description|Example|
   |---|---|---|---|
   |Country/Region|C|Business Location – Country|GB|
   |State/Province|ST|Business Location – State/Province|Surrey|
   |City/Locality|L|Business Location – City|Sutton|
   |Organization Unit|OU|Organization Unit if required to be listed*| **Optional***|
   |Organization|O|Organization’s legal business name|Your company name|
   |Common Name|CN|Domain to be secured by certificate|YourDomainName.com|

   ```bash
   sudo openssl req -new -key PrivateKeyFileName.key  -out CSRFileName.pem
   ```

5. Finally the openssl command will prompt you for an optional challenge password.

6. The resulting file will contain the public key, the digital certificate for this public key and the information you entered.

7. Now you are ready to submit the CSR to a certificate authority. You will usually copy the content of CSR file into the certificate request form. The CA will validate the ownership of the domain before issuing the certificate. After the request has been approved, you will receive a new certificate signed by the certificate authority. The certificate file will have .crt extension


8. Copy the certificate to your server. The easiest way is to copy the content of the crt file, create a new file on server and paste the content. Alternatively you can upload the certificate to S3 bucket and copy to server using aws cli.

9. Copy signed certificate files to /etc/pki/tls/certs/ directory.

10. You can check the details of the CA signed certificate.
    ```bash
    openssl x509 -in certificate.crt -text
    ```
11. We need to make sure that the signed certificate files has highly restrictive ownership. Perform these actions on all crt files

    ```bash
    sudo chown root.root certificate.crt
    sudo chmod 0600 certificate.crt
    ls -al certificate.crt
    ```

# Update ssl.conf
This is the configuration file for mod_ssl. It contains configuration which tells Apache where to find encryption key, certificate, SSL/TLS settings and cipher information.

1. Edit /etc/httpd/conf.d/ssl.conf

2. Update Apache’s SSLCertificateFile directive

   ```bash
   SSLCertificateFile /etc/pki/tls/certs/certificate.crt
   ```
3. If you have recieved CA intermediate certificate file, update SSLCACertificateFile directive
   ```bash
   SSLCACertificateFile /etc/pki/tls/certs/intermediate.crt
   ```

4. Update private key path in SSLCertificateKeyFile directive
   ```bash
   SSLCertificateKeyFile /etc/pki/tls/private/custom.key
   ```

5. Save ssl.conf and restart Apache
   ```bash
   sudo service httpd restart
   ```

Your Apache web server is now ready for SSL/TLS communication.
