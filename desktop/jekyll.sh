#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs XRDP on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Jekyll dependencies..."
#==============================================================================
# First: Install dependencies:
apt -y install make build-essential ruby ruby-dev
# Second: Configure path of Ruby Gem's:
echo "export GEM_HOME=\$HOME/gems" >> ~/.bashrc
echo "export PATH=\$HOME/gems/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc

#==============================================================================
_title "Installing Ruby bundler..."
#==============================================================================
gem install bundler

#==============================================================================
_title "Installing Jekyll..."
#==============================================================================
gem install jekyll

# Fifth: Change ownership if not in a CHROOT:
[[ -z "${CHROOT}" ]] && chown $USER:$USER -R ~/.bundle

#==============================================================================
_title "Installing Jekyll systemd service..."
#==============================================================================
# Sixth: Create Jekyll systemd service file:
cat << EOF > /etc/systemd/system/jekyll.service
[Unit]
Description=Jekyll service
After=syslog.target network.target

[Service]
User=kodi
Type=simple
ExecStart=/usr/local/bin/run-jekyll
ExecStop=/usr/bin/pkill -f jekyll

[Install]
WantedBy=multi-user.target network-online.target
EOF
if ischroot; then
	systemctl disable jekyll
	change_username /etc/systemd/system/jekyll.service
else
	systemctl enable jekyll
fi
# Seventh: Create "run-jekyll" command:
cat << EOF > /usr/local/bin/run-jekyll
#!/bin/bash
export GEM_HOME=\$HOME/gems
export PATH=\$HOME/gems/bin:\$PATH
cd /home/kodi/GitHub/xptsp.github.io
jekyll serve
EOF
chmod +x /usr/local/bin/run-jekyll
ischroot || change_username /usr/local/bin/run-jekyll
