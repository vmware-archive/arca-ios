//Copyright (C) 2013-2014 Pivotal Software, Inc.
//
//All rights reserved. This program and the accompanying materials
//are made available under the terms of the Apache License,
//Version 2.0 (the "License”); you may not use this file except in compliance
//with the License. You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//
//Created by Adrian Kemp on 2013-12-17

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ArcaContextFactory.h"
#import "ArcaObjectFactory.h"

/**-----------------------------------------------------------------------------
 The selectors which would need to be exported by an object wishing to replace the built in ArcaManagedObject
 -----------------------------------------------------------------------------*/
@protocol ArcaManagedObjectInterface
/**-----------------------------------------------------------------------------
 The keypath on the object that you will be using for uniqing purposes
 
 Typically, objects will have an identifier (id, person_id, userName, etc) that will be used to uniquely identify them. This is to be subclassed and return the keyPath for that property.
 @return The keyPath of the primary key (uniqueness) property
 ------------------------------------------------------------------------------*/
+ (NSString *)primaryKeyPath;
/**-----------------------------------------------------------------------------
 The actual primary key value for a given object
 
 Unlike the other selectors, this property returns the actual primary key for the object. It is not used for introspection, but for the actual uniqueness checks
 @return The primary key value
 ------------------------------------------------------------------------------*/
- (id)primaryKey;
/**-----------------------------------------------------------------------------
 The object that is responsible for creating object contexts
 
 @return The instance of the context factory class
 ------------------------------------------------------------------------------*/
+ (id<ArcaContextFactoryCompatibilityInterface>)contextFactory;
/**-----------------------------------------------------------------------------
 The object that is responsible for creating managed objects
 
 @return The instance of the object factory class
 ------------------------------------------------------------------------------*/
+ (id<ArcaObjectFactoryInterface>)objectFactory;

+ (NSEntityDescription *)entity;

@end

/**-----------------------------------------------------------------------------
 A subclass of NSManagedObject that adds several convenience methods and properties for easily populating data from an NSCollection to CoreData objects.
 ------------------------------------------------------------------------------*/
@interface ArcaManagedObject : NSManagedObject <ArcaManagedObjectInterface>

#pragma mark - Factories
/**-----------------------------------------------------------------------------
 Creates and returns an object for the given entity name, in the given context
 
 This selector is used solely to simplify the creation of new empty objects
 @param entityName The name of the entity in your data model (i.e. Person)
 @param context The context you want the object to be created in
 @warning The context will not be saved, the object will be inserted but not saved to the persistent store
 @return A new object of whatever class that entity is assigned to
 ------------------------------------------------------------------------------*/
+ (instancetype)objectForEntityNamed:(NSString *)entityName inContext:(NSManagedObjectContext *)context;

#pragma mark - Object Meta Data


/**-----------------------------------------------------------------------------
 The keypath in source data (i.e. JSON from a server request) which correspond to this object's primary key
 
 This is primarily used internally in the framework, as a given source key path may or may not be recognized by the source. For example, a server might recognize a person's unique identifier as id in some cases and person_id in others.
 @return A keyPath that this framework will recognize as a primary key provided by a source
 ------------------------------------------------------------------------------*/
+ (NSString *)sourcePrimaryKeyPath;
/**-----------------------------------------------------------------------------
 A collection which maps object keypaths to the keypaths that will be provided by the source.
 
 Most servers use property identifiers that are not friendly to CoreData (i.e. person_id). This dictionary provides a mapping to convert between the source data and the object's properties (person_id -> cloudId). Multiple mappings for each property can be given in an array (i.e. @"cloudId" : @[@"person_id",@"id"]). The system will search for a matching key and convert accordingly.
 @return An NSDictionary that represents the key mappings between source and object
 ------------------------------------------------------------------------------*/
+ (NSDictionary *)objectToSourceKeyMap;
    /**-----------------------------------------------------------------------------
 The NSAttributeDescription that corresponds to the property identified by the keyPath from primaryKeyPath
 
 This is used primarily for checking the type of a primary key, but can prove useful for any circumstance where introspection into the key type is needed
 @return An NSAttributeDescription for the primaryKey
 ------------------------------------------------------------------------------*/
+ (NSAttributeDescription *)primaryKeyAttribute;

#pragma mark - Retrievers
/**-----------------------------------------------------------------------------
 Retrieves all of the objects matching the provided parameters using the given context
 
 This is a simple convenience method to prevent the user from having to constantly manually create fetch requests. The only required parameter is managedObjectContext, which cannot be nil.
 @param predicate The NSPredicate that describes what data to retrieve
 @param sortDescriptors The sorting information to use on the retrieved data
 @param faultingData Whether the request should pre-fault the data, set to YES only if you intend to make use of all or most of the data in the request
 @param managedObjectContext The context to use for the fetch
 @param error If an error occurs, it will be populated into this variable
 @return An array containing the retrieved objects
 ------------------------------------------------------------------------------*/
+ (NSArray *)objectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error;
/**-----------------------------------------------------------------------------
 A wrapper for the objectsMatchingPredicate selector that fetches objects matching the primary keys provided
 
 This is used internally, but can be useful in any case where only a primary key is available
 @param primaryKeys An array of primary key values on which to match
 @param faultingData Whether the request should pre-fault the data, set to YES only if you intend to make use of all or most of the data in the request
 @param context The context to use for the fetch
 @param error If an error occurs, it will be populated into this variable
 @return An array containing the retrieved objects
 ------------------------------------------------------------------------------*/
+ (NSArray *)objectsMatchingPrimaryKeys:(NSArray *)primaryKeys faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)context error:(NSError **)error;

/**-----------------------------------------------------------------------------
 Used (internally) to create a fetch request for retrieving objects with the given options
 
 This is used internally, but is provided in the event that it might be needed.
 @param predicate The predicate to provide the fetch request
 @param sortDescriptors The array of sort descriptors to provide to the fetch request.
 @param faultingData Whether the request should pre-fault the data, set to YES only if you intend to make use of all or most of the data in the request
 @param managedObjectContext The context to use for the fetch
 @param error If an error occurs, it will be populated into this variable
 @return An array containing the retrieved objects
 ------------------------------------------------------------------------------*/
+ (NSFetchRequest *)fetchRequestForObjectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error;

#pragma mark - Deleters
/**-----------------------------------------------------------------------------
 A convenience method for deleting all objects of a given class from the persistent store
 @warning use with extreme care, as the context is saved by this selector. Objects will be deleted from the persistent store
 
 @param error Any errors that occur will be populated to this address
 @return A boolean indicating success or failure
 ------------------------------------------------------------------------------*/
+ (BOOL)deleteAllObjects:(NSError **)error;
/**-----------------------------------------------------------------------------
 Used when an object is to be replaced completely by new data (as opposed to incrementally updated)
 
 Clears all data except for the primary key. This is used internally when a server responds with a full JSON object, rather than a delta. Similarly, the user should make use of this when an object needs to be cleared prior to new data being added.
 ------------------------------------------------------------------------------*/
- (void)clearObjectDataForReplacement;

@end
