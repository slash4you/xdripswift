//
//  BackgroundTask.swift
//
//  Created by Yaro on 8/27/16.
//  Copyright © 2016 Yaro. All rights reserved.
//

import AVFoundation

class BackgroundTask {
    
    // MARK: - Vars
    private var avplayer : AVPlayer?
    private var aplayer  : AVAudioPlayer?
    private var playSoundTimer:RepeatingTimer?

    public init() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            //if let silentFile = Bundle.main.url(forResource: "blank", withExtension: "wav") {
            if let silentFile = Bundle.main.url(forResource: "1-millisecond-of-silence", withExtension: "mp3") {
                avplayer = AVPlayer(url: silentFile)
            }
            playSoundTimer = RepeatingTimer(timeInterval: TimeInterval(ConstantsWebServer.aggressiveSuspensionPreventionInterval), eventHandler: {
                self.playAudio()
            })
        } else {
            // creat audioplayer
            do {
                if let soundFile = Bundle.main.url(forResource: "1-millisecond-of-silence", withExtension: "mp3")  {
                    try aplayer = AVAudioPlayer(contentsOf: soundFile)
                }
                // create playSoundTimer
                playSoundTimer = RepeatingTimer(timeInterval: TimeInterval(ConstantsWebServer.moderateSuspensionPreventionInterval), eventHandler: {
                    self.playAudio()
                })
            } catch let error {
                print (error.localizedDescription)
            }
        }
    }
    
    // MARK: - Methods
    func disableSuspension() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            NotificationCenter.default.addObserver(self, selector: #selector(interruptedAudio), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        }
        if let playSoundTimer = playSoundTimer {
            playSoundTimer.resume()
        }
    }
    
    func enableSuspension() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        }
        // stop the timer for now, might be already suspended but doesn't harm
        if let playSoundTimer = playSoundTimer {
            playSoundTimer.suspend()
        }
    }
    
    @objc fileprivate func interruptedAudio(_ notification: Notification) {
        if notification.name == AVAudioSession.interruptionNotification && notification.userInfo != nil {
            let info = notification.userInfo!
            var intValue = 0
            (info[AVAudioSessionInterruptionTypeKey]! as AnyObject).getValue(&intValue)
            if intValue == 1 { playAudio() }
        }
    }
    
    fileprivate func playAudio() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            if let avplayer = self.avplayer {
                // Play audio forever by setting num of loops to -1
                //player.numberOfLoops = -1
                // 'actionAtItemEnd=none' prevent from suspending the session at playback end
                avplayer.actionAtItemEnd = .none
                avplayer.volume = 0.01
                avplayer.seek(to: CMTime.zero)
                avplayer.play()
            }
        } else {
            // play the sound
            if let aplayer = self.aplayer, !aplayer.isPlaying {
                aplayer.volume = 0.01
                aplayer.play()
            }
        }
    }
    
    fileprivate func stopAudio() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            if let avplayer = self.avplayer {
                avplayer.pause()
            }
        } else {
            if let aplayer = self.aplayer, aplayer.isPlaying {
                aplayer.stop()
            }
        }
    }
}
