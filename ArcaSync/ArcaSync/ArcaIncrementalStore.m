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
//  Created by Adrian Kemp on 2013-10-03.
//

#import "ArcaIncrementalStore.h"
#import "ArcaIncrementalStoreNode.h"

NSString * const ArcaIncrementalStoreDidFinishFetchRequest = @"ArcaIncrementalStoreDidFinishFetchRequest";

@interface ArcaIncrementalStore ()

@property (nonatomic, strong) NSMutableDictionary *permenantIDsByEntityName;
@property (nonatomic, strong) NSMutableArray *nodesToBeProcessed;
@property (nonatomic, strong) NSTimer *nodeTimer, *fetchTimer;
@property (nonatomic, strong) NSMutableDictionary *pendingFetchesByEntityName;

@end

@implementation ArcaIncrementalStore
@synthesize bridgeAdaptor=_bridgeAdaptor;

+ (void)initialize {
    [super initialize];
    [NSPersistentStoreCoordinator registerStoreClass:[self class] forStoreType:[self storeType]];
}

+ (ArcaIncrementalStore *)addStoreToCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    return (id)[coordinator addPersistentStoreWithType:[self storeType] configuration:nil URL:[NSURL URLWithString:@"Arca"] options:nil error:nil];
}

+ (ArcaIncrementalStore *)storeInCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    ArcaIncrementalStore *incrementalStore;
    for (id store in coordinator.persistentStores) {
        if ([store isKindOfClass:[ArcaIncrementalStore class]]) {
            incrementalStore = store;
        }
    }
    return incrementalStore;
}

+ (NSString *)storeType {
    return NSStringFromClass(self.class);
}

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options {
    self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options];
    self.nodeTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(processOutstandingNodes) userInfo:nil repeats:YES];
    //todo: configurable staleness interval.
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(processPendingFetchRequests) userInfo:nil repeats:YES];
    return self;
}

- (void)saveMetadata {
    //Need to persist our current id count, unfufilled store nodes, etc.
}

- (BOOL)loadMetadata:(NSError *__autoreleasing *)error {
    NSURL *storeURL = self.URL;
    
    CFUUIDRef storeUUID = CFUUIDCreateFromString(kCFAllocatorDefault, (__bridge CFStringRef)(storeURL.absoluteString));
    NSString *storeUUIDString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, storeUUID);
    CFRelease(storeUUID);
    //retrieve a UUID based on the store (probably generate it from the URL)
    
    self.metadata = @{NSStoreTypeKey : [self.class storeType],
                      NSStoreUUIDKey : storeUUIDString};
    

    NSDictionary *entitiesByName = self.persistentStoreCoordinator.managedObjectModel.entitiesByName;
    self.pendingFetchesByEntityName = [[NSMutableDictionary alloc] initWithCapacity:entitiesByName.count];
    self.permenantIDsByEntityName = [[NSMutableDictionary alloc] initWithCapacity:entitiesByName.count];
    for (NSString *entityName in entitiesByName) {
        self.permenantIDsByEntityName[entityName] = @1;
        self.pendingFetchesByEntityName[entityName] = @(NO);
    }
    
    self.nodesToBeProcessed = [NSMutableArray new];
    
    return YES;
}

- (void)setBridgeAdaptor:(ArcaBridgeAdaptor *)bridgeAdaptor {
    _bridgeAdaptor = bridgeAdaptor;
    _bridgeAdaptor.incrementalStore = self;
}

- (ArcaBridgeAdaptor *)bridgeAdaptor {
    if (!_bridgeAdaptor) {
        self.bridgeAdaptor = [[ArcaBridgeAdaptor alloc] initWithOperationQueue:[NSOperationQueue new]];
    }
    return _bridgeAdaptor;
}

- (id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSMutableArray *nodes = [NSMutableArray new];
    switch (request.requestType) {
        case NSSaveRequestType: {
            NSDictionary *updatedObjectsByEntity = [self objectChangesByEntityForChangeSet:context.updatedObjects];
            NSDictionary *insertedObjectsByEntity = [self objectChangesByEntityForChangeSet:context.insertedObjects];
            NSDictionary *deletedObjectsByEntity = [self objectChangesByEntityForChangeSet:context.deletedObjects];
            
            [nodes addObjectsFromArray:[self nodesForModifiedObjects:updatedObjectsByEntity withRequestType:@"Update"]];
            [nodes addObjectsFromArray:[self nodesForModifiedObjects:insertedObjectsByEntity withRequestType:@"Create"]];
            [nodes addObjectsFromArray:[self nodesForModifiedObjects:deletedObjectsByEntity withRequestType:@"Delete"]];
        } break;
        case NSCountResultType: //intentionally falls through
        case NSFetchRequestType: {
            self.pendingFetchesByEntityName[((NSFetchRequest *)request).entity.name] = @(YES);
        } break;
        default:
            return @[];
            break;
    }
    
    [self.nodesToBeProcessed addObjectsFromArray:nodes];
    return @[]; //since we do not provide actual completed objects we do not return actual completed objects.
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    return nil;
}

