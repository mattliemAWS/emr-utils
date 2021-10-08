# emr-utils - cis-emr-image

This utility is an example of how to secure an EMR cluster based off of CIS requirements. By default, EMR uses vanilla EC2 AMI and it's up to the customer to configure the EC2 as per their security requirements. The utility involves 
1) creating a custom EMR AMI: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-custom-ami.html
2) Running bootstrap action during cluster provisioning: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-bootstrap.html

Notes:
- Some CIS requirements must be applied after the ec2 instance is running which is why the additional bootstrap action is used.
- Amazon Inspector was used to scan the EMR cluster with CIS Operating System Security Configuration Benchmarks-1.0. 
- Not all CIS requirements are covered in this utility. There are some that are known to be incompatible with Hadoop e.g SElinux, and others that require user input. e.g how long should user session be active for
- Finally, (and most importantly) some CIS requirements are not applicable in the context of running on AWS. e.g firewall rules when you have security groups or password rotation requirements when you block SSH access and only interact with the EMR cluster remotely via EMR Steps API (A general best practice)

# Usage (Manual):
1. Provision latest vanilla AL and apply cis_image_creation.sh 
2. Create image out of latest AMI
3. Provision EMR cluster with custom ami and include cis_ba.sh

# Usage (EC2 Image Builder):
EC2 Image Builder is a fully-managed service that makes it easy to build, customize and deploy OS images without writing scripts.
1. Save cis_image_creation.sh in your user s3 bucket and use as cfn parameter
2. Update the Phase:Build:CopyandExecuteCISscripts step with the S3 path where you uploaded  the script to
2. Run CFN template which will create an image pipeline. The image pipeline will be scheduled to run cron - 0 0 12 1/1 * ? * using the ami provided as the parameter. It creates an image recipe that runs the cis_image_creation.sh as a individual component. 
3. Once the CFN is complete - go to image pipeline to run on demand. 
4. Image will be built and ami provided for to use as a custom EMR AMI