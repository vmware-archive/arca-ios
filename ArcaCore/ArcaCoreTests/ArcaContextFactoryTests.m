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
//Created by Adrian Kemp on 2014-01-28

#import <XCTest/XCTest.h>
#import <ArcaCore/ArcaCore.h>
#import "ArcaCoreTestCase.h"
#import "ErrorConstants.h"

@interface ArcaContextFactory ()

+ (void)setDefaultFactory:(ArcaContextFactory *)factory;
- (void)resetMainThreadContext;
- (BOOL)mainThreadContextExists;

@end

@interface ArcaContextFactoryTests : ArcaCoreTestCase

@end

@implementation ArcaContextFactoryTests

- (void)setUp
{
    [super setUp];
    
    [ArcaPersistentStoreCoordinator setDefaultCoordinator:[[ArcaPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel]];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testCreateContextFactory {
    ArcaContextFactory *newFactory = [ArcaContextFactory new];
    if (!newFactory) {
        XCTFail(@"Failed to create ArcaContextFactory");
    }
}

- (void)testSetContextFactory {
    ArcaContextFactory *defaultFactory;
    
    defaultFactory = [ArcaContextFactory new];
    [ArcaContextFactory setDefaultFactory:defaultFactory];
    
    XCTAssert([ArcaContextFactory defaultFactory] == defaultFactory, @"Default factory was not set correctly");
    
    [defaultFactory resetMainThreadContext];
    
    XCTAssert([defaultFactory mainThreadContextExists] == NO, @"Main thread context exists after being reset");
    
}

- (void)testDefaultContextFactory {
    ArcaContextFactory *defaultFactory = [ArcaContextFactory defaultFactory];
    if (!defaultFactory) {
        XCTFail(@"ArcaContextFactory did not return a default factory");
    }
}

- (void)testMainThreadObjectContext {
    NSManagedObjectContext *mainThreadContext = [[ArcaContextFactory defaultFactory] mainThreadContext];
    
    if (!mainThreadContext) {
        XCTFail(@"mainThreadContext is nil");
    }
    
    if (mainThreadContext.concurrencyType != NSMainQueueConcurrencyType) {
        XCTFail(@"mainThreadContext does not have a main queue concurrency type");
    }
}

- (void)testPrivateQueueContext {
    NSManagedObjectContext *privateContext = [[ArcaContextFactory defaultFactory] privateQueueContext];
    
    XCTAssert(privateContext != nil, @"Got nil private queue context");
    XCTAssert(privateContext.concurrencyType == NSPrivateQueueConcurrencyType, @"Private queue context does not have a private queue concurrency type");
    
    NSManagedObjectContext *childContext;
    @try {
        childContext = [[ArcaContextFactory defaultFactory] childContextForContext:privateContext];
    }
    @catch (NSException *exception) {
        XCTAssert([exception.name isEqualToString:PrivateConcurrencyParent] && [exception.reason isEqualToString:PrivateConcurrencyParentDescription], @"Unexpected exception when trying to create a child context on a private queue context");
    }
    
    XCTAssert(childContext == nil, @"Child context of private context is not nil");
}

- (void)testChildContext {
    NSManagedObjectContext *parentContext, *childContext;
    parentContext = [[ArcaContextFactory defaultFactory] privateQueueContext];
    
    @try {
    childContext = [[ArcaContextFactory defaultFactory] childContextForContext:parentContext];
    }
    @catch (NSException *exception) {
        if (exception.name != PrivateConcurrencyParent) {
            XCTFail(@"Got incorrect exception when trying to create a child on a private queue context");
        }
    }
    
    parentContext = [[ArcaContextFactory defaultFactory] mainThreadContext];
    
    childContext = [[ArcaContextFactory defaultFactory] childContextForContext:parentContext];
    
    if (!parentContext) {
        XCTFail(@"Got nil context when adding a child to the main queue context");
    }
}


@end
