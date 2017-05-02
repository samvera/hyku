1. Make sure you have the `~/.ssh/hybox` key first. If not, see the instructions in the section below.
1. Visit https://hybox.signin.aws.amazon.com/console and sign in.
1. Click "Services > EC2"
1. Click "Security Groups" in the sidebar (under Network & Security)
1. Click region dropdown in topbar and select "N. Virginia" to see US East entries
1. Select "demo-bastion" (I'm seeing two of these now, and I performed this operation for both)
1. Select "Inbound" from the tab below
1. Click "Edit" button, then add a new rule with Type "SSH" and Source to "My IP"
1. Click "Save" button
1. Click "Instances" in the sidebar
1. Click `demo-bastion` from the list
1. In the "Description" tab below, copy the "Public DNS" value
1. In your console type `ssh -A -i ~/.ssh/hybox ec2-user@<paste DNS here>` to connect to the bastion host
1. Back in your browser, click "demo-webapp" (for instance) from the list
1. In the "Description" tab below, copy the "Private DNS" value
1. Now you can SSH to any other machine in the cluster via e.g. `ssh ip-10-0-5-178.ec2.internal` (If you get a `Permission denied (publickey)` error, you may need to run the `ssh-add ~/.ssh/hybox` step from the instructions below.)

## Getting the SSH key

1. Visit https://hybox.signin.aws.amazon.com/console and sign in.
1. Click "S3"
1. Click on "hybox-keys"
1. Click on "key-pairs-us-east-1"
1. Check the box next to "hybox" and download the SSH key to `~/.ssh/`
1. Make the new SSH identity file private in your console with `chmod 0600 ~/.ssh/hybox`
1. In your console, add your key to the identity: `ssh-add ~/.ssh/hybox`

Note: You would need to `ssh-add` again after restarting.  Or use `-K` to retain the key persistently.