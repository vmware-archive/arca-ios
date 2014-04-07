ArcaCore was created as a part of the Cloud Foundry Mobile Services iOS Client SDK (that's why we just call it Arca). As a whole Arca provides a complete data management framework, that allows apps to very easily leverage the CoreData framework. ArcaCore is the part that builds on top of CoreData to enable stuff like proper duplication checks.

The ArcaCore component is broken up into four classes:

[ArcaPersistentStoreCoordinator](Classes/ArcaPersistentStoreCoordinator.md) - Subclasses the NSPersistentStoreCoordinator and adds some basic functionality. Key feature additions are the automatic discovery and setup of your xcdatamodel, and singleton-style access to the default coordinator.

[ArcaContextFactory](Classes/ArcaContextFactory.md) - Provides a singleton-style access point to an object that will create NSManagedObjectContexts for you, or retrieve the main context, or spawn a child context from one that you give it.

[ArcaObjectFactory](Classes/ArcaObjectFactory.md) - Provides a singleton-style access point for creating an empty object, or creating a collection of objects based on an NSDictionary, or an NSArray of NSDictionaries. The object factory will even intelligently cascade into relationships, creating every object in a tree automatically.

[ArcaManagedObject](Classes/ArcaManagedObject.md) - A subclass of NSManagedObject that adds key translation, primary keys (for de-duplication), and convenience functions for translating between an NSDictionary the NSManagedObject in either direction.