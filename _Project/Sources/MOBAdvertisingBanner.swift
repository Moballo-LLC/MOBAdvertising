//
//  AdBannerController.swift
//  MOBAdvertising
//
//  Created by Jason Morcos on 11/23/16.
//  Copyright © 2016 CBTech. All rights reserved.
//


#if canImport(GoogleMobileAds)
    import UIKit
    import GoogleMobileAds
    #if canImport(AppTrackingTransparency)
    import AppTrackingTransparency
    #endif
    import AdSupport

    public class MOBAdvertisingBanner: UIViewController, GADBannerViewDelegate {
        @objc var adUnitID:String!
        @objc var bannerView:GADBannerView!
        @objc var borderView:UIView!
        @objc var backgroundView:UIView!
        @objc var adLoaded = false
        @objc var shouldBeShown = false
        @objc var presentingAd = false
        @objc var contentController:UIViewController!
        var frameSavedBannerView:CGRect!
        var pendingFrameChange = false
        @objc let DidPresentAd = "com.moballo.advertising.adPresented"
        @objc let DidUnpresentAd = "com.moballo.advertising.adUnpresented"
        @objc var testDevices:[String] = [String]()
        @objc var simulatedDevices:[String] = [String]()
        @objc var shouldRequestTrackingIDFA:Bool = false

        override public func viewDidLoad() {
            super.viewDidLoad()

            // Do any additional setup after loading the view.
        }
        public init(view content: UIViewController, AdUnitID adUnitIDInit:String, ShouldShowAd showAdsIn: Bool = true, TestAdDevices testDevicesIn: [String]? = nil, shouldRequestTrackingIDFA: Bool = true) {
            //Show test ads on these explicit devices
            self.testDevices = testDevicesIn ?? [String]()
            self.simulatedDevices = [String]()
            if let simulatorStringed = GADSimulatorID as? String {
                self.simulatedDevices.append(simulatorStringed)
            }
            //Request IDFA Access usually
            self.shouldRequestTrackingIDFA = shouldRequestTrackingIDFA
            //Show an ad as soon as available
            self.shouldBeShown = showAdsIn
            //Set that no ad loaded yet
            self.adLoaded = false
            //Get ad info from init
            self.adUnitID = adUnitIDInit
            //Init Super View Controller
            super.init(nibName: nil, bundle: nil)
            //Setup Main View
            self.contentController = content
            //Setup below ad Background View
            self.backgroundView = UIView()
            //Setup ad border View
            self.borderView = UIView()
            //Setup Ad Banner View
            self.bannerView = GADBannerView(adSize: GADAdSizeBanner)
            self.bannerView.adUnitID = self.adUnitID;
            self.bannerView.rootViewController = self;
            self.bannerView.delegate = self
            //Set main view background color
            if #available(iOS 13.0, *) {
                self.setBackground(color: UIColor.systemBackground)
                self.bannerView.backgroundColor = UIColor.systemGray6
                self.borderView.backgroundColor = UIColor.systemGray6
            } else {
                self.setBackground(color: UIColor.white)
                self.bannerView.backgroundColor = UIColor.lightGray
                self.borderView.backgroundColor = UIColor.lightGray
            }
            //Init Google Ads framework
            GADMobileAds.sharedInstance().start { (status) in
                //Call Banner Load - ask for an ad
                self.requestIDFA()
            }
        }
        public func getContentController() -> UIViewController {
            return self.contentController
        }
        public func setBackground(color: UIColor) {
            self.view.window?.backgroundColor = color
            self.view.backgroundColor = color
            DispatchQueue.main.async {
                self.backgroundView?.backgroundColor = color
                self.view.window?.backgroundColor = color
                self.view.backgroundColor = color
            }
        }
        private func requestIDFA() {
            if(!shouldRequestTrackingIDFA) {
                self.bannerLoad()
                NSLog("adView:ASIdentifierManager NOT REQUESTING IDFA ACCESS")
                return
            }

            NSLog("adView:ASIdentifierManager Tracking UUID: " + ASIdentifierManager.shared().advertisingIdentifier.uuidString)
            #if canImport(AppTrackingTransparency)
                if #available(iOS 14, *) {
                    //Guard for application not yet being active
                    if(UIApplication.shared.applicationState != .active) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            self.requestIDFA()
                        })
                        return;
                    }

                    //Request authorization
                    if(ATTrackingManager.trackingAuthorizationStatus == .notDetermined) {
                        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                            // Tracking authorization completed. Start loading ads here.
                            if status == ATTrackingManager.AuthorizationStatus.authorized {
                                NSLog("adView:ASIdentifierManager ATTrackingManager=authorized")
                            } else if status == ATTrackingManager.AuthorizationStatus.denied {
                                NSLog("adView:ASIdentifierManager ATTrackingManager=denied")
                            } else if status == ATTrackingManager.AuthorizationStatus.restricted {
                                NSLog("adView:ASIdentifierManager ATTrackingManager=restricted")
                            } else if status == ATTrackingManager.AuthorizationStatus.notDetermined {
                                NSLog("adView:ASIdentifierManager ATTrackingManager=notDetermined")
                            } else {
                                NSLog("adView:ASIdentifierManager ATTrackingManager=UNKNOWN STATE OCCURED")
                            }

                            //Check for failed check for tracking advertising
                            if(status == .notDetermined) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                    self.requestIDFA()
                                })
                                return;
                            }

                            self.bannerLoad()
                        })
                        return;
                    }
                    
                }
            #endif
            NSLog("adView:ASIdentifierManager skipping requesting tracking permission. ASIdentifierManager.isAdvertisingTrackingEnabled=" + (ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? "Yes" : "No"));
            

            self.bannerLoad()
        }
        private func bannerLoad() {
            DispatchQueue.main.async {
                self.bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(self.bannerView.frame.size.width);
                NSLog("adView:requesting ad with width=" + String(Int(self.bannerView.adSize.size.width)))
                let request = GADRequest()
                if #available(iOS 13.0, *) {
                    request.scene = self.view.window?.windowScene
                }
                GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = self.testDevices + self.simulatedDevices
                self.bannerView.load(request)
                self.bannerView.isAutoloadEnabled = true
            }
        }
        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        override public func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }


        override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            UIView.animate(withDuration: 0.25, animations: ({
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }))

            if (self.bannerView != nil) {
                self.adLoaded = false
                self.pendingFrameChange = true
            }
            super.viewWillTransition(to: size, with: coordinator)
        }

        override public func loadView() {
            let content = UIView(frame: UIScreen.main.bounds)
            content.addSubview(self.backgroundView)
            content.addSubview(self.borderView)
            content.addSubview(self.bannerView)
            self.addChild(self.contentController)
            content.addSubview(self.contentController.view)
            self.contentController.didMove(toParent: self)
            content.backgroundColor = UIColor.black
            self.view = content
        }
        override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return self.contentController.supportedInterfaceOrientations
        }

        override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
            return self.contentController.preferredInterfaceOrientationForPresentation
        }

        override public func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if (!self.view.bounds.equalTo(self.frameSavedBannerView)) {
                self.reloadStuff()
            }
        }
        private func reloadStuff() {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25, animations: ({
                    self.view.setNeedsLayout()
                    if self.view.window != nil {
                        self.view.layoutIfNeeded()
                    }
                }))
            }
        }
        @objc public func hideBannerView() {
            self.shouldBeShown = false;
            self.reloadStuff()
        }
        @objc public func showBannerView() {
            self.shouldBeShown = true;
            self.reloadStuff()
        }
        public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            if(self.pendingFrameChange) {
                return
            }
            self.adLoaded = true
            self.frameSavedBannerView = CGRect.zero
            NSLog("bannerViewDidReceiveAd")
            self.reloadStuff()
        }
        public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            NSLog("bannerView:didFailToReceiveAdWithError: "+error.localizedDescription)
            self.reloadStuff()
        }
        @objc public func isPresentingAd() -> Bool {
            return presentingAd
        }
        override public func viewDidLayoutSubviews() {
            var contentFrame = self.view.bounds
            var bannerFrame = CGRect.zero
            self.frameSavedBannerView = self.view.bounds
            bannerFrame.size = self.bannerView.sizeThatFits(contentFrame.size)
            bannerFrame.size.width = self.view.bounds.size.width
            var backgroundViewFrame = bannerFrame
            var borderViewFrame = bannerFrame
            let borderSize = CGFloat(1.0)
            borderViewFrame.size.height = borderSize
            var displayShift = bannerFrame.size.height
            if #available(iOS 11.0, *) {
                let insets = self.view.window?.safeAreaInsets ?? self.view.safeAreaInsets
                bannerFrame.origin.x = insets.left
                bannerFrame.size.width -= insets.left
                bannerFrame.size.width -= insets.right
                displayShift += insets.bottom
            }

            // Check if the banner has an ad loaded and ready for display.  Move the banner off
            // screen if it does not have an ad.
            if (self.adLoaded && self.shouldBeShown) {
                contentFrame.size.height -= displayShift - borderSize
                bannerFrame.origin.y = contentFrame.size.height + borderSize;
                borderViewFrame.origin.y = contentFrame.size.height;
                backgroundViewFrame.origin.y = bannerFrame.origin.y
                backgroundViewFrame.size.height += displayShift
                NotificationCenter.default.post(name: Notification.Name(rawValue: self.DidPresentAd), object: nil)
                self.presentingAd = true
            } else {
                bannerFrame.origin.y = contentFrame.size.height + borderSize
                borderViewFrame.origin.y = contentFrame.size.height
                NotificationCenter.default.post(name: Notification.Name(rawValue: self.DidUnpresentAd), object: nil)
                self.presentingAd = false
            }
            self.contentController.view.frame = contentFrame
            self.bannerView.frame = bannerFrame
            self.borderView.frame = borderViewFrame
            self.backgroundView.frame = backgroundViewFrame
            self.bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(self.bannerView.frame.size.width)
            bannerFrame.origin.x = (contentFrame.size.width - self.bannerView.adSize.size.width) / 2.0
            if(self.pendingFrameChange) {
                self.pendingFrameChange = false
                self.bannerLoad()
            }
        }
    }
#endif
