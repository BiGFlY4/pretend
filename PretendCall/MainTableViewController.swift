//
//  MainTableViewController.swift
//  PretendCall
//
//  Created by Jifei sui on 2018/7/18.
//  Copyright © 2018年 Jifei sui. All rights reserved.
//

import UIKit
import CallKit

protocol CallStructDelegate: class {
    func setCallStruct(with data: CallInfo)
    func startCall()
}

class MainTableViewController: UITableViewController,CXCallObserverDelegate,CallStructDelegate {

    @IBOutlet weak var naviBarItem: UINavigationItem!
    @IBOutlet weak var callNowButton: UIBarButtonItem!
    @IBOutlet weak var settingButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var stopCallButton: UIBarButtonItem!
    @IBOutlet weak var segView: UIView!
    @IBOutlet weak var segmentBar: UISegmentedControl!
    @IBOutlet weak var noticeLabel: UILabel!
    weak var timer: Timer?
    var providerDelegate: ProviderDelegate?
    var callObserver: CXCallObserver?
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var backgroundTask: DispatchWorkItem?
    var delay: Double?
    var callInfo = CallInfo()
    var naviBarDelayTitle = false
    var blinkingTime = 3.0
    let updateTimeInterval:TimeInterval = 0.1
    
    @IBAction func callNow(_ sender: UIBarButtonItem) {
        let callInfoNow = CallInfo()
        settingButton.isEnabled = false
        callNowButton.isEnabled = false
        callNowButton.title = nil
        callNowButton.image = nil
        stopCallButton.title = nil
        stopCallButton.image = nil
        cancelButton.isEnabled = true
        cancelButton.title = "Cancel"
        cancelButton.image = UIImage(named: "Stop.png")
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        backgroundTask = DispatchWorkItem {
            AppDelegate.shared.displayIncomingCall(callInfo: callInfoNow) { _ in
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
            }
        }
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3, execute: backgroundTask!)
        segmentBar.isHidden = true
        noticeLabel.text = "Start in 3s, you may lock the screen now."
        noticeLabel.isHidden = false
        noticeLabel.startBlink()
    }
    
    @IBAction func cancelButtonAction(_ sender: UIBarButtonItem) {
        if backgroundTask != nil {
            backgroundTask?.cancel()
        }
        if backgroundTaskIdentifier != nil {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier!)
        }
        settingButton.isEnabled = true
        callNowButton.isEnabled = true
        callNowButton.title = "CallNow"
        callNowButton.image = UIImage(named: "NOW.png")
        cancelButton.isEnabled = false
        cancelButton.title = nil
        cancelButton.image = nil
        naviBarItem.title = "News Feed"
        timer?.invalidate()
        segmentBar.isHidden = false
        noticeLabel.isHidden = true
        noticeLabel.stopBlink()
    }
    
    @IBAction func stopCallButtonAction(_ sender: UIBarButtonItem) {
        AppDelegate.shared.endCall()
        providerDelegate?.endCall()
    }
    
    func setCallStruct(with data: CallInfo) {
        self.callInfo = data
    }
    
    @objc func triggerNaviTitle(_ notification:Notification) {
        if naviBarItem.title != "News Feed" {
            naviBarDelayTitle = !naviBarDelayTitle
        }
    }
    
    func startCall() {
        blinkingTime = 3.0
        settingButton.isEnabled = false
        callNowButton.isEnabled = false
        callNowButton.title = nil
        callNowButton.image = nil
        stopCallButton.title = nil
        stopCallButton.image = nil
        cancelButton.isEnabled = true
        cancelButton.title = "Cancel"
        cancelButton.image = UIImage(named: "Stop.png")
        naviBarItem.title = "TapMe"
        naviBarDelayTitle = false
        delay = Double(callInfo.delayMin * 60 + callInfo.delaySec)
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        backgroundTask = DispatchWorkItem {
            AppDelegate.shared.displayIncomingCall(callInfo: self.callInfo) { _ in
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
            }
        }
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + TimeInterval(delay!), execute: backgroundTask!)
        timer = Timer.scheduledTimer(timeInterval: updateTimeInterval, target: self, selector: #selector(updateDelayProgressView), userInfo: nil, repeats: true)
        segmentBar.isHidden = true
        noticeLabel.text = "You may lock the screen before it is triggered."
        noticeLabel.isHidden = false
        noticeLabel.startBlink()
    }
    
    @objc func updateDelayProgressView() {
        if naviBarDelayTitle {
            naviBarItem.title = format(delay: delay!)
        }
        else {
            naviBarItem.title = "TapMe"
        }
        delay! -= updateTimeInterval
        
        blinkingTime -= updateTimeInterval
        if blinkingTime < 0.0 {
            segmentBar.isHidden = false
            noticeLabel.isHidden = true
            noticeLabel.stopBlink()
        }
    }
    
    func format(delay: Double) -> String {
        if delay < 0.0 {
            return "00:00"
        }
        let interval = Int(delay.rounded())
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded == true {
            stopCallButton.isEnabled = false
            stopCallButton.title = nil
            stopCallButton.image = nil
            settingButton.isEnabled = true
            callNowButton.isEnabled = true
            callNowButton.title = "CallNow"
            callNowButton.image = UIImage(named: "NOW.png")
            timer?.invalidate()
            naviBarItem.title = "News Feed"
        }
        else if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            self.settingButton.isEnabled = false
            self.callNowButton.isEnabled = false
            self.callNowButton.title = nil
            self.callNowButton.image = nil
            self.cancelButton.isEnabled = false
            self.cancelButton.title = nil
            self.cancelButton.image = nil
            self.stopCallButton.isEnabled = true
            self.stopCallButton.title = "Stop"
            self.stopCallButton.image = UIImage(named: "EndCall.png")
            timer?.invalidate()
            naviBarItem.title = "News Feed"
            segmentBar.isHidden = false
            noticeLabel.isHidden = true
            noticeLabel.stopBlink()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "callSetting" {
            let secondViewController = segue.destination as! SettingTVC
            secondViewController.callStructDelegate = self
            secondViewController.callInfo = callInfo
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noticeLabel.isHidden = true
        segView.addBottomBorderWithColor(color: .groupTableViewBackground, width: 1)
        cancelButton.title = nil
        cancelButton.image = nil
        stopCallButton.title = nil
        stopCallButton.image = nil
        callObserver = CXCallObserver()
        callObserver?.setDelegate(self, queue: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(triggerNaviTitle(_:)), name: .didTapNaviBar, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UIView {
    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
}

extension UILabel {
    func startBlink() {
        UIView.animate(withDuration: 0.8,
                       delay:0.0,
                       options:[.allowUserInteraction, .curveEaseInOut, .autoreverse, .repeat],
                       animations: { self.alpha = 0 },
                       completion: nil)
    }
    
    func stopBlink() {
        layer.removeAllAnimations()
        alpha = 1
    }
}
