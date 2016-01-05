The Vialer PJSIP pod exposes the <a href="http://www.pjsip.org/">PJSIP</a> library as Cocoapod.

The most important part of the project is the "vialerbuild" script. It will:
- download a specified version of PJSIP from SVN.
- compile PJSIP for all iOS architectures.
- build a fat static library.
- wrap the fat library in a framework.

#### Usage:
You can add the pod to your framework by defining the source for the spec in you podfile:
```ruby
source 'https://github.com/VoIPGRID/PrivatePodSpecs-iOS.git'
```
and add:
```ruby
pod 'Vialer-pjsip-iOS'
```

#### Current issues:
When using the pod as a dependency in another podspec, linting generates the following error:
```
The 'Pods' target has transitive dependencies that include static binaries: VialerPJSIP.framework
```
As a workaround you can use
```
pod spec lint --use-libraries
```
