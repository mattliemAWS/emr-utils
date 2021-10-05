# emr-utils - ssl-nginx-emr-ui

EMR configures Encryption In Transit for a number of services running on EMR: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-data-encryption-options.html. However, not all UI's are automatically configured. This solution uses customer provided certificate via EMR security config and configures a nginx proxy to encrypt in transit communication to EMR UIs

This utility  wil re-use existing nginx/httpd conf files that are on the EMR cluster and configure them with SSL. The certificates being used for SSL are taken from the EMR Security Configs that are passed in during cluster provisioning: 

https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-create-security-configuration.html

#Usage:
1. Provision EMR cluster with attached BA (emr_EncryptionInTransit_httpdFix_533.sh)
2. Include EMR Spark configuration
 
[
  {
    "classification": "spark-defaults",
    "Properties": {
      "spark.ssl.historyServer.enabled": "false"
    }
  }
]

3. Setup regular ssh tunneling via foxyproxy/dynamic port forwarding from laptop to EMR master node:

https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-ssh-tunnel.html

4. Access UI’s via port 19443:
 
URL would be accessed via:
Spark History Server:  https://<emr_master_node>:19443/shs/
YARN Job History:      https://<emr_master_node>:19443/jh/
YARN Resource Manager: https://<emr_master_node>:19443/rm/
YARN Timeline Server:  https://<emr_master_node>:19443/yts
Tez UI:                https://<emr_master_node>:19443/tez
YARN Node Manager:     https://<emr_master_node>:19443/proxy/application_1626201934269_0003/
 
#Appedix
Why ssl enabled = false?
Spark has built in automatic redirect so that all traffic always goes to its own ssl port :18480. Even if you’re using our nginx proxy on 19443, it redirects you to the spark ui port. Our redirects only occur when accessing 19443 so when accessing spark UI through its default https port, it redirects to the http NM url. I had to disable the redirects by setting the above during cluster provisioning. After this is set to false, the spark ui on 19443 redirects to https NM logs on 19443 – all of which is SSL enforced
 
Version Support?
Tested with EMR 5.33+ and EMR 6.2+
