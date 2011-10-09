## BundleManager - Mail Plugin Manager

BundleManager is a tool to help Mac Mail bundle authors manage, install & keep up to date for their users.

### Why use this?

1. This tool allows you to easily integrate Sparkle, which isn't difficult in and of itself, 
but for plugins it can be a problem, when other plugins also include Sparkle. This way you 
don't have to maintain an additional application to avoid those problems.
2. It also, gives you some tools to preemptively deal with Mail upgrades and UUID issues.
3. It provides debugging tools for your user, i.e. system info collection and crash reports.
4. It gives the user an easy way to manage the plugin.
5. It provides a simplified installer and uninstaller, again without you having to maintain
another separate application.

### Main Features

* Installation
* Uninstallation
* Plugin Manager (for users)
* Automatic Updates (without having to add a framework to your plugin)
* Sends crash reports back to developer
* Checks for compatibility of plugins at boot time (i.e. after an install)
* Determine relevant information about the user's system (Mail, Message, etc.)
* Keep updated list of OS versions, including future versions, that are accessible to plugins

The features provided are separated into 2 separate applications, a user facing app and a 
faceless app. In truth the faceless app (Mail Bundle Tool, as I am currently calling it), 
is not truly faceless as it does interact with the user, but it will be a NSUIElement = 1
application. The feature split between the two apps should be obvious, but keep reading for 
more details.

