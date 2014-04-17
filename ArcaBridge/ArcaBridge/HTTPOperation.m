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

#import "HTTPOperation.h"
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <objc/runtime.h>

NSString * const HTTPMethodGetString = @"GET";
NSString * const HTTPMethodPutString = @"PUT";
NSString * const HTTPMethodPostString = @"POST";
NSString * const HTTPMethodDeleteString = @"DELETE";
NSString * const HTTPMethodPatchString = @"PATCH";

NSString * const HTTPBodyBoundaryFormat = @"--Boundary+0xAbCdGbOuNdArY\r\nContent-Disposition: form-data; name=\"%@\";\r\nContent-Type:application/json\r\n\r\n";
NSString * const HTTPContentSeparatorBoundryFormat = @"--Boundary+0xAbCdGbOuNdArY\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"attachment.png\"\r\nContent-Type:image/png\r\nContent-Transfer-Encoding: binary\r\n\r\n";
NSString * const HTTPContentFinalBoundary = @"--Boundary+0xAbCdGbOuNdArY--\r\n";

static NSString * const ApplicationJSONMimeIdentifier = @"application/json";
static NSString * const MultiPartMimeIdentifier = @"multipart/form-data; boundary=Boundary+0xAbCdGbOuNdArY";

@protocol ArcaObjectFactoryInterface <NSObject>

/**-----------------------------------------------------------------------------
 Creates or overwrites the objects represented in the source data.
 
 This operates recursively on the source data. If there is a person object with an account that is represented (fully) in the data, an account object will also be created/overwritten and a relationship to the person will be added. It can continue for as many recursion levels as there are represented in your object.
 @param sourceData The array or dictionary that contains the source (i.e. parsed JSON data from a server)
 @param objectClass The class of the objects at the top level of the collection (person, in the example from discussion)
 @param context The NSManagedObjectContext that will be used to create/retrieve the objects
 @param error Any errors that occur will be populated to this address
 
 @return The array of objects that were created or retrieved
 ------------------------------------------------------------------------------*/
+ (NSArray *)objectsFromSourceData:(id)sourceData forObjectClass:(Class)objectClass inContext:(NSManagedObjectContext *)context error:(NSError **)error;

@end

@protocol ArcaContextFactoryInterface <NSObject>

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

@protocol ArcaManagedObjectInterface
/**-----------------------------------------------------------------------------
 The keypath on the object that you will be using for uniqing purposes
 
 Typically, objects will have an identifier (id, person_id, userName, etc) that will be used to uniquely identify them. This is to be subclassed and return the keyPath for that property.
 @return The keyPath of the primary key (uniqueness) property
 ------------------------------------------------------------------------------*/
+ (NSString *)primaryKeyPath;
/**-----------------------------------------------------------------------------
 The actual primary key value for a given object
 
 Unlike the other selectors, this property returns the actual primary key for the object. It is not used for introspection, but for the actual uniqueness checks
 @return The primary key value
 ------------------------------------------------------------------------------*/
- (id)primaryKey;
/**-----------------------------------------------------------------------------
 The object that is responsible for creating object contexts
 
 @return The instance of the context factory class
 ------------------------------------------------------------------------------*/
+ (id<ArcaContextFactoryInterface>)contextFactory;
/**-----------------------------------------------------------------------------
 The object that is responsible for creating managed objects
 
 @return The instance of the object factory class
 ------------------------------------------------------------------------------*/
+ (id<ArcaObjectFactoryInterface>)objectFactory;

@end


@interface HTTPOperation ()

@property (nonatomic, assign) NSInteger networkActivityCount;
@property (nonatomic, readonly) HTTPOperationCompletionBlock userProvidedCompletionBlock;

@property (nonatomic, strong) NSString *entityName;

@end


@implementation HTTPOperation

static NSURL *baseURL;
+ (NSURL *)baseURL {
    return baseURL;
}

+ (void)setBaseURL:(NSURL *)newBaseURL {
    baseURL = newBaseURL;
}

