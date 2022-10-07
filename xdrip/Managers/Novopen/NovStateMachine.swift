//
//  NovStateMachine.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation
import os

class NovStateMachine {
    
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryNovopenStateMachine)

    fileprivate enum State : CaseIterable  {
        case AWAIT_ASSOCIATION_REQ
        case AWAIT_CONFIGURATION
        case ASK_INFORMATION
        case AWAIT_INFORMATION
        case AWAIT_STORAGE_INFO
        case AWAIT_XFER_CONFIRM
        case AWAIT_LOG_DATA
        case AWAIT_CLOSE_DOWN
        case PROFIT
        
        var description: String {
            return String(describing: self)
        }

        func next() -> State {
          let all = type(of: self).allCases // 1
          if self == all.last! {
            return all.first!
          } else {
            let index = all.firstIndex(of: self)!
            return all[index + 1]
          }
        }
    }
    
    private var curInsulinDose : Int32
    private var curSegmentCount : Int32
    private var state : State
    
    public init()
    {
        curInsulinDose = -1
        curSegmentCount = -1
        state = State.AWAIT_ASSOCIATION_REQ
    }
    
    func processPayload(payload: Data, delegate: NovopenDelegateProtocol) -> Fsa {
        
        let msg : NovMessage = NovMessage.parse(data: payload)
        if (msg.isError()) {
            trace("NFC : NovStateMachine.processPayload - invalid message", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .error)
            return Fsa(action: .DONE, data: Data([108]))
        }
        else if (msg.wantsRelease()) {
            trace("NFC : NovStateMachine.processPayload - remote close request", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .error)
            state = .AWAIT_CLOSE_DOWN
            return Fsa(action: .WRITE_READ, data: msg.closeDown())
        }
        else
        {
            switch (state)
            {
            case .AWAIT_ASSOCIATION_REQ:
                self.curInsulinDose = 0
                if (msg.requestIsValid()) {
                    let D : Data = msg.acceptAssoc()
                    trace("NFC : NovStateMachine.processPayload - AWAIT_ASSOCIATION_REQ -> %{public}@", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug, Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
                return Fsa(action: .DONE, data: Data([107]))
                
            case .AWAIT_CONFIGURATION:
                if (msg.configIsValid()) {
                    let D : Data = msg.acceptConfig()
                    trace("NFC : NovStateMachine.processPayload - AWAIT_CONFIGURATION -> %{public}@", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug, Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
                return Fsa(action: .DONE, data: Data([106]))
                
            case .ASK_INFORMATION:
                if (msg.configIsValid()) {
                    let D : Data = msg.askInformation()
                    trace("NFC : NovStateMachine.processPayload - ASK_INFORMATION -> %{public}@", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug, Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
                return Fsa(action: .DONE, data: Data([105]))

            case .AWAIT_INFORMATION:
                if (msg.specificationIsValid()) {
                    let D : Data = msg.confirmedAction()
                    trace("NFC : NovStateMachine.processPayload - AWAIT_INFORMATION -> %{public}@", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug, Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                } else {
                    let D : Data = msg.askInformation()
                    trace("NFC : NovStateMachine.processPayload - AWAIT_INFORMATION -> %{public}@", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug, Apdu.parse(data:D).description())
                    return Fsa(action: .WRITE_READ, data: D)
                }

            case .AWAIT_STORAGE_INFO:
                if (msg.segmentInfoIsValid()) {
                    self.curSegmentCount = msg.currentSegmentUsage()
                    let D : Data = msg.xferAction(segmentId: msg.currentSegmentId() )
                    trace("NFC : NovStateMachine.processPayload - AWAIT_STORAGE_INFO -> %{public}@", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug, Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
                return Fsa(action: .DONE, data: Data([104]))

            case .AWAIT_XFER_CONFIRM:
                if (msg.segmentDataIsValid()) {
                    trace("NFC : NovStateMachine.processPayload - AWAIT_XFER_CONFIRM -> next step", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug)
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: Data())
                }
                return Fsa(action: .DONE, data: Data([103]))

            case .AWAIT_LOG_DATA:
                if (msg.isEmpty()) {
                    trace("NFC : NovStateMachine.processPayload - AWAIT_LOG_DATA -> retrying...", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .error)
                    return Fsa(action: .WRITE_READ, data: Data())
                }
                if (self.curSegmentCount != (msg.index() + msg.count())) {
                    
                    let doses : [NovInsulinDose] = msg.doses()
                    if (doses.count > 0) {
                        for d in doses {
                            if ( d.isValid() && self.curInsulinDose < ConstantsNovopen.maxDosesToDownload ) {
                                delegate.receivedInsulinData(serialNumber: msg.pencilSerialNumber(), date: d.time(), dose: d.unit())
                                self.curInsulinDose += 1
                            }
                        }
                    }
                    
                    return Fsa(action: .WRITE_READ, data: msg.confirmedXfer())
                }
                let doses : [NovInsulinDose] = msg.doses()
                if (doses.count > 0) {
                    for d in doses {
                        if ( d.isValid() && self.curInsulinDose < ConstantsNovopen.maxDosesToDownload ) {
                            delegate.receivedInsulinData(serialNumber: msg.pencilSerialNumber(), date: d.time(), dose: d.unit())
                            self.curInsulinDose += 1
                        }
                    }
                }
                
                trace("NFC : NovStateMachine.processPayload - AWAIT_LOG_DATA -> close connection", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug)

                state = state.next()
                return Fsa(action: .WRITE_READ, data: msg.closeDown())
                
            case .AWAIT_CLOSE_DOWN:
                if (msg.isClosed() == false) {
                    trace("NFC : NovStateMachine.processPayload - AWAIT_CLOSE_DOWN -> missing expected closure", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .error)
                    return Fsa(action: .DONE, data: Data([102]))
                } else {
                    trace("NFC : NovStateMachine.processPayload - AWAIT_CLOSE_DOWN -> successful download", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .debug)
                    return Fsa(action: .DONE, data: Data([0]))
                }
            case .PROFIT:
                trace("NFC : NovStateMachine.processPayload - PROFIT -> not implemented yet", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .error)
                return Fsa(action: .DONE, data: Data([101]))
            }
        }
        
        //trace("NFC : NovStateMachine.processPayload - processing failed", log: self.log, category: ConstantsLog.categoryNovopenStateMachine, type: .error)
        //return Fsa(action: .DONE, data: Data([100]))
    }
    
    
}
