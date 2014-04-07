>#ArcaCore
>Bridging the gap between data, and CoreData

ArcaCore is the foundational component of the larger [Arca framework](https://github.com/cfmobile/arca-ios). It sits on top of the apple-provided CoreData framework and makes using NSManagedObjects a breeze.

You tell CoreData a lot about your objects, ArcaCore uses that information to intelligently convert between simple structures like NSDictionaries. This helps you take data retrieved from a server and put it directly into your local CoreData store without writing a lot of code for each object.

Setup is another area where most applications use very few of the options provided by CoreData. While we don't believe in reducing functionality, we do believe in providing sensible defaults. Many, if not most, apps will be able to use ArcaCore out of the box to perform all of their configuration and setup of CoreData -- that saves you a lot of boilerplate code.

##Key Features
- Automatic conversions between your NSManagedObjects and NSDictionaries
- Sensible configuration defaults to reduce the code required to use CoreData
- Primary keys mean no more duplicate objects
- Convenience selectors for contexts, objects, and key translation

Check out the [Changelist](Documentation/changelist.md) for recent feature developments.

##Architecture
ArcaCore is built the right way; it allows easy customization for common cases and guidance for when you need to really work with the nuts and bolts.

- **We don't use categories** which means that you won't have debugging-resistent conflicts in your app.
- **We do use protocols** wherever they make sense, which lets you replace things where needed without guesswork.
- **We don't use blocks** but we do let you use them. You won't be waylayed by seven layers of blocks when debugging your app.

Check out our [Architecture](wiki/Architecture) page for more information.

##Getting Started
Check out our [Quick Start Guide](Documentation/quick_start_guide.md), and the package [Documentation](Documentation/docset/html/index.html).

In addition, you might find our [Getting to Know our Repositories](wiki/Getting to Know our Repositories) guide handy, as it describes where you can find current, development, and daily releases.

##Contributing
If you've fixed a bug, or added a feature, we'd love to take a look. You can check out our [Contributing Guide](Documentation/contributing_guide.md) for full details on how to get your changes rolled into the project.

##Related Projects
[Levo](https://github.com/cfmobile/levo) - A scaffolding tool built on the concept of templating boilerplate code. Arca provides a full suite of levo templates for a quick and easy start.

[Arca For Android](https://github.com/cfmobile/arca-android) - The Android version of Arca. Based on the same concepts and also providing a full suite of templates for levo.
