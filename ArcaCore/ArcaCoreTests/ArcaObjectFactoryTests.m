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
#import "ErrorConstants.h"
#import "ArcaCoreTestCase.h"
#import "Person.h"

@interface ArcaObjectFactory ()

+ (NSString *)sourceKeyForLocalKey:(NSString *)localKey usingKeyMapping:(NSDictionary *)objectToSourceKeyPathMap inSourceRepresentation:(NSDictionary *)sourceRepresentation;
+ (void)populateRelationshipsOfObject:(ArcaManagedObject *)managedObject forSourceData:(NSDictionary *)sourceData error:(NSError **)error;
+ (NSArray *)arrayFromSourceData:(NSDictionary *)sourceData forKey:(NSString *)key;
+ (NSArray *)primaryKeysForObjectClass:(Class)objectClass inSourceData:(NSArray *)sourceData;
+ (NSArray *)createMissingRelatedObjectsForClass:(Class)relatedObjectClass matchingPrimaryKeys:(NSArray *)primaryKeys fromSourceData:(NSArray *)sourceData inContext:(NSManagedObjectContext *)context error:(NSError **)error;
+ (ArcaManagedObject *)objectOfClass:(Class)objectClass fromSourceData:(NSDictionary *)sourceData inContext:(NSManagedObjectContext *)context error:(NSError **)error;
+ (NSArray *)objectsFromSourceData:(id)sourceData forObjectClass:(Class)objectClass inContext:(NSManagedObjectContext *)context error:(NSError **)error;

+ (BOOL)updateObject:(ArcaManagedObject *)managedObject withSourceData:(id)sourceData error:(NSError **)error;
+ (BOOL)replaceObject:(ArcaManagedObject *)managedObject withSourceData:(id)sourceData error:(NSError **)error;


@end

@interface ArcaObjectFactoryTests : ArcaCoreTestCase

@end

@implementation ArcaObjectFactoryTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testCreateObjectFactory {
    ArcaObjectFactory *factory;
    @try {
        factory = [ArcaObjectFactory new];
    }
    @catch (NSException *exception) {
        if (exception.name != InitializeStaticClass) {
            XCTFail(@"Got incorrect exception when attempting to initialize an ArcaObjectFactory");
        }
    }

    if (factory) {
        XCTFail(@"Got an initialized object when attempting to initialize an ArcaObjectFactory (you shouldn't)");
    }
}

- (void)testSourceMappings {
    NSString *correctMapping;
    correctMapping = [ArcaObjectFactory sourceKeyForLocalKey:@"cloudId" usingKeyMapping:[Person objectToSourceKeyMap] inSourceRepresentation:@{@"id" : @1234}];
    
    if (![correctMapping isEqualToString:@"id"]) {
        XCTFail(@"Got incorrect mapping for known mapping of id to cloudId");
    }

    correctMapping = [ArcaObjectFactory sourceKeyForLocalKey:@"cloudId" usingKeyMapping:[Person objectToSourceKeyMap] inSourceRepresentation:@{@"person_id" : @1234}];
    
    if (![correctMapping isEqualToString:@"person_id"]) {
        XCTFail(@"Got incorrect mapping for known mapping of person_id to cloudId");
    }
    
    correctMapping = [ArcaObjectFactory sourceKeyForLocalKey:@"BAD_KEY" usingKeyMapping:[Person objectToSourceKeyMap] inSourceRepresentation:@{@"id" : @1234}];
    
    if (correctMapping != nil) {
        XCTFail(@"Got mapping for known bad local key");
    }

}

- (void)testCompleteSourceDataInsertion {
    self.context = nil;
    NSDictionary *personData;
    Person *newPerson;
    NSError *error;
    BOOL success;
    
    newPerson = [Person objectForEntityNamed:@"Person" inContext:self.context];

    personData = @{@"id" : @5,
                   @"first_name" : @"John",
                   @"last_name" : @"Doe",
                   @"email" : @"john.doe@example.com"};
    

    success = [ArcaObjectFactory replaceObject:newPerson withSourceData:personData error:&error];
    
    if (!success) {
        XCTFail(@"Got a failure when populating data that matched exactly to object schema");
    }
    
}

