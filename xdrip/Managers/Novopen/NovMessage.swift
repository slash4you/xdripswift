//
//  NovMessage.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovMessage {
    
    static let EVENT_REPORT_CHOSEN : Int = 0x0100
    static let CONFIRMED_EVENT_REPORT_CHOSEN : Int = 0x0101
    static let SCONFIRMED_EVENT_REPORT_CHOSEN : Int = 0x0201
    static let GET_CHOSEN : Int = 0x0203
    static let SGET_CHOSEN : Int = 0x0103
    static let CONFIRMED_ACTION : Int = 0x0107
    static let CONFIRMED_ACTION_CHOSEN : Int = 0x0207
    static let MDC_ACT_SEG_GET_INFO : Int = 0x0C0D
    static let MDC_ACT_SEG_TRIG_XFER : Int = 0x0C1C
    static let STORE_HANDLE : Int = 0x0100
    
    private var valid : Bool
    private var invokedId : Int
    private var closed : Bool
    private var length : Int
    private var apdu : Apdu
    private var aarq : Aarq
    private var aare : Aare
    private var dpdu : Dpdu
    
    public init() {
        valid = false
        invokedId = -1
        closed = false
        length = -1
        apdu = Apdu()
        aarq = Aarq()
        aare = Aare()
        dpdu = Dpdu()
    }
    
    func description() -> String {
        var logmsg : String = ""
        if (valid == true) {
            logmsg = "[MSG] Id:" + invokedId.description + " Length:" + length.description
        }
        else if (closed == true) {
            logmsg = "[MSG] Closed:" + closed.description
        }
        else {
            logmsg = "[MSG] Valid:" + valid.description
        }
        return logmsg
    }
    
    func isError() -> Bool {
        return apdu.isError()
    }
    
    func wantsRelease() -> Bool {
        return apdu.wantsRelease()
    }
    
    func requestIsValid() -> Bool {
        return aarq.isValid()
    }
    
    func isClosed() -> Bool {
        return closed
    }
    
    func requestAnswer() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Aare)
        let R : Aare = Aare(res: 3, pro: Apoep.APOEP, a: self.aarq.payload())
        let D : Data = R.encode()
        print("NFC: ", Aare.parse(data: D).description())
        return A.encode(payload: D)
    }
    
    func closeDown() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Rlrq)
        return A.encode(payload: Data([0x00, 0x00]))
    }
    
    static func parse(data: Data) -> NovMessage {
        let msg : NovMessage = NovMessage()
        
        if (data.count < 4) {
            print("NFC: NovMessage.parse - Invalid payload data")
            return msg
        }
        
        msg.length = data.count
        
        msg.apdu = Apdu.parse(data: data)
        
        print ("NFC: ",msg.apdu.description())
        
        switch msg.apdu.type() {
        case Apdu.ApduType.Aarq:
            msg.aarq = Aarq.parse(data: msg.apdu.payload())
            print("NFC: ", msg.aarq.description())
            break
        case Apdu.ApduType.Aare:
            msg.aare = Aare.parse(data: msg.apdu.payload())
            print("NFC: ", msg.aare.description())
            break
        case Apdu.ApduType.Rlrq:
            print("NFC: NovMessage.parse - not implemented yet")
            break
        case Apdu.ApduType.Rlre:
            msg.closed = true
            break
        case Apdu.ApduType.Abrt:
            print("NFC: NovMessage.parse - not implemented yet")
            break
        case Apdu.ApduType.Invalid:
            print("NFC: NovMessage.parse - not implemented yet")
            break
        case Apdu.ApduType.Prst:
            msg.valid = true
            msg.dpdu = Dpdu.parse(data: msg.apdu.payload())
            print ("NFC: ", msg.dpdu.description())
            break
        }
        
        return msg
    }
    
}
