# Changelog

All notable changes to this project will be documented in this file.

---
## [3.5.5](https://github.com/VoIPGRID/VialerSIPLib/tree/3.5.5) (22/5/2019)

Released on Wednesday, May 22, 2019

### Fixed
- Removed sending unsupported UPDATE sip message.

## [3.5.4](https://github.com/VoIPGRID/VialerSIPLib/tree/3.5.4) (15/4/2019)

Released on Monday, April 15, 2019

### Added
- Enabled Voice Activity Detection

## [3.5.3](https://github.com/VoIPGRID/VialerSIPLib/tree/3.5.3) (3/4/2019)

Released on Tuesday, April 3, 2019

### Fixed
- Resolved a crash that would sometimes happen when muting a call
- Network changes will no longer reset the mute status of a call

## [3.5.2](https://github.com/VoIPGRID/VialerSIPLib/tree/3.5.2) (5/3/2019)

Released on Tuesday, March 5, 2019

### Fixed
- Resolved a crash when trying to make an outgoing call after loading the library for the first time 

## [3.5.1](https://github.com/VoIPGRID/VialerSIPLib/tree/3.5.1) (27/12/2018)

Released on Thursday, December 27, 2018

### Added
- The caller name and number will now be taken from the P-Asserted-Identity or Remote-Party-ID headers if they are present.

## [3.4.2](https://github.com/VoIPGRID/VialerSIPLib/tree/3.4.2) (11/22/2018)

Released on Thursday, November 22, 2018

### Fixed
- Changed the way how in some VSLAccount functions is being checked on invalid accounts

## [3.4.1](https://github.com/VoIPGRID/VialerSIPLib/tree/3.4.1) (11/08/2018)

Released on Thursday, November 8, 2018.

### Fixed

