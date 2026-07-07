platform :osx, "12.0"

source 'https://github.com/MacDownApp/cocoapods-specs.git'  # Patched libraries.
source 'https://cdn.cocoapods.org/'

project 'MacDown.xcodeproj'

inhibit_all_warnings!

target "MacDown" do
  use_frameworks!

  pod 'handlebars-objc', '~> 1.4'
  pod 'hoedown', '~> 3.0.7', :inhibit_warnings => false
  pod 'JJPluralForm', '~> 2.1'
  pod 'LibYAML', '~> 0.1'
  pod 'M13OrderedDictionary', '~> 1.1'
  pod 'MASPreferences', '~> 1.4'

  # Sparkle 2.x: EdDSA signing, XPC-based installer, hardened-runtime friendly.
  # Requires use_frameworks! (above) and a source-level migration away from
  # SUUpdater to SPUStandardUpdaterController (see MainMenu.xib / MPMainController.m).
  pod 'Sparkle', '~> 2.9', :inhibit_warnings => false

  # No longer locked to 10.8; version bumped as part of dependency modernization.
  pod 'PAPreferences', '~> 0.5'
end

target "MacDownTests" do
  pod 'PAPreferences', '~> 0.5'
end

target "macdown-cmd" do
  pod 'GBCli', '~> 1.1'
end
