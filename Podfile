target "CleverSDK" do
  platform :ios, "8.0"
  inhibit_all_warnings!

  pod "AFNetworking", "~> 3.1"
  pod "PocketSVG", "~> 0.7"
  pod "SAMKeychain", "~> 1.5"

  target "CleverSDKTests" do
    inherit! :search_paths

    pod "CleverSDK", :path => "./"
    pod "Specta", "~> 1.0"
    pod "Expecta", "~> 1.0"
  end
end
