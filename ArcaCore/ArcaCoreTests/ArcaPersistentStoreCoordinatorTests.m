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

#import <XCTest/XCTest.h>
#import <ArcaCore/ArcaCore.h>
#import "ArcaCoreTestCase.h"
#import "ErrorConstants.h"

@interface ArcaPersistentStoreCoordinator ()

+ (void)configureUsingObjectModel:(NSManagedObjectModel *)objectModel;

@end

@interface ArcaPersistentStoreCoordinatorTests : ArcaCoreTestCase

@end

@implementation ArcaPersistentStoreCoordinatorTests

- (void)setUp
{
    [super setUp];
    [ArcaPersistentStoreCoordinator setDefaultCoordinator:nil];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testSetDefaultCoordinatorSuccess {
    [ArcaPersistentStoreCoordinator setDefaultCoordinator:nil];
}

- (void)testLazyLoadedDefaultPersistentStoreCoordinator {
    ArcaPersistentStoreCoordinator *defaultCoordinator;
    @try {
        defaultCoordinator = [ArcaPersistentStoreCoordinator defaultCoordinator];
    }
    @catch (NSException *exception) {
        XCTAssert([exception.name isEqualToString:NSInvalidArgumentException], @"Got unexpected exception when retrieving a default ArcaPersistentStoreCoordinator");
    }

    XCTAssert(defaultCoordinator == nil, @"Succeeded in retrieving a default ArcaPersistentStoreCoordinator (despite a bad model)");
}

- (void)testCreatePersistentStoreCoordinator {
    ArcaPersistentStoreCoordinator *newCoordinator = [[ArcaPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel];
    
    if (!newCoordinator) {
        XCTFail(@"Failed to create ArcaPersistentStoreCoordinator instance");
    }
}

- (void)testManagedObjectModelByName {
    NSString *modelName = @"TestModel";
    NSError *error;
    NSManagedObjectModel *objectModel;
    
    objectModel = [ArcaPersistentStoreCoordinator managedObjectModelNamed:nil inBundle:nil error:&error];
    if (!error) {
        XCTFail(@"No error returned when looking for a blank object model (name == nil)");
    }
    
    error = nil;
    objectModel = [ArcaPersistentStoreCoordinator managedObjectModelNamed:@"BAD_NAME" inBundle:nil error:&error];
    if (!error) {
        XCTFail(@"No error returned when looking for a non-existent object model");
    }

    error = nil;
    objectModel = [ArcaPersistentStoreCoordinator managedObjectModelNamed:modelName inBundle:nil error:&error];
    if (!error) {
        XCTFail(@"No error returned when looking in the wrong bundle for an object model");
    }
    
    error = nil;
    objectModel = [ArcaPersistentStoreCoordinator managedObjectModelNamed:modelName inBundle:self.bundle error:&error];
    if (error) {
        XCTFail(@"Got error when attempting to load a valid object model \n %@", error);
    }

}

- (void)testSetupDefaultStores {
    ArcaPersistentStoreCoordinator *newCoordinator = [[ArcaPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel];
    
    NSError *error;
    
    if (![newCoordinator setupDefaultStores:&error]) {
        XCTFail(@"Failed to setup default stores:\n %@", error);
    }
    
    
}

@end
