#
# Be sure to run `pod lib lint VialerSIPLib.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "VialerSIPLib"
s.version          = "0.0.1"
s.summary          = "PJSIP for ios"
s.description      = <<-DESC
Other pods for pjsip wrapper were not doing wat we needed. pjsip shouldn't stay connected all the time.
DESC
s.homepage         = "https://github.com/voipgrid/VialerSIPLib.git"
s.license          = 'MIT'
s.author           = { "Devhouse Spindle" => "hello@wearespindle.com" }
s.source           = { :git => "https://github.com/voipgrid/VialerSIPLib.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/wearespindle'

s.platform     = :ios, '9.0'
s.requires_arc = false

s.source_files = 'Pod/**/*.{h,m}'
s.public_header_files = 'Pod/**/*.{h,hpp}'

s.vendored_libraries = 'Pod/lib/*.a'

s.frameworks = 'CFNetwork', 'AudioToolbox', 'AVFoundation'

s.dependency 'CocoaLumberjack', '2.0.0-rc'

s.header_mappings_dir = 'Pod'

s.xcconfig = {
'GCC_PREPROCESSOR_DEFINITIONS' => 'PJ_AUTOCONF=1',
'LIBRARY_SEARCH_PATHS' => '$(PODS_ROOT)/VialerSIPLib/Pod/lib/',
'HEADER_SEARCH_PATHS' => "$(PODS_ROOT)/Headers/Public/VialerSIPLib/lib/include/**",
'ALWAYS_SEARCH_USER_PATHS' => 'YES'
}

end