- (void)testOverloadedSourceDataInsertion {
    self.context = nil;
    NSDictionary *personData;
    Person *newPerson;
    NSError *error;
    BOOL success;
    
    newPerson = [Person objectForEntityNamed:@"Person" inContext:self.context];
    
    personData = @{@"id" : @5,
                   @"first_name" : @"John",
                   @"last_name" : @"Doe",
                   @"email" : @"john.doe@example.com",
                   @"extra_field" : @"should cause success to be NO"};
    
    
    success = [ArcaObjectFactory replaceObject:newPerson withSourceData:personData error:&error];
    
    if (success) {
        XCTFail(@"Got success when populating data that did not match exactly to object schema");
    }
    
}

- (void)testIncompleteSourceDataInsertion {
    self.context = nil;
    NSDictionary *personData;
    Person *newPerson;
    NSError *error;
    BOOL success;
    
    newPerson = [Person objectForEntityNamed:@"Person" inContext:self.context];
    
    personData = @{@"id" : @5,
                   @"first_name" : @"John",
                   @"last_name" : @"Doe"};
    
    
    success = [ArcaObjectFactory replaceObject:newPerson withSourceData:personData error:&error];
    
    if (!success) {
        XCTFail(@"Got failure when populating data that matched exactly a subset of the object schema");
    }
    
    if (![error.domain isEqualToString:DataErrorDomain] || error.code != UnfulfilledMappingErrorCode) {
        XCTFail(@"Got an unexpected error when populating data that matched exactly a subset of the object schema");
    }
    
}

- (void)testPopulateRelationshipsForObject {
    NSError *error;
    Person *newPerson;
    self.context = nil;
    [self addPeopleToContext];
    
    newPerson = [Person objectForEntityNamed:@"Person" inContext:self.context];
    
    NSDictionary *sourceData = @{@"id" : @1,
                                 @"first_name" : @"Jimmy",
                                 @"siblings" : @[@3,@2]};
    
    [ArcaObjectFactory populateRelationshipsOfObject:newPerson forSourceData:sourceData error:&error];
}

- (void)testArrayFromSourceData {
    NSArray *arrayFromSourceData;
    NSDictionary *sourceData;
    NSString *sourceKey;
    NSArray *expectedResult;
    
    sourceKey = @"people";
    expectedResult = @[@1,@3,@5];
    sourceData = @{sourceKey : expectedResult};
    
    arrayFromSourceData = [ArcaObjectFactory arrayFromSourceData:sourceData forKey:sourceKey];
    if (![arrayFromSourceData isEqualToArray:expectedResult]) {
        XCTFail(@"Did not recieve the correct data");
    }
    
    sourceData = @{@"BAD_KEY" : expectedResult};
    
    arrayFromSourceData = [ArcaObjectFactory arrayFromSourceData:sourceData forKey:sourceKey];
    if ([arrayFromSourceData isEqualToArray:expectedResult]) {
        XCTFail(@"Got data from a known bad request");
    }
}

- (void)testRelatedObjectsFromSourceData {
    NSArray *arrayFromSourceData;
    NSArray *expectedKeys, *returnedKeys;
    
    expectedKeys = @[@1,@3];
    arrayFromSourceData = @[@{@"id" : @1}, @{@"id" : @3}];
    returnedKeys = [ArcaObjectFactory primaryKeysForObjectClass:[Person class] inSourceData:arrayFromSourceData];
    
    if (![returnedKeys isEqualToArray:expectedKeys]) {
        XCTFail(@"Returned primary keys did not match expectations");
    }
    
    arrayFromSourceData = expectedKeys;
    returnedKeys = [ArcaObjectFactory primaryKeysForObjectClass:[Person class] inSourceData:arrayFromSourceData];

    if (![returnedKeys isEqualToArray:expectedKeys]) {
        XCTFail(@"Returned primary keys did not match expectations");
    }
    
    expectedKeys = @[@1,@2,@4];
    returnedKeys = [ArcaObjectFactory primaryKeysForObjectClass:[Person class] inSourceData:arrayFromSourceData];

    if ([returnedKeys isEqualToArray:expectedKeys]) {
        XCTFail(@"Returned primary keys matched to a known incorrect set");
    }
}

