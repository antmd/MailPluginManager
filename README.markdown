## BundleManager - Mail Plugin Manager

BundleManager is a tool to help Mac Mail bundle authors manage, install & keep up to date for their users.

### Main Features

* Installation
* Uninstallation
* Plugin Manager (for users)
* Automatic Updates (without having to add a framework to your plugin)
* Sends crash reports back to developer
* Checks for compatibility of plugins at boot time (i.e. after an install)
* Determine relevant information about the user's system (Mail, Message, etc.)
* Keep updated list of OS versions, including future versions, that are accessible to plugins

* Only supports Snow Leopard & Lion - I'm even thinking of making it Lion only

---

### Still to do (mostly notes for me)

#### Common Pieces

* Determining relevant info about system
* Change companies.strings to a companies.plist that gets updated
* Load historicalUUIDs file from remote server on launch (MBM & MBT)
* Use synchronized file features in Lion when we can for historicalUUIDs
* Setup system to report system setup when requested by user/developer.
* Setup actions to watch changes of files to note when Plugins become active, disabled, domain change

#### Manager Interface

* Nothing currently

#### Tool

* Boot time plugin compatibility checking

	1. Define states that are relevant (i.e. update available, not compatible, etc)
		* Update Available
		* Not compatible with current OS
		* Not compatible with future known OS

	2. Define actions that can be taken
		* Perform the update
		* Disable Plugin (if enabled)
		* Delete Plugin
		* Visit website (if we have one)
		
	3. Create views for single item and multiple items

* Crash Reporting
* Allowing access to Latest OS Support info

#### launchd values of interest (for boot time checks)

* LaunchOnlyOnce = YES (nope)
* RunAtLoad = YES
* SuccessfulExit = NO (won't be rerun if exit 0;)
* WatchPaths = Array
* StartCalendarInterval = dict (run once a week perhaps in order to update plists)
* StandardOutPath = path
* [man page][launchd]

#### Other

* Add support for .mbinstall install through sparkle updater.

---

### How to use

_Sorry, this will come soon_

---

### Crazy Idea

Can a plugin be written to load first and then patch the loading process from that point to ensure that
any plugins about to be disabled can be handled more gracefully? Unlikely, but think about it.

---

© Copyright 2011 Little Known Software

You can use this software any way that you like, as long as you don't blame me for anything ;-)

[launchd]: http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html#//apple_ref/doc/man/5/launchd.plist
