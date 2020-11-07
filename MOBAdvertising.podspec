Pod::Spec.new do |s|
    s.name             = 'MOBAdvertising'
    s.version          = '6.0.0'
    s.summary          = 'A wrapper for GogleMobileAds that allows one to present banner ads that show with any application, including a tab bar application'
    s.homepage         = 'https://github.com/Moballo-LLC/MOBAdvertising'
    s.license          = 'MIT'
    s.author           = { 'Jason Morcos - Moballo, LLC' => 'jason.morcos@moballo.com' }
    s.source           = { :git => 'https://github.com/Moballo-LLC/MOBAdvertising.git', :tag => s.version.to_s }

    s.platforms = { :ios => "10.0" }
    s.pod_target_xcconfig = {
        'VALID_ARCHS' => 'arm64',
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.user_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.swift_version = '5.0'

    s.static_framework = true
    s.dependency 'Google-Mobile-Ads-SDK', '~> 7.68'

    s.framework = 'UIKit'
    s.framework = 'GoogleMobileAds'
    s.framework = 'AVFoundation'
    s.framework = 'AudioToolbox'
    s.framework = 'CFNetwork'
    s.framework = 'CoreGraphics'
    s.framework = 'CoreMedia'
    s.framework = 'CoreMotion'
    s.framework = 'CoreTelephony'
    s.framework = 'CoreVideo'
    s.framework = 'MediaPlayer'
    s.framework = 'MessageUI'
    s.framework = 'CoreServices'
    s.framework = 'QuartzCore'
    s.framework = 'Security'
    s.framework = 'StoreKit'
    s.framework = 'SystemConfiguration'
    s.weak_framework = 'AdSupport'
    s.weak_framework = 'SafariServices'
    s.weak_framework = 'WebKit'

    s.source_files  = ['_Project/Sources/**/*.swift']
end
