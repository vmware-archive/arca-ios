
#import <Foundation/Foundation.h>

#ifndef HTTP_CRUD_OPERATION_STATE_DEFINITION
#define HTTP_CRUD_OPERATION_STATE_DEFINITION

typedef enum {
    HTTPCRUDOperationSuccessfulState,
    HTTPCRUDOperationSuccessfulWithWarningState,
    HTTPCRUDOperationFailState
} HTTPCRUDOperationState;

#endif

#ifndef HTTP_METHOD_DEFINITION
#define HTTP_METHOD_DEFINITION

typedef enum {
    HTTPMethodPost,
    HTTPMethodGet,
    HTTPMethodPut,
    HTTPMethodDelete,
    HTTPMethodPatch
} HTTPMethod;

#endif

#ifndef HTTP_METHOD_STRING_DEFINITION
#define HTTP_METHOD_STRING_DEFINITION

extern NSString * const HTTPMethodGetString;
extern NSString * const HTTPMethodPutString;
extern NSString * const HTTPMethodPostString;
extern NSString * const HTTPMethodDeleteString;

#endif