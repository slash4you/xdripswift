//
//  NovopenManager.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 26/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation
import os
import CoreNFC

class NovopenManager : NSObject, NFCTagReaderSessionDelegate {
    
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryNovopenController)

    private var session : NFCTagReaderSession?
    
    private var phd : PHDLinkLayerHelper?
    
    private var engine : NovStateMachine?
    
    private var transaction : Int
    
    private var mlcMax : Int
    
    private var mleMax : Int
    
    private var cachedResponse : Data
    
    public weak var nfcDelegate: NovopenDelegateProtocol?

    public init(delegate: NovopenDelegateProtocol) {
        nfcDelegate = delegate
        session = nil
        phd = PHDLinkLayerHelper()
        engine = NovStateMachine()
        transaction = 0
        mlcMax = 255
        mleMax = 255
        cachedResponse = Data()
        NovMessage.reset()
    }
    
    func read() -> Void {
        guard NFCNDEFReaderSession.readingAvailable else {
            trace("NFC: NFC reader is not available", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
            return
        }

        if (self.session == nil) {
            self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
            self.resetContext()
            self.startSession()
        }
    }

    fileprivate func resetContext() -> Void {
        phd = PHDLinkLayerHelper()
        engine = NovStateMachine()
        transaction = 0
        mlcMax = 255
        mleMax = 255
        cachedResponse = Data()
        NovMessage.reset()
    }
    
    fileprivate func startSession() -> Void {
        if let tagSession = self.session {
            tagSession.alertMessage = TextsNovopenNFC.holdTopOfIphoneNearSensor
            tagSession.begin()
        }
    }
    
    fileprivate func closeSession(success: Bool) -> Void {
        if let tagSession = self.session {
            if (success) {
                tagSession.alertMessage = TextsNovopenNFC.scanComplete
                tagSession.invalidate()
            } else {
                tagSession.invalidate(errorMessage: TextsNovopenNFC.nfcErrorRetryScan )
            }
        }
    }
    
    fileprivate func transceiveEMPTY(tag : NFCISO7816Tag, payload: Data)  -> Void {
        let empty : Data = Data([0x00,0x03,0xD0,0x00,0x00])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xD6, p1Parameter:0x00, p2Parameter:0x00, data: empty, expectedResponseLength:-1)
        trace("NFC: transceiveEMPTY - command = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, empty.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: transceiveEMPTY - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: transceiveEMPTY - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            trace("NFC: transceiveEMPTY - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())
            self.transceiveUP( tag: tag, payload: payload )
        }
    }

    fileprivate func transceiveUP(tag : NFCISO7816Tag, payload: Data)  -> Void {
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xD6, p1Parameter:0x00, p2Parameter:0x00, data: payload, expectedResponseLength:-1)
        trace("NFC: transceiveUP - command = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, payload.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: transceiveUP - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: transceiveUP - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            trace("NFC: transceiveUP - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())
            self.readLengthFromLinkLayer(tag: tag)
        }
    }
    
    fileprivate func readDataFromLinkLayer(tag: NFCISO7816Tag, offset: Int, remaining: Int, length: Int) -> Void {
        // build arguments
        let O1 : UInt8 = UInt8((offset >> 8) & 0xFF)
        let O0 : UInt8 = UInt8(offset & 0xFF)
        // read data
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:O1, p2Parameter:O0, data: Data(), expectedResponseLength:length)
        trace("NFC: readDataFromLinkLayer - command = {}", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug)
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: readDataFromLinkLayer - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: readDataFromLinkLayer - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            guard (response.count == length) else {
                trace("NFC: readDataFromLinkLayer - Invalid response length", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            guard (self.transaction < ConstantsNovopen.maxNfcTransactions) else {
                trace("NFC: readDataFromLinkLayer - maximum of transactions reached", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }

            trace("NFC: readDataFromLinkLayer - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())

            self.transaction += 1

            // cache response
            self.cachedResponse.append(contentsOf: response)
            
            if (remaining <= length) {
                if let phd = self.phd, let engine = self.engine {
                        
                        let input : Data = phd.unpackInnerPacket(tag: tag, bytes: self.cachedResponse)
                        trace("NFC: readDataFromLinkLayer - input = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, input.toHexString())
                        
                        if (input.count >= 0) {
                            let fsa : Fsa = engine.processPayload(payload: input, delegate: self.nfcDelegate!)
                            switch fsa.action()
                            {
                            case .WRITE_READ:
                                //print("NFC: readDataFromLinkLayer - OUT L:" + fsa.data().count.description + " P:" + fsa.data().toHexString())
                                let output: Data = phd.packInnerPacket(tag: tag, bytes: fsa.data())
                                self.transceiveEMPTY(tag: tag, payload: output)
                                break
                            case .READ:
                                self.readLengthFromLinkLayer(tag: tag)
                                break
                            default:
                                let result : Bool = ( fsa.data().count > 0 && fsa.data().first == 1 )
                                trace("NFC: readDataFromLinkLayer - end of session, status = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .info, result.description)
                                self.closeSession(success: result)
                                break
                            }
                        } else {
                            trace("NFC: readDataFromLinkLayer - unpack data failed", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                            self.closeSession(success: false)
                        }
                }
            } else {
                // bound length to mleMax
                let boundedLength : Int = min((remaining - length), self.mleMax)
                // read and cache next chunk
                self.readDataFromLinkLayer(tag: tag, offset: (offset+length), remaining: (remaining - length), length: boundedLength)
            }

        }
    }
    
    fileprivate func readLengthFromLinkLayer(tag : NFCISO7816Tag) -> Void {
        // clear previous cached response
        self.cachedResponse = Data()
        // read length
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:0x00, p2Parameter:0x00, data: Data(), expectedResponseLength:2)
        trace("NFC: readLengthFromLinkLayer - command = {}", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug)
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: readLengthFromLinkLayer - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: readLengthFromLinkLayer - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            guard (response.count == 2) else {
                trace("NFC: readLengthFromLinkLayer - Invalid response length", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            
            trace("NFC: readLengthFromLinkLayer - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())

            let len : Int = Int(response[0]) * 256 + Int(response[1])
            if (len <= self.mleMax) {
                // read only one chunk
                self.readDataFromLinkLayer(tag: tag, offset: 2, remaining: 0, length: len)
            } else {
                // read several chunks
                self.readDataFromLinkLayer(tag: tag, offset: 2, remaining: len, length: self.mleMax)
            }
        }
    }
    
    fileprivate func transceiveSN(tag : NFCISO7816Tag) -> Void {
        let buf : Data = Data([ 0xE1, 0x04 ])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xA4, p1Parameter:0x00, p2Parameter:0x0C, data: buf, expectedResponseLength:-1)
        trace("NFC: transceiveSN - command = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, buf.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: transceiveSN - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: transceiveSN - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            trace("NFC: transceiveSN - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())
            self.readLengthFromLinkLayer(tag: tag)
        }
    }

    fileprivate func readContainer(tag : NFCISO7816Tag) -> Void {
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:0x00, p2Parameter:0x00, data: Data(), expectedResponseLength:15)
        trace("NFC: readContainer - command = {}", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug)
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: readContainer - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: readContainer - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            guard (response.count == 15) else {
                trace("NFC: readContainer - Invalid response length", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }

            trace("NFC: readContainer - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())
            //let cclen : UInt16 = UInt16(response[0]) * 256 + UInt16(response[1])
            //let mapping : UInt8 = response[2]
            self.mleMax = Int(response[3]) * 256 + Int(response[4])
            self.mleMax = min(self.mleMax, 255)
            self.mlcMax = Int(response[5]) * 256 + Int(response[6])
            self.mlcMax = min(self.mlcMax, 255)
            //let t : UInt8 = response[7]
            //let l : UInt8 = response[8]
            //let ident : UInt16 = UInt16(response[9]) * 256 + UInt16(response[10])
            //let nmax : UInt16 = UInt16(response[11]) * 256 + UInt16(response[12])
            //let rsec : UInt8 = response[13]
            //let wsec : UInt8 = response[14]
            //print("NFC: cclen=0x", String(format: "%04X", cclen))
            //print("NFC: mapping=0x", String(format: "%02X", mapping))
            //print("NFC: t=0x", String(format: "%02X", t))
            //print("NFC: l=0x", String(format: "%02X", l))
            //print("NFC: ident=0x", String(format: "%04X", ident))
            //print("NFC: nmax=0x", String(format: "%04X", nmax))
            //print("NFC: rsec=0x", String(format: "%02X", rsec))
            //print("NFC: wsec=0x", String(format: "%02X", wsec))

            self.transceiveSN(tag: tag)
        }
    }
    
    fileprivate func transceiveSC(tag : NFCISO7816Tag) -> Void {
        let buf : Data = Data([ 0xE1, 0x03 ])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xA4, p1Parameter:0x00, p2Parameter:0x0C, data: buf, expectedResponseLength:-1)
        trace("NFC: transceiveSC - command = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, buf.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: transceiveSC - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: transceiveSC - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            trace("NFC: transceiveSC - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())
            self.readContainer(tag: tag)
        }
    }

    fileprivate func transceiveSA(tag : NFCISO7816Tag) -> Void {
        let buf : Data = Data([ 0xD2, 0x76, 0x00, 0x00, 0x85, 0x01, 0x01 ])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xA4, p1Parameter:0x04, p2Parameter:0x00, data: buf, expectedResponseLength:256)
        trace("NFC: transceiveSA - command = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, buf.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    trace("NFC: transceiveSA - response error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                }
                self.closeSession(success: false)
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                trace("NFC: transceiveSA - Invalid response", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
                self.closeSession(success: false)
                return
            }
            trace("NFC: transceiveSA - response = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .debug, response.toHexString())
            self.transceiveSC(tag: tag)
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        // Process detected tag objects.
        trace("NFC: tagReaderSession - Tag detected", log: self.log, category: ConstantsLog.categoryNovopenController, type: .info)

        guard let firstTag = tags.first else { return }
        guard case .iso7816(let tag) = firstTag else { return }

        session.connect(to: firstTag) { error in
            if let error = error {
                trace("NFC: tagReaderSession - Connection failure error = %{public}@", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error, error.localizedDescription)
                self.closeSession(success: false)
                return
            }
            
            trace("NFC: tagReaderSession - Tag connected", log: self.log, category: ConstantsLog.categoryNovopenController, type: .info)
            self.transceiveSC(tag: tag)
        }
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        trace("NFC: tagReaderSessionDidBecomeActive - session did become active", log: self.log, category: ConstantsLog.categoryNovopenController, type: .info)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            // Show an alert when the invalidation reason is not because of a
            // successful read during a single-tag read session, or because the
            // user canceled a multiple-tag read session from the UI or
            // programmatically using the invalidate method call.
            if (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                trace("NFC: tagReaderSession - session invalidation", log: self.log, category: ConstantsLog.categoryNovopenController, type: .error)
            }
        }
        // To read new tags, a new session instance is required.
        self.session = nil
        self.resetContext()
    }

}
