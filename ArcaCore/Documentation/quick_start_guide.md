#Quick Start Guide
##Installing ArcaCore
###The Framework
ArcaCore is available as a static framework, which makes it as easy to include in your project as adding CoreData itself. Simply grab the current release under the [files](https://github.com/omniamp/arca-core-ios/files) section, and add the unzipped .framework file to your project in Xcode.

- Goto https://github.com/omniamp/ArcaCore/files
- Download the release labelled as current
- Unzip the package
- In Xcode, use the add files to project wizard to add the .framework file
- Then, just import the framework where you need it using #import <ArcaCore/ArcaCore.h>

###The Documentation
ArcaCore comes with a complete docset ready for installation to Xcode. There is an install script aptly named install-docs.sh that you can run, or you can install it manually

	cp ArcaCore.framework/Versions/Current/Resources/English.lproj/ArcaCore.docset ~/Library/Developer/Shared/Documentation/DocSets


##Using ArcaCore

###Getting To Know Arca
The quickest way to get familiar with ArcaCore is to install the documenatation, and then [scaffold an app](#scaffold-an-app). The docset will add tooltips to all of the Arca specific stuff, so you can cruise through the sample app that you generate learning as you go.

Since you'll be scaffolding a fully functional app, you can easy tweak the scaffolding options to make changes to the app. It's the best way to really get under the hood, without messing anything up. Any time you want you can get a fresh sandbox in which to play.

###Using An Existing App
You can of course add ArcaCore to an existing app, and it's pretty easy:

- Use [ArcaPersistentStoreCoordinator setDefaultCoordinator:] to give the framework your persistent store coordinator to work with (it will need it for many of it's operations)
	
- Change all of your NSManagedObjects to subclass ArcaManagedObject, and implement +PrimaryKeyPath.

- You'll also need to implement +objectToSourceDataKeyMap for any object that will come in from an external soure (plist, network, etc)
	
Now, there is a big caveat when integrating into an existing project; whatever calls you make directly to CoreData don't get checked by ArcaCore. That means that while ArcaCore will be dealing with primary keys and relationships, it'll only be doing that for calls you make through it's APIs.

##Scaffolding An App
###Levo
We've created a solution for generating lots of boilerplate code from a series of templates, and a data schema. It would be well worth your while to take a deeper look at [levo](https://github.com/cfmobile/levo), but for right now we're going to go through it step by step.


####Grab The Scaffold Package
Go ahead and grab the scaffold package in the [files](https://github.com/cfmobile/arca-ios-templates/files) and unpack it. It has everything you'll need, including a pre-compiled binary of our Code Generator for OS X. If you're in a hurry and just want some pay-off, just run arca-scaffold.sh and you'll get an app.

###Generating The App
You can generate the default app that we've packaged up for you by running

	levo -t github.com/cfmobile/arca-ios-templates -m User:id:int:firstName:string:lastName:string
	
Go ahead and try that, and confirm that the resulting project runs in Xcode. Once you're satisfied, we're going to make some changes

###Modifying The App

Delete that project, and generate a new one with the following command:

	levo -t github.com/cfmobile/arca-ios-templates -m User:id:int:firstName:string:lastName:string:nickName:string:account:Account -m Account:id:int:user:User
	
Now you'll see that your app has changed. There is now an additional model (Account), and additional field on User, and each User has a 1:1 relationship with an Account.