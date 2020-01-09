# Modify Ubuntu Kit

**Modify Ubuntu Kit** is a set of scripts designed to assist in creating a customized version of Ubuntu with desired packages and settings already integrated into the image file.  Services can be disabled and/or enabled for running as a Live CD, but enabled by default once the install has been completed.

## Origin Story: Red Dragon Xubuntu

The Red Dragon Xubuntu installs were born of my need to replace Windows 7 on my desktop machine, since updates will not be forthcoming after January 2020.  For the record, I've tried Windows 8, 8.1 and 10 and (well, quite frankly) I hate them all.  I hate Windows 10 mostly because I have no control over the updating process.  I need things to remain "stable", not change simply because Microsoft decides features that I need and rely on are no longer part of the OS.  Media Center is the best example of this (not that I have cable anymore...), however, if I look longer, I'm sure I can find more examples to give...

I was already using Xubuntu on my HTPC machine, so this is just the next step to full household adoption.  I needed some that felt close to Windows 7, cause I didn't want my wife to feel uncomfortable with the new OS that I was forcing on her.

Because I don't have the bandwidth or storage to host these ISOs, I can't distribute them as downloadable ISOs.  So if you want them, you have to build them.  I am using [XUbuntu 18.04.3](https://xubuntu.org/download) as the base for the install.   When I apply my UI changes, XUbuntu is a close enough match for the Windows environment, so I don't feel like I'm dealing with a totally different OS (which I totally am).  The learning curve for dealing with the underbody of the OS is whole another story....

Using this command, you can install all scripts under the requested package.  Supported packages are **base**, **desktop**, and **htpc**. For example, to create my updated base ISO, you would use:
> edit_chroot build **base**

Please note that you must unpack the ISO you wish to use as the base.  **Desktop** requires the **base** package for completeness, and **HTPC** packages requires both **base** and **desktop**.  (However, you don't **NEED** the **base** package to run the **desktop** package....)  If you don't use XUbuntu as the base for your ISOs, then I can't/won't help you, as these scripts assume that you are modifying a Xubuntu ISO....

Additional information about the **Red Dragon XUbuntu** scripts can be found here:

- [Red Dragon Xubuntu Base edition](base/README.MD)
- [Red Dragon Xubuntu Desktop edition](desktop/README.MD)
- [Red Dragon Xubuntu HTPC edition](htpc/README.MD)

## Onward: The Primary Script
The primary script in this GitHub repository is the **edit_chroot** script, installed by default in the **/usr/local/bin** folder.  

Using the following commands, this script can:

- **unpack** - Unpacks the Ubuntu filesystem from DVD or extracted ISO on hard drive.
- **unpack-iso** - Unpacks the Ubuntu filesystem from ISO on hard drive.
- **pack** - Packs the unpacked filesystem into **filesystem.squashfs**
- **pack-xz** -Packs the unpacked filesystem using XZ compression into **filesystem.squashfs**.
- **iso** - Builds an ISO image in the specified directory, containing the packed filesystem.
- **rebuild** - Combines the **pack** and **iso** parameters.
- **rebuild-xz** - Combines the **pack-xz** and **iso** parameters.
- **build** - Enter the unpacked filesystem environment to install specified series of packages.
- **enter** - Enter the unpacked filesystem environment to make changes.
- **upgrade** - Only upgrades Ubuntu packages with updates available.
- **unmount** - Safely unmounts all unpacked filesystem mount points.
- **remove** - Safely removes the unpacked filesystem from the hard drive.
- **update** - Updates this script with the latest version.
- **rdbuild** - Builds one or all Red Dragon distro builds.
- **rdcopy** - Copies Red Dragon distros to the Red Dragon USB stick.
- **help** - The help message

## Editing the unpacked Filesystem environment

#### Tasks performed before bash prompt inside chroot environment :
- Updates the script from GitHub, then copies the toolkit into the chroot environment
- If requested (enabled by default), mounts the **/tmp** directory as a ramdisk, so temporary files will not be stored in the image.
- Mounts all necessary directories within the chroot environment.
- Sets the **HOME** variable  to **/etc/skel**, so that any changes to default users are copied during each new user creation.
- Sets the **USER** and **SUDO_USER** variable to **root**.
- Sets the **KODI_OPT** variable to **/opt/kodi**, which where GitHub repositories for Kodi addons are expected to be downloaded to.
- Sets the **KODI_BASE** variable to http://mirrors.kodi.tv/addons/leia/, which should (hopefully) correspond to the current Kodi version.

#### While inside the chroot environment
**(CHROOT)** is appended to the base prompt, to make it easier to indentify which program is in the unpacked filesystem.  It'll look like this (your system name will differ):
> (**CHROOT**)root@kodi-VirtualBox:/#

#### Tasks performed after exiting chroot environment:
- Moves user ID **999** to a different user ID below **998** so that the Live portion of the Live CD works properly.
- Moves group ID **999** to a different group ID below **998** so that the Live portion of the Live CD works properly.
- Upgrades any GitHub repositories under the **/opt** directory (if any).
- Upgrades any GitHub repositories under the **/opt/kodi** directory (if any).
- Updates the Ubuntu repository lists.
- Removes old kernels from the chroot environment.
- Removes unnecessary packages from the install to save space and tries to fix any broken packages found.
- Upgrades any Ubuntu package that needs upgrading.
- Removes all cached packages from the install to save space. 
- Disable all services that user has specified that shouldn't be run during a Live CD run.
- Empty the contents of **/tmp** directory. 

#### Notes about aborting the script once entering the chroot####
If you absolutely **MUST** CTRL-C during the script's execution, you must run the following command:
> edit_chroot unmount

This wil safely unmount everything that the script has mounted to the chroot environment.  Without it, you are in danger of screwing up your real system's OS!  

To safely remove the filesystem environment, use this command:
> edit_chroot remove

## Secondary Commands
These commands are available inside the filesystem environment while it is being edited.  Some commands have been altered to make certain assumptions in the program scripts without having to double-check everytime.

#### change_ownership
This command instructs the finisher script to change the ownership of the specified file or directory to user 1000, whatever user that may be.

#### change_password
This command instructs the finisher script to change the password from the default **xubuntu** to the contents of the variable **PASSWORD**  in the finisher script.  By default, the **PASSWORD** variable contains **xubuntu**.  By specifying a second parameter, you can specify what to change the password from. 

#### change_username
This command instructs the finisher script to change the username of the specified file from **kodi** to the name of user 1000.  By default, the username to replace is **kodi**.  By specifying a second parameter, you can specify what to change the username from.

#### kodi_repo
This command downloads the specified addon from the Kodi repository and places it in the specified directory.  This command takes two parameters: the URL to the folder containing the ZIP files, and the destination to unpack it to.

Kodi 18 (Leia) addons are found here: **http://mirrors.kodi.tv/addons/leia/**

#### relocate_dir
This command instructs the finisher script to copy the specified folder to the **/home** directory and add a line to **/etc/fstab** to mount the new location over the old location.  This is particularly useful if you want the contents of a particular directory to survive reinstalls.

#### sleep_allow
This command unmasks the **sleep.target**, **suspend.target**, **hibernate.target**, and **hybrid-sleep.target** files, allowing the OS to enter into a sleep mode.
 
#### sleep_disallow
This command unmasks the **sleep.target**, **suspend.target**, **hibernate.target**, and **hybrid-sleep.target** files, allowing the OS to enter into a sleep mode.  This is particularly useful if you have a VM that does recording (aka: Windows 7 Media Center) that just cannot be put to sleep because doing so it **WILL** cause it to miss scheduled recordings!

### Altered Commands
The following commands have been altered in order to provide compatibility with previous versions of Ubuntu (namely 16.04 and below), or to provide additional functionality not present in the original commands.

#### unzip / zip
These commands have been altered to check for the existance of the **zip/unzip** command, and installs the command if it wasn't found.  Once confirmed installed, the command is executed.

#### 7z
This command has been altered to check for the existance of the **7z** command, and installs the command if it wasn't found.  Once confirmed installed, the command is executed.

#### systemctl / service
These command has been altered to change the **/usr/local/bin/disabled.list** file when services are disabled and enabled.  When services are disabled, it adds the service to the **/usr/local/bin/disabled.list** file.  When services are enabled, it removes the service from said file.  To override this behavior, add **-dry-run** to the command.

#### add-apt-repository
This command has been altered to call **apt update** after executing the original command when it is run on Ubuntu 16.04.x-based systems.  This emulates the Ubuntu 18.04-based version of add-apt-repository command.

## The "settings.conf" File
Upon installation of the toolkit, the **files/settings.conf** file is copied to **/usr/local/finisher/settings.conf**.  This file contains all the settings that this toolkit requires to operate.  The variables:

- **MUK_DIR** - MUK installation directory (default:**/opt/modify_ubuntu_kit**)
- **ISO_VERSION** - Override version number used in ISO filename here (Default: 18.04.3)
 **ISO_DIR** - Where to place the generated ISO file.  (Default: current directory)
- **UNPACK_DIR** - Where to place extracted and chroot environment directories.  (Defaults: same as **ISO_DIR**).
- **FLAG_ADD_DATE** - Flag: Defaults to adding date ISO was generated to end of ISO name.  (Default: 1)
- **FLAG_XZ** - Flag: Use XZ (value: 1) instead of GZIP (value: 0) compression. (Default: 0)
- **FLAG_MKISOFS** - Flag: Use MKIFOFS (value: 1) instead of GENISOIMAGE (Default: 0) 
- **FLAG_TMP_RAM** - Flag: Set to 1 to use RAM for temp folder.  (Default: 0)
- **ISO_PREFIX** - ISO name prefix string.  (Default: **Ubuntu**)
- **ISO_POSTFIX** - ISO postfix string.  (Default: **desktop**)
- **ISO_LABEL** - Label to use for ISO.  (Default: "${ISO_PREFIX} ${ISO_VERSION}")
- **OLD_KERNEL** - Default for removing old kernels from chroot environment.  (Default: 1)

## The Finisher Script
The finisher script runs at the very end of OS installation.  It is responsible for the following actions:

- A custom script is attempted to be downloaded from DropBox per machine's ethernet address and executed.
- Any additional executable scripts found in **/usr/local/finisher/finisher.d** are executed.
- Change usernames in specified files from **kodi** (or specified alternative) to user 1000's name.
- Change passwords in specified files from **xubuntu** (or specified alternative) to the password stored in variable **$PASSWORD**.
- Change the ownership of files and/or directories specified to user 1000.
- If the **/home** directory is contained in a different partition than the **/** (root) directory, it copies the contents of specified directories under the **/home** directory (only if it doesn't already exist), then adds a line to mount the copied directory to the original directory within **/etc/fstab**.
- Enable all services specified to be disabled only during running as a Live CD.

## Extra Credits
- [https://nathanpfry.com/how-to-customize-an-ubuntu-installation-disc/](https://nathanpfry.com/how-to-customize-an-ubuntu-installation-disc/ "How to Customize an Ubuntu Installation Disc - nathanpfry.com")
- [https://help.ubuntu.com/community/LiveCDCustomization](https://help.ubuntu.com/community/LiveCDCustomization "LiveCDCustomization - Community Help Wiki")
