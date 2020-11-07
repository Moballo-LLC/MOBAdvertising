# MOBAdvertising
MOBAdvertising is an easy-to-use, drop-in wrapper for Google AdMob Banner Ads. Simply wrap your app in MOBAdvertising to display ads on the bottom in a jiffy.
***
## Import with CocoaPods
```
  use_frameworks!
  pod 'MOBAdvertising'
```
***
## Initialization and Setup
### Info.plist
- Define `GADApplicationIdentifier` to be your app's GAD Application Identifier
- Add and customize the following keys:
```
<key>NSUserTrackingUsageDescription</key>
<string>This app is expensive to develop and distribute. We rely on personalized advertising to gain sufficient revenue to continue development and support.</string>
<key>SKAdNetworkItems</key>
  <array>
    <dict>
      <key>SKAdNetworkIdentifier</key>
      <string>cstr6suwn9.skadnetwork</string>
    </dict>
  </array> <key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsForMedia</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```
### AppDelegate.swift
#### At the top of the file
```
import MOBAdvertising
var bannerViewControllered: MOBAdvertisingBanner!
```
#### Inside of "application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool"
```
bannerViewControllered = MOBAdvertisingBanner(view: (self.window?.rootViewController)!, AdUnitID: "YOUR ADMOB AD UNIT ID", ShouldShowAd: true, TestAdDevices: [String]?)
self.window!.rootViewController = bannerViewControllered;
self.window?.makeKeyAndVisible()
```
***
## To Show/Hide Ads
```
bannerViewControllered.hideBannerView()
or
bannerViewControllered.showBannerView()
```
***
Easy as pie! Enjoy!

