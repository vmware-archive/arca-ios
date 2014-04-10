>#Arca
>Enterprise-grade iOS made simple

Arca is a comprehensive data handling framework for iOS. It's built atop CoreData to take advantage of the native system integrations that provides. It also follows industry best practices, built from the ground up to be extensible and easy to use and debug.

Arca is in daily use, and was built using the lessons learned from Pivotal Labs expertise in the field. That means there is a pool of industry experts already using, and improving it.

##Getting Started
Check out our [Quick Start Guide](Documentation/quick_start_guide.md), and the package [Documentation](Documentation/docset/html/index.html).

After you've gotten a look at what Arca can do for you, you can check out some of our [Sample Apps](https://github.com/cfmobile/arca-ios-samples) for examples on how to make the most of the framework.

In addition, you might find our [Getting to Know our Repositories](wiki/Getting to Know our Repositories) guide handy, as it describes where you can find current, development, and daily releases.

##Components
[ArcaCore](ArcaCore) provides a wrapper around CoreData; adding convenience functions that simplify creating objects, and getting data to and from remote sources (i.e. your API).

[ArcaSync](ArcaSync) provides a system that watches your data changes and requests. It trains your database to request, update, and push new data to and from the remote source.

[ArcaBridge](ArcaBridge) is the glue that connects core and sync. It provides simple interfaces to local and network sources, which makes your database able to talk to multiple sources easily.

##Contributing
If you've fixed a bug, or added a feature, we'd love to take a look. You can check out our [Contributing Guide](Documentation/contributing_guide.md) for full details on how to get your changes rolled into the project.

If you're new to open source, and just looking to cut your teeth, check out the [issues](https://github.com/cfmobile/arca-ios/issues) section. If you're looking for additional guidance, we try to keep an eye on the arca tag on [stackoverflow#arca](https://stackoverflow.com/tags/arca)

##Other Arca iOS Repositories
[Sample Apps](https://github.com/cfmobile/arca-ios-samples) using Arca as their foundation.

[Levo Templates](https://github.com/cfmobile/arca-ios-templates) for generating Arca compatible models and controllers, or entire applications in a snap.

##Related Projects
[Levo](https://github.com/cfmobile/levo) - A scaffolding tool built on the concept of templating boilerplate code. Arca provides a full suite of levo templates for a quick and easy start.

[Arca For Android](https://github.com/cfmobile/arca-android) - The Android version of Arca. Based on the same concepts and also providing a full suite of templates for levo.

##License
Arca is available under the Apache 2.0 License. See the LICENSE file for more information.