static NSOperationQueue *networkingQueue;
+ (NSOperationQueue *)networkingQueue {
    if (!networkingQueue) {
        networkingQueue = [NSOperationQueue new];
    }
    return networkingQueue;
}

+ (void)setNetworkingQueue:(NSOperationQueue *)newNetworkingQueue {
    networkingQueue = newNetworkingQueue;
}

- (id)init {
    self = [super init];
    [self setCompletionBlock:^(HTTPOperation *__weak HTTPOperation) {
        if (HTTPOperation.entityName && HTTPOperation.method == HTTPMethodGet) {
            Class targetObjectClass = NSClassFromString(HTTPOperation.entityName);
            if ([targetObjectClass conformsToProtocol:@protocol(ArcaManagedObjectInterface)]) {
                NSError *error;
                id<ArcaContextFactoryInterface> contextFactory = [targetObjectClass contextFactory];
                NSManagedObjectContext *managedObjectContext = [contextFactory privateQueueContext];
                id<ArcaObjectFactoryInterface> objectFactory = [targetObjectClass objectFactory];
                [objectFactory objectsFromSourceData:HTTPOperation.returnedObject forObjectClass:targetObjectClass inContext:managedObjectContext error:&error];
                [managedObjectContext save:&error];
            }
        }
    }];
    return self;
}

- (void)main {
    if (self.isCancelled) {
        return;
    }
    
#ifdef OFFLINE_MODE
    self.returnedObject = [self testResponse];
    [self success];
    return;
#endif
    
    NSError *error;
    self.returnedObject = [self performHTTPRequest:&error];
    
    if (self.isCancelled) {
        return;
    }
    
    if (self.HTTPResponse.statusCode >= 200 && self.HTTPResponse.statusCode <= 299) {
        [self success];
    } else {
        [self failure:error];
    }
}

- (BOOL)validateRequest:(NSError **)error {
    if (self.payload && self.method == HTTPMethodGet) {
        if (error) {
            *error = [NSError errorWithDomain:@"Remote Operation"
                                         code:0x01
                                     userInfo:@{NSLocalizedFailureReasonErrorKey : @"You provided a body on a GET method"}];
        }
        return NO;
    }
    return YES;
}

- (void)setCompletionBlock:(HTTPOperationCompletionBlock)completionBlock {
    __weak HTTPOperation *weakSelf = self;
    _userProvidedCompletionBlock = completionBlock;
    [super setCompletionBlock:^{
        if([NSThread isMainThread]) {
            weakSelf.userProvidedCompletionBlock(weakSelf);
        } else {
            HTTPOperation *dispatchSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatchSelf.userProvidedCompletionBlock(dispatchSelf);
            });
        }
    }];
}

- (void)configureForPayload:(id)payload {
    self.payload = payload;
}

- (void)success {
    return;
}

- (void)failure:(NSError *)error {
    return;
}

- (id)testResponse {
    return nil;
}

- (NSData *)formattedBodyData:(NSError **)error {
    return [NSData new];
}

