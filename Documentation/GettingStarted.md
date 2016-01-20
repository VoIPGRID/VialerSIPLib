_Getting started with the VialerSIPLib._

***

There are 3 steps to getting started with the library.

1. Add the VialerSIPLib files to your project
2. Create and configure the library
3. Add an Account to the library
4. Set callback to accept incoming calls

After these steps, the library is up and running and ready for action. We suggest that you create a proper middleware setup that will push a VoIP notification to the app. The app should call `[VialerSIPLib sharedInstance] registerAccount:]` when receiving the notification to make sure there is a proper registration.

#### 1. Add the VialerSIPLib to your project

##### CocoaPods

```ruby
    platform :ios, '9.0'
    pod 'VialerSIPLib'
```

#### 2. Create and configure the library

Configure the library with an Endpoint Configuration. At this moment, we have some difficulties with TCP connections, so we stick to UDP. After you configured the library, it is started automatically.

```objective-c
    VSLEndpointConfiguration *endpointConfiguration = [[VSLEndpointConfiguration alloc] init];
    VSLTransportConfiguration *updTransportConfiguration = [VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeUDP];

    endpointConfiguration.transportConfigurations = @[updTransportConfiguration];

    NSError *error;
    BOOL success = [[VialerSIPLib sharedInstance] configureLibraryWithEndPointConfiguration:endpointConfiguration error:&error];
    if (!success || error) {
        NSLog(@"Failed to startup VialerSIPLib: %@", error);
    }
```

#### 3. Add an Account to the library

Add a user to the libary. The user can be of any class, as long the calls implements the `SIPEnabledUser` protocol. We suggest to set `sipRegisterOnAdd` to NO. This will prevent pjsip to register at the provided domain.

```objective-c
    SipUser *testUser = [[SipUser alloc] init];
    testUser.sipUsername = KeysUsername;
    testUser.sipPassword = KeysPassword;
    testUser.sipDomain = KeysDomain;
    testUser.sipProxy = KeysProxy;
    testUser.sipRegisterOnAdd = NO;

    NSError *error;
    [[VialerSIPLib sharedInstance] createAccountWithSipUser:testUser error:&error];
    if (error) {
        NSLog(@"Failed to create Account: %@", error);
    }
```

#### 4. Set callback for incoming calls

```objective-c
TODO
```
