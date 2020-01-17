Getting started with the VialerSIPLib (W.I.P.)
==============================================

There are 4 steps to getting started with the library.

1. Add the VialerSIPLib files to your project
2. Create and configure the library
3. Add an Account to the library
4. Set callback to accept incoming calls
5. Create outbound calls

After these steps, the library is up and running and ready for action. We suggest that you create a proper middleware setup that will push a VoIP notification to the app. The app should call `[VialerSIPLib sharedInstance] registerAccount:]` when receiving the notification to make sure there is a proper registration.

### 1. Add the VialerSIPLib to your project

#### CocoaPods

```ruby
    platform :ios, '10.0'
    pod 'VialerSIPLib'
```

### 2. Create and configure the library

Configure the library with an Endpoint Configuration. After you configured the library, it is started automatically.

Objective-C
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

### 3. Add an Account to the library

Add a user to the libary. The user can be of any class, as long the calls implements the `SIPEnabledUser` protocol. We suggest to set `sipRegisterOnAdd` to NO. This will prevent pjsip to register at the provided domain.

Objective-C
```objective-c
    SipUser *testUser = [[SipUser alloc] init];
    testUser.sipAccount = KeysAccount;
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
### 4. Inbound calls

#### 1. AppDelegate - instantiate CallKitProviderDelegate to a private property 

Objective-C
```objective-c
    - (CallKitProviderDelegate *)callKitProviderDelegate {
        if !(_callKitProviderDelegate) { 
            _callKitProviderDelegate = [[CallKitProviderDelegate alloc] initWithCallManager:[[VialerSIPLib sharedInstance].callManager]]; 
        }
        return _callKitProviderDelegate;
    }
```

Swift
```swift
    var providerDelegate: CallKitProviderDelegate?
    providerDelegate = CallKitProviderDelegate(callManager: VialerSIPLib.sharedInstance().callManager)
```

#### 2. Adapt the incoming call callback block.

Objective-C
```objective-c
    [VialerSIPLib sharedInstance].incomingCallBlock = ^(VSLCall * _Nonnull call) {
        [self.callKitProviderDelegate reportIncomingCall:call];
    };
```

#### 3. The CallKit provider delegate informs your app about incoming calls through 2 notifications:

- CallKitProviderDelegateOutboundCallStarted
- CallKitProviderDelegateInboundCallAccepted

These notification should be used by your app to display the appropriate calling screen.
When receving this notification, a VSLCall object is sent with it an can by found in the notification's
user info dict with the key: VSLNotificationUserInfoCallKey.
All operations on a VSLCall should now be done through the new VSLCallManager class. This means:
- starting a call to a number
- answering an inbound call
- ending a call
- toggle mute and hold
- sending DTMF tones

You can also query the CallManger for a call based on "UUID" or "PJSIP call ID".

### 5. Outbound calls

Use the new VSLCallManager -startCall function to instantiate an outbound call.

To be able to use the app through a native iOS interface, e.g. recents or contacts, you will need to create an "Intent Extension".
This is done by creating a new "target" and selecting "Intent Extension". You will see a new target and also a folder with the same name as the extension you've just created with 2 files in it (at least for swift) IntentHandler.swift and info.plist.
Replace the contents of IntentHandler.swift with:

Objective-C
```objective-c
#pragma mark - INStartAudioCallIntentHandling
- (void)handleStartAudioCall:(INStartAudioCallIntent *)intent
                  completion:(void (^)(INStartAudioCallIntentResponse *response))completion {
    NSLog(@"HANDLE Audio intent:%@",intent);
    INStartAudioCallIntentResponse *response = nil;
    NSArray<INPerson *> *contacts = intent.contacts;
    INPerson *person = contacts.firstObject;
    if (person.personHandle != nil) {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INStartAudioCallIntent class])];
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeContinueInApp userActivity:userActivity];
    } else {
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailure userActivity:nil];
    }
    completion(response);
}
```
Swift
```swift
    /*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    Abstract:
    Intents handler principal class
    */
    import Intents
    class IntentHandler: INExtension, INStartAudioCallIntentHandling {
        func handle(startAudioCall intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void) {
            let response: INStartAudioCallIntentResponse
            defer { completion(response) }
            // Ensure there is a person handle
            guard intent.contacts?.first?.personHandle != nil else { 
                response = INStartAudioCallIntentResponse(code: .failure, userActivity: nil) 
                return 
            }
            let userActivity = NSUserActivity(activityType: String(describing: INStartAudioCallIntent.self))
            response = INStartAudioCallIntentResponse(code: .continueInApp, userActivity: userActivity)
        }
    }
```

Modifiy the info.plist. The "NSExtension" dictionary item needs te get a "NSExtensionAttributes" item With an Array item called "IntentsSupported" which will get 1 item, a String "Item 0" and it's value should be "INStartAudioCallIntent"

Add the A NSUserActivity Extension to your project. Code -> NSUserActivity+StartCallConvertible.swift
And the class: StartCallConvertible.swift used by the extension.

When the user wants to start an oubound call through the native interface using your app the following app delegate function will be called:

Objective-C
```objective-c
    - (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler;
```

Swift
```swift
    optional func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool
```

You can obtain the phone number through:

Objective-C
```ojective-c
    NSString *handle = userActivity.startCallHandle;
```

Swift
```swift
    let handle = userActivity.startCallHandle
```
Than start a call to the number using the sip lib just like you would do from within your app.
