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
assert 'googleConsentForCookiesKey = "gad_has_consent_for_cookies"' in source
assert 'UserDefaults.standard.set(0, forKey: googleConsentForCookiesKey)' in source
assert 'UserDefaults.standard.removeObject(forKey: googleConsentForCookiesKey)' in source
assert 'finishSharedConsentAfterTransientFailure()' in source
assert 'finishSharedConsent(mode: .limited, retryableFailure: true)' in source
assert 'finishSharedConsent(mode: mode, retryableFailure: false)' in source
assert 'private enum AdServingMode' in source
assert 'case currentConsent' in source
assert 'case limited' in source
assert 'case unavailable' in source
assert 'private var isAdServingPermitted: Bool' in source
assert '''case .limited:
            return true
        case .currentConsent:
            return ConsentInformation.shared.canRequestAds
        case .unavailable:
            return false''' in source
assert source.count('isAdServingPermitted') >= 4
assert 'Configured Moballo banner; demo=' in source
assert 'Moballo banner loaded successfully' in source
assert 'retryableFailure' in source
assert 'authorizationRetryAttempts < 3' in source
assert 'refreshConsentWhileServingLimited()' in source
assert 'guard adServingMode == .limited' in source
assert 'acceptExistingLimitedFallback: Bool = true' in source
assert 'if acceptExistingLimitedFallback, sharedConsentMode == .limited' in source
assert 'acceptExistingLimitedFallback: false' in source
assert 'authorizationRetryAttempts = max(0, authorizationRetryAttempts - 1)' in source
assert source.count('if adServingMode == .limited {') >= 2
assert 'if !Self.sharedMobileAdsStarted {' in source
assert 'self.startMobileAds(generation: generation)' in source
assert '''case .limited:
                self.startMobileAds(generation: generation) { [weak self] in''' in source
assert source.index('self.startMobileAds(generation: generation) { [weak self] in') < source.index('self.scheduleAuthorizationRetry()')
assert '''self.authorizationStarted = false
            self.authorizationComplete = true''' in source
assert 'authorizationGeneration += 1' in source
assert source.count('self.authorizationGeneration == generation') >= 3
assert '''if authorizationComplete {
            if adServingMode == .limited {
                scheduleAuthorizationRetry()
            }
            if !adLoaded || pendingAdLoad {
                loadBannerIfPossible()
            }
            return
        }''' in source
assert 'sharedTrackingRetryAttempts < 3' in source
assert 'UIApplication.didBecomeActiveNotification' in source
assert 'presentSharedConsentFormWhenActive(from: presenter)' in source
assert 'sharedConsentDidBecomeActiveObserver' in source
assert 'guard UIApplication.shared.applicationState == .active else' in source
assert 'stopObservingSharedConsentApplicationActivation()' in source
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
assert 'selector: #selector(applicationDidBecomeActive)' in source
assert '@objc private func applicationDidBecomeActive()' in source
assert source.count('UIApplication.shared.applicationState == .active') >= 3
assert '''if !adLoaded || pendingAdLoad {
                loadBannerIfPossible()
            }
        } else {
            beginAuthorizationIfNeeded()
        }''' in source
assert '''authorizationStarted = false
        authorizationComplete = false
        adServingMode = nil
        authorizationGeneration += 1
        authorizationRetryAttempts = 0
        authorizationRetryScheduled = false''' in source
assert '''let mode: AdServingMode = ConsentInformation.shared.canRequestAds
                    ? .currentConsent
                    : .unavailable''' in source
assert 'finishSharedConsent(mode: mode, retryableFailure: false)' in source
assert '''case .unavailable:
                self.authorizationStarted = false
                self.authorizationComplete = true''' in source
assert '''case .unavailable:
                self.pendingAdLoad = false''' in source
assert 'A successful UMP denial is global.' in source
assert '''case .currentConsent:
                self.authorizationRetryAttempts = 0''' in source
assert source.count('name: NotificationName.privacyChoicesDidChange') >= 2
assert 'Every live banner must leave its local limited mode together.' in source
privacy_options = source.split('public func presentPrivacyOptions(from presenter: UIViewController)', 1)[1].split('@objc private func privacyChoicesDidChange()', 1)[0]
assert 'guard error == nil else' in privacy_options
assert 'Self.activateLimitedAdFallback()' not in privacy_options
assert privacy_options.index('guard error == nil else') < privacy_options.index('Self.invalidateSharedConsentDecision()')
assert '''public var shouldOfferPrivacyOptions: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }''' in source
assert 'bannerView.delegate = nil' in source
assert 'bannerRetryAttempts = 0' in source
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
assert project.count('CURRENT_PROJECT_VERSION = 9001;') == 2
assert project.count('MARKETING_VERSION = 9.0.1;') == 2
assert 'IPHONEOS_DEPLOYMENT_TARGET = 10.0;' not in project
assert 'FRAMEWORK_SEARCH_PATHS = "";' not in project
assert 'HEADER_SEARCH_PATHS = "";' not in project
assert 'OTHER_LDFLAGS = "";' not in project
assert '<string>6.0</string>' in info_plist
assert "pod 'MOBAdvertising', '9.0.1'" in readme
assert 'MOBALLO_USE_TEST_ADS=1' in readme
assert 'does not require\narbitrary-load ATS exceptions' in readme
assert 'request limited\n  ads' in readme
assert 'successful UMP flow is authoritative' in readme
assert '`canRequestAds == false`' in readme
assert "paid/ad-free entitlement is absolute" in readme
assert "Never use production inventory for QA" in readme
print("MOBAdvertising consent and demo-routing policy passed")