- (void)prepareRequest:(NSMutableURLRequest **)urlRequest error:(NSError **)error {
    NSString *appVersion = [NSString stringWithFormat:@"%@-%@",
                            [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"],
                            [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];
    [*urlRequest setHTTPMethod:[self stringFromOperationMethod:self.method]];
    [*urlRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [*urlRequest setValue:ApplicationJSONMimeIdentifier forHTTPHeaderField:@"Accept"];
    if (self.attachments) {
        [*urlRequest setValue:MultiPartMimeIdentifier forHTTPHeaderField:@"Content-Type"];
    } else {
        [*urlRequest setValue:ApplicationJSONMimeIdentifier forHTTPHeaderField:@"Content-Type"];
    }
    [*urlRequest setValue:appVersion forHTTPHeaderField:@"X-App-Version"];
    for (NSString *headerField in self.additionalHeaders) {
        [*urlRequest setValue:self.additionalHeaders[headerField] forHTTPHeaderField:headerField];
    }
    
    [*urlRequest setHTTPBody:[self formattedBodyData:error]];
}

- (void)addAttachmentsToBodyData:(NSData **)bodyData {
    if (!self.attachments) {
        return;
    }
    
    NSMutableData *bodyDataWithAttachments = [*bodyData mutableCopy];
    
    NSInteger attachmentIndex = 0;
    for (NSString *key in self.attachments) {
        NSString *contentSeparator = [NSString stringWithFormat:HTTPContentSeparatorBoundryFormat, key];
        [bodyDataWithAttachments appendData:[contentSeparator dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyDataWithAttachments appendData:UIImagePNGRepresentation(self.attachments[key])];
        [bodyDataWithAttachments appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        attachmentIndex++;
    }
    [bodyDataWithAttachments appendData:[HTTPContentFinalBoundary dataUsingEncoding:NSUTF8StringEncoding]];
    
    *bodyData = [bodyDataWithAttachments copy];
}

- (id)performHTTPRequest:(NSError **)error {
    if (![self validateRequest:error]) {
        return nil;
    }
    NSMutableURLRequest *HTTPRequest = [NSMutableURLRequest requestWithURL:[self URLForPath:self.path withParameters:self.queryParameters]];
    [self prepareRequest:&HTTPRequest error:error];
    if (*error) {
        return nil;
    }
    [self pushNetworkActivityIndicator];
    NSHTTPURLResponse *HTTPResponse = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:HTTPRequest returningResponse:&HTTPResponse error:error];
    self.HTTPResponse = HTTPResponse;
    [self popNetworkActivityIndicator];
    return responseData;
}

- (NSURL *)URLForPath:(NSString *)path withParameters:(NSDictionary *)parameters {
    if (parameters) {
        if (self.method == HTTPMethodGet || self.method == HTTPMethodDelete) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@",baseURL, path, [self encodeParameters:parameters]]];
            return url;
        }
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", baseURL, path]];
}

- (NSString *)encodeParameters:(NSDictionary *)parameters {
    NSMutableString *parametersString = [NSMutableString string];
    for (NSString *key in [parameters allKeys]) {
        NSString *p = parameters[key];
        [parametersString appendFormat:@"&%@=%@",key,p];
    }
    return parametersString;
}

- (void)configureForFetchingEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate error:(NSError *__autoreleasing *)error {
    self.entityName = entityName;
    self.method = HTTPMethodGet;
    self.path = [NSString stringWithFormat:@"%@s", entityName];
}

#pragma mark - Enumeration Conversion Selectors
- (NSString *)stringFromOperationMethod:(HTTPMethod)method {
    switch (method) {
        case HTTPMethodGet:
            return HTTPMethodGetString;
        case HTTPMethodDelete:
            return HTTPMethodDeleteString;
        case HTTPMethodPost:
            return HTTPMethodPostString;
        case HTTPMethodPut:
            return HTTPMethodPutString;
        case HTTPMethodPatch:
            return HTTPMethodPatchString;
        default:
            return @"";
    }
}

- (HTTPMethod)operationMethodFromString:(NSString *)string {
    if ([string isEqualToString:HTTPMethodGetString]) {
        return HTTPMethodGet;
    } else if ([string isEqualToString:HTTPMethodPostString]) {
        return HTTPMethodPost;
    } else if ([string isEqualToString:HTTPMethodPutString]) {
        return HTTPMethodPut;
    } else if ([string isEqualToString:HTTPMethodDeleteString]) {
        return HTTPMethodDelete;
    } else if ([string isEqualToString:HTTPMethodPatchString]) {
        return HTTPMethodPatch;
    } else {
        [NSException raise:NSInternalInconsistencyException format:@"Invalid value passed for method"];
        return -1;
    }
}

#pragma mark - Network Activity Selectors
- (void)pushNetworkActivityIndicator {
    self.networkActivityCount++;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
}

- (void)popNetworkActivityIndicator {
    self.networkActivityCount--;
    
    if (self.networkActivityCount < 0) {
        NSLog(@"** Unbalanced calls to push/pop network activity **");
        self.networkActivityCount = 0;
    }
    
    if (self.networkActivityCount == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    }
}

@end


