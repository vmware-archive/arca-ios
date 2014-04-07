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

#pragma mark - NSException Names
extern NSString * const MissingObjectModel;
extern NSString * const MissingImplementation;
extern NSString * const InvalidNilArgument;
extern NSString * const PrivateConcurrencyParent;
extern NSString * const InitializeStaticClass;

#pragma mark - NSException Reasons
extern NSString * const MissingObjectModelDescription;
extern NSString * const PrivateConcurrencyParentDescription;

#pragma mark - Core Data Error Domain
extern NSString * const CoreDataErrorDomain;

#pragma mark Codes
extern NSInteger const InvalidContextErrorCode;
extern NSInteger const InvalidSchemaNameErrorCode;
extern NSInteger const MissingSchemaErrorCode;
extern NSInteger const InvalidSchemaErrorCode;

#pragma mark Descriptions

#pragma mark - Object Error Domain
extern NSString * const ObjectErrorDomain;

#pragma mark  Codes
extern NSInteger const InvalidMappingErrorCode;
extern NSInteger const MissingObjectDefinition;

#pragma mark Descriptions
extern NSString * const MissingObjectDefinitionDescription;

#pragma mark - Data Error Domain 
extern NSString * const DataErrorDomain;

#pragma mark Codes
extern NSInteger const InvalidDataErrorCode;
extern NSInteger const UnfulfilledMappingErrorCode;

#pragma mark Descriptions
extern NSString * const JustAWarningDescription;

extern NSString * const MissingMappingsErrorDescription;
extern NSString * const ArrayOfArraysErrorDescription;