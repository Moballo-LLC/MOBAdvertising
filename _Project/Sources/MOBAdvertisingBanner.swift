//
//  MOBAdvertisingBanner.swift
//  MOBAdvertising
//
//  Consent-gated adaptive banner presentation for Moballo UIKit apps.
//

import UIKit
import GoogleMobileAds
import UserMessagingPlatform
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

public final class MOBAdvertisingBanner: UIViewController, BannerViewDelegate {
    private enum AdServingMode {
        case currentConsent
        case limited
        case unavailable
    }

    private enum NotificationName {
        static let didPresent = Notification.Name("com.moballo.advertising.adPresented")
        static let didUnpresent = Notification.Name("com.moballo.advertising.adUnpresented")
        static let privacyChoicesDidChange = Notification.Name(
            "com.moballo.advertising.privacyChoicesDidChange"
        )
    }

    private static let googleDemoBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
    private static let googleConsentForCookiesKey = "gad_has_consent_for_cookies"
    private static var sharedConsentComplete = false
    private static var sharedConsentInFlight = false
    private static var sharedConsentMode: AdServingMode?
    private static var sharedConsentWaiters: [(AdServingMode, Bool) -> Void] = []
    private static weak var sharedConsentPresenter: UIViewController?
    private static var sharedConsentDidBecomeActiveObserver: NSObjectProtocol?
    private static var sharedTrackingComplete = false
    private static var sharedTrackingInFlight = false
    private static var sharedTrackingWaiters: [() -> Void] = []
    private static var sharedTrackingRetryAttempts = 0
    private static var sharedTrackingRetryWorkItem: DispatchWorkItem?
    private static var sharedDidBecomeActiveObserver: NSObjectProtocol?
    private static var sharedMobileAdsStarted = false
    private static var sharedMobileAdsStartInFlight = false
    private static var sharedMobileAdsStartWaiters: [() -> Void] = []

    private let contentController: UIViewController
    private var bannerView = BannerView(adSize: AdSizeBanner)
    private let bannerAdUnitID: String
    private let backgroundView = UIView()
    private let borderView = UIView()
    private let testDevices: [String]
    private let shouldRequestTrackingAuthorization: Bool

    private var adLoaded = false
    private var shouldBeShown: Bool
    private var presentingAd = false
    private var authorizationStarted = false
    private var authorizationComplete = false
    private var adServingMode: AdServingMode?
    private var authorizationGeneration = 0
    private var authorizationRetryAttempts = 0
    private var authorizationRetryScheduled = false
    private var bannerRequestInFlight = false
    private var requestedBannerWidth: CGFloat?
    private var pendingAdLoad = false
    private var bannerRetryAttempts = 0
    private var bannerRetryWorkItem: DispatchWorkItem?
    private var lastLaidOutBounds: CGRect?
    private var lastLaidOutAvailableWidth: CGFloat?
    private var isViewVisible = false

    public init(
        view content: UIViewController,
        AdUnitID productionAdUnitID: String,
        ShouldShowAd shouldShowAd: Bool = true,
        TestAdDevices testAdDevices: [String]? = nil,
        shouldRequestTrackingIDFA: Bool = true
    ) {
        contentController = content
        shouldBeShown = shouldShowAd
        testDevices = testAdDevices ?? []
        shouldRequestTrackingAuthorization = shouldRequestTrackingIDFA
        bannerAdUnitID = Self.runtimeBannerAdUnitID(productionAdUnitID)

        super.init(nibName: nil, bundle: nil)

        configureBannerView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(privacyChoicesDidChange),
            name: NotificationName.privacyChoicesDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #if DEBUG
        NSLog("Configured Moballo banner; demo=\(bannerView.adUnitID == Self.googleDemoBannerAdUnitID)")
        #endif
    }

    // Source compatibility for apps that used MOBAdvertising 1.x. The Google
    // app ID must now live in GADApplicationIdentifier in the host Info.plist.
    public convenience init(
        view content: UIViewController,
        AdApplicationID _: String,
        AdUnitID productionAdUnitID: String,
        TestAds _: Bool? = false
    ) {
        self.init(view: content, AdUnitID: productionAdUnitID)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("MOBAdvertisingBanner must be initialized with a content controller.")
    }

