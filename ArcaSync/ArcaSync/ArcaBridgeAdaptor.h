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

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class ArcaIncrementalStoreNode;
@class ArcaIncrementalStore;

@protocol ArcaBridgeAdaptorOperationInterface;
@protocol ArcaManagedObjectInterface;

@interface ArcaBridgeAdaptor : UICollectionViewController

@property (nonatomic, strong) ArcaIncrementalStore *incrementalStore;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue;
- (void)registerOperationClass:(Class)operationClass forEntity:(NSEntityDescription *)entity;
- (void)unRegisterOperationClass:(Class)operationClass forEntity:(NSEntityDescription *)entity;
- (void)unRegisterOperationClassesForEntity:(NSEntityDescription *)entity;
- (void)queueOperation:(NSOperation *)operation;
- (NSOperation *)operationForFetchingEntity:(NSString *)entity withPredicate:(NSPredicate *)predicate error:(NSError **)error;
- (NSOperation *)operationForNode:(ArcaIncrementalStoreNode *)node error:(NSError **)error;
@end
