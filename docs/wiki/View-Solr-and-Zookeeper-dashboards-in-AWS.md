## Goal

Both Solr and Exhibitor (which is used to manage the Zookeeper ensemble) provide a web-based dashboard for viewing status and interacting with the service. As an administrator of the Hyku stack, it is often convenient to be able to view these dashboards, especially when troubleshooting Solr or Zookeeper related problems. In the AWS deployment, both Solr and Zookeeper run in a private subnet within a VPC; this means the dashboards cannot be accessed directly, so a set of steps is needed to make this possible.

## Solution

1. Open up the necessary ports in the Solr and Zookeeper security groups. 

   _Note: This step only needs to be done once, then it will work for everyone needing to connect afterwards. This step could also be included in CloudFormation._
   1. For Solr, this is port 8983. For Exhibitor, this is port 80.
   2. In the AWS EC2 console, select `Security Groups` and search for "BastionSecurityGroup" (there should be only one result.) Copy the Group ID, it should be something like "sg-12345678".
   3. Still in the `Security Groups` section, search for "SolrSecurityGroup" (there should be only one result.) Select the `Inbound` tab, and click `Edit`. Select to `Add Rule`. For the port, use *8983*, for the source, paste in the bastion security group ID. Select Save.
   4. Still in the `Security Groups` section, search for "ZookeeperSecurityGroup" (there should be only one result.) Select the `Inbound` tab, and click `Edit`. Select to `Add Rule`. For the port, use *80*, for the source, paste in the bastion security group ID. Select Save.

2. Set up a tunneled ssh connection, allowing a local port to push to the necessary port on the solr or zookeeper node.
   1. In the AWS EC2 console, select `Instances`. Select the bastion instance and copy its Public DNS value. Select one of  each of the solr and zookeeper instances and copy their private IP addresses.
   2. In a terminal, run: `ssh -i keypair.pem -L 8983:<solr-node-ip>:8983 ec2-user@<bastion-dns-name>`. This sets up an ssh connection to the solr instance, which forwards requests from local port 8983 to the same port on the solr instance. The keypair is the same used to log in to the bastion instance.
   3. In another terminal, run: `ssh -i keypair.pem -L 8984:<zookeeper-node-ip>:80 ec2-user@<bastion-dns-name>`. This sets up an ssh connection to the zookeeper instance, which forwards requests from local port 8984 to port 80 on the zookeeper instance.

3. Configure a browser to proxy requests through localhost ports
   1. Firefox has an add-on called FoxyProxy which is convenient for this purpose, but most browsers can be set up with a proxy. Note that this is not a SOCKS proxy.
   2. To view the Solr UI, set the proxy to point to host `localhost` and port `8983`
   3. To view the Exhibitor UI (for zookeeper), set the proxy to point to host `localhost` and port `8984`

4. Use the browser with the proxy settings to open the dashboard UI
   1. For Solr: http://localhost/solr/
   2. For Exhibitor (Zookeeper): http://localhost/exhibitor/v1/ui/index.html