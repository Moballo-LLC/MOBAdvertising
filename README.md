# MOBAdvertising

MOBAdvertising is a UIKit wrapper for consent-gated, anchored adaptive Google
Mobile Ads banners. Version 9 requires iOS 13 or later and coordinates UMP,
App Tracking Transparency, Mobile Ads startup, and banner loading in that order.

## CocoaPods

```ruby
use_frameworks!
pod 'MOBAdvertising', '9.0.0'
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

Failed consent refreshes fail closed and retry while an active banner remains
requested. Interrupted ATT prompts and transient banner failures use bounded
retries; hiding the banner cancels pending per-banner retry work.
