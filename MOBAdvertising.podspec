Pod::Spec.new do |s|
    s.name             = 'MOBAdvertising'
    s.version          = '6.1.0'
    s.summary          = 'A wrapper for GogleMobileAds that allows one to present banner ads that show with any application, including a tab bar application'
    s.homepage         = 'https://github.com/Moballo-LLC/MOBAdvertising'
    s.license          = 'MIT'
    s.author           = { 'Jason Morcos - Moballo, LLC' => 'jason.morcos@moballo.com' }
    s.source           = { :git => 'https://github.com/Moballo-LLC/MOBAdvertising.git', :tag => s.version.to_s }

    s.platforms = { :ios => "10.0" }
    s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'EXCLUDED_ARCHS[sdk=iphoneos*]' => 'x86_64' }
    s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'EXCLUDED_ARCHS[sdk=iphoneos*]' => 'x86_64' }
    s.swift_version = '5.0'
    s.dependency 'Google-Mobile-Ads-SDK', '~> 7.68'

    s.static_framework = true

    s.weak_framework = 'UIKit'
    s.weak_framework = 'AVFoundation'
    s.weak_framework = 'AudioToolbox'
    s.weak_framework = 'CFNetwork'
    s.weak_framework = 'CoreGraphics'
    s.weak_framework = 'CoreMedia'
    s.weak_framework = 'CoreMotion'
    s.weak_framework = 'CoreTelephony'
    s.weak_framework = 'CoreVideo'
    s.weak_framework = 'MediaPlayer'
    s.weak_framework = 'MessageUI'
    s.weak_framework = 'CoreServices'
    s.weak_framework = 'QuartzCore'
    s.weak_framework = 'Security'
    s.weak_framework = 'StoreKit'
    s.weak_framework = 'SystemConfiguration'
    s.weak_framework = 'AdSupport'
    s.weak_framework = 'SafariServices'
    s.weak_framework = 'WebKit'
    s.weak_framework = 'GoogleMobileAds'
    s.weak_framework = 'UserMessagingPlatform'

    s.source_files  = ['_Project/Sources/**/*.swift']
end
