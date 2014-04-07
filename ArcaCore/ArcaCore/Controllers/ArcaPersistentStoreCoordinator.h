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

#import <CoreData/CoreData.h>

/**-----------------------------------------------------------------------------
Used to provide access to the persistent store coordiantor, and for easy setup when the app being developed uses the standard settings for the data model
 ------------------------------------------------------------------------------*/
@interface ArcaPersistentStoreCoordinator : NSPersistentStoreCoordinator

/**-----------------------------------------------------------------------------
 Ominpresent accessor for the default persistent store coordiantor
 
 This is used heavily within the framework, so if you do choose to create your own store coordinator, be sure to set it as the default using the +setDefaultCoordinator selector
 @return The default persistent store coordinator
 ------------------------------------------------------------------------------*/
+ (ArcaPersistentStoreCoordinator *)defaultCoordinator;
/**-----------------------------------------------------------------------------
 Setter for the default persistent store coordiantor, to allow for customizing the coordinator as needed by your application
 @warning You must, and should only, use this setter whenever you stray from the default coordinator provided by the framework. You might do so when you require data models in non standard bundles, for instance.
 @param coordinator The new coordinator to be used by the framework
 ------------------------------------------------------------------------------*/
+ (void)setDefaultCoordinator:(ArcaPersistentStoreCoordinator *)coordinator;
/**-----------------------------------------------------------------------------
 Convenience selector for retrieving a managedObjectModel given a name and bundle
 
 If bundle is nil, the main bundle will be checked. ModelName cannot be nil
 @param modelName The name of the model (excluding the extension)
  @param bundle The NSBundle where the model can be found (for a nil value, the main bundle will be used)
  @param error Any errors that occur will be populated to this address
 @return The NSManagedObjectModel found for the name and bundle provided, or nil
 ------------------------------------------------------------------------------*/
+ (NSManagedObjectModel *)managedObjectModelNamed:(NSString *)modelName inBundle:(NSBundle *)bundle error:(NSError **)error;
/**-----------------------------------------------------------------------------
 A lookup function to determine the NSEntityDescription that is mapped to a given class
 
 NSEntityDescriptions provide the class that they are associated with, this allows the reverse lookup to be done. The mapping is generated once whenever the default coordinator is set
 @param class The class to retrieve the entity description for
 @return The NSEntityDescription that maps to the class provided
 ------------------------------------------------------------------------------*/
+ (NSEntityDescription *)entityForClass:(Class)class;
/**-----------------------------------------------------------------------------
 A convenience method for configuring a default sqllite3 store.
 
 If a custom persistent store coordinator is needed, but the standard storage system will suffice, you can use this selector to set them up easily
 @param error Any errors that occur will be populated to this address
 @return A boolean indicating success or failure
 ------------------------------------------------------------------------------*/
- (BOOL)setupDefaultStores:(NSError **)error;

@end
