## BundleManager - Mail Plugin Manager

BundleManager is a tool to help Mac Mail bundle authors manage, install & keep up to date for their users.

### Why use this?

1. This tool allows you to easily integrate Sparkle, which isn't difficult in and of itself, but for plugins it can be a problem, when other plugins also include Sparkle. This way you don't have to maintain an additional application to avoid those problems.
2. It also, gives you some tools to preemptively deal with Mail upgrades and UUID issues.
3. It provides debugging tools for your user, i.e. system info collection and crash reports.
4. It gives the user an easy way to manage the plugin.
5. It provides a simplified installer and uninstaller, again without you having to maintain another separate application.

### Main Features

* Installation
* Uninstallation
* Plugin Manager (for users)
* Automatic Updates (without having to add a framework to your plugin)
* Sends crash reports back to developer
* Checks for compatibility of plugins at boot time (i.e. after an install)
* Determine relevant information about the user's system (Mail, Message, etc.)
* Keep updated list of OS versions, including future versions, that are accessible to plugins

The features provided are separated into 2 separate applications, a user facing app and a faceless app. In truth the faceless app (Mail Bundle Tool, as I am currently calling it), is not truly faceless as it does interact with the user, but it will be a NSUIElement = 1 application. The feature split between the two apps should be obvious, but keep reading for more details.

