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

#import <CoreData/CoreData.h>
#import "ArcaPersistentStoreCoordinator.h"
#import "ArcaObjectFactory.h"
#import "ArcaManagedObject.h"
#import "ErrorConstants.h"

@protocol ArcaManagedObjectPrivateInterface <NSObject>

+ (NSArray *)objectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)managedObjectContext bypassingIncrementalStore:(BOOL)bypassIncrementalStore error:(NSError *__autoreleasing *)error;

+ (NSPredicate *)predicateForMatchingPrimaryKeys:(NSArray *)primaryKeys;

@end

@implementation ArcaObjectFactory

#pragma mark - Utilities

+ (id)objectKeyPathForSourceKeyPath:(NSString *)sourceKeyPath inMapping:(NSDictionary *)keyPathMapping {
    id sourceMapping;
    if ([keyPathMapping.allKeys containsObject:sourceKeyPath]) {
        sourceMapping = keyPathMapping[sourceKeyPath];
    } else {
        sourceMapping = sourceKeyPath;
    }
    return sourceMapping;
}

///This function is responsible for returning the correct key (of possibly multiple mappings) for a given source representation.
///So a Person object may (on different endpoints) have it's server id represented by either id or person_id. This function
///returns the correct key (or nil).
+ (NSString *)sourceKeyForLocalKey:(NSString *)localKey usingKeyMapping:(NSDictionary *)objectToSourceKeyPathMap inSourceRepresentation:(NSDictionary *)sourceRepresentation {
    id sourceMapping;
    if ( (sourceMapping = [self objectKeyPathForSourceKeyPath:localKey inMapping:objectToSourceKeyPathMap]) == nil) {
        return nil;
    }
    
    if ([sourceMapping isKindOfClass:[NSArray class]]) {
        return [sourceRepresentation.allKeys firstObjectCommonWithArray:sourceMapping];
    } else if ([sourceRepresentation.allKeys containsObject:sourceMapping]) {
        return sourceMapping;
    }
    return nil;
}

+ (NSMutableDictionary *)mutableDictionaryForObjectClass:(Class)objectClass fromSourceData:(id)sourceData {
    if ([sourceData isKindOfClass:[NSDictionary class]]) {
        return [sourceData mutableCopy];
    }
    
    Class primaryKeyClass = NSClassFromString([objectClass primaryKeyAttribute].attributeValueClassName);
    if ([sourceData isKindOfClass:primaryKeyClass]) {
        return [[NSMutableDictionary alloc] initWithObjectsAndKeys:sourceData, [objectClass sourcePrimaryKeyPath], nil];
    }
    
    return nil;
}

+ (NSArray *)arrayFromSourceData:(NSDictionary *)sourceData forKey:(NSString *)key {
    NSArray *arrayFromSourceData;
    if ( (arrayFromSourceData = sourceData[key]) == nil) {
        return nil;
    }
    
    if ([arrayFromSourceData isKindOfClass:[NSArray class]]) {
        return arrayFromSourceData;
    } else {
        return @[arrayFromSourceData];
    }
}

+ (NSArray *)primaryKeysForObjectClass:(Class)objectClass inSourceData:(NSArray *)sourceData {
    if (![sourceData isKindOfClass:[NSArray class]]) {
        return @[];
    }
    NSMutableArray *primaryKeys = [NSMutableArray new];
    for (NSDictionary *objectData in sourceData) {
        id primaryKey = [self primaryKeyForObjectClass:objectClass inObjectData:objectData];
        if (primaryKey) {
            [primaryKeys addObject:primaryKey];
        }
    }
    return primaryKeys;
}

+ (id)primaryKeyForObjectClass:(Class)objectClass inObjectData:(NSDictionary *)objectData {
    if ([objectData isKindOfClass:[NSDictionary class]]) {
        return objectData[[objectClass sourcePrimaryKeyPath]];
    } else {
        return objectData;
    }
}

#pragma mark - Object Creation

