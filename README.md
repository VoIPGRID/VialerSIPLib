# VialerSIPLib

<!--- [![CI Status](http://img.shields.io/travis/wearespindle/VialerSIPLib.svg?style=flat)](https://travis-ci.org/wearespindle/VialerSIPLib) -->
[![Version](https://img.shields.io/cocoapods/v/VialerSIPLib.svg?style=flat)](https://cocoapods.org/pods/VialerSIPLib)
[![License](https://img.shields.io/cocoapods/l/VialerSIPLib.svg?style=flat)](https://opensource.org/licenses/GPL-3.0)
[![Platform](https://img.shields.io/cocoapods/p/VialerSIPLib.svg?style=flat)](https://cocoapods.org/pods/VialerSIPLib)

We've created a better wrapper for the PJSIP library. 

Why did we make a new wrapper for the PJSIP library? Previous implementations we found ([Gossip](https://github.com/chakrit/gossip), [Swig](https://github.com/petester42/swig) & [Telephone](https://github.com/eofster/Telephone)) had a primary goal to keep the SIP connection and registration up to date. Because a mobile app is switching networks and connections all the time, it is not possible to keep the SIP registration correct. Since iOS 8, Apple strongly advised to start using VoIP push notification and not to try keep the connection alive all the time. 
And because we think adjusting one of the libraries wouldn’t do the trick, we decided to make our own wrapper. This library is created as a cocoapod to make inclusion in your app dead simple. Many thanks and credits go to the creators of PJSIP and the people who created the wrappers around it. 
But now it is our turn. And we would like your help. We try to make the wrapper as general as possible, so please use it the way you want to use it. If you think you can help improving this library, please send us an email or create a pull-request. We will respond asap.

We use this library in our own app, [Vialer](https://www.vialerapp.com). To make sure we always have a correct version of PJSIP, we created our own cocoapod named [Vialer-pjsip-iOS](https://github.com/voipgrid/Vialer-pjsip-iOS).

## Status

In active development.

## Usage

### Requirements

- Cocoapods
- iOS 10.0 or greater
- [Git lfs](https://github.com/git-lfs/git-lfs/wiki/Installation)

### Installation

VialerSIPLib is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
    platform :ios, '10.0'
    pod 'VialerSIPLib'
```

When you are having trouble that your app can't compile because of a linker error.
Try this because of the VialerSIPLIB is now requiring git-lfs.
Clear the cache of cocoapods which is located at: `/Users/$USER/Library/Caches/CocoaPods`
Thanks to phatblat from this thread [CocoaPods/CocoaPods#4801](https://github.com/CocoaPods/CocoaPods/issues/4801)

### Running

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Rename `Keys.sample.swift` from the Example/VialerSIPLib directory to Keys.swift and add your personal credentials. You can now run a the library with a very basic UI.

For more information on how to get started, read the [Getting Started Guide](Documentation/GettingStarted.md).

### Documentation

We try to be as extensive as possible for our documentation. [Your can find them here](Documentation/README.md). Or check out our [CocoaDocs](http://cocoadocs.org/docsets/VialerSIPLib/).

#### Roadmap

We want to be clear on what we will build and what progress we're making. Please check [our goals](Documentation/Goals.md) and [roadmap](Documentation/Goals.md#roadmap-v10---mvp).

## Contributing

See the [CONTRIBUTING.md](CONTRIBUTING.md) file on how to contribute to this project.

We would really like to have you involved in the project. Please contact us at vialersiplib@wearespindle.com, or create a pull request.

## Contributors

See the [Credits](Documentation/Credits.md) file for a list of contributors to the project.

Devhouse Spindle, vialersiplib@wearespindle.com

For more credits & contributions, please see [Credits & Documentation](Documentation/Credits.md).

## Roadmap

### Changelog

The changelog can be found in the [CHANGELOG.md](CHANGELOG.md) file.

### In progress

- Stability for incoming phonecalls
- Overall stability in the app
- Refactor to Swift here code is touched

### Future

- Secure calling
- Videocalling

## Get in touch with a developer

If you want to report an issue see the [CONTRIBUTING.md](CONTRIBUTING.md) file for more info.

We will be happy to answer your other questions at vialersiplib@wearespindle.com or insert alias.

## License

VialerSIPLib is made available under the GNU General Public License v3.0 license. See the [LICENSE file](LICENSE) for more info.
