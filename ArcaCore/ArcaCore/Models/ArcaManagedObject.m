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

#import "ArcaManagedObject.h"
#import "ErrorConstants.h"
#import "ArcaContextFactory.h"
#import "ArcaObjectFactory.h"
#import "ArcaPersistentStoreCoordinator.h"
#import <objc/runtime.h>

@implementation ArcaManagedObject

#pragma mark - Factories
+ (instancetype)objectForEntityNamed:(NSString *)entityName inContext:(NSManagedObjectContext *)context {
    return [[ArcaManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context] insertIntoManagedObjectContext:context];
}

+ (id)contextFactory {
    return [ArcaContextFactory defaultFactory];
}

+ (id)objectFactory {
    return [ArcaObjectFactory class];
}

#pragma mark - Object Meta Data
+ (NSString *)primaryKeyPath {
    [[NSException exceptionWithName:MissingImplementation reason:@"primaryKeyPath has not been implemented." userInfo:nil] raise];
    return nil;
}

+ (NSString *)sourcePrimaryKeyPath {
    id sourcePrimaryKeyMapping = [self objectToSourceKeyMap][[self primaryKeyPath]];
    if ([sourcePrimaryKeyMapping isKindOfClass:[NSArray class]]) {
        return ((NSArray *)sourcePrimaryKeyMapping)[0];
    } else {
        return sourcePrimaryKeyMapping;
    }
}

+ (NSDictionary *)objectToSourceKeyMap {
    [[NSException exceptionWithName:MissingImplementation reason:@"objectToSourceKeyMap has not been implemented" userInfo:nil] raise];
    return nil;
}

+ (NSString *)entityName {
    return [self entity].name;
}

+ (NSEntityDescription *)entity {
    return [ArcaPersistentStoreCoordinator entityForClass:self];
}

+ (NSAttributeDescription *)primaryKeyAttribute {
    return [self entity].attributesByName[[self primaryKeyPath]];
}

- (id)primaryKey {
    return [self valueForKey:[self.class primaryKeyPath]];
}

#pragma mark - Retrievers

+ (NSFetchRequest *)fetchRequestForObjectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error {
    if(managedObjectContext == nil) {
        [[NSException exceptionWithName:InvalidNilArgument reason:@"The context cannot be nil" userInfo:nil] raise];
        return nil;
    }
    
    if (sortDescriptors == nil) {
        sortDescriptors = @[];
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    fetchRequest.returnsObjectsAsFaults = !faultingData;
    fetchRequest.sortDescriptors = sortDescriptors;
    fetchRequest.predicate = predicate;
    
    return fetchRequest;
}

+ (NSArray *)objectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)managedObjectContext bypassingIncrementalStore:(BOOL)bypassIncrementalStore error:(NSError *__autoreleasing *)error {
    NSFetchRequest *fetchRequest = [self fetchRequestForObjectsMatchingPredicate:predicate sortDescriptors:sortDescriptors faultingData:faultingData inContext:managedObjectContext error:error];
    if (bypassIncrementalStore) {
        Class incrementalStoreClass = NSClassFromString(@"ArcaIncrementalStore");
        
        NSManagedObjectContext *context = managedObjectContext;
        NSMutableArray *affectedStores = [NSMutableArray new];
        while (context && !context.persistentStoreCoordinator) {
            context = context.parentContext;
        }
        for (NSIncrementalStore *store in context.persistentStoreCoordinator.persistentStores) {
            if (![store isKindOfClass:incrementalStoreClass]) {
                [affectedStores addObject:store];
            }
        }
        fetchRequest.affectedStores = affectedStores;
    }
    
    return [managedObjectContext executeFetchRequest:fetchRequest error:error];
    
}

+ (NSArray *)objectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error {
    
    return [self objectsMatchingPredicate:predicate sortDescriptors:sortDescriptors faultingData:faultingData inContext:managedObjectContext bypassingIncrementalStore:NO error:error];
}

+ (NSArray *)objectsMatchingPrimaryKeys:(NSArray *)primaryKeys faultingData:(BOOL)faultingData inContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {

    NSPredicate *predicate = [self predicateForMatchingPrimaryKeys:primaryKeys];
    
    return [self objectsMatchingPredicate:predicate sortDescriptors:nil faultingData:faultingData inContext:context error:error];
}

+ (NSPredicate *)predicateForMatchingPrimaryKeys:(NSArray *)primaryKeys {
    return [NSPredicate predicateWithFormat:@"%K in %@", [self primaryKeyPath], primaryKeys];
}


#pragma mark - Deleters

+ (BOOL)deleteAllObjects:(NSError **)error {
    __block BOOL success;
    NSManagedObjectContext *context = [[ArcaContextFactory defaultFactory] privateQueueContext];
    
    NSArray *allObjects = [self objectsMatchingPredicate:nil sortDescriptors:nil faultingData:NO inContext:context error:error];
    
    for (NSManagedObject *managedObject in allObjects) {
        [context deleteObject:managedObject];
    }
    
    [context performBlockAndWait:^{
        success = [context save:error];
    }];

    return success;
}

- (void)clearObjectDataForReplacement {
    [self.managedObjectContext performBlockAndWait:^{
        NSDictionary *objectAttributes = self.entity.attributesByName;
        for (NSString *attributeName in objectAttributes) {
            if ([attributeName isEqualToString:[self.class primaryKeyPath]]) {
                continue;
            }
            [self willChangeValueForKey:attributeName];
            [self setValue:nil forKey:attributeName];
            [self didChangeValueForKey:attributeName];
        }
    }];
}

@end
