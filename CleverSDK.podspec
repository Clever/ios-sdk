#
# Be sure to run `pod lib lint CleverSDK.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name              = "CleverSDK"
  # Version is also set in CLVCleverSDK.h, please keep them in sync
  s.version           = "1.0.0"
  s.summary           = "A simple iOS library to access Clever Instant Login"
  s.description       = <<-DESC
  CleverSDK provides developers with a simple library to access Clever Instant Login.
  The SDK includes a Login handler (the `CLVOAuthManager`) and a Login Button (the 'CLVLoginButton') that can be added to any `UIView`.
  The SDK returns an `access_token` to the user that can be used to make calls to the Clever API.
  DESC
  s.homepage          = "https://github.com/Clever/ios-sdk"
  s.license           = 'Apache 2.0'
  s.authors           = { "Nikhil Pandit" => "nikhil.pandit@clever.com", "Alex Smolen" => "alex.smolen@clever.com", "Peter Nga" => "peter.nga@clever.com", "Dylan Hurd" => "dylan.hurd@clever.com", "Clever Support" => "tech-support@clever.com" }
  s.source            = { :git => "https://github.com/Clever/ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url  = 'https://twitter.com/clever'
  s.documentation_url = "https://dev.clever.com/"

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'CleverSDK/Classes/**/*'

  s.public_header_files = 'CleverSDK/Classes/**/*.h'
  s.dependency 'AFNetworking', '~> 3.1'
  s.dependency "PocketSVG", "~> 0.7"
  s.dependency "SAMKeychain", "~> 1.5"
end