    deinit {
        bannerRetryWorkItem?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    public override func loadView() {
        let rootView = UIView(frame: .zero)
        rootView.addSubview(backgroundView)
        rootView.addSubview(borderView)
        rootView.addSubview(bannerView)

        addChild(contentController)
        rootView.addSubview(contentController.view)
        contentController.didMove(toParent: self)
        view = rootView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        applySystemColors()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewVisible = true
        if lastLaidOutBounds != view.bounds {
            reloadLayout()
        }
        beginAuthorizationIfNeeded()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isViewVisible = false
        bannerRetryWorkItem?.cancel()
        bannerRetryWorkItem = nil
    }

    public override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        adLoaded = false
        pendingAdLoad = shouldBeShown
        coordinator.animate(alongsideTransition: { _ in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.loadBannerIfPossible()
        })
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lastLaidOutBounds = view.bounds

        let borderSize = CGFloat(1)
        let safeInsets = view.window?.safeAreaInsets ?? view.safeAreaInsets
        let availableWidth = max(0, view.bounds.width - safeInsets.left - safeInsets.right)
        let previousAvailableWidth = lastLaidOutAvailableWidth
        lastLaidOutAvailableWidth = availableWidth
        let availableWidthChanged = previousAvailableWidth.map {
            abs($0 - availableWidth) >= 0.5
        } ?? false
        if availableWidthChanged {
            adLoaded = false
            pendingAdLoad = shouldBeShown
        }
        guard availableWidth > 0 else {
            contentController.view.frame = view.bounds
            setPresentingAd(false)
            pendingAdLoad = shouldBeShown
            return
        }

        let adSize = largeAnchoredAdaptiveBanner(width: availableWidth)
        bannerView.adSize = adSize
        var contentFrame = view.bounds
        var bannerFrame = CGRect(
            x: safeInsets.left + max(0, (availableWidth - adSize.size.width) / 2),
            y: view.bounds.maxY + borderSize,
            width: adSize.size.width,
            height: adSize.size.height
        )
        var borderFrame = CGRect(x: 0, y: view.bounds.maxY, width: view.bounds.width, height: borderSize)
        var backgroundFrame = CGRect(
            x: 0,
            y: bannerFrame.minY,
            width: view.bounds.width,
            height: adSize.size.height + safeInsets.bottom
        )

        if adLoaded && shouldBeShown {
            contentFrame.size.height = max(
                0,
                view.bounds.height - adSize.size.height - safeInsets.bottom - borderSize
            )
            borderFrame.origin.y = contentFrame.maxY
            bannerFrame.origin.y = borderFrame.maxY
            backgroundFrame.origin.y = bannerFrame.minY
            setPresentingAd(true)
        } else {
            setPresentingAd(false)
        }

        contentController.view.frame = contentFrame
        bannerView.frame = bannerFrame
        borderView.frame = borderFrame
        backgroundView.frame = backgroundFrame

        if availableWidthChanged || pendingAdLoad {
            loadBannerIfPossible()
        }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        contentController.supportedInterfaceOrientations
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        contentController.preferredInterfaceOrientationForPresentation
    }

    public override var childForStatusBarStyle: UIViewController? { contentController }
    public override var childForStatusBarHidden: UIViewController? { contentController }

    public func getContentController() -> UIViewController { contentController }

    public func setBackground(color: UIColor) {
        view.backgroundColor = color
        view.window?.backgroundColor = color
        backgroundView.backgroundColor = color
    }

    @objc public func hideBannerView() {
        shouldBeShown = false
        pendingAdLoad = false
        adLoaded = false
        bannerRetryAttempts = 0
        bannerRetryWorkItem?.cancel()
        bannerRetryWorkItem = nil
        bannerView.isAutoloadEnabled = false
        reloadLayout()
    }

    @objc public func showBannerView() {
        guard !shouldBeShown else { return }
        shouldBeShown = true
        pendingAdLoad = true
        beginAuthorizationIfNeeded()
        reloadLayout()
    }

    @objc public func isPresentingAd() -> Bool { presentingAd }

