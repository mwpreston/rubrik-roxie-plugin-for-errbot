#!/bin/bash

# Variables used for echoing in color
black='\E[30;47m'
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
blue='\E[34;47m'
magenta='\E[35;47m'
cyan='\e[0;36m'
white='\E[37;47m'
reset='\e[0m'   
newlinedefault='yes'
# function used to echo in color
cecho() { 
	local default_msg="No message passed."
	message=${1:-$default_msg}   # Defaults to default message.
	color=${2:-$cyan}           # Defaults to black, if not specified.
  	newline=${3:-$newlinedefault}
	#echo -e "$color"
  	#echo "$message"
  	#echo -e "$reset"
	if [ "$newline" = "no" ]; then
		echo -n -e "$color $message $reset"
	else
		echo -e "$color $message $reset"
	fi

	return
}

#function to ensure password meets Mattermost complexity requirements
test_password() {
        if [[ ${#botpassword} -ge 10 && "${botpassword//[^@#$%!&*+=-]/}" && "$botpassword" == *[[:upper:]]* && "$botpassword" == *[[:lower:]]* && "$botpassword" == *[0-9]* ]]; then
                passcheck="good"
        else
                passcheck="Password must contain 1 uppercase, 1 lowercase, 1 special character and be at least 10 characters in length"
        fi
}

#function which checks for script prerequisties
check_prerequisites() {
        if command -v python3 &>/dev/null; then
                cecho " - Python 3 is installed" $green
        else
                cecho " - Cannot find python3. Please install python3 and re-run the script" $red
                echo ""
                cecho "Exiting script" $red
                echo ""
                exit
        fi
        if command -v virtualenv &>/dev/null; then
                cecho " - virtualenv is installed" $green
        else
                cecho " - Cannot find virtualenv! Please install virtualenv and re-run the script." $red
                echo ""
                cecho "Exiting script..." $red
                echo ""
                exit
        fi
	if test -f "/opt/mattermost/bin/mattermost"; then
		cecho " - Mattermost CLI has been found!" $green
	else
		cecho " - Cannot find the Mattermost CLI" $red
		echo ""
		cecho "Exiting script..." $red
		echo ""
		exit
	fi
}


clear
cecho "**********************************************************************" $cyan
cecho "**            Welcome to the Rubrik for Errbot Installer            **" $cyan
cecho "**********************************************************************" $cyan
echo ""
cecho "This script will install the following packages and applications..." $cyan
cecho "  - Errbot" $yellow
cecho "  - Rubrik SDK for Python" $yellow
cecho "  - Rubrik Plugin for Errbot (Roxie)" $yellow
cecho "  - Mattermost Backend for Errbot" $yellow
cecho "  - mattermostdriver" $yellow
echo ""
cecho "Checking Prerequisites..." $cyan
check_prerequisites
echo ""

read -r -p "All looks good - Would you like to continue with the installation? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
	echo ""
    	cecho "Alright, let's go! First things first - we will need some information from you!" $cyan
   	echo ""
    	cecho "We need a directory to host all of the Errbot core files, plugins, and Mattermost backend"
	echo ""
	read -r -p "Where would you like to store this? [/usr/share/errbot] " errbotdir
	errbotdir=${errbotdir:-/usr/share/errbot}
	echo ""
	
	cecho "Now we will need some information around your Mattermost installation" 
	echo ""
	read -r -p "What is the IP or DNS of your Mattermost server? [localhost] " mattermostserver
	read -r -p "What team would you like to install the bot into? " mattermostteam
	read -r -p "Do you run Mattermost under http or https? [http] " mattermostscheme
	read -r -p "What port does Mattermost run on? [8065] " mattermostport
	mattermostport=${mattermostport:-8065}
	mattermostscheme=${mattermostscheme:-http}
	mattermostserver=${mattermostserver:-localhost}
	echo ""
	
	cecho "Cool! Just a few more tidbits of information around the bot then..."
	echo ""
	read -r -p "I'm going to need the email address you would like to use for the bot? [roxie@localhost.local] " botemail
	read -r -p "Alright, how about a username for the bot? We like to call ours Roxie [Roxie] " botusername
	echo "Aaaand finally a password. This must be 10 characters and contain at least 1 upper case letter, 1 lowercase letter, 1 number and 1 special character"
	
	while true; do
        	botpassword=$(systemd-ask-password "Enter Password: ")
		test_password $botpassword
        	if [ "$passcheck" = "good" ]; then
                	while true; do
				echo ""
				confirmpassword=$(systemd-ask-password "Confirm Password:")
                        	if [ "$botpassword" = "$confirmpassword" ]; then
                                	break 2
                        	else
                                	echo ""
					echo "Passwords do not seem to match - try again!"
                                	break 1
                        	fi
                	done
        	else
                	echo ""
			echo "$passcheck"
			
        	fi
	done
	
	botemail=${botemail:-roxie@localhost.local}
	botusername=${botusername:-Roxie}
	echo ""
    	
	cecho "Alright - I think we got it!  Here's the rundown of what will happen"
	echo ""
	cecho "We will create the following directories on this system..."
	cecho " - $errbotdir/errbot-core - to host your Errbot core files and run a virtualenv" $yellow
	cecho " - $errbotdir/mattermost - to host the Mattermost backend for Errbot" $yellow
	cecho " - $errbotdir/roxie - To host the Rubrik Plugin for Errbot and the main configuration file" $yellow
	echo ""
	cecho "We will use the following Mattermost settings to build the bot configuration file..."
	cecho " - Server: $mattermostserver" $yellow
	cecho " - Scheme: $mattermostscheme" $yellow
	cecho " - Port: $mattermostport" $yellow
	cecho " - Team: $mattermostteam" $yellow
	echo ""
	cecho "$botmessage"
        cecho " - Username: $botusername" $yellow
        cecho " - Email: $botemail" $yellow
        cecho " - Password: *******" $yellow

	read -r -p "Soooo - does all this seem good to you? [y/n] " response

	if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
	then
		clear
		cecho "Excellent! Sit back, chill, grab a bevvy - we will keep you posted"
		echo ""
		cecho "Begining Installation...." $cyan
		cecho " - Creating Directory for Errbot Core files in $errbotdir/errbot-core..." $yellow "no"
		mkdir -p $errbotdir/errbot-core
		cecho "Done" $green
		cecho " - Creating Directory for Rubrik Roxie plugin in $errbotdir/roxie..." $yellow "no"
                mkdir -p $errbotdir/roxie
                cecho "Done" $green
		cecho " - Creating Directory for Mattermost Errbot backend in $errbotdir/errbot-mattermost" $yellow "no"
                mkdir -p $errbotdir/errbot-mattermost
                cecho "Done" $green
		cecho " - Creating virtualenv in $errbotdir/errbot-core..." $yellow "no"
		virtualenv --python `which python3` $errbotdir/errbot-core > /dev/null
		cecho "Done" $green
		cecho " - Installing Errbot into virtualenv..." $yellow "no"
		$errbotdir/errbot-core/bin/pip install errbot > /dev/null
		cecho "Done" $green
		cecho " - Installing the Rubrik SDK for Python into virtualenv..." $yellow "no"
		$errbotdir/errbot-core/bin/pip install rubrik_cdm > /dev/null
		cecho "Done" $green		
                cecho " - Installing the mattermostdriver into virtualenv..." $yellow "no"
                $errbotdir/errbot-core/bin/pip install mattermostdriver > /dev/null
                cecho "Done" $green
		cecho " - Adding $errbotdir/errbot-mattermost to virtualenv PYTHONPATH environment variable..." $yellow "no"
		echo "export PYTHONPATH=$errbotdir/errbot-mattermost:\$PYTHONPATH" >> $errbotdir/errbot-core/bin/activate
		cecho "Done" $green
		cecho " - Activating the virtualenv..." $yellow "no"
		source $errbotdir/errbot-core/bin/activate > /dev/null
		cecho "Done" $green
		cecho " - Creating Errbot instance in $errbotdir/roxie" $yellow "no"
		cd $errbotdir/roxie
		errbot --init > /dev/null
		deactivate
		cecho "Done" $green
		cecho " - Cloning the Roxie Errbot plugin from GitHub...." $yellow "no"
		git clone -q https://github.com/mwpreston/rubrik-roxie-plugin-for-errbot.git /tmp/rubrik-roxie-errbot > /dev/null
		cecho "Done" $green
		cecho " - Copying Roxie plugin files to $errbotdir/roxie/plugins..." $yellow "no"
		cp -r /tmp/rubrik-roxie-errbot/rubrik $errbotdir/roxie/plugins/
		cecho "Done" $green
		cecho " - Cloning Mattermost Backend for Errbot into $errbotdir/errbot-mattermost" $yellow "no"
		git clone -q https://github.com/Vaelor/errbot-mattermost-backend.git $errbotdir/errbot-mattermost > /dev/null
		cecho "Done" $green
		cecho " - Creating $botusername user in Mattermost.  This will be our bot!!!..." $yellow "no"
		cd /opt/mattermost/bin
		./mattermost user create --email $botemail --username $botusername --password $botpassword --system_admin
		cecho "Done" $green
		cecho " - Backing up default configuration file in $errbotdir/roxie/..." $yellow "no"
		mv $errbotdir/roxie/config.py $errbotdir/roxie/config.py.bak
		cecho "Done" $green
		cecho " - Creating new configuration file in $errbotdir/roxie/..." $yellow "no"
		echo "import logging
		
BACKEND = 'Mattermost'
BOT_EXTRA_BACKEND_DIR = '$errbotdir/errbot-mattermost' # This points where we cloned the Mattermost Backend
BOT_DATA_DIR = '$errbotdir/roxie/data' # This points to where we first initialized our Errbot instance
BOT_EXTRA_PLUGIN_DIR = '$errbotdir/roxie/plugins/' # This points to where we first initialized our Errbot instance
BOT_LOG_LEVEL = logging.DEBUG
BOT_LOG_FILE = '$errbotdir/roxie/errbot.log'

BOT_IDENTITY = {
        # Required
        'team': '$mattermostteam',
        'server': '$mattermostserver',
        # For the login, either
        'login': '$botemail',
        'password': '$botpassword',
        # Optional
        'insecure': True,
        'scheme': '$mattermostscheme',
        'port': $mattermostport # Default = 8065
}

BOT_ADMINS = ('@admin', )" >> $errbotdir/roxie/config.py
		cecho "Done" $green
		echo ""
	        cecho "Installation Complete!!!"
		cecho "=============================="
		cecho "Congrats - we are done!" $cyan
		echo ""
		cecho "Start your bot with the below command, head into Mattemost, configure authentication and start chatting!" $cyan
		echo ""
		cecho "======================================================================================"
		echo ""
		cecho "Start bot in foreground mode with following command..." $cyan
		echo ""
		echo "source $errbotdir/errbot-core/bin/activate && $errbotdir/errbot-core/bin/errbot -c $errbotdir/roxie/config.py"	
		echo ""
		cecho "Start bot in daemon mode with the following command..." $cyan
		echo ""
		echo "source $errbotdir/errbot-core/bin/activate && $errbotdir/errbot-core/bin/errbot -d -c $errbotdir/roxie/config.py"
		echo ""
		cecho "======================================================================================"
		echo ""
		read -r -p "Would you like to configure Roxie to run on startup? [Y/N] " response
		if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			echo ""
			cecho "Good Choice!  I'll get working on that now!" $cyan
			cecho " - Creating startup script for Roxie..." $yellow "no"
			echo "source $errbotdir/errbot-core/bin/activate && $errbotdir/errbot-core/bin/errbot -d -c $errbotdir/roxie/config.py &


while true; do
        sleep 10
done" >> /usr/bin/runroxie
			cecho "Done!" $green
			cecho " - Setting up systemd service..." $yellow "no"
			echo "[Unit]
Description=Rubrik Roxie Plugin for Errbot
After=mattermost.service

[Service]
Type=simple
ExecStart=/bin/bash /usr/bin/runroxie

[Install]
WantedBy=multi-user.target
" >> /lib/systemd/system/roxie-errbot.service
			cecho "Done!" $green
			cecho " - Reloading systemd..." $yellow "no"
			systemctl daemon-reload
			cecho "Done!" $green
			cecho " - Enabling Roxie to start on boot..." $yellow "no"
			systemctl enable roxie-errbot.service
			cecho "Done!" $green
			cecho " - Starting Roxie service..." $yellow "no"
			systemctl start roxie-errbot.service
			cecho "Done!" $green
		else
			echo ""
			cecho "Well, whatever, start and stop it yourself the above commands then!" $cyan
		fi
		echo ""
		echo ""
		cecho "Once Errbot is started you can configure the Rubrik Roxie Plugin by heading into Mattermost and DM'ing $botusername with the following text..." $cyan
		cecho "!plugin config Rubrik" $yellow
		echo ""
		
		cecho "That's a wrap!!! I'll let Roxie take it from here!" $cyan
	else
		cecho "I get it, something just doesn't feel right" $red
		cecho "Let's just kill the script and maybe we can try again in a bit..." $red
		echo ""
		exit
	fi
else
	cecho "Gotchya, something just doesn't feel right eh?" $red
	cecho "Let's kill the script now" $red
	echo ""
    	exit
fi
