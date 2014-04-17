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
//Created by Adrian Kemp on 2013-04-16

#import "HTTPJSONOperation.h"

NSDictionary static *NSDictionaryRemoveNSNulls(NSDictionary *dictionary);
NSArray static *NSArrayRemoveNSNulls(NSArray *array);
id static NSCollectionRemoveNSNulls(id collection);

@implementation HTTPJSONOperation

- (id)performRequest:(NSError **)error {
    NSData *responseData = [super performHTTPRequest:error];
    
    NSString *connectionErrorString = nil;
    if ((*error)) {
        connectionErrorString = (*error).localizedDescription;
        return nil;
    }
    [NSHTTPCookie cookiesWithResponseHeaderFields:[self.HTTPResponse allHeaderFields] forURL:[NSURL URLWithString:@"/"]];
    
    if (self.HTTPResponse == nil && error) {
        *error = [NSError errorWithDomain:@"Remote Operation"
                                     code:0x03
                                 userInfo:@{NSLocalizedFailureReasonErrorKey : @"No response returned for operaiton"}];
        return nil;
    }
    
    if (responseData.length > 0) {
        id returnedObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
        self.returnedObject = NSCollectionRemoveNSNulls(returnedObject);
    }
    
    return self.returnedObject;
}


- (NSData *)formattedBodyData:(NSError **)error {
    
    if (self.bodyJSON == nil) {
        return [NSData new];
    }
    
    if (self.attachments) {
        NSMutableData *multiPartFriendlyObjectData = [NSMutableData new];
        for (NSString *fullyQualifiedKey in self.bodyJSON) {
            NSString *boundaryString = [NSString stringWithFormat:HTTPBodyBoundaryFormat, fullyQualifiedKey];
            [multiPartFriendlyObjectData appendData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
            [multiPartFriendlyObjectData appendData:[self.bodyJSON[fullyQualifiedKey] dataUsingEncoding:NSUTF8StringEncoding]];
            [multiPartFriendlyObjectData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
        return [multiPartFriendlyObjectData copy];
    } else {
        return [NSJSONSerialization dataWithJSONObject:self.bodyJSON
                                               options:NSJSONWritingPrettyPrinted error:error];
    }
}

- (void)configureForPayload:(id)payload {
    if ([payload isKindOfClass:[NSDictionary class]]) {
        self.bodyJSON = payload;
    } else {
        [[NSException exceptionWithName:@"Invalid Collection Type" reason:@"You passed an unrecognized collection type" userInfo:nil] raise];
    }

}

- (void)setPayload:(NSDictionary *)payload {
    self.bodyJSON = payload;
}

- (NSDictionary *)payload {
    return self.bodyJSON;
}

@end

NSDictionary static *NSDictionaryRemoveNSNulls(NSDictionary *dictionary) {
    BOOL argumentWasMutable = [dictionary isKindOfClass:[NSMutableDictionary class]];
    
    NSMutableDictionary *returnDictionary = [dictionary mutableCopy];
    for (NSString *key in dictionary) {
        id value = dictionary[key];
        if([value isKindOfClass:[NSNull class]]) {
            [returnDictionary removeObjectForKey:key];
        } else {
            returnDictionary[key] = NSCollectionRemoveNSNulls(value);
        }
    }
    
    if (argumentWasMutable) {
        return [returnDictionary mutableCopy];
    } else {
        return [returnDictionary copy];
    }
}

NSArray static *NSArrayRemoveNSNulls(NSArray *array) {
    BOOL argumentWasMutable = [array isKindOfClass:[NSMutableArray class]];
    
    NSMutableArray *returnArray = [array mutableCopy];
    for (__autoreleasing id value in array) {
        if([value isKindOfClass:[NSNull class]]) {
            [returnArray removeObject:value];
        } else {
            NSUInteger index = [returnArray indexOfObject:value];
            [returnArray replaceObjectAtIndex:index withObject:NSCollectionRemoveNSNulls(value)];
        }
    }
    
    if(argumentWasMutable) {
        array = [returnArray mutableCopy];
    } else {
        array = [returnArray copy];
    }
    return array;
}

id static NSCollectionRemoveNSNulls(id collection) {
    if ([collection isKindOfClass:[NSDictionary class]]) {
        return NSDictionaryRemoveNSNulls(collection);
    } else if([collection isKindOfClass:[NSArray class]]) {
        return NSArrayRemoveNSNulls(collection);
    } else {
        return collection;
    }
}