The tool application will be embedded inside of the manager application. When plugins call it
they should use a standard NSTask call to it and pass one of the parameters [defined below](#commands).
A .h file will be available with **macros** defined for the calls to the tool. These will be 
defined as macros in order to avoid namespace conflicts between plugins using this code. [A 
List](#macros) is provided in these docs so you can see what you can do.

This manager only supports Snow Leopard & Lion - I'm even thinking of making it Lion only!


### Mail Bundle Manager (MBM)<a id="manager"/>

It has the following main features:

1. Installation
2. Uninstallation (by user double-click)
3. Plugin Manager
4. Send relevant system info to developer (by user action)

#### Installation

A file package format has been defined (with an extension of `mbinstall`) that can be used to create
a Mail Plugin specific installer that BundleManager handles for you, very similar to Installer, but it is 
aware of the specific constraints of Mail Bundles and will install the BundleManager as well, if desired.

A single plist file defines what will be installed, you can have other components besides just the plugin,
and where they should go. You can define Release Notes sections (using either an rtf file or html) and 
a license agreement as well. The user is presented with a view of what will be installed, so that we are 
not hiding anything from them. Eventually it will prompt for required authorization, though at the moment
that is missing.

Here are images of a dummy installation:

![Installation Release Notes](images/Example_Install_1.png)

![Installation License Info](images/Example_Install_2.png)

![Installation License Agreement Dialog](images/Example_Install_License.png)

![Installation Review](images/Example_Install_3.png)

#### Uninstallation

Similarly a file package format has been defined (with an extension of, you guessed it, `mbuninstall`)
for an uninstall, so the user can double-click something to start an uninstall. It has an almost identical
feature set to the uninstall and uses the same format for the manifest file ([see below](#manifest)). 
There is the ability to trigger an uninstall directly from your plugin as well if you want to have a button
in your prefs to uninstall ([see tool](#tool)).


#### Mail Plugin Manager Window

This interface is for the user to interact with and is the default mode when the Mail Bundle Manager is
opened without a file. Here is an example of what it looks like:

![Mail Bundle Manager Window](images/Mail_Bundle_Manager.png)

I have tried to add as much information about the plugin as I can get from the plugin itself. There are 
ways to add more detailed information to the Info.plist file so that MBM can provide a better experience,
but it's good to try to show something.

The user can enable/disable, remove, update and change the domain of the plugin from this window. They 
can also click on the name to go to a product site and the company name to go to the company site.

#### Send System Info to developer

This feature has not yet been implemented, but will just be a button for the user to click to 
send to a particular plugin developer (guessing that developers email needs to be worked out!). 
The information will include the plugin details, the system version, computer information and 
versions and UUIDs of both the Message framework and Mail.


### Mail Bundle Tool (MBT)<a id="tool"/>

All interacts with MBT will be by command line, with perhaps a scripting interface for requests of
information rather than actions.

It has the following main features:

1. Uninstallation (by plugin demand)
2. Automatic update checking (by plugin demand)
3. Send crash reports to developer (by plugin demand)
4. Check all plugins for compatibility/updates at boot time
5. Get relevant System information (by plugin request)
6. Get list of *past & future* compatibility information (by plugin request)

#### Uninstallation

A plugin will be able to request the uninstallation of itself. when this happens MBT will
present a standard type of uninstall "Are you sure?" dialog and then proceed to uninstall 
and restart Mail.

#### Automatic update checking

This comes as a command line request from the plugin, with the path to the plugin to update.
It will check (using Sparkle currently) to see if there is an update available and will let 
Sparkle progress through a normal update process if it is found.

#### Send crash reports to developer

**Not yet implemented.**

Look for any crash reports for the plugin (whose path will have been passed in) and if found
send these back to the developer, targeting some type of web service.

#### Check all plugins for compatibility/updates at boot

At boot time (though a Launch Agent) check for any incompatibilities or updates for existing 
plugins, either enabled or disabled.

This feature will be initiated by a Launch Agent setup for the user (which shouldn't need
any special authorization) and will be launched each time the user logs in to a full session 
(excludes terminal sessions).

This mode will look at all plugins in both "Bundles" and "Bundles (Disabled[ X])" to find the 
latest ones and look to see if that have incompatibilities or updates and notify the user.

A dialog/window will be presented to the user to potentially do something. For a single item
a window similar to the following will appear:

![Single Incompatible/Updatable Plugin Found](images/Single_Plugin_Notice.png)

When there are more than one plugins that need the user's attention a different presentation
is shown, similar to the Manager's look, like this:

![Multiple Incompatible/Updatable Plugins Found](images/Multi_Plugin_Notice.png)

Through both of these the user can perform and Update, Disable a plugin, Remove it or ignore
the message altogether.

I am thinking of also running it whenever the Bundles folder list changes as well, but not 
sure that we be a proper time, so I need to think about that one some more.

#### Get relevant system information

**Not yet implemented.**

This should allow the caller to get back a dictionary of information about the system, such as 
OS Version, Mail Version & UUID, Message.framework version & UUID.

This will probably need some type of Applescript interface, so this has a lesser priority.

#### Get list of *past & future* compatibility information

**Not yet implemented.**

The tool will keep an updated version of a list of UUIDs that Mail and Message.framework have 
defined and supported for plugins to access, so they can actually test in *advance* if they will 
be compatible with an upcoming OS release. Or even just an OS release after the one the user
has.

This will probably need some type of Applescript interface, so this has a lesser priority.

#### Command Line Syntax<a id="commands"/>

In general, the syntax is very simple:

		/path/to/MailBundleTool -command [path/to/plugin]

With these as the full options:

		-uninstall path/to/plugin

Uninstalls the plugin at the indicated path (required).
	
		-update path/to/plugin

Checks for and, if found, updates the plugin at the indicated path (required).
	
		-send-crash-reports path/to/plugin

Sends any crash reports found for the plugin at the indicated path (required).
	
		-update-and-crash-reports path/to/plugin

Sends any crash reports found and updates, if found, for the plugin at the indicated path (required).
	
		-validate-all

This command is used at boot time to validate all plugins. *Generally only called by the Launch Agent*.
	

### Manifest File Format<a id="manifest"/>

The manifest file, which should be named `mbm-manifest.plist` is a plist file that contains
a description of the items to install or uninstall. It also is used to describe to the user
what is being installed.

There are several keys at the top level of the plist that are used to configure the installer
window and define information about what we are doing.

		manifest-type			[install/uninstall]					(String)
		display-name			Plugin Name							(String)
		background-image-path	path/to/image_to_show_in_installer	(String)
		action-items			(see below)							(Array)
		confirmation-steps		(see below)							(Array)
		
Install specific (ignored during uninstall). These define the min and max versions of OS and
min version of Mail supported. Pretty self-explanatory.
		
		min-os-major-version	10.X								(Number)
		max-os-major-version	10.X								(Number)
		min-mail-version		X.X									(Number)

Uninstall specific (ignored during install). These are used to determine how the Mail Plugin 
Manager application can be deleted if different cases. Assuming that the Manager is included
in an uninstall manifest.
		
		can-delete-bundle-manager-if-no-other-plugins-use			(Boolean)
		can-delete-bundle-manager-if-no-plugins-left				(Boolean)
		
#### Action Items<a id="action-items"/>

#### Confirmation Steps<a id="confirm-steps"/>

### Macros Defined<a id="macros"/>

**Not yet written.**

---

### Still to do (mostly notes for me)

#### Common Pieces

* Make it use ARC!!!
* Setup actions to watch changes of files to note when Plugins become active, disabled, domain change
* Change companies.strings to a companies.plist that gets updated
* Load historicalUUIDs file from remote server on launch (MBM & MBT)
* Use synchronized file features in Lion when we can for historicalUUIDs
* Setup system to report system setup when requested by user/developer.
* Determining relevant info about system
* Add authorizations where needed when accessing files the user needs admin for.

#### Manager Interface

* Add an Update All Plugins button to Manager window when relevant.

#### Tool

* Add an Update All Plugins button to Multi Plugin window when relevant.
* Crash Reporting
* Allowing access to Latest OS Support info
* During the boot validation process, we need to be able to skip items the user has previously
	seen and dismissed.

#### launchd values of interest (for boot time agent setup)

* RunAtLoad = YES
* SuccessfulExit = NO (won't be rerun if exit 0;)
* WatchPaths = Array
* StartCalendarInterval = dict (run once a week perhaps in order to update plists)
* StandardOutPath = path
* [man page][launchd]
* LaunchOnlyOnce = YES (nope)

#### Other

* Add support for .mbinstall install through sparkle updater?

---

### Crazy Idea

Can a plugin be written to load first and then patch the loading process from that point to ensure that
any plugins about to be disabled can be handled more gracefully? Unlikely, but think about it.

---

© Copyright 2011 Little Known Software

You can use this software any way that you like, as long as you don't blame me for anything ;-)

[launchd]: http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html#//apple_ref/doc/man/5/launchd.plist
