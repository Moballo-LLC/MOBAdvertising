Pod::Spec.new do |s|
    s.name             = 'MOBAdvertising'
    s.version          = '9.0.0'
    s.summary          = 'Consent-gated adaptive Google Mobile Ads banners for UIKit applications'
    s.homepage         = 'https://github.com/Moballo-LLC/MOBAdvertising'
    s.license          = 'MIT'
    s.author           = { 'Jason Morcos - Moballo, LLC' => 'jason.morcos@moballo.com' }
    s.source           = { :git => 'https://github.com/Moballo-LLC/MOBAdvertising.git', :tag => s.version.to_s }

    s.platforms = { :ios => "13.0" }
    s.swift_version = '5.0'
    s.dependency 'Google-Mobile-Ads-SDK', '13.6.0'
    s.dependency 'GoogleUserMessagingPlatform', '3.1.0'

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
