#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'vtmap_gl'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  #s.dependency 'MapboxAnnotationExtension', '~> 0.0.1-beta.1'
  #s.dependency 'Mapbox-iOS-SDK', '~> 5.6.0'

  s.dependency 'ViettelMapAnnotationExtension', '~> 0.0.1'
  s.dependency 'ViettelMapSDK', '~> 1.0.3'
  s.dependency 'ViettelMapGeocoder', '~> 1.0.19'
  s.dependency 'ViettelMapDirections', '~> 1.0.3'
  s.dependency 'ViettelMapNavigation'
  #s.swift_version = '5.0'
  s.ios.deployment_target = '10.0'
end

