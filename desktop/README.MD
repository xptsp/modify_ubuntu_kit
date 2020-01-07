#Red Dragon Xubuntu Desktop Scripts#
These scripts installs software on your machine:

##canon_printers_info.sh##
I needed the link to information on how to install Canon printer drivers in the installation, so that I could have an easier time getting my in-laws machine up and running with their printer correctly.  Now you know the story behind this one....

##chrome.sh##
This script installs [Google Chrome](https://www.google.com/chrome/index.html)  on your machine.  Description from website:
> A more simple, secure, and faster web browser than ever, with Google's smarts built-in.

##cpu-g.sh##
This script installs [CPU-G (a CPU-Z alternative for Linux)](https://www.linux-apps.com/p/1130329/)  on your machine.  

Description from website:
> CPU-G is an application that shows useful information about your hardware. It collects and displays information about your CPU, RAM, Motherboard, some general information about your system and more. ...

##ddclient.sh##
This script installs [DDClient](https://sourceforge.net/p/ddclient/wiki/Home/) onto your system, then applies the instructions found [here](https://jenssegers.com/dynamic-dns-for-cloudflare-with-ddclient) to add CloudFlare support to it.  This script also disables it on a Live CD and instructs the toolkit not to reenable it upon OS installation. 

Description from website:
> DDclient is a small but full featured client requiring only Perl and no additional modules. It runs under most UNIX OSes and has been tested under GNU/Linux and FreeBSD. Supported features include: operating as a daemon, manual and automatic updates, static and dynamic updates, optimized updates for multiple addresses, MX, wildcards, abuse avoidance, retrying failed updates, and sending update status to syslog and through e-mail.

##dolphin.sh##
This script installs [Dolphin Emulator](https://dolphin-emu.org/)  on your machine.

Description from website:

> Dolphin is an emulator for two recent Nintendo video game consoles: the GameCube and the Wii. It allows PC gamers to enjoy games for these two consoles in full HD (1080p) with several enhancements: compatibility with all PC controllers, turbo speed, networked multiplayer, and even more! 

##gimp.sh##
This script installs [GNU Image Manipulation Program (GIMP)](https://www.gimp.org/)  on your machine.  Description from website:
> GIMP is a cross-platform image editor available for GNU/Linux, OS X, Windows and more operating systems.

##github_desktop.sh##
This script installs [a fork of GitHub Desktop](https://github.com/shiftkey/desktop)  that supports various Linux distributions.  For those unfamilar with GitHub Desktop, [this link](https://desktop.github.com/) takes you to the original GitHub Desktop webpage for a full description of capabilities.  

Description from GitHub Desktop website:
> Focus on what matters instead of fighting with Git. Whether you're new to Git or a seasoned user, GitHub Desktop simplifies your development workflow. 

##ncid.sh##
This script installs [Network Caller ID (NCID)](http://ncid.sourceforge.net/) server and client packages onto your machine.   This script also removes the **mailutils-common** and **postfix** packages that get installed alongside them, as well as reconfigures the server to not require a modem and fixes a few improperly marked executable files.  It also creates a Kodi notification systemd service.  (Requires Kodi... Duh :p )

Description from website:
> NCID (Network Caller ID) is Caller ID (CID) distributed over a network to a variety of devices and computers.   

##nginx.sh##
This script installs [Nginx](https://www.nginx.com/), a web server which can also be used as a reverse proxy, load balancer, mail proxy and HTTP cache. 

##pcsx2.sh##
This script installs [PCSX2](https://pcsx2.net/), a PlayStation 2 emulator.

##playonlinux.sh##
This script installs Wine first (if not already installed), then installs [PlayOnLinux](https://www.playonlinux.com/en/).  Description from website:
> PlayOnLinux will allow you to play your favorite games on Linux easily.

##pulseaudio_systemd.sh##
This script installs [ZeroConf](https://en.wikipedia.org/wiki/Zero-configuration_networking), [Avahi](https://avahi.org/), and PulseAudio preference software, then creates a PulseAudio systemd service and configures the system not to spawn user-process copies of PulseAudio.

##remarkable.sh##
This script installs [Remarkable](hhttps://remarkableapp.github.io/linux.html), a free and open-source Linux Markdown editor.

##retropie.sh##
This script installs [RetroPie](https://retropie.org.uk/) on your machine.  Description from website:
>RetroPie allows you to turn your Raspberry Pi, ODroid C1/C2, or PC into a retro-gaming machine. It builds upon Raspbian, EmulationStation, RetroArch and many other projects to enable you to play your favourite Arcade, home-console, and classic PC games with the minimum set-up. For power users it also provides a large variety of configuration tools to customise the system as you want. 

##samba.sh##
This script installs [Samba](https://www.samba.org) on your machine.   It also configures the install to create a share to user 1000's home directory.  In addition, a Samba GUI program is installed and minor additions are added to allow the GUI to work properly.

A finisher script is installed to create a user (user 1000's username) with either the default password ("xubuntu") or the password specified during execution of the finisher's per-machine script.

Description from website:
>Samba has provided secure, stable and fast file and print services for all clients using the SMB/CIFS protocol, such as all versions of DOS and Windows, OS/2, Linux and many others. 

##screencopy.sh##
This script builds and installs [ScrCpy (Screen Copy)](https://github.com/Genymobile/scrcpy), which allows the user to display and control an Android device.  It also installs  [ScrCpy GUI](https://github.com/Tomotoes/scrcpy-gui),  a simple & beautiful GUI application for scrcpy.

##ssh.sh##
This script installs [SSH](https://www.ssh.com/ssh) on your machine.  The generated SSH keys are removed and the service is disabled for Live CDs.  A finisher script is added to regenerate the SSH keys upon OS installation.

Description from website:
> A software package that enables secure system administration and file transfers over insecure networks

##steam.sh##
Thsi script installs [Steam for Linux](https://store.steampowered.com/linux) on your machine.  Description from website:
> Browse the newest, top selling and discounted SteamOS + Linux supported games 

##ubiquity_slideshow.sh##
This script downloads the [Ubiquity Installer Slideshow](https://ubuntu-mate.community/t/run-the-ubiquity-installer-slideshow-after-installation/14757)  to **/usr/share/ubiquity-slideshow/slideshow.py**.

##unified_remote.sh##
This script installs [Unified Remote](https://www.unifiedremote.com/) on your machine.  Description from website:
> The one-and-only remote for your computer.  Turn your smartphone into a universal remote control.

##virtualbox-5.2.sh##
This script installs [VirtualBox 5.2](https://www.virtualbox.org/) and the VirtualBox 5.2 Guest Extensions on your machine.

Description from Website:
> VirtualBox is a powerful x86 and AMD64/Intel64 virtualization product for enterprise as well as home use.

##vpn_establish.sh##
This script creates a [Split Tunnel VPN connection](https://forum.htpcguides.com/Thread-Split-Tunnel-Guide-for-Ubuntu-18-04) to [FreeVPN](https://freevpn.org/).  This script does **NOT** work for Ubuntu 16.04!

##vpn_launchers.sh##
This script installs both Google Chrome (using the before mentioned script) and FireFox, and creates launchers that launch the browser desired under the **htpc** user.  

**DEPENDENCY NOTICE:** The **vpn_established.sh** script is run if it hasn't been set up before this script has been run.

##vpn_transmission.sh##
This script installs the [Transmission daemon](https://help.ubuntu.com/community/TransmissionHowTo) and [Transmission Remote GUI (TransGUI)](https://sourceforge.net/projects/transgui/) onto your system and configures the packages to work with the Split Tunnel VPN established by the **vpn_established.sh** script.

**DEPENDENCY NOTICE:** The **vpn_established.sh** script is run if it hasn't been set up before this script has been run.

##whatsapp.sh##
This script installs Google Chrome using the **chrome.sh** script if not installed, then [WhatsApp](https://www.whatsapp.com/) onto your machine.

**DEPENDENCY NOTICE:** The **chrome.sh** script is run if it hasn't been set up before this script has been run.

##x11vnc.sh##
This script installs [X11VNC](http://www.karlrunge.com/x11vnc/) onto your machine.  It adds a finisher script to set the default password to default password ("xubuntu") or the password specified during execution of the finisher's per-machine script.  The script also installs a systemd service file to autolaunch this program at boot.

Description from website:
> x11vnc allows one to view remotely and interact with real X displays (i.e. a display corresponding to a physical monitor, keyboard, and mouse) with any VNC viewer. In this way it plays the role for Unix/X11 that WinVNC plays for Windows. 

##xrdp.sh##
This script installs and configures [XRDP](http://xrdp.org/) onto your machine.  Note that the script does not work on OSes before 18.04!

Description from website:
> xrdp provides a graphical login to remote machines using RDP (Microsoft Remote Desktop Protocol). 

##youtube-dl.sh##
This script installs [youtube-dl](https://ytdl-org.github.io/youtube-dl/index.html) and [youtube-dlg](http://www.webupd8.org/2017/08/youtube-dl-gui-04-ships-with-new-user.html) onto your machine.

Description from website about "youtube-dl":
> youtube-dl is a command-line program to download videos from YouTube.com and a few more sites.

Description from website about "youtube-dlg":
> YouTube-DL GUI is, like its name suggests, a graphical user interface for the powerful command line tool youtube-dl, available for Linux and Windows.