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

# Several of the pods above (GBCli, handlebars-objc, hoedown, JJPluralForm,
# LibYAML, M13OrderedDictionary, MASPreferences, PAPreferences) still ship
# with their own, much older MACOSX_DEPLOYMENT_TARGET (as low as 10.6),
# which is below Xcode's currently supported minimum (10.13) and well below
# this project's own target (12.0, set at the top of this file). Xcode
# doesn't build those targets against our deployment target automatically --
# it warns on every build instead. Force every pod sub-target up to ours,
# the same fix macdown3000 applies to the same dependency set.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      deployment_target = config.build_settings['MACOSX_DEPLOYMENT_TARGET']
      if deployment_target && deployment_target.to_f < 12.0
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end
