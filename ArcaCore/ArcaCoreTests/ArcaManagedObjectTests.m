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

#import "ArcaCoreTestCase.h"
#import <ArcaCore/ArcaCore.h>
#import "ErrorConstants.h"
#import "TestConstants.h"
#import "Person.h"

@interface ArcaManagedObject ()

- (id)primaryKey;

@end

@interface ArcaManagedObjectTests : ArcaCoreTestCase

@end

@implementation ArcaManagedObjectTests

- (void)setUp {
    [super setUp];
    //Set up the testing queue and semaphore
    self.asyncTestQueue = [NSOperationQueue new];
    self.semaphore = dispatch_semaphore_create(0);
}

- (void)tearDown {
    [super tearDown];
    
    //Tear down the testing queue and semaphore
    [self.asyncTestQueue cancelAllOperations];
    self.asyncTestQueue = nil;
    self.semaphore = nil;
}

- (void)testCreateManagedObject {
    ArcaManagedObject *testObject = [[ArcaManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    if (!testObject) {
        XCTFail(@"Failed to create ArcaManagedObject instance");
    }
}

- (void)testConvenienceInit {
    ArcaManagedObject *testObject = [ArcaManagedObject objectForEntityNamed:@"Person" inContext:self.context];
    if (!testObject) {
        XCTFail(@"Failed to create ArcaManagedObject instance using objectForEntityNamed:inContext:");
    }
}

- (void)testMissingPrimaryKeyPath {
    NSString *primaryKeyPath;
    @try {
        primaryKeyPath = [ArcaManagedObject primaryKeyPath];
    }
    @catch (NSException *exception) {
        if (exception.name != MissingImplementation) {
            XCTFail(@"Missing primary keypath did not throw proper exception");
        }
    }
    if (primaryKeyPath != nil) {
        XCTFail(@"ArcaManagedObject did not return nil primaryKeyPath");
    }
    
    ArcaManagedObject *brokenObject = [ArcaManagedObject objectForEntityNamed:@"Broken" inContext:self.context];
    
    id primaryKey;
    @try {
        primaryKey = [brokenObject primaryKey];
    }
    @catch (NSException *exception) {
        if (exception.name != MissingImplementation) {
            XCTFail(@"Missing primary keypath did not throw proper exception");
        }
    }
    
    if (primaryKey != nil) {
        XCTFail(@"Recieved primary key value from ArcaManagedObject base class");
    }
}

- (void)testValidPrimaryKeyPath {
    NSString *primaryKeyPath = [Person primaryKeyPath];
    if (primaryKeyPath != PersonPrimaryKeyPath) {
        XCTFail(@"Person did not return the correct primary keyPath");
    }
    
    Person *newPerson = [Person objectForEntityNamed:@"Person" inContext:self.context];
    if (![[newPerson primaryKey] isEqualToNumber:@0]) {
        XCTFail(@"Incorrect primary key for created person object");
    }
}

- (void)testMissingObjectToSourceKeyMap {
    NSDictionary *objectToSourceKeyMap;
    @try {
        objectToSourceKeyMap = [ArcaManagedObject objectToSourceKeyMap];
    }
    @catch (NSException *exception) {
        if (exception.name != MissingImplementation) {
            XCTFail(@"Missing objectToSourceKeyMap did not throw proper exception");
        }
    }
    
    if (objectToSourceKeyMap != nil) {
        XCTFail(@"Got non nil objectToSourceKeyMap from ArcaMAnagedObject base class");
    }
}

- (void)testValidObjectToSourceKeyMap {
    ArcaManagedObject *testObject = [ArcaManagedObject objectForEntityNamed:@"Person" inContext:self.context];
    NSDictionary *objectToSourceKeyMap = [testObject.class objectToSourceKeyMap];
    if (objectToSourceKeyMap == nil) {
        XCTFail(@"Got nil key map for valid class: %@", testObject.class);
    }
    
}

- (void)testMatchingObjectsWithAllNilArguments {
    self.context = nil;
    NSArray *matchingObjects;
    @try {
         matchingObjects = [Person objectsMatchingPredicate:nil sortDescriptors:nil faultingData:NO inContext:nil error:nil];
    }
    @catch (NSException *exception) {
        if (exception.name != InvalidNilArgument) {
            XCTFail(@"Missing context did not throw proper exception");
        }
    }
    
    if (matchingObjects.count != 0) {
        XCTFail(@"Got objects from nil context");
    }
}

- (void)testMatchingObjectsWithBadSortDescriptorsAndPredicate {
    self.context = nil;
    NSArray *matchingObjects;
    NSError *error;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %d", @"BAD_KEY", 0xDEADBEEF];
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"BAD_KEY" ascending:NO]];
    matchingObjects = [Person objectsMatchingPredicate:predicate sortDescriptors:sortDescriptors faultingData:NO inContext:self.context error:&error];
    
    if (error != nil) { //This is strange, but the framework does not throw errors when given invalid keys for predicates/sorts
        XCTFail(@"Got error when fetching with invalid predicate and sort descriptors (not a typo, the framework used to allow this.)");
    }
}

- (void)testRetrievingAddedObjects {
    self.context = nil;
    [self addPeopleToContext];
    NSError *error;
    NSArray *matchingObjects = [Person objectsMatchingPredicate:nil sortDescriptors:nil faultingData:NO inContext:self.context error:&error];
    
    if (error) {
        XCTFail(@"Got error when retrieving existing objects using default predicate and sort");
    }
    
    if (matchingObjects.count == 0) {
        XCTFail(@"Got no objects when retrieving known existing objects");
    }
}

- (void)testRetrievingAddedObjectsByPrimaryKey {
    self.context = nil;
    [self addPeopleToContext];
    NSError *error;
    NSArray *primaryKeys = @[@1,@3];
    
    NSArray *matchingObjects = [Person objectsMatchingPrimaryKeys:primaryKeys faultingData:NO inContext:self.context error:&error];
    
    if (error) {
        XCTFail(@"Got error when retrieving existing objects using default predicate and sort");
    }
    
    NSArray *returnedPrimaryKeys = [[matchingObjects valueForKey:[Person primaryKeyPath]] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"integerValue" ascending:YES]]];
    
    if (![returnedPrimaryKeys isEqualToArray:primaryKeys]) {
        XCTFail(@"incorrect objects retrieved from known existing objects");
    }
}

- (void)testDeletingAllObjectsOfType {
    NSError *error;
    self.context = nil;
    [self configureArcaPersistentStoreCoordinator];
    [self addPeopleToContext];
    [self saveContext];
    
    [Person deleteAllObjects:&error];

    if (error) {
        XCTFail(@"Got error when deleting all Person objects");
    }

    NSArray *remainingObjects = [Person objectsMatchingPredicate:nil sortDescriptors:nil faultingData:NO inContext:self.context error:&error];
    
    if (error) {
        XCTFail(@"Got error when retrieving all Person objects after deleting them all");
    }
    
    if (remainingObjects.count != 0) {
        XCTFail(@"Person objects remaining after having deleted all of them");
    }
    
    [self restoreTestingPersistentStoreCoordinator];
}

@end
