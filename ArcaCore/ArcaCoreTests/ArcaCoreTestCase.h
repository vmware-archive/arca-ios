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
//Created by Adrian Kemp on 2014-01-27

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

@interface ArcaCoreTestCase : XCTestCase

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSOperationQueue *asyncTestQueue;
@property (nonatomic, retain) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong, readonly) NSManagedObjectModel *objectModel;
@property (nonatomic, strong, readonly) NSBundle *bundle;

- (void)runAsynchronousBlock:(void (^)(void))block;
- (void)configureArcaPersistentStoreCoordinator;
- (void)addPeopleToContext;
- (void)saveContext;
- (void)restoreTestingPersistentStoreCoordinator;

@end
