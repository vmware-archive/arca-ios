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
//Created by Adrian Kemp on 2013-12-18

#import <Foundation/Foundation.h>

typedef enum {
    HTTPMethodGet,
    HTTPMethodPut,
    HTTPMethodPost,
    HTTPMethodDelete,
    HTTPMethodPatch
} HTTPMethod;

@protocol ArcaBridgeAdaptorOperationInterface
@property (nonatomic, strong) id objectSourceId;
@property (nonatomic, strong) NSDictionary *payload;

- (void)configureForFetchingEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate error:(NSError **)error;
@end

@class HTTPOperation;
typedef void (^HTTPOperationCompletionBlock)(__weak HTTPOperation *HTTPOperation);
@interface HTTPOperation : NSOperation <ArcaBridgeAdaptorOperationInterface>

#pragma mark - Callback Properties
//@property (nonatomic, weak) id <HTTPOperationSyncDelegate> syncDelegate;

#pragma mark - Response Properties
@property (nonatomic, strong) NSHTTPURLResponse *HTTPResponse;
@property (nonatomic, assign) Class expectedReturnType;
@property (nonatomic, strong) id returnedObject;

#pragma mark - Request Properties
@property (nonatomic, assign) HTTPMethod method;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSDictionary *additionalHeaders;
@property (nonatomic, readonly) NSMutableDictionary *queryParameters;
@property (nonatomic, strong) NSDictionary *bodyJSON;
@property (nonatomic, strong) NSDictionary *attachments;

+ (NSOperationQueue *)networkingQueue;
+ (NSURL *)baseURL;
+ (void)setBaseURL:(NSURL *)baseURL;

- (void)configureForData:(id)collection;
- (void)success;
- (void)failure:(NSError *)error;
- (void)setCompletionBlock:(HTTPOperationCompletionBlock)completionBlock;
- (id)testResponse;

@end
