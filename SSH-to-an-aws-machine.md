1. Visit https://console.aws.amazon.com and sign in.
1. Click "EC2"
1. Click "Security Groups" in the sidebar
1. Click region dropdown in topbar and select "N. Virginia" to see US East entries
1. Then select "demo-bastion" (I'm seeing two of these now, and I performed this operation for both)
1. Select "Inbound" from the tab below
1. Edit the rules and set "Source" to "My IP"
1. Click "Instances" in the sidebar
1. Click "demo-bastion" from the list
1. In the "Description" tab below copy the "Public DNS"
1. In your console type `ssh -i <path to key> -A ec2-user@<paste DNS>`
1. Now you can SSH to any other machine in the cluster.

## Getting the SSH key

1. Visit https://console.aws.amazon.com and sign in.
1. Click "S3"
1. Click on "hybox-keys"
1. Click on "key-pairs-us-east-1"
1. Check the box next to "hybox" and download the SSH key to `~/.ssh/`
1. Make the new SSH identity file private in your console with `chmod 0600 ~/.ssh/hybox`
1. In your console, add your key to the identity: `ssh-add ~/.ssh/hybox`