    public var shouldOfferPrivacyOptions: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    public func presentPrivacyOptions(from presenter: UIViewController) {
        guard shouldOfferPrivacyOptions else { return }
        ConsentForm.presentPrivacyOptionsForm(from: presenter) { error in
            DispatchQueue.main.async {
                #if DEBUG
                if let error {
                    NSLog("Unable to present advertising privacy options: \(error.localizedDescription)")
                }
                #endif
                if error != nil {
                    Self.activateLimitedAdFallback()
                } else {
                    Self.invalidateSharedConsentDecision()
                }
                NotificationCenter.default.post(
                    name: NotificationName.privacyChoicesDidChange,
                    object: nil
                )
            }
        }
    }

    @objc private func privacyChoicesDidChange() {
        replaceBannerView()
        pendingAdLoad = shouldBeShown
        authorizationStarted = false
        authorizationComplete = false
        adServingMode = nil
        authorizationGeneration += 1
        authorizationRetryAttempts = 0
        authorizationRetryScheduled = false
        reloadLayout()
        beginAuthorizationIfNeeded()
    }

    @objc private func applicationDidBecomeActive() {
        guard shouldBeShown, isViewVisible else { return }
        if authorizationComplete {
            if !adLoaded || pendingAdLoad {
                loadBannerIfPossible()
            }
        } else {
            beginAuthorizationIfNeeded()
        }
    }

