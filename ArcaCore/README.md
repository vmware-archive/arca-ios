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