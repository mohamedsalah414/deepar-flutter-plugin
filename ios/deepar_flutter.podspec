#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint deepar.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'deepar_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Offical Flutter SDK for DeepAR Plugin.'
  s.description      = <<-DESC
Official Flutter SDK for DeepAR Plugin.
                       DESC
  s.homepage         = 'http://deepar.ai'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Deepar.ai' => 'support@deepar.ai' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.resources    = ['Assets/**.*']
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.preserve_paths = 'DeepAR.xcframework/**/*'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework DeepAR' }
  s.vendored_frameworks = 'DeepAR.xcframework'
end
