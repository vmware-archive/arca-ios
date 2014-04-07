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

#import <Foundation/Foundation.h>

/**-----------------------------------------------------------------------------
 The collection of selectors that is required by other components in Arca
 ------------------------------------------------------------------------------*/
@protocol ArcaContextFactoryCompatibilityInterface <NSObject>

/**-----------------------------------------------------------------------------
 An NSManagedObjectContext with the default persistent store, and a concurrency type of main queue
 
 The context is lazy loaded, and will be nilled any time the factory itself is destroyed
 @return The main thread NSManagedObjectContext
 ------------------------------------------------------------------------------*/
- (NSManagedObjectContext *)mainThreadContext;

/**-----------------------------------------------------------------------------
 Creates and returns an NSManagedObjectContext with the default persistent store and a concurrency type of private queue
 
 This selector creates a new NSManagedObjectContext each time it is called
 @return A private queue NSManagedObjectContext
 ------------------------------------------------------------------------------*/
- (NSManagedObjectContext *)privateQueueContext;

@end

/**-----------------------------------------------------------------------------
 The collection of selectors that an object must export in order to function as a (replacement to) ArcaContextFactory
 ------------------------------------------------------------------------------*/
@protocol ArcaContextFactoryInterface <ArcaContextFactoryCompatibilityInterface>

/**-----------------------------------------------------------------------------
 Convenience access to an omnipresent factory
 
 This function simply calls [[self alloc] init] to create the default factory, and so does not need to be altered even by a subclass
 @return The default static factory 
 ------------------------------------------------------------------------------*/
+ (id <ArcaContextFactoryInterface>)defaultFactory;

/**-----------------------------------------------------------------------------
 Creates and returns an NSManagedObjectContext with the given parent context, and a concurrency type of private queue
 
 This selector creates a new NSManagedObjectContext each time it is called
 @param parentContext must be a mainQueueConcurrency type context
 @warning This selector will throw an exception if passed a private queue type parent (as this will ultimately cause your app to hang due to a semaphore)
 @return A private queue NSManagedObjectContext
 ------------------------------------------------------------------------------*/
- (NSManagedObjectContext *)childContextForContext:(NSManagedObjectContext *)parentContext;

@end

/**-----------------------------------------------------------------------------
 Used to provide an omnipresent main thread NSManagedObjectContext, as well as simplifying the creation of both standalone and child contexts.
 
 ### Subclassing Notes

 You probably do not need to subclass ArcaContextFactory. If you should desire to, you may want to expose some of the private methods (via a class extension in your .m file).
 
 Methods you may want/need to export
 
     + (void)setDefaultFactory
     - (void)resetMainThreadContext
     - (BOOL)mainThreadContextExists
------------------------------------------------------------------------------**/
@interface ArcaContextFactory : NSObject <ArcaContextFactoryInterface>

@end