    public func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        guard bannerView === self.bannerView else { return }
        bannerRequestInFlight = false
        guard requestedWidthMatchesCurrentLayout else {
            requestedBannerWidth = nil
            adLoaded = false
            pendingAdLoad = shouldBeShown
            reloadLayout()
            loadBannerIfPossible()
            return
        }
        requestedBannerWidth = nil
        guard shouldBeShown,
              isAdServingPermitted else {
            adLoaded = false
            reloadLayout()
            return
        }
        pendingAdLoad = false
        adLoaded = true
        bannerRetryAttempts = 0
        bannerRetryWorkItem?.cancel()
        bannerRetryWorkItem = nil
        bannerView.isAutoloadEnabled = false
        #if DEBUG
        NSLog("Moballo banner loaded successfully")
        #endif
        reloadLayout()
    }

    public func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        guard bannerView === self.bannerView else { return }
        bannerRequestInFlight = false
        if !requestedWidthMatchesCurrentLayout {
            requestedBannerWidth = nil
            adLoaded = false
            pendingAdLoad = shouldBeShown
            reloadLayout()
            loadBannerIfPossible()
            return
        }
        requestedBannerWidth = nil
        pendingAdLoad = false
        adLoaded = false
        bannerView.isAutoloadEnabled = false
        #if DEBUG
        NSLog("Unable to load Moballo banner ad: \(error.localizedDescription)")
        #endif
        reloadLayout()
        scheduleBannerRetryIfNeeded()
    }

    private static func runtimeBannerAdUnitID(_ productionAdUnitID: String) -> String {
        #if DEBUG
        return googleDemoBannerAdUnitID
        #elseif targetEnvironment(simulator)
        return googleDemoBannerAdUnitID
        #else
        return ProcessInfo.processInfo.environment["MOBALLO_USE_TEST_ADS"] == "1"
            ? googleDemoBannerAdUnitID
            : productionAdUnitID
        #endif
    }

    private func beginAuthorizationIfNeeded() {
        guard shouldBeShown, isViewVisible else { return }
        if authorizationComplete {
            if !adLoaded || pendingAdLoad {
                loadBannerIfPossible()
            }
            return
        }
        guard !authorizationStarted else { return }
        authorizationStarted = true
        authorizationGeneration += 1
        let generation = authorizationGeneration

        Self.requestSharedConsent(from: self) { [weak self] mode, retryableFailure in
            guard let self, self.authorizationGeneration == generation else { return }
            self.adServingMode = mode
            switch mode {
            case .limited:
                self.startMobileAds(generation: generation) { [weak self] in
                    guard let self, self.authorizationGeneration == generation else { return }
                    if retryableFailure {
                        self.scheduleAuthorizationRetry()
                    } else {
                        self.authorizationRetryAttempts = 0
                    }
                }
                return
            case .unavailable:
                self.authorizationStarted = false
                self.authorizationComplete = true
                self.authorizationRetryAttempts = 0
                self.pendingAdLoad = false
                self.adLoaded = false
                self.reloadLayout()
                return
            case .currentConsent:
                break
            }
            guard self.shouldBeShown, self.isViewVisible else {
                self.authorizationStarted = false
                return
            }
            self.authorizationRetryAttempts = 0
            self.requestTrackingIfNeeded(generation: generation)
        }
    }

    private static func requestSharedConsent(
        from presenter: UIViewController,
        completion: @escaping (AdServingMode, Bool) -> Void
    ) {
        if sharedConsentComplete, let sharedConsentMode {
            completion(sharedConsentMode, false)
            return
        }
        sharedConsentWaiters.append(completion)
        guard !sharedConsentInFlight else { return }
        sharedConsentInFlight = true

        ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { error in
            DispatchQueue.main.async {
                guard error == nil else {
                    #if DEBUG
                    NSLog("Unable to update advertising consent: \(error!.localizedDescription)")
                    #endif
                    activateLimitedAdFallback()
                    finishSharedConsent(mode: .limited, retryableFailure: true)
                    return
                }
                presentSharedConsentFormWhenActive(from: presenter)
            }
        }
    }

    private static func presentSharedConsentFormWhenActive(from presenter: UIViewController) {
        guard UIApplication.shared.applicationState == .active else {
            sharedConsentPresenter = presenter
            observeNextSharedConsentApplicationActivation()
            return
        }

        sharedConsentPresenter = nil
        stopObservingSharedConsentApplicationActivation()
        ConsentForm.loadAndPresentIfRequired(from: presenter) { formError in
            DispatchQueue.main.async {
                #if DEBUG
                if let formError {
                    NSLog("Unable to present advertising consent: \(formError.localizedDescription)")
                }
                #endif
                if formError != nil {
                    activateLimitedAdFallback()
                    finishSharedConsent(mode: .limited, retryableFailure: true)
                    return
                }

                clearLimitedAdFallback()
                let mode: AdServingMode = ConsentInformation.shared.canRequestAds
                    ? .currentConsent
                    : .unavailable
                finishSharedConsent(mode: mode, retryableFailure: false)
            }
        }
    }

    private static func observeNextSharedConsentApplicationActivation() {
        guard sharedConsentDidBecomeActiveObserver == nil else { return }
        sharedConsentDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            guard let presenter = sharedConsentPresenter else {
                activateLimitedAdFallback()
                finishSharedConsent(mode: .limited, retryableFailure: true)
                return
            }
            presentSharedConsentFormWhenActive(from: presenter)
        }
    }

    private static func stopObservingSharedConsentApplicationActivation() {
        guard let observer = sharedConsentDidBecomeActiveObserver else { return }
        NotificationCenter.default.removeObserver(observer)
        sharedConsentDidBecomeActiveObserver = nil
    }

    private static func finishSharedConsent(
        mode: AdServingMode,
        retryableFailure: Bool
    ) {
        stopObservingSharedConsentApplicationActivation()
        sharedConsentPresenter = nil
        sharedConsentInFlight = false
        sharedConsentComplete = !retryableFailure
        sharedConsentMode = mode
        let waiters = sharedConsentWaiters
        sharedConsentWaiters.removeAll()
        waiters.forEach { $0(mode, retryableFailure) }
    }

    private static func activateLimitedAdFallback() {
        UserDefaults.standard.set(0, forKey: googleConsentForCookiesKey)
        sharedConsentComplete = false
        sharedConsentMode = .limited
    }

    private static func clearLimitedAdFallback() {
        UserDefaults.standard.removeObject(forKey: googleConsentForCookiesKey)
    }

    private static func invalidateSharedConsentDecision() {
        sharedConsentComplete = false
        sharedConsentMode = nil
    }

    private func scheduleAuthorizationRetry() {
        guard authorizationRetryAttempts < 3,
              !authorizationRetryScheduled,
              shouldBeShown,
              isViewVisible else { return }
        authorizationRetryAttempts += 1
        authorizationRetryScheduled = true
        let delay = TimeInterval(5 * authorizationRetryAttempts)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.authorizationRetryScheduled = false
            self.refreshConsentWhileServingLimited()
        }
    }

    private func refreshConsentWhileServingLimited() {
        guard adServingMode == .limited,
              shouldBeShown,
              isViewVisible,
              !authorizationStarted else { return }
        authorizationStarted = true
        authorizationGeneration += 1
        let generation = authorizationGeneration
        Self.requestSharedConsent(from: self) { [weak self] mode, retryableFailure in
            guard let self, self.authorizationGeneration == generation else { return }
            self.authorizationStarted = false
            self.adServingMode = mode
            switch mode {
            case .limited:
                if !self.authorizationComplete {
                    self.authorizationStarted = true
                    self.startMobileAds(generation: generation) { [weak self] in
                        guard let self, self.authorizationGeneration == generation else { return }
                        if retryableFailure {
                            self.scheduleAuthorizationRetry()
                        }
                    }
                    return
                }
                if retryableFailure {
                    self.scheduleAuthorizationRetry()
                }
                return
            case .currentConsent, .unavailable:
                self.authorizationRetryAttempts = 0
                // Every live banner must leave its local limited mode together.
                // Re-enter through the shared decision so a successful denial
                // also withdraws any banner owned by another controller.
                NotificationCenter.default.post(
                    name: NotificationName.privacyChoicesDidChange,
                    object: nil
                )
                return
            }
        }
    }

    private func requestTrackingIfNeeded(generation: Int) {
        guard shouldRequestTrackingAuthorization else {
            startMobileAds(generation: generation)
            return
        }
        Self.requestSharedTrackingAuthorization { [weak self] in
            guard let self, self.authorizationGeneration == generation else { return }
            self.startMobileAds(generation: generation)
        }
    }

    private static func requestSharedTrackingAuthorization(completion: @escaping () -> Void) {
        if sharedTrackingComplete {
            completion()
            return
        }
        sharedTrackingWaiters.append(completion)
        guard !sharedTrackingInFlight else { return }
        sharedTrackingInFlight = true

        performSharedTrackingAuthorizationRequest()
    }

    private static func performSharedTrackingAuthorizationRequest() {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            guard UIApplication.shared.applicationState == .active else {
                observeNextSharedApplicationActivation()
                return
            }
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    if ATTrackingManager.trackingAuthorizationStatus == .notDetermined,
                       sharedTrackingRetryAttempts < 3 {
                        scheduleSharedTrackingAuthorizationRetry()
                    } else {
                        finishSharedTrackingAuthorization()
                    }
                }
            }
            return
        }
        #endif
        finishSharedTrackingAuthorization()
    }

    private static func finishSharedTrackingAuthorization() {
        sharedTrackingRetryWorkItem?.cancel()
        sharedTrackingRetryWorkItem = nil
        sharedTrackingRetryAttempts = 0
        stopObservingSharedApplicationActivation()
        sharedTrackingInFlight = false
        sharedTrackingComplete = true
        let waiters = sharedTrackingWaiters
        sharedTrackingWaiters.removeAll()
        waiters.forEach { $0() }
    }

    private func startMobileAds(
        generation: Int,
        completion: @escaping () -> Void = {}
    ) {
        Self.startSharedMobileAds { [weak self] in
            guard let self, self.authorizationGeneration == generation else { return }
            guard self.shouldBeShown, self.isViewVisible else {
                self.authorizationStarted = false
                return
            }
            self.authorizationStarted = false
            self.authorizationComplete = true
            self.pendingAdLoad = self.shouldBeShown
            self.loadBannerIfPossible()
            completion()
        }
    }

    private static func startSharedMobileAds(completion: @escaping () -> Void) {
        if sharedMobileAdsStarted {
            completion()
            return
        }
        sharedMobileAdsStartWaiters.append(completion)
        guard !sharedMobileAdsStartInFlight else { return }
        sharedMobileAdsStartInFlight = true
        #if DEBUG
        NSLog("Initializing Mobile Ads after advertising authorization")
        #endif
        MobileAds.shared.start { _ in
            DispatchQueue.main.async {
                sharedMobileAdsStartInFlight = false
                sharedMobileAdsStarted = true
                let waiters = sharedMobileAdsStartWaiters
                sharedMobileAdsStartWaiters.removeAll()
                waiters.forEach { $0() }
            }
        }
    }

    private func loadBannerIfPossible() {
        guard shouldBeShown,
              isViewVisible,
              UIApplication.shared.applicationState == .active,
              isAdServingPermitted,
              !bannerRequestInFlight,
              bannerRetryWorkItem == nil else {
            return
        }
        let safeInsets = view.window?.safeAreaInsets ?? view.safeAreaInsets
        let availableWidth = max(0, view.bounds.width - safeInsets.left - safeInsets.right)
        guard availableWidth > 0 else {
            pendingAdLoad = true
            return
        }

        pendingAdLoad = false
        bannerRequestInFlight = true
        requestedBannerWidth = availableWidth
        bannerView.adSize = largeAnchoredAdaptiveBanner(width: availableWidth)
        bannerView.isAutoloadEnabled = false
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = testDevices
        let request = Request()
        if #available(iOS 13.0, *) {
            request.scene = view.window?.windowScene
        }
        bannerView.load(request)
    }

    private func configureBannerView() {
        bannerView.adUnitID = bannerAdUnitID
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.isAutoloadEnabled = false
    }

    private func replaceBannerView() {
        bannerRetryWorkItem?.cancel()
        bannerRetryWorkItem = nil
        bannerRetryAttempts = 0
        bannerRequestInFlight = false
        requestedBannerWidth = nil
        adLoaded = false

        bannerView.delegate = nil
        bannerView.removeFromSuperview()
        bannerView = BannerView(adSize: AdSizeBanner)
        configureBannerView()
        if isViewLoaded {
            view.insertSubview(bannerView, belowSubview: contentController.view)
        }
    }

    private var requestedWidthMatchesCurrentLayout: Bool {
        guard let requestedBannerWidth else { return false }
        let safeInsets = view.window?.safeAreaInsets ?? view.safeAreaInsets
        let currentWidth = max(0, view.bounds.width - safeInsets.left - safeInsets.right)
        return abs(requestedBannerWidth - currentWidth) < 0.5
    }

    private var isAdServingPermitted: Bool {
        guard authorizationComplete else { return false }
        switch adServingMode {
        case .limited:
            return true
        case .currentConsent:
            return ConsentInformation.shared.canRequestAds
        case .unavailable:
            return false
        case nil:
            return false
        }
    }

    private static func observeNextSharedApplicationActivation() {
        guard sharedDidBecomeActiveObserver == nil else { return }
        sharedDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            stopObservingSharedApplicationActivation()
            performSharedTrackingAuthorizationRequest()
        }
    }

    private static func stopObservingSharedApplicationActivation() {
        guard let observer = sharedDidBecomeActiveObserver else { return }
        NotificationCenter.default.removeObserver(observer)
        sharedDidBecomeActiveObserver = nil
    }

    private static func scheduleSharedTrackingAuthorizationRetry() {
        sharedTrackingRetryAttempts += 1
        sharedTrackingRetryWorkItem?.cancel()
        let delay = min(pow(2, Double(sharedTrackingRetryAttempts - 1)), 4)
        let workItem = DispatchWorkItem {
            sharedTrackingRetryWorkItem = nil
            performSharedTrackingAuthorizationRequest()
        }
        sharedTrackingRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleBannerRetryIfNeeded() {
        guard bannerRetryAttempts < 5,
              bannerRetryWorkItem == nil,
              shouldBeShown,
              isViewVisible,
              UIApplication.shared.applicationState == .active,
              isAdServingPermitted else {
            return
        }

        bannerRetryAttempts += 1
        let delay = min(pow(2, Double(bannerRetryAttempts)), 32)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.bannerRetryWorkItem = nil
            self.pendingAdLoad = true
            self.loadBannerIfPossible()
        }
        bannerRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func applySystemColors() {
        let backgroundColor = UIColor.systemBackground
        let separatorColor = UIColor.systemGray6
        view.backgroundColor = backgroundColor
        backgroundView.backgroundColor = backgroundColor
        borderView.backgroundColor = separatorColor
        bannerView.backgroundColor = separatorColor
    }

    private func reloadLayout() {
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
            if self.view.window != nil {
                self.view.layoutIfNeeded()
            }
        }
    }

    private func setPresentingAd(_ presenting: Bool) {
        guard presentingAd != presenting else { return }
        presentingAd = presenting
        NotificationCenter.default.post(
            name: presenting ? NotificationName.didPresent : NotificationName.didUnpresent,
            object: nil
        )
    }
}
