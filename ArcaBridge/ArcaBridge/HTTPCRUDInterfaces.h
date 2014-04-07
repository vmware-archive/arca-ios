
#ifndef HTTP_CRUD_OPERATION_SYNC_DELEGATE_INTERFACE
#define HTTP_CRUD_OPERATION_SYNC_DELEGATE_INTERFACE

@class HTTPCRUDOperation;

@protocol HTTPCRUDOperationSyncDelegate

- (void)operationFailed:(HTTPCRUDOperation *)operation withError:(NSError *)error;
- (void)operationSucceeded:(HTTPCRUDOperation *)operation;

@end

#endif



