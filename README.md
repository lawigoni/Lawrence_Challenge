# Lawrence_Challenge

This Terraform code creates and deploys a running instance of a web server in AWS that serves a single static page with the content "Hello World!" The web application is secured and hosted such that only appropriate ports are publicly exposed, and any HTTP requests are redirected to HTTPS. The code also includes automated tests to validate the correctness of the server configuration.

## Prerequisites
Before running the Terraform code, you will need to have the following:

An AWS account with access keys
Terraform installed on your local machine
A key pair for SSH access to the EC2 instance
Basic knowledge of AWS, Terraform, and Nginx configuration

## Automated Tests
This code includes automated tests to validate the correctness of the server configuration. The tests are defined in the test/test.sh file and can be run by executing the following command:

### This will perform the following tests:

Verify that the web server is running and serving the correct content
Verify that HTTP requests are redirected to HTTPS
Verify that the SSL certificate is valid
