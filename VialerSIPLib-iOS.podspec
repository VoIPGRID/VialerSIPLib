#
# Be sure to run `pod lib lint VialerSIPLib.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
	s.name             	= "VialerSIPLib-iOS"
	s.version          	= "0.0.32"
	s.summary          	= "Vialer SIP Library for iOS"
	s.description      	= <<-DESC
                                    Objective-C wrapper around PJSIP
                                  DESC

	s.homepage         	= "https://www.wearespindle.com"
	s.license          	= 'GNU GPL v3'
	s.author           	= {"Devhouse Spindle" => "hello@wearespindle.com"}

	s.source           	= {:git => "https://github.com/VoIPGRID/VialerSIPLib-iOS.git", :tag => s.version.to_s}
	s.social_media_url 	= "https://twitter.com/wearespindle"

	s.platform     		= :ios, '9.0'
	s.requires_arc 		= true

	s.source_files 		= "Pod/Classes/**/*.{h,m}"
	s.public_header_files   = "Pod/Classes/**/*.h"

        s.resource_bundles  = { 'VialerSIPLib-iOS' => 'Pod/Resources/*.wav' }

	s.dependency 'Vialer-pjsip-iOS'
	s.dependency 'CocoaLumberjack', '~> 2.2'
        s.dependency 'Reachability'
end
