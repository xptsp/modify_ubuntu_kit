#Red Dragon Xubuntu HTPC Scripts#
These scripts alter the Xubuntu operating system as described:

##autologin_htpc.sh##
This script changes the LightDM login process to login the "htpc" user automatically without using the password.

##comskip.sh##
This script installs [ComSkip](https://www.comskip.org/) (a commerical detection software) and [Comskipper](https://github.com/Helly1206/comskipper) onto your machine.

Description from Comskipper website:
> This program can skip commercials while still recording. It's a wrapper over the original comskip software. 

##couchpotato.sh##
This script installs [CouchPotato](https://couchpota.to/) onto your machine.

Description from website:
> Awesome PVR for usenet and torrents. Just fill in what you want to see and CouchPotato will add it to your "want to watch"-list. Every day it will search through multiple NZBs & Torrents sites, looking for the best possible match. If available, it will download it using your favorite download software. 

##emby.sh##
This script installs [Emby Server](https://emby.media/index.html) onto your machine.

Description from website:
> Bringing all of your home videos, music, and photos together into one place has never been easier. Your personal Emby Server automatically converts and streams your media on-the-fly to play on any device.

##extra_packages.sh##
This script installs two packages: **libshairport2** (shared library to emulate an AirPort Express) and **librtmp1** (shared library - toolkit for RTMP streams) onto your machine.

##kodi.sh##
This script installs a few things onto your machine

- Installs [Kodi](https://kodi.tv/) , the **kodi-pvr-hts** addon, visualizations and screensavers
- Some default settings for Kodi and a few addons
- Modifies the default skin to focus on TV when booting Kodi
- Adds a finisher task to configure default web login details.

##libcec.sh##
This script installs [libcec](http://libcec.pulse-eight.com/) onto your machine.

Description from website:
> libCEC allows you in combination with the right hardware to control your device with your TV remote control. Utilising your existing HDMI cabling

##lirc.sh##
This script installs [lirc](http://www.lirc.org/) from Ubuntu 16.04 onto your machine.

Description from website:
> LIRC is a package that allows you to decode and send infra-red signals of many (but not all) commonly used remote controls. 

##mycroft.sh##
This script installs [MyCroft](https://mycroft.ai/) onto your machine.

Description from website:
> Control technology with your voice

##nuc_led.sh##
This script installs [the NUC LED kernel module](https://github.com/xptsp/intel_nuc_led) onto your machine.

##openbox.sh##
This script installs [OpenBox](http://openbox.org/wiki/Main_Page), configuring a default background, as well as disabling the screen saver, screen blanking, and display power management signaling.  It also sets up automatic restart of Kodi when it crashes or quits.

##sickchill.sh##
This script installs [SickChill](https://sickchill.github.io/) onto your machine.

Description from the website:
> SickChill is an automatic Video Library Manager for TV Shows.
It watches for new episodes of your favorite shows, and when they are posted it does its magic: automatic torrent/nzb searching, downloading, and processing at the qualities you want.

##soundwire.sh##
This script installs [SoundWire](http://georgielabs.net/) onto your machine and creates a service to launch it automatically.

Description from website:
> Turn your Android device into wireless headphones / wireless speaker. Stream any music or audio from your PC to your Android phone, tablet, or other PCs. SoundWire does audio mirroring (audio cast). You can use any music player on your PC or laptop like Spotify, YouTube, or iTunes and stream low-latency live sound over WiFi directly to your Android device. Also works over 3G/4G cell networks or WAN.

##trim_os.sh##
This script removes packages from the installation that I feel serve no purpose in a HTPC machine, because there is no visible functional desktop to use.

I use this script to reduce the size of the ISO, since it is bigger than the permitted 4.3GB sizes that can be created....

##tvheadend.sh##
This script installs [Tvheadend](https://tvheadend.org/) onto your machine and attempts to configure the default username and pasword upon OS installation.  It also installs a power management script to prevent the OS from sleeping or hibernating while recording.  It also installs a [mobile UI](git://github.com/polini/TvheadendMobileUI)  for Tvheadend

Description from website:
> Tvheadend is a TV streaming server and recorder for Linux, FreeBSD and Android supporting DVB-S, DVB-S2, DVB-C, DVB-T, ATSC, ISDB-T, IPTV, SAT>IP and HDHomeRun as input sources.
