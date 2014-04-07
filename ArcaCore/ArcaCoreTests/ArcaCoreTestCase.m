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

extern void __gcov_flush(void);

@interface ArcaCoreTestCase ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *testingPersistentStoreCoordinator;

@end

@implementation ArcaCoreTestCase

- (void)setUp {
    [super setUp];
    
    //Set up a persistent store
    self.testingPersistentStoreCoordinator = self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel];
    NSError *error = nil;
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:@{} error:&error];
    if (error || self.persistentStoreCoordinator.persistentStores.count == 0) {
        XCTFail(@"Could not set up persistent store");
    }
    
    //Set up entities
}

- (void)tearDown {
    [super tearDown];
    
    //Tear down the persistent store
    
    //Tear down the entities
    
    //flush the coverage generator
    __gcov_flush();
}

- (void)runAsynchronousBlock:(void (^)(void))block {
    [self.asyncTestQueue addOperationWithBlock:^{
        block();
        dispatch_semaphore_signal(self.semaphore);
    }];
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
}

- (NSBundle *)bundle {
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"Omnia.ArcaCoreTests"];
    if (!bundle) {
        XCTFail(@"Could not find test bundle");
    }
    return bundle;
}

- (NSManagedObjectModel *)objectModel {
    NSURL *urlForModelFile = [self.bundle URLForResource:@"TestModel" withExtension:@"momd"];
    if (!urlForModelFile) {
        XCTFail(@"Could not locate model file");
    }
    
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:urlForModelFile];
}

- (NSManagedObjectContext *)context {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _context;
}

- (void)addPeopleToContext {
    NSManagedObject *newPerson;
    
    newPerson = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    [newPerson setValue:@0 forKey:@"cloudId"];
    [newPerson setValue:@"John" forKey:@"firstName"];
    [newPerson setValue:@"Smith" forKey:@"lastName"];
    [newPerson setValue:@"john.smith@example.com" forKey:@"emailAddress"];
    
    newPerson = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    [newPerson setValue:@1 forKey:@"cloudId"];
    [newPerson setValue:@"Jane" forKey:@"firstName"];
    [newPerson setValue:@"Smith" forKey:@"lastName"];
    [newPerson setValue:@"jane.smith@example.com" forKey:@"emailAddress"];

    newPerson = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    [newPerson setValue:@2 forKey:@"cloudId"];
    [newPerson setValue:@"John" forKey:@"firstName"];
    [newPerson setValue:@"Doe" forKey:@"lastName"];
    [newPerson setValue:@"john.doe@example.com" forKey:@"emailAddress"];
    
    newPerson = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
    [newPerson setValue:@3 forKey:@"cloudId"];
    [newPerson setValue:@"Jane" forKey:@"firstName"];
    [newPerson setValue:@"Doe" forKey:@"lastName"];
    [newPerson setValue:@"jane.doe@example.com" forKey:@"emailAddress"];

    return;
}

- (void)saveContext {
    __block BOOL success;
    __block NSError *error;
    [self.context performBlockAndWait:^{
        success = [self.context save:&error];
    }];
    
    if (!success) {
        XCTFail(@"Got failure when saving to the context");
    }
    
    if (error) {
        XCTFail(@"Got error when saving to the context: %@", error);
    }
}

- (void)configureArcaPersistentStoreCoordinator {
    NSError *error;
    
    [ArcaPersistentStoreCoordinator setDefaultCoordinator:[[ArcaPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel]];
    [[ArcaPersistentStoreCoordinator defaultCoordinator] setupDefaultStores:&error];
    self.persistentStoreCoordinator = [ArcaPersistentStoreCoordinator defaultCoordinator];
    
    if (error) {
        XCTFail(@"Got error when setting up the default coordinator: %@", error);
    }
    
    self.context = [[ArcaContextFactory defaultFactory] privateQueueContext];
}

- (void)restoreTestingPersistentStoreCoordinator {
    self.persistentStoreCoordinator = self.testingPersistentStoreCoordinator;
    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.context.persistentStoreCoordinator = self.persistentStoreCoordinator;
}

@end
