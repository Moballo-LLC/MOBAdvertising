#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "_Project/Sources/MOBAdvertisingBanner.swift").read_text()
spec = (root / "MOBAdvertising.podspec").read_text()
readme = (root / "README.md").read_text()
podfile = (root / "_Project/Podfile").read_text()
lockfile = (root / "_Project/Podfile.lock").read_text()
project = (root / "_Project/MOBAdvertising.xcodeproj/project.pbxproj").read_text()
info_plist = (root / "_Project/Sources/Info.plist").read_text()

required_in_order = [
    "requestConsentInfoUpdate",
    "loadAndPresentIfRequired",
    "requestTrackingAuthorization",
    "MobileAds.shared.start",
    "bannerView.load(request)",
]
positions = [source.index(item) for item in required_in_order]
assert positions == sorted(positions), "Consent, ATT, SDK startup, and ad loading are out of order"
assert 'ca-app-pub-3940256099942544/2435281174' in source
assert '#elseif targetEnvironment(simulator)' in source
assert 'bannerView.isAutoloadEnabled = false' in source
assert 'ConsentInformation.shared.canRequestAds' in source
assert 'allowed: false,\n                        retryableFailure: true' in source
assert 'allowed: formError == nil && ConsentInformation.shared.canRequestAds' in source
assert 'Configured Moballo banner; demo=' in source
assert 'Moballo banner loaded successfully' in source
assert 'retryableFailure' in source
assert 'authorizationRetryAttempts < 3' in source
assert 'sharedTrackingRetryAttempts < 3' in source
assert 'UIApplication.didBecomeActiveNotification' in source
assert 'bannerRetryAttempts < 5' in source
assert 'scheduleBannerRetryIfNeeded()' in source
assert 'guard self.shouldBeShown, self.isViewVisible' in source
assert 'requestedBannerWidth = availableWidth' in source
assert 'requestedWidthMatchesCurrentLayout' in source
assert 'replaceBannerView()' in source
assert 'NotificationName.privacyChoicesDidChange' in source
assert 'selector: #selector(privacyChoicesDidChange)' in source
assert 'name: NotificationName.privacyChoicesDidChange' in source
assert '@objc private func privacyChoicesDidChange()' in source
assert '''public var shouldOfferPrivacyOptions: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }''' in source
assert 'bannerView.delegate = nil' in source
assert 'bannerView = BannerView(adSize: AdSizeBanner)' in source
assert source.count('guard bannerView === self.bannerView else { return }') == 2
assert 'lastLaidOutAvailableWidth = availableWidth' in source
assert 'availableWidthChanged' in source
assert 'previousBounds?.width != view.bounds.width' not in source
assert "Google-Mobile-Ads-SDK', '13.6.0'" in spec
assert "GoogleUserMessagingPlatform', '3.1.0'" in spec
assert 'ios => "13.0"' in spec
assert "platform :ios, '13.0'" in podfile
assert "pod 'Google-Mobile-Ads-SDK', '13.6.0'" in podfile
assert "pod 'GoogleUserMessagingPlatform', '3.1.0'" in podfile
assert 'Google-Mobile-Ads-SDK (13.6.0)' in lockfile
assert 'GoogleUserMessagingPlatform (3.1.0)' in lockfile
assert project.count('CURRENT_PROJECT_VERSION = 9000;') == 2
assert project.count('MARKETING_VERSION = 9.0.0;') == 2
assert 'IPHONEOS_DEPLOYMENT_TARGET = 10.0;' not in project
assert 'FRAMEWORK_SEARCH_PATHS = "";' not in project
assert 'HEADER_SEARCH_PATHS = "";' not in project
assert 'OTHER_LDFLAGS = "";' not in project
assert '<string>6.0</string>' in info_plist
assert "pod 'MOBAdvertising', '9.0.0'" in readme
assert 'MOBALLO_USE_TEST_ADS=1' in readme
assert 'does not require\narbitrary-load ATS exceptions' in readme
print("MOBAdvertising consent and demo-routing policy passed")
