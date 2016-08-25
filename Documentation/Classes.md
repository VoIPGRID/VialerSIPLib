Classes (W.I.P)
===============

Here is a brief overview of the main classes in this library.

### VialerSIPLib

The library is setup in such a way that there is one entrypoint to the functionality in the app. VialerSIPLib has a singleton which is set on [VialerSIPLib sharedInstance].
With this instance you can setup the Endpoint & accounts and make & receive calls. When you want to use the library, it should be enough to import the header file of this class.

### VSLEndpoint

Singleton object that will be created & configured via VialerSIPLib instance. The endpoint will talk to you SIP provider.

### VSLAccount

Object that will hold the information regarding your SIP account. It holds credentials, calls and registration status.

### VSLCall

Object that represents a call. The properties can be used in KVO to get updates about the call status. When there is an incoming call, an instance of this class will be given to the callback.
