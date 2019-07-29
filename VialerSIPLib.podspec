#
# Be sure to run `pod lib lint VialerSIPLib.podspec --use-libraries' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
	s.name             	= "VialerSIPLib"
	s.version          	= "3.5.6"
	s.summary          	= "Vialer SIP Library for iOS"
	s.description      	= "Objective-C wrapper around PJSIP."
	s.homepage         	= "https://github.com/VoIPGRID/VialerSIPLib"
	s.license          	= 'GNU GPL v3'
	s.author           	= {"Devhouse Spindle" => "vialersiplib@wearespindle.com"}

	s.source           	= {:git => "https://github.com/VoIPGRID/VialerSIPLib.git", :tag => s.version.to_s}
	s.social_media_url 	= "https://twitter.com/wearespindle"

	s.platform     		= :ios, '9.0'
	s.requires_arc 		= true

	s.source_files 		= "Pod/Classes/**/*.{h,m}"
	s.public_header_files   = "Pod/Classes/**/*.h"

	s.resource_bundles  = { 'VialerSIPLib' => 'Pod/Resources/*.wav' }

	s.dependency 'Vialer-pjsip-iOS'
	s.dependency 'CocoaLumberjack'
    s.dependency 'Reachability'
end
