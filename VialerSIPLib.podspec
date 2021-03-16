Pod::Spec.new do |s|
	s.name             	= "VialerSIPLib"
	s.version          	= "3.7.3"
	s.summary          	= "Vialer SIP Library for iOS"
	s.description      	= "Objective-C wrapper around PJSIP."
	s.homepage         	= "https://github.com/VoIPGRID/VialerSIPLib"
	s.license          	= 'GNU GPL v3'
	s.author           	= {"Devhouse Spindle" => "opensource@wearespindle.com"}

	s.source           	= {:git => "https://github.com/VoIPGRID/VialerSIPLib.git", :tag => s.version.to_s}
	s.social_media_url 	= "https://twitter.com/wearespindle"

	s.platform     		= :ios, '10.0'
	s.requires_arc 		= true

	s.source_files 		= "Pod/Classes/**/*.{h,m}"
	s.public_header_files   = "Pod/Classes/**/*.h"

	s.resource_bundles  = { 'VialerSIPLib' => 'Pod/Resources/*.wav' }
	s.static_framework = true

	s.dependency 'Vialer-pjsip-iOS', '~> 3.5s'
	s.dependency 'CocoaLumberjack'
    s.dependency 'Reachability'
end
