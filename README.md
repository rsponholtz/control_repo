Table of contents
=================
* This repository was initially started from the [Puppet-RampUpProgram](https://github.com/Puppet-RampUpProgram/control-repo) initial control repo.  We've added modules to do an automated SAP HANA & App Server installation.  These modules are in the **site** directory. Of course these modules may be used by themselves, or as this document describes as part of a brand-new Puppet Enterprise installation. 


* [Before starting](#before-starting)
* [What you get from this control\-repo](#what-you-get-from-this-control-repo)
* [High Level process summary for SAP](#high-level-process)
* [How to set it all up](#how-to-set-it-all-up)
  * [Copy this repo into your own Git server](#copy-this-repo-into-your-own-git-server)
    * [GitLab](#gitlab)
    * [Stash](#stash)
    * [GitHub](#github)
  * [Configure PE to use the control\-repo](#configure-pe-to-use-the-control-repo)
    * [Install PE](#install-pe)
    * [Get the control\-repo deployed on your master](#get-the-control-repo-deployed-on-your-master)
  * [Setup a webhook in your Git server](#setup-a-webhook-in-your-git-server)
    * [Gitlab](#gitlab-1)
  * [Test Code Manager](#test-code-manager)
  * [SAP Hana modules](#sap-hana-modules)

# Before starting

This control-repo and the steps below are intended to be used with a new installation of Puppet Enterprise (PE).

**Warning:** When using an existing PE installation any existing code or modules in `/etc/puppetlabs/code` will be copied to a backup directory `/etc/puppetlabs/code_bak_<timestamp>` in order to allow deploying code from Code Manager.

# What you get from this control-repo

When you finish the instructions below, you will have the beginning of a best practices installation of PE including:

 - A Git server (eg. GitHub)
 - The ability to push code to your Git server and have it automatically deployed to your PE master
 - A config_version script that outputs the most recent SHA of your code each time you run `puppet agent -t`
 - Optimal tuning of PE settings for this configuration
 - Working and example [roles and profiles](https://docs.puppet.com/pe/latest/puppet_assign_configurations.html#assigning-configuration-data-with-role-and-profile-modules) code
 - The ability to set up and install SAP Hana on RedHat Linux virtual machines in Azure

# High level process

1. Create an Azure Resource Group

1. Within the Azure Resource Group, create a virtual network.  This will handle traffic between the machines in Azure.  

1. Create an Azure Windows Virtual machine as a "client" machine within the resource group, on the virtual network created above.  These instructions describe setting up SAP in Azure within a locked-down environment - the SAP machines will not be accessible from the Internet.  This client machine will be able to access resources within the virtual network, including the SAP HANA server and the application servers.

1. Create an Azure virtual machine as the puppet server.  For this example we used an Ubuntu machine, but any machine that will run Puppet enterprise will be fine.

1. Install Puppet enterprise and the control_repo onto the puppet server.  This also includes customizing the Puppet modules as appropriate for your environment.

1. Configure Puppet Enterprise to be able to manage RedHat machines

1. Configure and run the SAP-Hana-Deploy resource group template

1. Configure the SAP modules within the PE server.  Run puppet on the SAP Hana machine and the App server machine

1. Verify SAP HANA installation

1. Run application server/ERP installation on the Application server

1. Verify correct operation of the environment

## Create an Azure Resource Group
## Create an Azure Virtual Network
## 
## Copy this repo into your own Git server

### GitLab

1. On a new server, install GitLab.
 - https://about.gitlab.com/downloads/

2. After GitLab is installed, sign into the web UI with the user `root`.
 - The first time you visit the UI it will force you to enter a password for the `root` user.

2. In the GitLab UI, create a group called `puppet`.
 - http://doc.gitlab.com/ce/workflow/groups.html

3. In the GitLab UI, make yourself a user to edit and push code.

4. From your laptop or development machine, make an SSH key and link it with your GitLab user.
 - Note: The SSH key allows your laptop to communicate with the GitLab server and push code.
 - https://help.github.com/articles/generating-ssh-keys/
 - http://doc.gitlab.com/ce/ssh/README.html

7. In the GitLab UI, add your user to the `puppet` group.
 - You must give your user at least master permissions to complete the following steps.
 - Read more about permissions:
    - https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/permissions/permissions.md

8. In the GitLab UI, create a project called `control-repo` and set its Namespace to the `puppet` group.

10. On your laptop, clone this PuppetLabs-RampUpProgram control repo.
 - `git clone https://github.com/PuppetLabs-RampUpProgram/control-repo.git`
 - `cd control-repo`

14. On your laptop, remove the origin remote.
 - `git remote remove origin`

15. On your laptop, add your GitLab repo as the origin remote.
 - `git remote add origin <SSH URL of your GitLab repo>`

16. On your laptop, push the production branch of the repo from your machine up to your Git server.
 - `git push origin production`

### Stash

Coming soon!

### GitHub

Coming soon!

## Configure PE to use the control-repo

### Install PE

1. Download the latest version of the PE installer for your platform
 - https://puppetlabs.com/download-puppet-enterprise
2. SSH into your Puppet master and copy the installer tarball into `/tmp`
2. Expand the tarball and `cd` into the directory
3. Run `puppet-enterprise-installer` to install

If you run into any issues or have more questions about the installer you can see our docs here:

http://docs.puppetlabs.com/pe/latest/install_basic.html

### Get the control-repo deployed on your master

At this point you have our control-repo code deployed into your Git server.  However, we have one final challenge: getting that code onto your Puppet master.  In the end state the master will pull code from the Git server via Code Manager, however, at this moment your Puppet master does not have credentials to get code from the Git server.

We will set up a deploy key in the Git server that will allow an SSH key we make to deploy the code and configure everything else.

1. On your Puppet master, make an SSH key for r10k to connect to GitLab

  ~~~
  mkdir /etc/puppetlabs/puppetserver/ssh
  /usr/bin/ssh-keygen -t rsa -b 2048 -C 'code_manager' -f /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa -q -N ''
  cat /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa.pub
  ~~~

 - References:
    - https://help.github.com/articles/generating-ssh-keys/
    - http://doc.gitlab.com/ce/ssh/README.html
2. In the GitLab UI, create a deploy key on the `control-repo` project
 - Paste in the public key from above
3. Login to the PE console
4. Navigate to the **Nodes > Classification** page
 - Click on the **PE Master** group
 - Click the **Classes** tab
 - Add the `puppet_enterprise::profile::master`
    - Set the `r10k_remote` to the SSH URL from the front page of your GitLab repo
    - Set the `r10k_private_key` parameter to `/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa`
 - **Commit** your changes
5. On your Puppet master
 - Run:

    ~~~
    puppet agent -t
    r10k deploy environment -pv
    puppet agent -t
    ~~~

5. Navigate back to the **Nodes > Classification** page
 - Near the top of the page select "add a group"
 - Type `role::all_in_one_pe` for the group name
    - Click the **Add Group** button
 - Click the **add membership rules, classes and variables** link that appears
    - Below **Pin specific nodes to the group** type your master's FQDN into the box
       - Click **pin node**
 - Select the **Classes** tab
    - On the right hand side, click the **Refresh** link
       - Wait for this to complete
    - In the **add new classes** box type `role::all_in_one_pe`
       - Click **add class**
 - **Commit** your changes
8. On your Puppet master
 - Run:

    ~~~
    puppet agent -t
    echo 'code_manager_mv_old_code=true' > /opt/puppetlabs/facter/facts.d/code_manager_mv_old_code.txt
    puppet agent -t
    ~~~

9. Code Manager is configured and has been used to deploy your code

## Setup a webhook in your Git server

Independent of which Git server you choose you will grab the webhook URL from your master.  Then each Git Server will have similar but slightly different ways to add the webhook.

1. On your Puppet master
 - `cat /etc/puppetlabs/puppetserver/.puppetlabs/webhook_url.txt`

### Gitlab

2. In your Git server's UI, navigate to the control-repo repository
 -  In the left hand pane, scroll to the bottom and select **settings**
 - In the left hand pane, select **webhooks**
3. Paste the above webhook URL into the URL field
4. In the trigger section mark the checkbox for **push events** only
3. Disable SSL verification on the webhook
 - Since Code Manager uses a self-signed cert from the Puppet CA it is not generally trusted
3. After you created the webhook use "test webhook" or similar functionality to confirm it works

## Test Code Manager

One of the components setup by this control-repo is that when you "push" code to your Git server, the git server will inform the Puppet master to deploy the branch you just pushed.

1. On your Puppet Master, `tail -f /var/log/puppetlabs/puppetserver/puppetserver.log`.
2. On your laptop in a separate terminal window:
 - Add a new file

    ~~~
    touch test_file
    git add test_file
    git commit -m "adding a test_file"
    git push origin production
    ~~~

3. Allow the push to complete and then wait a few seconds for everything to sync over.
 - On your Puppet Master, `ls -l /etc/puppetlabs/code/environments/production`.
    - Confirm test_file is present
4. In your first terminal window review the `puppetserver.log` to see the type of logging each sync will create.

5. done with the test

##SAP HANA Modules
The modules that we've created/used are specific to creating a test HANA & Application server environment in Azure, and depend on a resource group being created using the [SAP-HANA-DEPLOY](https://github.com/AzureCAT-GSI/SAP-Hana-Deploy) template.  Please refer to the template for documentation on usage.

These modules consist of:
1. hanaconfig - this module configures a vanilla RedHat 7.2 virtual machine with the proper configurations for SAP hana.  
1. hanapartition - this module configures 4 premium drives into a logical volume group, creates volumes within it, mounts the volumes appropriately for HANA, and adds the volumes to the /etc/fstab
1. sapmount - mounts the Azure Files repository, which contains the artifacts for installation
1. saphana - performs the automated install of SAP hana 
1. sapfastmount - downloads the sapmount files into a partition, for faster installation of the ERP package
1. sapapp - prepares the app server for execution of the application server & ERP install