- (NSDictionary *)objectChangesByEntityForChangeSet:(NSSet *)changeSet {
    NSMutableDictionary *changedObjectsByEntity = [NSMutableDictionary new];
    for (NSManagedObject *changedObject in changeSet) {
        if (!changedObjectsByEntity[changedObject.entity.name]) {
            changedObjectsByEntity[changedObject.entity.name] = [NSMutableArray new];
        }
        [changedObjectsByEntity[changedObject.entity.name] addObject:changedObject];
    }
    return changedObjectsByEntity;
}

- (NSMutableArray *)nodesForModifiedObjects:(NSDictionary *)modifiedObjectsByEntity withRequestType:(NSString *)requestMethod {
    NSMutableArray *nodes = [NSMutableArray new];
    for (NSString *entityName in modifiedObjectsByEntity) {
        NSArray *modifiedObjects = modifiedObjectsByEntity[entityName];
        for (NSManagedObject *modifiedObject in modifiedObjects) {
            NSMutableDictionary *updatedValues = [NSMutableDictionary new];
            NSEntityDescription *entityDescription = modifiedObject.entity;
            NSDictionary *attributesByName = entityDescription.attributesByName;
            for (NSString *attributeName in attributesByName) {
                id value = [modifiedObject valueForKey:attributeName];
                if (value) {
                    updatedValues[attributeName] = value;
                }
            }
            ArcaIncrementalStoreNode *newNode = [[ArcaIncrementalStoreNode alloc] initWithObjectID:modifiedObject.objectID withValues:updatedValues version:1];
            newNode.requestMethod = requestMethod;
            [nodes addObject:newNode];
        }
    }
    return nodes;
}

- (void)processOutstandingNodes {
    NSMutableArray *finishedNodes = [NSMutableArray new];
    for (ArcaIncrementalStoreNode *node in self.nodesToBeProcessed) {
        if (node.operation.isFinished) {
            [finishedNodes addObject:node];
        } else {
            NSError *error;
            [self.bridgeAdaptor operationForNode:node error:&error];
            [self.bridgeAdaptor.operationQueue addOperation:node.operation];
        }
    }
    [self.nodesToBeProcessed removeObjectsInArray:finishedNodes];
}

- (void)processPendingFetchRequests {
    NSMutableArray *processedEntityNames = [NSMutableArray new];
    for (NSString *entityName in self.pendingFetchesByEntityName) {
        if ([self.pendingFetchesByEntityName[entityName] boolValue]) {
            [processedEntityNames addObject:entityName];
            NSOperation *fetchOperation = [self.bridgeAdaptor operationForFetchingEntity:entityName withPredicate:nil error:nil];
            NSLog(@"fetch operation: %@", fetchOperation);
            NSOperation *dummyOperation = [NSOperation new];
            [dummyOperation setCompletionBlock:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ArcaIncrementalStoreDidFinishFetchRequest object:self];
            }];
            [dummyOperation addDependency:fetchOperation];
            NSLog(@"queue: %@", self.bridgeAdaptor.operationQueue);
            [self.bridgeAdaptor.operationQueue addOperations:@[fetchOperation, dummyOperation] waitUntilFinished:NO];
        }
    }
    for (NSString *entityName in processedEntityNames) {
        self.pendingFetchesByEntityName[entityName] = @(NO);
    }
}

- (void)retryFailedNode:(ArcaIncrementalStoreNode *)node {
}

- (id)newValueForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    return nil;
}

- (NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError *__autoreleasing *)error {
    NSMutableArray *managedObjectIDs = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (NSManagedObject *managedObject in array) {
        NSNumber *permenantID = self.permenantIDsByEntityName[managedObject.entity.name];
        NSManagedObjectID *managedObjectID = [self newObjectIDForEntity:managedObject.entity referenceObject:permenantID];
        permenantID = @( (permenantID.integerValue + 1) );
        self.permenantIDsByEntityName[managedObject.entity.name] = permenantID;
        
        [managedObjectIDs addObject:managedObjectID];
    }
    
    return managedObjectIDs;
}

@end
