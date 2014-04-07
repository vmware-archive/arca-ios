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
//Created by Adrian Kemp on 2014-01-29

#import <Foundation/Foundation.h>
@class ArcaManagedObject;

/**-----------------------------------------------------------------------------
 The selectors which would need to be exported by an object wishing to replace the built in ArcaObjectFactory
 -----------------------------------------------------------------------------*/
@protocol ArcaObjectFactoryInterface <NSObject>

/**-----------------------------------------------------------------------------
 Creates or overwrites the objects represented in the source data.
 
 This operates recursively on the source data. If there is a person object with an account that is represented (fully) in the data, an account object will also be created/overwritten and a relationship to the person will be added. It can continue for as many recursion levels as there are represented in your object.
 @param sourceData The array or dictionary that contains the source (i.e. parsed JSON data from a server)
 @param objectClass The class of the objects at the top level of the collection (person, in the example from discussion)
 @param context The NSManagedObjectContext that will be used to create/retrieve the objects
 @param error Any errors that occur will be populated to this address
 
 @return The array of objects that were created or retrieved
 ------------------------------------------------------------------------------*/
+ (NSArray *)objectsFromSourceData:(id)sourceData forObjectClass:(Class)objectClass inContext:(NSManagedObjectContext *)context error:(NSError **)error;

@end

/**-----------------------------------------------------------------------------
 Provides an omnipresent factory which simplifies the creation of core data objects
 ------------------------------------------------------------------------------*/
@interface ArcaObjectFactory : NSObject <ArcaObjectFactoryInterface>

/**-----------------------------------------------------------------------------
 Creates or overwrites the object represented in the source data.
 
 This operates recursively on the source data. If there is a person object with an account that is represented (fully) in the data, an account object will also be created/overwritten and a relationship to the person will be added. It can continue for as many recursion levels as there are represented in your object.
 @param sourceData The dictionary that contains the source (i.e. parsed JSON data from a server)
 @param objectClass The class of the object at the top level of the collection (person, in the example from discussion)
 @param context The NSManagedObjectContext that will be used to create/retrieve the object
 @param error Any errors that occur will be populated to this address
 
 @return The array of object that were created or retrieved
 ------------------------------------------------------------------------------*/
+ (ArcaManagedObject *)objectOfClass:(Class)objectClass fromSourceData:(NSDictionary *)sourceData inContext:(NSManagedObjectContext *)context error:(NSError **)error;
/**-----------------------------------------------------------------------------
 Updates an object with source data
 
 This will operate recursively on objects in the source data (i.e. a person with a nested account object, will update both the person and the account, and the relationship). It will only update fields that are present, leaving other data on the object unchanged
 @param managedObject The object to be updated
  @param sourceData The dictionary containing the object source data
  @param error Any errors that occur will be populated to this address
 @return A boolean indicating success or failure
 ------------------------------------------------------------------------------*/
+ (BOOL)updateObject:(ArcaManagedObject *)managedObject withSourceData:(id)sourceData error:(NSError **)error;
/**-----------------------------------------------------------------------------
 Overwrites or creates an object with source data
 
 This will operate recursively on objects in the source data (i.e. a person with a nested account object, will overwrite/create both the person and the account, and the relationship). It will ensure that only the fields present in the source data are populated on the object (erasing all other fields)
 @param managedObject The object to be overwritten
 @param sourceData The dictionary containing the object source data
 @param error Any errors that occur will be populated to this address
 @return A boolean indicating success or failure
 ------------------------------------------------------------------------------*/
+ (BOOL)replaceObject:(ArcaManagedObject *)managedObject withSourceData:(id)sourceData error:(NSError **)error;

@end
