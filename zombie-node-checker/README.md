# emr-utils - zombie node checker

This simple utility reports nodes whose instance state are "Running" as per EC2 but are not "Running" as per YARN Resource Manager. This will help reduce cost by not paying for resources your cluster is not using.

This can occur when termination protection is enabled on an EMR cluster and the node becomes "UNHEALTHY" as per YARN. In this scenario, the Amazon EMR instance controller blacklists the node and does not allocate YARN containers to it until it becomes healthy again. A common reason for unhealthy nodes is that disk utilization goes above 90%. With termination protection, Amazon EC2 core instances remain in a blacklisted state and continue to count toward cluster capacity. You can connect to an Amazon EC2 core instance for configuration and data recovery, and resize your cluster to add capacity. 

Another example where this might occur is if EMR loses communication to the core/task node and cannot send a termination signial. YARN will mark this node as lost and the node will still be running on EC2. 

This example sents a zombie_node_count metric to datadog. An alert can be setup when zombie_node_count > 1 for a defined period. Similar process can be done for CW metrics/alarms as well. 

