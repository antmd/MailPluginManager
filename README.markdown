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

### Still to do (mostly notes for me)

* Rethink the status, enabled, inLocalDomain properties.
* Add more tests, for MailBundle to handle company, companyURL, latestVersion, compatibilityWithCurrentMail, and inLocalDomain.
* Load historicalUUIDs file from remote server on launch (MBM & MBT)
* Use synchronized file features in Lion when we can for historicalUUIDs
* Setup system to report system setup when requested by user/developer.
* Update background drawing of MailBundleView
	1 Draw Border in the MailBundleView based on status and compatibility (green, light grey, red)
	2 Set color of latest version text to green (?) if there is an update & enable button
	3 Change color of text for company to blue to indicate link (too many colors?)
* Add a link directly to product for Name & Icon.
* Setup actions to watch changes of files to note when Plugins become active, disabled, domain change

### How to use

_Sorry, this will come soon_

### Crazy Idea

Can a plugin be written to load first and then patch the loading process from that point to ensure that
any plugins about to be disabled can be handled more gracefully? Unlikely, but think about it.

© Copyright 2011 Little Known Software

You can use this software any way that you like, as long as you don't blame me for anything ;-)
