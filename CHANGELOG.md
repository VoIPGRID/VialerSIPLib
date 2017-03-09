# Changelog
All notable changes to this project will be documented in this file.

---
## [2.6.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.5.0) (01/24/2017)
Released on Thursday, March 9, 2017.

#### Added
* Video support (#54)[https://github.com/VoIPGRID/VialerSIPLib/pull/54]
* Make vibration toggable (#64)[https://github.com/VoIPGRID/VialerSIPLib/pull/64]

#### Fixed
* Sipproxy can be set to nil (#60)[https://github.com/VoIPGRID/VialerSIPLib/pull/60]
* Check if completion block are present before calling (#63)[https://github.com/VoIPGRID/VialerSIPLib/pull/63]
* When destroying pjsip, app doesn't crash (#68, #70)[https://github.com/VoIPGRID/VialerSIPLib/pull/70]
* When call is declined, proper SIP response is sent. (#75)[https://github.com/VoIPGRID/VialerSIPLib/pull/75]


## [2.5.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.5.0) (01/24/2017)
Released on Tuesday, January 24, 2017.

#### Added
* Notifications are sent when a call was accepted or rejected through CallKit (#55)[https://github.com/VoIPGRID/VialerSIPLib/pull/55]
* Documentation of the repo had a cleanup (#56)[https://github.com/VoIPGRID/VialerSIPLib/pull/56]
* Getting started guide was updated for Objective C example for intents extension (ddec838)[https://github.com/VoIPGRID/VialerSIPLib/commit/ddec838a8b64f7f6ebe83e13732aeb001d56e502]


## [2.4.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.4.0) (01/18/2017)
Released on Wednesday, January 18, 2017.

#### Added
* Added custom ringtone if file is present (#49)[https://github.com/VoIPGRID/VialerSIPLib/pull/49]

#### Fixed
* Remove if check on error pointer when creating VSLCall (#49)[https://github.com/VoIPGRID/VialerSIPLib/pull/49]


## [2.3.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.3.0) (01/18/2017)
Released on Wednesday, January 18, 2017.

#### Added
* Show stats after call in example app (#46)[https://github.com/VoIPGRID/VialerSIPLib/pull/46]
* Added log callback so that implementing app can get logs (#47)[https://github.com/VoIPGRID/VialerSIPLib/pull/47]


## [2.2.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.2.0) (01/13/2017)
Released on Friday, January 13, 2017.

#### Added
* Enable TCP or UDP switch in the Example app (#42)[https://github.com/VoIPGRID/VialerSIPLib/pull/42]

#### Fixed
* VSLAudiocontroller forward declaration is replaced by importing header. (#37)[https://github.com/VoIPGRID/VialerSIPLib/pull/37]
* Start monitoring network changes after the call started. (#38)[https://github.com/VoIPGRID/VialerSIPLib/pull/38]
* Update VIA headers when sending reINVITES. (#38)[https://github.com/VoIPGRID/VialerSIPLib/pull/38]
* When transport is on UDP, transport isn't shutdown on network change. (#38)[https://github.com/VoIPGRID/VialerSIPLib/pull/38]
* Proximity sensor is activated when the call is active (#41)[https://github.com/VoIPGRID/VialerSIPLib/pull/41]


## [2.1.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.1.0) (01/09/2017)
Released on Monday, January 9, 2017.

#### Added
* Bluetooth routes can be changed (#26)[https://github.com/VoIPGRID/VialerSIPLib/pull/26]


#### Fixed
* Updated documentation (#24)[https://github.com/VoIPGRID/VialerSIPLib/pull/24]
* Start network monitoring only when there is a call active (#34)[https://github.com/VoIPGRID/VialerSIPLib/pull/34]
* Network changes are delayed a little to prevent multiple register attempts (8c4c96a)[https://github.com/VoIPGRID/VialerSIPLib/commit/8c4c96ac76c4535abf47629dfe23b2c74a6498c7]


## [2.0.1](https://github.com/VoIPGRID/VialerSIPLib/tree/2.0.1) (12/09/2016)
Released on Friday, December 9, 2016.

#### Fixed
* Fixed networkmonitoring (again)(#22)[https://github.com/VoIPGRID/VialerSIPLib/pull/22]
* Show correct number in dialscreen (#23)[https://github.com/VoIPGRID/VialerSIPLib/pull/23]


## [2.0.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.0.0) (12/08/2016)
Released on Thursday, December 8, 2016.

#### Added
* Integration for CallKit
* add support media and sip stun (#15)[https://github.com/VoIPGRID/VialerSIPLib/pull/15]

#### Fixed
* Fixed networkmonitoring (0085628)[https://github.com/VoIPGRID/VialerSIPLib/commit/0085628e0c7737fee7cf80cba587261a966e944e]
* Better control over tcp connection (14e3eb7)[https://github.com/VoIPGRID/VialerSIPLib/commit/14e3eb75a9f2f3cfe3ea16cd7590a14214b6ef9e]
