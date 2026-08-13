#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
# Linking pattern mirrors deepar_flutter_plus (preserve_paths + xcconfig OTHER_LDFLAGS).
# Also pass the dylib by path so a bad FRAMEWORK_SEARCH_PATHS cannot drop the link.
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
  s.source_files     = 'Classes/**/*.{h,m,mm}'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.preserve_paths = 'Frameworks/gpupixel.framework/**/*'
  s.vendored_frameworks = 'Frameworks/gpupixel.framework'
  s.frameworks = 'AVFoundation', 'CoreMedia', 'CoreVideo', 'OpenGLES', 'UIKit', 'Foundation'
  s.libraries = 'c++'

  gpupixel_dylib = '"$(PODS_TARGET_SRCROOT)/Frameworks/gpupixel.framework/gpupixel"'
  link_flags = "$(inherited) -framework gpupixel -lc++ #{gpupixel_dylib}"

  # Same shape as deepar_flutter_plus: force the vendored dylib onto the link line.
  s.xcconfig = {
    'OTHER_LDFLAGS' => "-framework gpupixel -lc++ #{gpupixel_dylib}",
    'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/Frameworks"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(PODS_TARGET_SRCROOT)/Frameworks"',
    'OTHER_LDFLAGS' => link_flags,
  }

  s.user_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(PODS_ROOT)/../.symlinks/plugins/gpupixel_flutter/ios/Frameworks"',
    'OTHER_LDFLAGS' => '$(inherited) -framework gpupixel -lc++',
  }

  s.swift_version = '5.0'
end
