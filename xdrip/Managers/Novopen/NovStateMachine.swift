//
//  NovStateMachine.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovStateMachine {

    static let MAX_REQUESTS : Int = 100
    
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
    
    
    private var curSegmentCount : Int32
    private var state : State
    
    public init()
    {
        curSegmentCount = -1
        state = State.AWAIT_ASSOCIATION_REQ
    }
    
    func processPayload(payload: Data) -> Fsa {
        
        let msg : NovMessage = NovMessage.parse(data: payload)
        print("NFC: NovStateMachine.processPayload - ", msg.description())
        if (msg.isError()) {
            print("NFC : NovStateMachine.processPayload - invalid message")
            return Fsa()
        }
        else if (msg.wantsRelease()) {
            print("NFC : NovStateMachine.processPayload - remote close request")
            state = .AWAIT_CLOSE_DOWN
            return Fsa(action: .WRITE_READ, data: msg.closeDown())
        }
        else
        {
            switch (state)
            {
            case .AWAIT_ASSOCIATION_REQ:
                if (msg.requestIsValid()) {
                    let D : Data = msg.acceptAssoc()
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " " + Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
                break
            case .AWAIT_CONFIGURATION:
                if (msg.configIsValid()) {
                    let D : Data = msg.acceptConfig()
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " " + Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
                break
            case .ASK_INFORMATION:
                if (msg.configIsValid()) {
                    let D : Data = msg.askInformation()
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " " + Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
            case .AWAIT_INFORMATION:
                if (msg.specificationIsValid()) {
                    let D : Data = msg.confirmedAction()
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " " + Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                } else {
                    let D : Data = msg.askInformation()
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " " + Apdu.parse(data:D).description())
                    return Fsa(action: .WRITE_READ, data: D)
                }
            case .AWAIT_STORAGE_INFO:
                if (msg.segmentInfoIsValid()) {
                    self.curSegmentCount = msg.currentSegmentUsage()
                    let D : Data = msg.xferAction(segmentId: msg.currentSegmentId() )
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " " + Apdu.parse(data:D).description())
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: D)
                }
            case .AWAIT_XFER_CONFIRM:
                if (msg.segmentDataIsValid()) {
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " send nil payload" )
                    state = state.next()
                    return Fsa(action: .WRITE_READ, data: Data())
                }
            case .AWAIT_LOG_DATA:
                if (msg.isEmpty()) {
                    print ("NFC: NovStateMachine.processPayload - " + state.description + " send nil payload" )
                    return Fsa(action: .WRITE_READ, data: Data())
                }
                print("NFC: NovStateMachine.processPayload - not implemented yet")
            case .AWAIT_CLOSE_DOWN:
                if (msg.isClosed() == false) {
                    print("NFC : NovStateMachine.processPayload - missing expected closure")
                }
            case .PROFIT:
                print("NFC: NovStateMachine.processPayload - not implemented yet")
            }
        }
        print("NFC: NovStateMachine.processPayload - processing failed")
        return Fsa()
    }
    
    
}
