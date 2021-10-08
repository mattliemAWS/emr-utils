import sys
import subprocess
import json
import requests
import socket
import logging
from datadog import initialize, statsd

def main():
	logging.basicConfig(
	stream=sys.stdout,
	format='%(asctime)s %(levelname)-8s %(message)s',
	level=logging.INFO,
	datefmt='%Y-%m-%d %H:%M:%S')

	f = open('/mnt/var/lib/info/job-flow.json')
	data = json.load(f)
	cluster_id = data["jobFlowId"]

	emr_nodes_list = []
	emr_nodes = subprocess.check_output("aws emr list-instances --region us-east-1 --instance-states=RUNNING --cluster-id=" + cluster_id, shell = True)
	for i in json.loads(emr_nodes)["Instances"]:
		emr_node = {
			"State" : i["Status"]["State"],
			"Ec2InstanceId": i["Ec2InstanceId"],
			"PrivateDnsName": i["PrivateDnsName"]
			}
		emr_nodes_list.append(emr_node)

	emr_cluster_describe = subprocess.check_output("aws emr describe-cluster --region us-east-1 --cluster-id=" + cluster_id, shell = True)
	for i in json.loads(emr_cluster_describe)["Cluster"]["InstanceGroups"]:
		if i["InstanceGroupType"] == "MASTER":
			master_instancegroup = i["Id"]

	master_nodes = {}
	emr_list_instances = subprocess.check_output("aws emr list-instances --region us-east-1 --cluster-id=" + cluster_id, shell = True)
	for i in json.loads(emr_list_instances)["Instances"]:
		if i["InstanceGroupId"] == master_instancegroup:
			master_nodes[i["PrivateDnsName"]] = i["Status"]["State"]

	cluster_ip = socket.getfqdn()
	yarn_nodes = {}
	for i in requests.get('http://' + cluster_ip + ':8088/ws/v1/cluster/nodes?states=RUNNING').json()["nodes"]["node"]:
		yarn_nodes[i["nodeHostName"]] = i["state"]

	zombie_nodes = []
	zombie_node_count = 0
	for i in emr_nodes_list:
		if i["PrivateDnsName"] not in yarn_nodes and i["PrivateDnsName"] not in master_nodes:
		#if i["PrivateDnsName"] not in yarn_nodes:
			zombie_node_count += 1
			zombie_nodes.append(i["PrivateDnsName"])

	#send metrics to DD
    statsd.histogram('zombie_node_count', zombie_node_count)

	if not zombie_nodes:
		logging.info("Zombie node list is empty")
	else:
		logging.info('Number of Zombie Nodes: %s' % zombie_node_count)
		logging.info('List of Zombie Nodes are: %s' % zombie_nodes)

if __name__ == '__main__':
	main()