+ (NSArray *)createMissingRelatedObjectsForClass:(Class)relatedObjectClass matchingPrimaryKeys:(NSArray *)primaryKeys fromSourceData:(NSArray *)sourceData inContext:(NSManagedObjectContext *)context error:(NSError **)error {
    NSMutableArray *sourceDataForObjectsToCreate = [NSMutableArray new];
    
    //Generate the array of only those source data dictionaries belonging to missing objects (filter out those that already exist)
    for (NSDictionary *relatedObjectData in sourceData) {
        id relatedObjectPrimaryKey;
        if ([relatedObjectData isKindOfClass:[NSDictionary class]]) {
            NSString *relatedObjectSourcePrimaryKeyPath = [self sourceKeyForLocalKey:[relatedObjectClass primaryKeyPath] usingKeyMapping:[relatedObjectClass objectToSourceKeyMap] inSourceRepresentation:sourceData[0]];
            relatedObjectPrimaryKey = relatedObjectData[relatedObjectSourcePrimaryKeyPath];
        } else {
            relatedObjectPrimaryKey = relatedObjectData;
        }
        
        if ([primaryKeys containsObject:relatedObjectPrimaryKey]) {
            [sourceDataForObjectsToCreate addObject:relatedObjectData];
        }
    }
    
    return [self objectsFromSourceData:sourceDataForObjectsToCreate forObjectClass:relatedObjectClass inContext:context error:error];
}

+ (NSArray *)objectsFromSourceData:(id)sourceData forObjectClass:(Class)objectClass inContext:(NSManagedObjectContext *)context error:(NSError **)error {
    NSMutableArray *createdObjects = [NSMutableArray new];
    NSArray *primaryKeysFromSourceData;
    NSArray *existingObjects;
    NSArray *existingPrimaryKeys;
    if (sourceData == nil) {
        return nil;
    } else if (![sourceData isKindOfClass:[NSArray class]]) {
        sourceData = @[sourceData];
    }
    
    primaryKeysFromSourceData = [self primaryKeysForObjectClass:objectClass inSourceData:sourceData];
    
    existingObjects = [objectClass objectsMatchingPredicate:[objectClass predicateForMatchingPrimaryKeys:primaryKeysFromSourceData] sortDescriptors:nil faultingData:YES inContext:context bypassingIncrementalStore:YES error:error];
    
    existingPrimaryKeys = [existingObjects valueForKey:[objectClass primaryKeyPath]];
    
    for (id objectData in sourceData) {
        ArcaManagedObject *populatedObject;
        id objectPrimaryKey = [self primaryKeyForObjectClass:objectClass inObjectData:objectData];
        if (![existingPrimaryKeys containsObject:objectPrimaryKey]) {
            populatedObject = [self objectOfClass:objectClass fromSourceData:objectData inContext:context error:error];
        } else {
            populatedObject = existingObjects[[existingPrimaryKeys indexOfObject:objectPrimaryKey]];
            [self replaceObject:populatedObject withSourceData:objectData error:error];
        }

        if (populatedObject) {
            [createdObjects addObject:populatedObject];
        } else {
            return nil;
        }
    }
    
    return createdObjects;
}

+ (ArcaManagedObject *)objectOfClass:(Class)objectClass fromSourceData:(NSDictionary *)sourceData inContext:(NSManagedObjectContext *)context error:(NSError **)error {
    ArcaManagedObject *newObject = [objectClass objectForEntityNamed:[ArcaPersistentStoreCoordinator entityForClass:objectClass].name inContext:context];
    if (!newObject) {
        if (error) {
            *error = [NSError errorWithDomain:ObjectErrorDomain code:MissingObjectDefinition userInfo:@{NSLocalizedDescriptionKey : MissingObjectDefinitionDescription,
                                                                                                        NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"cannot create object for class: %@", objectClass]}];
        }
        return nil;
    }
    
    if ([sourceData isKindOfClass:[NSDictionary class]]) {
        [self replaceObject:newObject withSourceData:sourceData error:error];
        return newObject;
    } else if ([sourceData isKindOfClass:NSClassFromString([objectClass primaryKeyAttribute].attributeValueClassName)]) {
        [newObject setValue:sourceData forKey:[objectClass primaryKeyPath]];
        return newObject;
    }
    return nil;
}

#pragma mark - Object Population

