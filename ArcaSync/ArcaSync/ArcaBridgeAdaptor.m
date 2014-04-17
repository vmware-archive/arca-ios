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
//  Created by Adrian Kemp on 2014-03-18.

#import <objc/runtime.h>
#import "ArcaBridgeAdaptor.h"
#import "ArcaIncrementalStoreNode.h"
#import "ArcaIncrementalStore.h"

@protocol ArcaManagedObjectInterface

+ (NSString *)primaryKeyPath;
- (id)primaryKey;

@end

@protocol ArcaBridgeAdaptorOperationInterface
    @property (nonatomic, strong) id objectSourceId;
    @property (nonatomic, strong) NSDictionary *payload;

    - (void)configureForFetchingEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate error:(NSError **)error;
@end

@interface ArcaBridgeAdaptor ()

@property (nonatomic, strong) NSMutableDictionary *operationClassesByEntity;

@end

@implementation ArcaBridgeAdaptor

- (void)queueOperation:(NSOperation *)operation {
    [self.operationQueue addOperation:operation];
}

- (NSOperation *)operationForNode:(ArcaIncrementalStoreNode *)node error:(NSError **)error {
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = self.incrementalStore.persistentStoreCoordinator;

    NSManagedObject *object = [managedObjectContext existingObjectWithID:node.objectID error:error];
    NSOperation *newOperation = [[self operationClassForEntity:object.entity.name] new];
    node.operation = newOperation;
    [self configureOperation:newOperation forNode:node error:error];
    return newOperation;
}

- (NSOperation *)operationForFetchingEntity:(NSString *)entity withPredicate:(NSPredicate *)predicate error:(NSError **)error {
    Class operationClass = [self operationClassForEntity:entity];
    NSOperation <ArcaBridgeAdaptorOperationInterface> *newOperation = [operationClass new];
    [newOperation configureForFetchingEntity:entity withPredicate:predicate error:error];
    return newOperation;
}

- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue {
    self = [super init];
    self.operationClassesByEntity = [NSMutableDictionary new];
    self.operationQueue = operationQueue;
    return self;
}

- (void)registerOperationClass:(Class)operationClass forEntity:(NSEntityDescription *)entity {
    self.operationClassesByEntity[entity.name] = operationClass;
}

- (void)unRegisterOperationClass:(Class)operationClass forEntity:(NSEntityDescription *)entity {
    [self.operationClassesByEntity removeObjectForKey:entity.name];
}

- (void)unRegisterOperationClassesForEntity:(NSEntityDescription *)entity {
    [self.operationClassesByEntity removeObjectForKey:entity.name];
}

- (void)configureOperation:(NSOperation *)operation forNode:(ArcaIncrementalStoreNode *)node error:(NSError **)error {
    NSMutableDictionary *valuesByKey = [NSMutableDictionary new];
    NSEntityDescription *entity = node.objectID.entity;
    
    NSString *primaryKeyPath;
    Class objectClass = NSClassFromString(entity.managedObjectClassName);
    if ([objectClass conformsToProtocol:@protocol(ArcaManagedObjectInterface)]) {
        primaryKeyPath = [objectClass primaryKeyPath];
    }
    
    if (!primaryKeyPath) {
        if (error) {
            //send a useful error
            *error = [NSError errorWithDomain:@"" code:0x0 userInfo:@{}];
        }
    }
    
    NSDictionary *propertiesByName = entity.propertiesByName;
    for (NSString *propertyName in propertiesByName) {
        id valueForKey = [node valueForPropertyDescription:propertiesByName[propertyName]];
        if (valueForKey) {
            valuesByKey[propertyName] = valueForKey;
        }
    }
    id primaryKey = valuesByKey[primaryKeyPath];
    [valuesByKey removeObjectForKey:primaryKeyPath];

    if ([operation conformsToProtocol:@protocol(ArcaBridgeAdaptorOperationInterface)]) {
        ((NSOperation <ArcaBridgeAdaptorOperationInterface> *)operation).payload = valuesByKey;
        ((NSOperation <ArcaBridgeAdaptorOperationInterface> *)operation).objectSourceId = primaryKey;
    } else {
        if (error) {
            //send a useful error
            *error = [NSError errorWithDomain:@"" code:0x0 userInfo:@{}];
        }
    }
}

- (Class)operationClassForEntity:(NSString *)entityName {
    Class operationClass = self.operationClassesByEntity[entityName];
    if (!operationClass) {
        operationClass = NSClassFromString(@"HTTPOperation");
    }
    return operationClass;
}

@end