- When account registration returns a Forbidden or Unauthorized remove the account from the endpoint (#163)
- Updated the prioritization that the caller info coming from the PBX has higher priority then the phonebook (#164)

## [3.4.0](https://github.com/VoIPGRID/VialerSIPLib/tree/3.4.0) (09/11/2018)

Released on Thursday, October 11, 2018.

Removed some old deprecated functions for configuring the codecs.
See the Example project on how to configure the codecs for the endpoint.

### Added

- Ability to add a configuration for the OPUS codec. (#156)

## [3.3.4](https://github.com/VoIPGRID/VialerSIPLib/tree/3.3.4) (07/17/2018)

Released on Firday, August 31, 2018.

### Added

- Added check to see if STUN servers are being used

## [3.3.3](https://github.com/VoIPGRID/VialerSIPLib/tree/3.3.3) (07/17/2018)

Released on Tuesday, August 21, 2018.

### Fixed

- Regex update for the Call-ID to prevent crash

## [3.3.2](https://github.com/VoIPGRID/VialerSIPLib/tree/3.3.2) (07/17/2018)

Released on Monday, August 13, 2018.

### Added

- Reinvite calls when there is a new transport created (#153)
- Handle interuptions only during a call (#152)

## [3.3.1](https://github.com/VoIPGRID/VialerSIPLib/tree/3.3.1) (07/17/2018)

Released on Tuesday, July 17, 2018.

### Added

- Post notification when there is an error aftter an register (#149)

## [3.3.0](https://github.com/VoIPGRID/VialerSIPLib/tree/3.3.0) (06/28/2018)

Released on Thursday, June 28, 2018.

### Added

- Add a notification and state for audio during a call. (#145)
- The call-ID is being set in the SIP message is now added to VSLCall. (#144)

## [3.2.0](https://github.com/VoIPGRID/VialerSIPLib/tree/3.2.0) (06/15/2018)

Released on Friday, June 15, 2018.

### Added

- Configurable codecs through the new VSLCodecConfiguration class. (#133)
- Ability to do a blind transfer of a call (#137)
- Build in a check to see if there is audio for call. When there is no audio in the first 10 seconds a notification is posted. (#138)

### Fixed

- First pass of removing the call referencing from the VSLAccount class in favor of the VSLCallManager (#142)
- Some memory managent for the VSLCall and the VSLRingback classes (#142)

## [3.1.3](https://github.com/VoIPGRID/VialerSIPLib/tree/3.1.2) (04/06/2018)

Released on Friday, April 6, 2018.

### Added

- Updated Vialer-pjsip-iOS to the newest version.

### Fixed

- Fix issue when there were no calls possible from the background when video is disabled remove the video codec option from the INVITE (#131)
- Incoming callername not showing #124 (#130)
- Fixed issue that call was not being to release on hold status (#129)

## [3.1.2](https://github.com/VoIPGRID/VialerSIPLib/tree/3.1.2) (03/16/2018)

Released on Tuesday, March 16, 2018.

### Added

- Update Vialer-PJSIP-IOS pod to the newest version

## [3.1.1](https://github.com/VoIPGRID/VialerSIPLib/tree/3.1.1) (03/06/2018)

Released on Tuesday, March 06, 2018.

### Added

- Update Vialer-PJSIP-IOS pod to the newest version

## [3.1.0](https://github.com/VoIPGRID/VialerSIPLib/tree/3.1.0) (02/19/2018)

Released on Monday, February 19, 2018.

### Added

- Ability to use Stun servers.

###

- Fixes for the previous release secure calling. Extra file for the IP Change configuration for PJSIP.

## [3.0.0](https://github.com/VoIPGRID/VialerSIPLib/tree/3.0.0) (01/22/2018)

Released on Monday, Januari 22, 2018.

### Added

- Ability to use secure calling
- Update Vialer-PJSIP-IOS pod to the newest version
- Added possibility to support Stun and Ice through configuration

### Fixed

- Configurable wheter the account needs to be unregistered after a call has been made

## [2.8.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.8.0) (10/25/2017)

Released on Wednesday, October 25, 2017.

### Added

- Vialer-PJSIP-iOS pod update to the newest version

### Fixed

- Some cleanup in a call when this has finished
- Some documentation warnings have been fixed
- Updated the project to XCode 9

## [2.7.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.7.0) (18/09/2017)

Released on

### Added

- Callback for when for missed calls (#96)[https://github.com/VoIPGRID/VialerSIPLib/pull/96]

## [2.6.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.6.0) (03/09/2017)

Released on Thursday, March 9, 2017.

#### Added

- Video support (#54)[https://github.com/VoIPGRID/VialerSIPLib/pull/54]
- Make vibration toggable (#64)[https://github.com/VoIPGRID/VialerSIPLib/pull/64]

#### Fixed

- Sipproxy can be set to nil (#60)[https://github.com/VoIPGRID/VialerSIPLib/pull/60]
- Check if completion block are present before calling (#63)[https://github.com/VoIPGRID/VialerSIPLib/pull/63]
- When destroying pjsip, app doesn't crash (#68, #70)[https://github.com/VoIPGRID/VialerSIPLib/pull/70]
- When call is declined, proper SIP response is sent. (#75)[https://github.com/VoIPGRID/VialerSIPLib/pull/75]

## [2.5.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.5.0) (01/24/2017)

Released on Tuesday, January 24, 2017.

#### Added

- Notifications are sent when a call was accepted or rejected through CallKit (#55)[https://github.com/VoIPGRID/VialerSIPLib/pull/55]
- Documentation of the repo had a cleanup (#56)[https://github.com/VoIPGRID/VialerSIPLib/pull/56]
- Getting started guide was updated for Objective C example for intents extension (ddec838)[https://github.com/VoIPGRID/VialerSIPLib/commit/ddec838a8b64f7f6ebe83e13732aeb001d56e502]

## [2.4.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.4.0) (01/18/2017)

Released on Wednesday, January 18, 2017.

#### Added

- Added custom ringtone if file is present (#49)[https://github.com/VoIPGRID/VialerSIPLib/pull/49]

#### Fixed

- Remove if check on error pointer when creating VSLCall (#49)[https://github.com/VoIPGRID/VialerSIPLib/pull/49]

## [2.3.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.3.0) (01/18/2017)

Released on Wednesday, January 18, 2017.

#### Added

- Show stats after call in example app (#46)[https://github.com/VoIPGRID/VialerSIPLib/pull/46]
- Added log callback so that implementing app can get logs (#47)[https://github.com/VoIPGRID/VialerSIPLib/pull/47]

## [2.2.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.2.0) (01/13/2017)

Released on Friday, January 13, 2017.

#### Added

- Enable TCP or UDP switch in the Example app (#42)[https://github.com/VoIPGRID/VialerSIPLib/pull/42]

#### Fixed

- VSLAudiocontroller forward declaration is replaced by importing header. (#37)[https://github.com/VoIPGRID/VialerSIPLib/pull/37]
- Start monitoring network changes after the call started. (#38)[https://github.com/VoIPGRID/VialerSIPLib/pull/38]
- Update VIA headers when sending reINVITES. (#38)[https://github.com/VoIPGRID/VialerSIPLib/pull/38]
- When transport is on UDP, transport isn't shutdown on network change. (#38)[https://github.com/VoIPGRID/VialerSIPLib/pull/38]
- Proximity sensor is activated when the call is active (#41)[https://github.com/VoIPGRID/VialerSIPLib/pull/41]

## [2.1.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.1.0) (01/09/2017)

Released on Monday, January 9, 2017.

#### Added

- Bluetooth routes can be changed (#26)[https://github.com/VoIPGRID/VialerSIPLib/pull/26]

#### Fixed

- Updated documentation (#24)[https://github.com/VoIPGRID/VialerSIPLib/pull/24]
- Start network monitoring only when there is a call active (#34)[https://github.com/VoIPGRID/VialerSIPLib/pull/34]
- Network changes are delayed a little to prevent multiple register attempts (8c4c96a)[https://github.com/VoIPGRID/VialerSIPLib/commit/8c4c96ac76c4535abf47629dfe23b2c74a6498c7]

## [2.0.1](https://github.com/VoIPGRID/VialerSIPLib/tree/2.0.1) (12/09/2016)

Released on Friday, December 9, 2016.

#### Fixed

- Fixed networkmonitoring (again)(#22)[https://github.com/VoIPGRID/VialerSIPLib/pull/22]
- Show correct number in dialscreen (#23)[https://github.com/VoIPGRID/VialerSIPLib/pull/23]

## [2.0.0](https://github.com/VoIPGRID/VialerSIPLib/tree/2.0.0) (12/08/2016)

Released on Thursday, December 8, 2016.

#### Added

- Integration for CallKit
- add support media and sip stun (#15)[https://github.com/VoIPGRID/VialerSIPLib/pull/15]

#### Fixed

- Fixed networkmonitoring (0085628)[https://github.com/VoIPGRID/VialerSIPLib/commit/0085628e0c7737fee7cf80cba587261a966e944e]
- Better control over tcp connection (14e3eb7)[https://github.com/VoIPGRID/VialerSIPLib/commit/14e3eb75a9f2f3cfe3ea16cd7590a14214b6ef9e]
