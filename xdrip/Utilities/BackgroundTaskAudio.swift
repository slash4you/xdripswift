//
//  BackgroundTask.swift
//
//  Created by Yaro on 8/27/16.
//  Copyright © 2016 Yaro. All rights reserved.
//

import AVFoundation

class BackgroundTask {
    
    // MARK: - Vars
    private var player : AVPlayer?
    private var audioPlayer:AVAudioPlayer?
    private var playSoundTimer:RepeatingTimer?

    public init() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            //if let silentFile = Bundle.main.url(forResource: "blank", withExtension: "wav") {
            if let silentFile = Bundle.main.url(forResource: "1-millisecond-of-silence", withExtension: "mp3") {
                player = AVPlayer(url: silentFile)
            }
        } else {
            // creat audioplayer
            do {
                if let soundFile = Bundle.main.url(forResource: "1-millisecond-of-silence", withExtension: "mp3")  {
                    try audioPlayer = AVAudioPlayer(contentsOf: soundFile)
                }
                // create playSoundTimer
                playSoundTimer = RepeatingTimer(timeInterval: TimeInterval(Double(ConstantsWebServer.lightSuspensionPreventionInterval)), eventHandler: {
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
            playAudio()
        } else {
            if let playSoundTimer = playSoundTimer {
                playSoundTimer.resume()
            }
        }
    }
    
    func enableSuspension() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
            stopAudio()
        } else {
            // stop the timer for now, might be already suspended but doesn't harm
            if let playSoundTimer = playSoundTimer {
                playSoundTimer.suspend()
            }
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
            if let player = self.player {
                // Play audio forever by setting num of loops to -1
                //player.numberOfLoops = -1
                // 'actionAtItemEnd=none' prevent from suspending the session at playback end
                player.actionAtItemEnd = .none
                player.volume = 0.01
                player.play()
            }
        } else {
            // play the sound
            if let audioPlayer = self.audioPlayer, !audioPlayer.isPlaying {
                audioPlayer.volume = 0.01
                audioPlayer.play()
            }
        }
    }
    
    fileprivate func stopAudio() {
        if ConstantsWebServer.aggressiveSuspensionPrevention {
            if let player = self.player {
                player.seek(to: CMTime.zero)
                player.pause()
            }
        } else {
            if let audioPlayer = self.audioPlayer, audioPlayer.isPlaying {
                audioPlayer.stop()
            }
        }
    }
}
