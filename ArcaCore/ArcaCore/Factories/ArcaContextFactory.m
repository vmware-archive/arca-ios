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
//Created by Adrian Kemp on 2014-01-19

#import <CoreData/CoreData.h>
#import "ArcaPersistentStoreCoordinator.h"
#import "ArcaContextFactory.h"
#import "ErrorConstants.h"

@interface ArcaContextFactory ()

@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;

@end

@implementation ArcaContextFactory

static ArcaContextFactory *defaultFactory;
+ (ArcaContextFactory *)defaultFactory {
    if (!defaultFactory) {
        defaultFactory = [[self alloc] init];
    }
    return defaultFactory;
}

+ (void)setDefaultFactory:(ArcaContextFactory *)factory {
    defaultFactory = factory;
    if (defaultFactory == nil) {
        [defaultFactory resetMainThreadContext];
    }
}

- (id)init {
    self = [super init];
    return self;
}

#pragma mark - Context Creators

- (void)resetMainThreadContext {
    _mainThreadContext = nil;
}

- (BOOL)mainThreadContextExists {
    return _mainThreadContext != nil;
}

- (NSManagedObjectContext *)mainThreadContext {
    if (!_mainThreadContext && [ArcaPersistentStoreCoordinator defaultCoordinator]) {
            _mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            _mainThreadContext.persistentStoreCoordinator = [ArcaPersistentStoreCoordinator defaultCoordinator];
    }
    return _mainThreadContext;
}

- (NSManagedObjectContext *)privateQueueContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [ArcaPersistentStoreCoordinator defaultCoordinator];
    return context;
}

- (NSManagedObjectContext *)childContextForContext:(NSManagedObjectContext *)parentContext {
    if (parentContext.concurrencyType == NSPrivateQueueConcurrencyType) {
        [[NSException exceptionWithName:PrivateConcurrencyParent reason:PrivateConcurrencyParentDescription userInfo:@{}] raise];
        return nil;
    }
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = parentContext;
    return context;
}

@end
