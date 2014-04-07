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
//Created by Adrian Kemp on 2014-01-27.

#pragma mark - NSException Names
NSString * const MissingObjectModel = @"Missing Object Model";
NSString * const MissingImplementation = @"Missing implemtation";
NSString * const InvalidNilArgument = @"Argument is nil";
NSString * const PrivateConcurrencyParent = @"Invalid Parent Context";
NSString * const InitializeStaticClass = @"Static class initialization";

#pragma mark - NSException Reasons
NSString * const MissingObjectModelDescription = @"Cannot find the object model requested";
NSString * const PrivateConcurrencyParentDescription = @"Private concurrency contexts cannot be parents";

#pragma mark - Core Data Error Domain
NSString * const CoreDataErrorDomain = @"CoreDataErrorDomain";

#pragma mark Codes
NSInteger const InvalidContextErrorCode = 0x01;
NSInteger const InvalidSchemaNameErrorCode = 0x02;
NSInteger const MissingSchemaErrorCode = 0x03;
NSInteger const InvalidSchemaErrorCode = 0x04;
#pragma mark Descriptions

#pragma mark - Object Error Domain
NSString * const ObjectErrorDomain = @"ObjectErrorDomain";

#pragma mark  Codes
NSInteger const InvalidMappingErrorCode = 0x01;
NSInteger const MissingObjectDefinition = 0x02;

#pragma mark Descriptions
NSString * const MissingObjectDefinitionDescription = @"Could not create object.";

#pragma mark - Data Error Domain
NSString * const DataErrorDomain = @"DataErrorDomain";

#pragma mark Codes
NSInteger const InvalidDataErrorCode = 0x01;
NSInteger const UnfulfilledMappingErrorCode = 0x02;

#pragma mark Descriptions
NSString * const JustAWarningDescription = @"Warning (non-fatal error)";

NSString * const MissingMappingsErrorDescription = @"Cannot find all mappings for the source data";
NSString * const ArrayOfArraysErrorDescription = @"Cannot support arrays directly within arrays (should be an array of dictionaries)";
