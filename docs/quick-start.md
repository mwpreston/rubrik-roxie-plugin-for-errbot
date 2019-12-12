# Introduction to the Rubrik Roxie Plugin for Errbot

Errbot is a python based chatbot that connects to your favorite chat service and brings your tools into the conversation. This plug-in extends Errbot's architecture to bring Roxie, Rubrik's intelligent personal assistant into the fold. Utilizing the Roxie Plugin for Errbot allows organizations to integrate common cloud data management tasks into their preferred collobaration platforms, granting end-users to chat or query the plugin in order to perform functions through simple conversation such as:

- Assigning an SLA Domain to a Rubrik object
- Taking an on-demand snapshot of a Virtual Machine
- Performing a Live Mount of a Virtual Machine

The Rubrik Plugin for Errbot will interpret the natural conversation and peform the respective API calls to a Rubrik cluster in order to perform the requested functionality, while responding back to the users within the chat service.

*Note: While Errbot can be utilized on it's own, the real power comes when it is accessed through a bot within a chat service. This guide will walk through the process of setting up Errbot and Roxie with Mattermost, an on-premises open source chat service. While this guide focuses on Mattermost, modifications could be made in order to make this work with Slack as well ??? MWP - Need to word better.*

# Prerequisites

The code assumes that you have already deployed at least one Rubrik cluster into your environment and have completed the initial configuration process to form a cluster. This code also assumes that Mattermost, the chat service Errbot will connect to, has been downloaded and configured properly.

The following software packages are prerequisites in order to support the Roxie Plugin for Errbot and Mattermost. 

1. Python3
1. virtualenv
1. git


# Installation

This guide will walk through the bare minimum steps in order to get Errbot and the Rubrik Plugin for Errbot installed, configured, and connected to a Mattermost instance. For further information and more detailed installation instructions, refer to the [Official Errbot Documentation]().

After completing this guide the following applications and packages will be installed:

1. Errbot
1. mattermostdriver
1. Mattermost Backend for Errbot
1. Rubrik Python SDK
1. Roxie Plugin for Mattermost

Installation can be performed in two different manners; Automated or Manual, outlined below.

## Automated Installation

For convenience we have developed a script which will automate all of the actions performed in the Manual Installation section. **Note** The automated installation only works when you wish to install all components on the same server which runs Mattermost.

To run an automated installation use the following steps:

1. Download the automated script [here](/install/install.sh)
1. Execute the script by running `./install.sh`
1. The script will prompt for various bits of information including installation directories, Mattermost configuration, and Bot configuration. Be sure to input everything correctly when prompted.
1. Upon completion, Errbot, Mattermost Backend for Errbot, MattermostDriver, and the Rubrik Roxie Plugin for Errbot will be installed.
1. Before you can begin using Roxie, the plugin will need to be configured to point to your cluster and supplied an administrative API token. More details around this can be found in the [`Configuring the Rubrik Plugin for Errbot`](#Configuring-the-Rubrik-Plugin-for-Errbot) section.

## Manual installation

The manual installation process can be broken down into three subsections; Installing Errbot, Installing the Rubrik Plugin for Errbot, and Installing the Mattermost Backend for Errbot

### Installing Errbot
The first step to creating our Roxie bot involves getting Errbot installed, configured, and running. While package managers may be used for certain Linux distrobutions, the following will walk through the more prefered installation method using virtualenv:

1. Create a new python3 based virtual environment

    `virtualenv --python ``which python3`` /usr/share/errbot-core`

1. Install Errbot using pip

    `/usr/share/errbot-core/bin/pip install errbot`

1. Install the Rubrik Python SDK

    `/usr/share/errbot-core/bin/pip install rubrik_cdm`

1. Activate the virtualenv

    `source /usr/share/errbot-core/bin/activate`

1. Create and switch to a directory to host the errbot instance.

    `mkdir /usr/share/errbot-roxie && cd /usr/share/errbot-roxie`

1. Initialize the directory for Errbot. This will copy the nessessary files, as well as a default configuration file to our working directory

    `errbot --init`

### Installing the Rubrik Plugin for Errbot 

1. Download the Rubrik Roxie Plugin for Errbot

    `git clone https://github.com/mwpreston/rubrik-roxie-plugin-for-errbot.git /tmp/rubrik-roxie`

1. Copy the Rubrik Plugin for Errbot to the working directory

    `cp -r /tmp/rubrik-roxie/rubrik-errbot/rubrik /usr/share/errbot-roxie/plugins/`

Errbot and the Rubrik Plugin for Errbot have now been successfully installed. We can quickly test the installations by running the `errbot` command from within our working directory as follows:

![](img/errbot-run.png)

Errbot will now be started in text/developer mode. Here we can test that Errbot is responding by issuing the `!tryme` command, which in turn calls an example plugin which was loaded during the `errbot --init` process. A succesful Errbot installation will respond with 'It works !' as shown below:

![](img/2019-12-11-11-45-19.png)

To confirm that the Rubrik Plugin for Errbot has been successfully loaded issue the `!status plugins` command and search for the Rubrik plugin. A properly working pluging will have an 'A' displayed for its status to indicate it has been activated. The following illustrates a properly function Rubrik plugin:

![](img/rubrik-plugin-status.png)

This mearly ensures that our plugin is working. Configuration still needs to occur before it is able to connect to a Rubrik cluster. Before that however, the next step is to get Errbot talking to Mattermost.

### Installation of the mattermostdriver and Errbot for Mattermost Backend

In order for Mattermost to talk to Errbot and vice-versa we have to connect the two application utilizing a backend. A backend is simply a connector which leverages web hooks allowing communication to flow between Mattermost and Errbot. The following steps outline the installation and configuration for both the mattermostdriver and the backend:

1. Install the mattermostdriver packages through pip. **Ensure the virtualenv for Errbot is still active**

    `/usr/share/errbot-core/bin/pip install mattermostdriver`

1. Clone the Errbot Backend for Mattermost to a desired directory

    `git clone https://github.com/Vaelor/errbot-mattermost-backend.git`

1. Use the Mattermost CLI to create a user to use as your bot. The user must be assigned the system admin role.  We like to call ours Roxie

    `/opt/mattermost/bin/mattermost user create --email roxie@rubrik.us --username roxie --password SuperSecret123! --system_admin`

    ![](img/user-create-cli.png)

    **Optionally you may use the `Invite People` option from the main menu within your Teams Mattermost space.

1.  Modify the `config.py` configuration file within the working directory (/usr/share/errbot-roxie if following along), pointing it to the mattermost backend and configuring the bot.

    For example, we want to change the default `config.py` which looks something like this...
    
    ```
    import logging

    # This is a minimal configuration to get you started with the Text mode.
    # If you want to connect Errbot to chat services, checkout
    # the options in the more complete config-template.py from here:
    # https://raw.githubusercontent.com/errbotio/errbot/master/errbot/config-template.py

    BACKEND = 'Text'  # Errbot will start in text mode (console only mode) and will answer commands from there.

    BOT_DATA_DIR = '/usr/share/errbot-mattermost/data'
    BOT_EXTRA_PLUGIN_DIR = '/usr/share/errbot-mattermost/plugins'

    BOT_LOG_FILE = '/usr/share/errbot-mattermost/errbot.log'
    BOT_LOG_LEVEL = logging.DEBUG

    BOT_ADMINS = ('@CHANGE_ME', )  # !! Don't leave that to "@CHANGE_ME" if you connect your errbot to a chat system !!
    ```
    
    To this

    ```
    import logging

    # This is a minimal configuration to get you started with the Text mode.
    # If you want to connect Errbot to chat services, checkout
    # the options in the more complete config-template.py from here:
    # https://raw.githubusercontent.com/errbotio/errbot/master/errbot/config-template.py

    BACKEND = 'Mattermost'  
    BOT_EXTRA_BACKEND_DIR = '/usr/share/errbot-mattermost-backend' # This points where we cloned the Mattermost Backend
    BOT_DATA_DIR = '/usr/share/errbot-mattermost/data' # This points to where we first initialized our Errbot instance
    BOT_EXTRA_PLUGIN_DIR = '/usr/share/errbot-mattermost/plugins/' # This points to where we first initialized our Errbot instance
    BOT_LOG_LEVEL = logging.DEBUG
    BOT_LOG_FILE = '/usr/share/errbot-mattermost/errbot.log'

    BOT_IDENTITY = {
            # Required
            'team': 'devrel',
            'server': '10.10.15.26',
            # For the login, either
            'login': 'roxie@rubrik.us',
            'password': 'SuperSecret123!',
            # Optional
            'insecure': True,
            'scheme': 'http',
            'port': 8065 # Default = 8065
    }

    BOT_ADMINS = ('@admin', )  # !! Don't leave that to "@CHANGE_ME" if you connect your errbot to a chat system !!
    ```

1. Add the following line to your virtualenv activate script(/usr/share/errbot-core/bin/activate if following along). This ensures the newly cloned Mattermost backend directory is part of the PYTHONPATH environment variable within the virtual environment.

    ```
    export PYTHONPATH=/usr/share/errbot-mattermost-backend:$PYTHONPATH
    ```

We have now completed all of the installations required and can begin to run our Errbot instance.

### Running the Errbot instance

The Errbot instance, Mattermost Backend and Rubrik plugin are now ready to be started. To start Errbot with our desired configuration run the following command:

`source <path_to_errbot_install>/bin/activate && <path_to_errbot_install>/bin/errbot -c <path_to_working_directory>/config.py`

If following along with this guide, the command would look as follows:

`source /usr/share/errbot-core/bin/activate && /usr/share/errbot-core/bin/errbot -c /usr/share/errbot-roxie/config.py`

#### Configuring Errbot and Roxie to start on system boot

# Configuring the Rubrik Plugin for Errbot

TODO

# Code Review

TODO

## Creating new functions

TODO

# Further Reading

TODO

* Errbot Documentation
* Mattermost Documentation
* Rubrik API Documentation