+ (BOOL)updateObject:(ArcaManagedObject *)managedObject withSourceData:(id)sourceData error:(NSError **)error {
    
    Class objectClass = NSClassFromString(managedObject.entity.managedObjectClassName);
    NSMutableDictionary *objectData = [self mutableDictionaryForObjectClass:objectClass fromSourceData:sourceData];
    
    NSMutableDictionary *dataErrors = [NSMutableDictionary new];
    BOOL sourceDataMatchedAllObjectFields = YES;
    
    NSDictionary *objectAttributes = managedObject.entity.attributesByName;
	NSDictionary *objectToSourceKeyMap = [objectClass objectToSourceKeyMap];
    
    for (NSString *attributeName in objectAttributes) {
        NSString *sourceDataKey = [self sourceKeyForLocalKey:attributeName usingKeyMapping:objectToSourceKeyMap inSourceRepresentation:objectData];
        
        if (!sourceDataKey) {
            sourceDataMatchedAllObjectFields = NO;
            continue;
        }
        
        Class requiredValueClass = NSClassFromString(((NSAttributeDescription *)objectAttributes[attributeName]).attributeValueClassName);
        id dataForKey = objectData[sourceDataKey];
        
        if (![dataForKey isKindOfClass:requiredValueClass]) {
            dataErrors[sourceDataKey] = @"invalid class for key";
            continue;
        }
        
        [managedObject setValue:objectData[sourceDataKey] forKey:attributeName];
        [objectData removeObjectForKey:sourceDataKey];
    }
    
    NSArray *missingObjectMappings = objectData.allKeys;
    
    if (missingObjectMappings.count != 0) {
        if (error) {
            NSMutableDictionary *errorUserInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:missingObjectMappings, @"Missing Mappings", nil];
            errorUserInfo[NSLocalizedFailureReasonErrorKey] = MissingMappingsErrorDescription;
            errorUserInfo[NSLocalizedDescriptionKey] = JustAWarningDescription;
            if (dataErrors.count) {
                [errorUserInfo addEntriesFromDictionary:dataErrors];
            }
            *error = [NSError errorWithDomain:DataErrorDomain code:InvalidDataErrorCode userInfo:errorUserInfo];
        }
        return NO;
    }
    
    if (!sourceDataMatchedAllObjectFields) {
        if (error) {
            *error = [NSError errorWithDomain:DataErrorDomain code:UnfulfilledMappingErrorCode userInfo:dataErrors];
        }
    }
    
    return YES;
}

+ (BOOL)replaceObject:(ArcaManagedObject *)managedObject withSourceData:(id)sourceData error:(NSError **)error {
    [managedObject clearObjectDataForReplacement];
    
    return [self updateObject:managedObject withSourceData:sourceData error:error];
}

+ (void)populateRelationshipsOfObject:(ArcaManagedObject *)managedObject forSourceData:(NSDictionary *)sourceData error:(NSError **)error {
    Class objectClass = managedObject.class;
    NSDictionary *objectToSourceKeyPathMapping = [objectClass objectToSourceKeyMap];
    NSDictionary *objectRelationshipsByName = managedObject.entity.relationshipsByName;
    
    for (NSString *objectRelationshipName in objectRelationshipsByName) {
        NSString *sourceDataKey = [self sourceKeyForLocalKey:objectRelationshipName usingKeyMapping:objectToSourceKeyPathMapping inSourceRepresentation:sourceData];
        
        NSArray *relatedObjectSourceData;
        if ( (relatedObjectSourceData = [self arrayFromSourceData:sourceData forKey:sourceDataKey]) == nil) {
            continue;
        }
        
        NSRelationshipDescription *relationship = objectRelationshipsByName[objectRelationshipName];
        Class relatedObjectClass = NSClassFromString(relationship.destinationEntity.managedObjectClassName);
        
        NSArray *relatedObjectPrimaryKeys = [self primaryKeysForObjectClass:relatedObjectClass inSourceData:relatedObjectSourceData];
        
        NSArray *relatedObjects = [relatedObjectClass objectsMatchingPredicate:[relatedObjectClass predicateForMatchingPrimaryKeys:relatedObjectPrimaryKeys] sortDescriptors:nil faultingData:NO inContext:managedObject.managedObjectContext bypassingIncrementalStore:YES error:error];
        
        NSArray *existingRelatedObjectPrimaryKeys = [relatedObjects valueForKey:[relatedObjectClass primaryKeyPath]];
        NSMutableArray *missingRelatedObjectPrimaryKeys = [relatedObjectPrimaryKeys mutableCopy];
        [missingRelatedObjectPrimaryKeys removeObjectsInArray:existingRelatedObjectPrimaryKeys];
        
        [self createMissingRelatedObjectsForClass:relatedObjectClass matchingPrimaryKeys:missingRelatedObjectPrimaryKeys fromSourceData:relatedObjectSourceData inContext:managedObject.managedObjectContext error:error];
    }
    
    return;
}

#pragma mark -

- (id)init {
    [NSException exceptionWithName:InitializeStaticClass reason:@"You cannot initialize ArcaObjectFactory, it is static class" userInfo:@{}];
    return nil;
}

@end
