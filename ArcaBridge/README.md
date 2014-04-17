>#ArcaBridge
>Remote Data, Locally

ArcaBridge is the glue that lets ArcaCore and ArcaSync work together. It is a package of operations that can be registered and kicked off when data needs to be transferred between your local store and your remote store.

Included are HTTP operations for common tasks, and in the future that may extend to include operations for more elaborate tasks or even different protocols. You can easily subclass the existing operations, or create completely new ones by implementing the provided interfaces.

##Key Features
- Register operations with the bridge adaptor to customize how data is sent and recieved from the remote store.
- A sensible default configuration provides immediate out-of-the-box compatibility with a rails-like RESTful server.
- Requests for new data, and updates to existing data are automatically converted to operations.