The tool application will be embedded inside of the manager application. When plugins call it they should use a standard NSTask call to it and pass one of the parameters [defined below](#commands). A .h file will be available with **macros** defined for the calls to the tool. These will be defined as macros in order to avoid namespace conflicts between plugins using this code. [A List](#macros) is provided in these docs so you can see what you can do.

This manager only supports Snow Leopard & Lion.


<a name="manager"/>
### Mail Bundle Manager (MBM)

It has the following main features:

1. Installation
2. Uninstallation (by user double-click)
3. Plugin Manager

#### Installation

A file package format has been defined (with an extension of `mbinstall`) that can be used to create a Mail Plugin specific installer that BundleManager handles for you, very similar to Installer, but it is aware of the specific constraints of Mail Bundles and will install the BundleManager as well, if desired.

A single plist file defines what will be installed, you can have other components besides just the plugin, and where they should go. You can define Release Notes sections (using either an rtf file or html) and a license agreement as well. The user is presented with a view of what will be installed, so that we are not hiding anything from them. Eventually it will prompt for required authorization, though at the moment that is missing.

Here are images of a dummy installation:

![Installation Release Notes][install-1]

![Installation License Info][install-2]

![Installation License Agreement Dialog][install-3]

![Installation Review][install-4]

#### Uninstallation

Similarly a file package format has been defined (with an extension of `mbremove`) for an uninstall, so the user can double-click something to start an uninstall. It has an almost identical feature set to the uninstall and uses the same format for the manifest file ([see below](#manifest)). There is the ability to trigger an uninstall directly from your plugin as well if you want to have a button in your prefs to uninstall ([see tool](#tool)).


#### Mail Plugin Manager Window

This interface is for the user to interact with and is the default mode when the Mail Bundle Manager is opened without a file. Here is an example of what it looks like:

![Mail Bundle Manager Window][manager-window]

I have tried to add as much information about the plugin as I can get from the plugin itself. There are ways to add more detailed information to the Info.plist file so that MBM can provide a better experience, but it's good to try to show something.

The user can enable/disable, remove, update and change the domain of the plugin from this window. They can also click on the name to go to a product site and the company name to go to the company site.


<a name="tool"/>
### Mail Bundle Tool (MBT)

All interacts with MBT will be by command line, with perhaps a scripting interface for requests of information rather than actions.

It has the following main features:

1. Uninstallation (by plugin demand)
2. Automatic update checking (by plugin demand)
3. Send crash reports to developer (by plugin demand)
4. Check all plugins for compatibility/updates at boot time
5. Get relevant System information (by plugin request)
6. Get list of *past & future* compatibility information (by plugin request)

#### Uninstallation

A plugin will be able to request the uninstallation of itself. when this happens MBT will present a standard type of uninstall "Are you sure?" dialog and then proceed to uninstall and restart Mail.

#### Automatic update checking

This comes as a command line request from the plugin, with the path to the plugin to update. It will check (using Sparkle currently) to see if there is an update available and will let Sparkle progress through a normal update process if it is found.

#### Send crash reports to developer

**Not yet implemented.**

Look for any crash reports for the plugin (whose path will have been passed in) and if found send these back to the developer, targeting some type of web service.

#### Check all plugins for compatibility/updates at boot

At boot time (though a Launch Agent) check for any incompatibilities or updates for existing plugins, either enabled or disabled.

This feature will be initiated by a Launch Agent setup for the user (which shouldn't need any special authorization) and will be launched each time the user logs in to a full session (excludes terminal sessions).

This mode will look at all plugins in both "Bundles" and "Bundles (Disabled[ X])" to find the latest ones and look to see if that have incompatibilities or updates and notify the user.

A dialog/window will be presented to the user to potentially do something. For a single item a window similar to the following will appear:

![Single Incompatible/Updatable Plugin Found][single-notice]

When there are more than one plugins that need the user's attention a different presentation is shown, similar to the Manager's look, like this:

![Multiple Incompatible/Updatable Plugins Found][multi-notice]

Through both of these the user can perform and Update, Disable a plugin, Remove it or ignore the message altogether.

I am thinking of also running it whenever the Bundles folder list changes as well, but not sure that we be a proper time, so I need to think about that one some more.

<a name="sys-info"/>
#### Get relevant system information

**Not yet implemented.**

This should allow the caller to get back a dictionary of information about the system, such as OS Version, Mail Version & UUID, Message.framework version & UUID.

<a name="uuid-list"/>
#### Get list of *past & future* compatibility information

**Not yet implemented.**

The tool will keep an updated version of a list of UUIDs that Mail and Message.framework have defined and supported for plugins to access, so they can actually test in *advance* if they will be compatible with an upcoming OS release. Or even just an OS release after the one the user has.

<a name="commands"/>
#### Command Line Syntax

In general, the syntax is very simple:

		/path/to/MailBundleTool -command [path/to/plugin] [-freq 999]

With these as the full options:

		-uninstall path/to/plugin

Uninstalls the plugin at the indicated path (required).
	
		-update path/to/plugin [-freq 999]

Checks for and, if found, updates the plugin at the indicated path (required). If the optional `-freq` flag is passed MBT will schedule a recurring check for updates without any further need for the plugin to manage it. When used the number represents hours. See the [note below](#freq-note)<span style="color:red"/>&nbsp;\*</span>.
	
		-send-crash-reports path/to/plugin [-freq 999]

Sends any crash reports found for the plugin at the indicated path (required). If the optional `-freq` flag is passed MBT will schedule a recurring check for sending crash reports without any further need for the plugin to manage it. When used the number represents hours. See the [note below](#freq-note)<span style="color:red"/>&nbsp;\*</span>.
	
		-update-and-crash-reports path/to/plugin [-freq 999]

Sends any crash reports found for the plugin at the indicated path (required). If the optional `-freq` flag is passed MBT will schedule a recurring check for updates & sending crash reports without any further need for the plugin to manage it. When used the number represents hours. See the [note below](#freq-note)<span style="color:red"/>&nbsp;\*</span>.
	
		-system-info path/to/plugin

Will collect a bunch of information from the system and return the results to you (through a notification block) as a `NSDictionary`. See [system information](#sys-info) above. The path is required to be able to post the notification to the correct plugin.
	
		-uuid-list path/to/plugin

Will return a list of the past and future UUIDs that Mail and Message.framework support (through a notification block) as a `NSDictionary`. See [compatibility information](#uuid-list) above. The path is required to be able to post the notification to the correct plugin.
	
		-validate-all

This command is used at boot time to validate all plugins. *Generally only called by the Launch Agent*.

<a name="freq-note"/>
<span style="color:red"/>&nbsp;\*&nbsp;</span>The __frequency flag__ `-freq` is independent between the three commands that use it. What this means is that you can schedule the updates differently than the crash reports and even have a separate schedule for doing both.


<a name="manifest"/>
### Manifest File Format

The manifest file, which should be named **`mbm-manifest.plist`** is a plist file that contains a description of the items to install or uninstall. It also is used to describe to the user what is being installed.

There are several keys at the top level of the plist that are used to configure the installer window and define information about what we are doing.

		manifest-type			[install/uninstall]						(String)
		display-name			Plugin Name								(String)
		background-image-path	path/to/image_to_show_in_installer		(String)
		action-items			(see below)								(Array)
		confirmation-steps		(see below)								(Array)
		
Install specific (ignored during uninstall). These define the min and max versions of OS and min version of Mail supported. Pretty self-explanatory.
		
		min-os-major-version	10.X									(Number)
		max-os-major-version	10.X									(Number)
		min-mail-version		X.X										(Number)

Uninstall specific (ignored during install). These are used to determine how the Mail Plugin Manager application can be deleted if different cases. Assuming that the Manager is included in an uninstall manifest.
		
		can-delete-bundle-manager-if-no-other-plugins-use				(Boolean)
		can-delete-bundle-manager-if-no-plugins-left					(Boolean)
		
<a name="action-items"/>
#### Action Items

This is an array of dictionary objects that describe what is to be installed or uninstalled. The objects will not be installed in any particular order. Here are the keys and example values with a description of them afterward.

		path					Delivery/MyPlugin.mailbundle			(String)
		destination-path		<LibraryDomain>/Mail/Bundles/			(String)
		name					My Bundle								(String)
		description				A Bundle for Testing					(String)
		is-bundle-manager												(Boolean)
		user-can-choose-domain											(Boolean)

The key `path` is the path where to find the original object to act upon.

* In the case of an **install**, this value should be a path *relative* to the package file or an absolute URL. For instance, in the example above there would be a folder called `Delivery` inside the `.mbinstall` package that would contain the mail bundle. If it is a full URL it will try to install directly from the web, but please remember that no access will mean a failure. *Currently not yet implemented*.
* For an **uninstall**, this value should be a path to where the item should be installed. This should be a full path or a path using a tilda (~).

The key `destination-path` is the path to where the item should be copied during an install. **It is ignored during an uninstall**. This is a full path, a path using a tilda (~), or a path beginning with the special marker `<LibraryDomain>`. The value `<LibraryDomain>` will be expanded to the Library folder in the domain the users selects to install to. Tildas will also be expanded.

The key `name` is the value used in display during the install/uninstall.
*This key is optional, but strongly recommended*

The key `description` is the value used in display during the install/uninstall during the Review step.
*This key is optional*

The key `is-bundle-manager` indicates that the item described is the Mail Bundle Manager application. This is a boolean flag that is used to facilitate the proper installation/removal of this item. Special handling is done to ensure the most recent version is available/installed and that it is not removed if another plugin is using it. 
*This key is optional*

The key `user-can-choose-domain` let's the user select the domain they want to install to. The default values is `NO` and the User Domain will be used. This is ignored during uninstall.
*This key is optional*
*Currently not implemented*.

<!--
	permissions-needed	none									(Array of Strings)
The key `permissions-needed` is an array of strings indicating the types of permissions that might be needed to install this file. The values should be one of `none`, `admin` or `other`.
*This key is optional*
-->

<a name="confirm-steps"/>
#### Confirmation Steps

This is an array of dictionary objects with values describing each of the steps to display to the user, in the desired order, during the confirmation of the install/uninstall process. 

Here are the keys and example values with a description of them afterward.

		type						[license|information|confirm]		(String)
		title						(Name shown at top of page)			(String)
		bullet-title				(Name of step in list at left)		(String)
		path						/path/to/resource					(String)
		license-agreement-required										(Boolean)

The key `type` defines one of three types of display steps, `license` and `information` are essentially the same and just display some content to the user, however the `license` type step will test to see if the user must [agree to a license](#license-agree) and, if so, present a proper alert to ensure that they agree. The `confirm` step shows the list of what will happen and show the Install/Remove button before doing the actions.

The key `title` is used at the top of the information display and is used as the default bullet title, if one of those is not present.
*This key is required*.

The key `bullet-title` is used in the step list on the left side of the window. If no value is provided the `title` value is used.
*This key is optional, but recommended*.

The key `path` is the path where to find the resource to display for either an `information` or `license` type. The path should be relative to the manifest file and should be either an RTF/RTFD file or an HTML file (with resources relative to that file. *It is required for the `license` and `information` types*.

<a name="license-agree"/>
The key `license-agreement-required` works in conjunction with the `license` type and is ignored in other cases. If set to **YES**, then the license will require the user to agree before continuing. The default is **NO**.
*This key is optional*.

<a name="localization"/>
#### Localizing Install/Uninstall packages

These packages can be localized in the same way that applications or bundles can. If you put an .lproj folder for a language in the package, any text values that are pulled out of your manifest file will attempt to be localized from those localization folders.

Unfortunately this doesn't include the base of the project itself and thus all the parts around this that are not localized will come through in English. Hopefully we can get some localization done for the rest of the app.

---

<a name="macros"/>
### Macros Defined

#### Fire and Forget Macros

These macros are the ones that you might call when the app launches to do the update in the background. They do not require your plugin to take any other action. The names are pretty self-explanatory, I think.

		MBMUninstallForBundle(mbmMailBundle)		
		MBMCheckForUpdatesForBundle(mbmMailBundle)
		MBMSendCrashReportsForBundle(mbmMailBundle)
		MBMUpdateAndSendReportsForBundle(mbmMailBundle)
		
You need to pass in the bundle for your plugin, so it can properly determine the bundle identifier and it's path.

#### Notification Block Macros

These macros allow you to get information back from MBT by having a block run which is passed a dictionary of the results.

		MBMMailInformationForBundleWithBlock(mbmMailBundle, mbmNotificationBlock)
		MBMUUIDListForBundleWithBlock(mbmMailBundle, mbmNotificationBlock)

The first argument is the bundle of your plugin, as with the macros above. The second argument is the block that you want to run when the results are returned. It is defined as a `MBMResultNotificationBlock` and has been `typedef`'d like this:

		typedef void(^MBMResultNotificationBlock)(NSDictionary *);

It takes the single argument of the dictionary of results and has a void result.

The keys for the results in the dictionary are listed below.

		MBM_UUID_COMPLETE_LIST_KEY				NSArray of all uuid dictionaries

*Not yet completed*.

---

### Still to do (mostly notes for me)

#### Common Pieces

* Ensure that run paths through the app all quit when appropriate.
* Add authorizations where needed when accessing files the user needs admin for.
* Change the MailBundle class to cache the list of mail plugins so that there is no need to rehit for update info.
* Setup actions to watch changes of files to note when Plugins become active, disabled, domain change.
* Add complete error handling.
* Update remote file URLs (can we use github link?)
* Add real version information to the uuids file for system, mail and message.
* *Would be nice*
* Parse company Name from the Get Info string of info.plist

#### Manager Interface

* Add support for different domain installation.
* Support the `<LibraryDomain>` path prefix.
* Add an Update All Plugins button to Manager window when relevant.
* Handle install path with a full URL.

#### Tool

* During the boot validation process, we need to be able to skip items the user has previously seen and dismissed.
* Build out Launch Agent scheduling for boot-time validation and plugin scheduling.
* Crash Reporting.
* What happens when a command is sent and the app is already running?
* Add an Update All Plugins button to Multi Plugin window when relevant.

#### launchd values of interest (for boot time agent setup)

* RunAtLoad = YES
* SuccessfulExit = NO (won't be rerun if exit 0;)
* WatchPaths = Array
* StartCalendarInterval = dict (run once a week perhaps in order to update plists)
* StandardOutPath = path
* [man page][launchd]
* LaunchOnlyOnce = YES (nope)

#### Data to be stored about each bundle

* Last run date of update, crash report & both.
* Crash Report(s) unsuccessfully sent (file paths to a folder I manage)

#### Other

* Add support for .mbinstall install through sparkle updater?
* What about debs that want to use this but have there own installer?

---

### Crazy Idea

Can a plugin be written to load first in Mail and then patch the loading process for other mailbundles from that point to ensure that any plugins about to be disabled can be handled more gracefully? Unlikely, but think about it.

---

© Copyright 2011 Little Known Software

You can use this software any way that you like, as long as you don't blame me for anything ;-)

<!-- links -->
[launchd]: http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html#//apple_ref/doc/man/5/launchd.plist

<!-- images -->
[install-1]: http://media.lksw.eu/mbm/Example_Install_1.png
[install-2]: http://media.lksw.eu/mbm/Example_Install_2.png
[install-3]: http://media.lksw.eu/mbm/Example_Install_3.png
[install-4]: http://media.lksw.eu/mbm/Example_Install_4.png
[manager-window]: http://media.lksw.eu/mbm/Mail_Bundle_Manager.png
[single-notice]: http://media.lksw.eu/mbm/Single_Plugin_Notice.png
[multi-notice]: http://media.lksw.eu/mbm/Multi_Plugin_Notice.png
