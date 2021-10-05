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
1. Run CFN template that will create an imagine pipeline in Image Builder. This will define all aspects of the process to create a CIS image for EMR. It consists of the image recipe, infrastructure configuration, distribution, and test settings.