- (void)testCreateMissingRelatedObjects {
    NSError *error;
    Person *newPerson;
    NSDictionary *sourceData;
    NSArray *createdObjects;
    NSArray *createdObjectPrimaryKeys;
    
    self.context = nil;
    [self addPeopleToContext];
    
    newPerson = [Person objectForEntityNamed:@"Person" inContext:self.context];
    
    sourceData = @{@"id" : @1,
                  @"first_name" : @"Jimmy",
                  @"siblings" : @[@3,@2]};

    createdObjects = [ArcaObjectFactory createMissingRelatedObjectsForClass:[Person class] matchingPrimaryKeys:@[@3,@2] fromSourceData:sourceData[@"siblings"] inContext:self.context error:&error];
                                                                                                                 
    createdObjectPrimaryKeys = [createdObjects valueForKey:[Person primaryKeyPath]];
    
    if (![createdObjectPrimaryKeys isEqualToArray:sourceData[@"siblings"]]) {
        XCTFail(@"Created objects do not match the expected set");
    }
    
    if (error && (error.domain != DataErrorDomain || error.code != UnfulfilledMappingErrorCode)) {
        XCTFail(@"Got unexpected error when creating missing objects from valid source data: %@", error);
    }
    

    
}

- (void)testCreateObjectFromSourceData {
    NSError *error;
    Person *newPerson;
    NSDictionary *sourceData;
    
    self.context = nil;
    [self addPeopleToContext];
    
    sourceData = @{@"id" : @1,
                   @"first_name" : @"Jimmy"};
    
    newPerson = (Person *)[ArcaObjectFactory objectOfClass:[Person class] fromSourceData:sourceData inContext:self.context error:&error];

    if (!newPerson) {
        XCTFail(@"Object not created from valid source data");
    }
    
    if (error.code != UnfulfilledMappingErrorCode || ![error.domain isEqualToString:DataErrorDomain]) {
        XCTFail(@"Unexpected error occurred creating valid object from source data: %@", error);
    }
    
    sourceData = @{@"BAD_KEY" : @"fishes",
                   @"BAD_KEY_2" : @44444};
    error = nil;
    
    newPerson = (Person *)[ArcaObjectFactory objectOfClass:[Person class] fromSourceData:sourceData inContext:self.context error:&error];
    
    if (!error) {
        XCTFail(@"No error when creating object from known invalid source data");
    }
}

- (void)testCreateMultipleObjectsFromSourceData {
    NSError *error;
    NSArray *createdObjects;
    NSArray *sourceData;
    
    self.context = nil;
    [self addPeopleToContext];
    
    sourceData = @[@{@"id" : @1,
                   @"first_name" : @"Jimmy"},
                   @{@"id" : @2,
                     @"last_name" : @"Doe"}];
    
    createdObjects = [ArcaObjectFactory objectsFromSourceData:sourceData forObjectClass:[Person class] inContext:self.context error:&error];
    
    if (createdObjects.count == 0) {
        XCTFail(@"Objects not created from valid source data");
    }
    
    if (error.code != UnfulfilledMappingErrorCode || ![error.domain isEqualToString:DataErrorDomain]) {
        XCTFail(@"Unexpected error occurred creating valid object from source data: %@", error);
    }
    
    sourceData = @[@{@"BAD_KEY" : @"fishes",
                   @"BAD_KEY_2" : @44444}];
    error = nil;
    
    createdObjects = [ArcaObjectFactory objectsFromSourceData:sourceData forObjectClass:[Person class] inContext:self.context error:&error];
    
    if (!error) {
        XCTFail(@"No error when creating objects from known invalid source data");
    }

    
    
}

@end
