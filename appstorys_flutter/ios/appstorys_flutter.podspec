#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint appstorys_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'appstorys_flutter'
  s.version          = '1.0.0-alpha07'
  s.summary          = 'AppStorys Flutter plugin — campaign delivery SDK.'
  s.description      = <<-DESC
    Flutter plugin for AppStorys: delivers in-app campaigns (banners, modals,
    surveys, CSAT, floaters, spin-the-wheel, scratch cards, stories, tooltips)
    powered by the AppStorys shared-core KMP library.
  DESC
  s.homepage         = 'https://appversal.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Appversal' => 'support@appversal.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # AppStorysCore.xcframework — built from shared-core on macOS:
  #   ./gradlew :shared-core:assembleReleaseXCFramework
  # Copy the output to ios/Frameworks/ and uncomment the line below.
  # s.vendored_frameworks = 'Frameworks/AppStorysCore.xcframework'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                       => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
