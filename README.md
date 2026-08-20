# MOBAdvertising

MOBAdvertising is a UIKit wrapper for consent-gated, anchored adaptive Google
Mobile Ads banners. Version 9 requires iOS 13 or later and coordinates UMP,
App Tracking Transparency, Mobile Ads startup, and banner loading in that order.

## CocoaPods

```ruby
use_frameworks!
pod 'MOBAdvertising', '9.0.1'
```

## Host configuration

Add the app's production Google Mobile Ads application identifier to its
`Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-…~…</string>
```

If the app requests tracking authorization, add an accurate
`NSUserTrackingUsageDescription`. Keep Google's current SKAdNetwork inventory
in the host app when the app uses attribution. MOBAdvertising does not require
arbitrary-load ATS exceptions; do not add them for the SDK.

Publish the appropriate UMP consent and privacy-options messages in AdMob. The
SDK cannot create that server-side configuration.

## App setup

```swift
import MOBAdvertising

private var bannerController: MOBAdvertisingBanner?

func installBanner(around contentController: UIViewController) {
    let controller = MOBAdvertisingBanner(
        view: contentController,
        AdUnitID: "YOUR PRODUCTION BANNER UNIT ID"
    )
    bannerController = controller
    window?.rootViewController = controller
    window?.makeKeyAndVisible()
}
```

Debug and Simulator builds use Google's anchored-adaptive demo unit. A physical
Release build uses the supplied production unit unless its launch environment
contains `MOBALLO_USE_TEST_ADS=1`. Interact with a creative only after it is
visibly labeled as a test ad.

## Visibility and privacy options

```swift
bannerController?.hideBannerView()
bannerController?.showBannerView()

if bannerController?.shouldOfferPrivacyOptions == true {
    bannerController?.presentPrivacyOptions(from: presentingViewController)
}
```

## Revenue-safe privacy behavior

- Refresh UMP on every process launch before deciding how to request ads.
- When the current UMP flow completes and permits requests, remove any manual
  limited-ad override, request ATT only when the host asks for it, and let
  Google's current decision choose the highest-value eligible serving mode.
- If the UMP update or required form cannot complete, set Google's documented
  `gad_has_consent_for_cookies` signal to `0`, skip ATT, and request limited
  ads. Do not gate this error-only manual LTD path on a stale `canRequestAds`
  value; that value becomes authoritative after the current UMP flow completes
  successfully. Continue bounded UMP recovery attempts without withdrawing an
  already eligible limited banner.
- A successful UMP flow is authoritative. If it completes with
  `canRequestAds == false`, remove any manual limited-ad override and do not
  request ads until the user changes their privacy choices.
- A host's paid/ad-free entitlement is absolute. Call `hideBannerView()` and do
  not instantiate another ad surface for an entitled user; the limited fallback
  must never bypass that product promise.
- Never use production inventory for QA. Debug, Simulator, and explicit
  `MOBALLO_USE_TEST_ADS=1` runs use Google's demo unit.

Interrupted ATT prompts and transient banner failures use bounded retries;
hiding the banner cancels pending per-banner retry work. Host apps remain
responsible for accurate App Store privacy answers, a published Google consent
message, and any jurisdiction-specific legal requirements.
