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

#import <UIKit/UIKit.h>
#import "ArcaPersistentStoreCoordinator.h"
#import "ArcaContextFactory.h"
#import "ErrorConstants.h"

@interface ArcaContextFactory ()

+ (void)setDefaultFactory:(ArcaContextFactory *)factory;

@end

@interface ArcaPersistentStoreCoordinator ()

@end

@implementation ArcaPersistentStoreCoordinator

static ArcaPersistentStoreCoordinator *defaultCoordinator;
+ (ArcaPersistentStoreCoordinator *)defaultCoordinator {
    if (!defaultCoordinator) {
        NSString *objectModelName = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
        NSError *error;
        NSManagedObjectModel *objectModel = [ArcaPersistentStoreCoordinator managedObjectModelNamed:objectModelName inBundle:nil error:&error];
        if (error) {
            NSLog(@"ArcaCore: data model load failure: %@", error.localizedDescription);
        } else {
            NSLog(@"ArcaCore: data model loaded successfully");
        }
        error = nil;
        [self setDefaultCoordinator:[[ArcaPersistentStoreCoordinator alloc] initWithManagedObjectModel:objectModel]];
        [[self defaultCoordinator] setupDefaultStores:&error];
        if (error) {
            NSLog(@"ArcaCore: default persistent store setup failure: %@", error.localizedDescription);
        } else {
            NSLog(@"ArcaCore: default store setup succeeded");
        }

    };
    return defaultCoordinator;
}

+ (void)setDefaultCoordinator:(ArcaPersistentStoreCoordinator *)coordinator {
    defaultCoordinator = coordinator;
    if (coordinator == nil) {
        [ArcaContextFactory setDefaultFactory:nil];
        [self setEntitiesByClass:nil];
        return;
    }
    NSMutableDictionary *entitiesByClass = [NSMutableDictionary new];
    NSDictionary *entitiesByName = coordinator.managedObjectModel.entitiesByName;
    for (NSEntityDescription *entityName in entitiesByName) {
        entitiesByClass[entityName] = entitiesByName[entityName];
    }
    [self setEntitiesByClass:entitiesByClass];
}

static NSDictionary *entitiesByClass;
+ (NSEntityDescription *)entityForClass:(Class)class {
    return entitiesByClass[NSStringFromClass(class)];
}

+ (void)setEntitiesByClass:(NSDictionary *)entities {
    entitiesByClass = entities;
}

+ (NSManagedObjectModel *)managedObjectModelNamed:(NSString *)modelName inBundle:(NSBundle *)bundle error:(NSError **)error {
    if (modelName == nil) {
        if (error) {
            *error = [NSError errorWithDomain:CoreDataErrorDomain code:InvalidSchemaNameErrorCode userInfo:@{}];
        }
        return nil;
    }
    if (bundle == nil) {
        bundle = [NSBundle mainBundle];
    }

    NSURL *objectModelURL = [bundle URLForResource:modelName withExtension:@"momd"];
    if (!objectModelURL) {
        if (error) {
            *error = [NSError errorWithDomain:CoreDataErrorDomain code:MissingSchemaErrorCode userInfo:@{}];
        }
        return nil;
    }
    
    NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:objectModelURL];
    if (!objectModel && error) {
        *error = [NSError errorWithDomain:CoreDataErrorDomain code:InvalidSchemaErrorCode userInfo:@{}];
    }
    
    return objectModel;
}

- (BOOL)setupDefaultStores:(NSError **)error {
    NSDictionary *defaultStoreOptions = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                                          NSInferMappingModelAutomaticallyOption : @YES};
    

    NSString *storeURLDirectory = [self defaultPersistentStoreDirectory:error];

    if (![[NSFileManager defaultManager] fileExistsAtPath:storeURLDirectory isDirectory:NULL]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:storeURLDirectory withIntermediateDirectories:YES attributes:nil error:error]) {
            return NO;
        }
    }
    
    NSURL *storeURL = [self defaultPersistentStoreURL:error];

    if (!storeURL) {
        return NO;
    }
    if (![self addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:defaultStoreOptions error:error]) {
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        [userInfo setValue:storeURL forKey:@"storeURL"];
        *error = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:[userInfo copy]];
        return NO;
    }
    
    return YES;
}

- (NSString *)defaultPersistentStoreDirectory:(NSError **)error {
    NSString *documentsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:error].path;
#ifdef TESTING
    static NSString *UUID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFUUIDRef CFUUID = CFUUIDCreate(NULL);
        CFStringRef CFString = CFUUIDCreateString(NULL, CFUUID);
        CFRelease(CFUUID);
        UUID = (__bridge NSString *)CFString;
    });
    documentsDirectory = [NSString stringWithFormat:@"%@%@/",NSTemporaryDirectory(), UUID];
#endif
    return [documentsDirectory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL *)defaultPersistentStoreURL:(NSError **)error {
    NSString *storeLocation = [NSString stringWithFormat:@"file://%@/%@", [self defaultPersistentStoreDirectory:error], @"ArcaDefaultStore.CDBStore"];
    return [NSURL URLWithString:storeLocation];
}

@end
