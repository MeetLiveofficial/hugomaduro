#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'gpupixel_flutter'
  s.version          = '1.0.0'
  s.summary          = 'GPUPixel beauty bridge for Flutter'
  s.description      = 'Native GPUPixel pipeline with Flutter Texture + MethodChannel.'
  s.homepage         = 'https://meetlive.online'
  s.license          = { :type => 'Apache-2.0' }
  s.author           = { 'Krimson' => 'dev@meetlive.online' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.vendored_frameworks = 'Frameworks/gpupixel.framework'
  s.frameworks = 'AVFoundation', 'CoreMedia', 'CoreVideo', 'OpenGLES', 'UIKit'
  s.library = 'c++'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'OTHER_CPLUSPLUSFLAGS' => '-fcxx-modules',
  }
  s.swift_version = '5.0'
end
