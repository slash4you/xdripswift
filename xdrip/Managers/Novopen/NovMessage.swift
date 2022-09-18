//
//  NovMessage.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovMessage {
    
    private static let sharedInstance = NovMessage()
    
    static let EVENT_REPORT_CHOSEN : UInt16 = 0x0100
    static let CONFIRMED_EVENT_REPORT_CHOSEN : UInt16 = 0x0101
    static let SCONFIRMED_EVENT_REPORT_CHOSEN : UInt16 = 0x0201
    static let GET_CHOSEN : UInt16 = 0x0203
    static let SGET_CHOSEN : UInt16 = 0x0103
    static let CONFIRMED_ACTION : UInt16 = 0x0107
    static let CONFIRMED_ACTION_CHOSEN : UInt16 = 0x0207
    static let MDC_ACT_SEG_GET_INFO : UInt16 = 0x0C0D
    static let MDC_ACT_SEG_TRIG_XFER : UInt16 = 0x0C1C
    static let STORE_HANDLE : UInt16 = 0x0100
    
    private var valid : Bool
    private var invokedId : UInt16
    private var closed : Bool
    private var apdu : Apdu
    private var aarq : Aarq
    private var aare : Aare
    private var aReport : NovEventReport
    private var aRequest : NovEventRequest
    private var aInfo : NovEventInfo
    
    private init() {
        valid = false
        invokedId = 0
        closed = false
        apdu = Apdu()
        aarq = Aarq()
        aare = Aare()
        aReport = NovEventReport()
        aRequest = NovEventRequest()
        aInfo = NovEventInfo()
    }
    
    static func reset() -> Void {
        sharedInstance.valid = false
        sharedInstance.invokedId = 0
        sharedInstance.closed = false
        sharedInstance.apdu = Apdu()
        sharedInstance.aarq = Aarq()
        sharedInstance.aare = Aare()
        sharedInstance.aReport = NovEventReport()
        sharedInstance.aRequest = NovEventRequest()
        sharedInstance.aInfo = NovEventInfo()
    }
    
    func description() -> String {
        var logmsg : String = ""
        if (valid == true) {
            logmsg = "[MSG] Id:" + String(format: "%04X", invokedId)
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
    
    func configIsValid() -> Bool {
        return aReport.config().isAsExpected()
    }
    
    func isClosed() -> Bool {
        return closed
    }
    
    func acceptAssoc() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Aare)
        let R : Aare = Aare(res: 3, pro: Apoep.APOEP, a: self.aarq.payload())
        //let P : Data = R.encode()
        //print("NFC: ", Aare.parse(data: P).description())
        return A.encode(payload: R.encode())
    }
    
    func closeDown() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Rlrq)
        return A.encode(payload: Data([0x00, 0x00]))
    }
    
    //NFC:  [DPDU] invokeId:0000 Choice:0101 L:188 Payload:
    //  H   TIME      T   L
    // 0000 00000000 0d1c 00b2
    //  ID   N    L
    // 400a 0004 00ac
    //  _    H   NAT  _     STORE_CAPAB  SAMPLE_ALG    CAPAC_CNT       OPSTAT        STORE_LABEL      NUM_SEG      TIMEOUT          USAGE_CNT
    // 003d 0100 0008 0038 0a4d00020800 094300020000 0941000400000320 095300020000 0a5700040002504d 095100020001 0a63000400000000 0944000400000017
    //  _    H    NAT _     ID               SPEC_SMALL   UNIT_CODE   MAP
    // 0006 0002 0004 0020 092f000400823401 0a460002f040 099600021560 0a550008 0001 0004 0a56 0004
    //  _    H   NAT  _     ID               SPEC_SMALL   MAP
    // 0005 0003 0003 001a 092f000400823402 0a460002f040 0a550008 0001 0004 0a66 0002
    //  _    H   NAT  _     ID               SPEC_SMALL   MAP
    // 0006 0004 0003 001a 092f00040082f000 0a460002f040 0a550008 0001 0004 0a66 0002
    //NFC : [REPORT] L:178 handle:0000 instance:0000 index:0 count:0 doses:  config: [CONF] L:172 valid:true id:400A handle:0100 nbSegments:1 totalEntries:23 totalStorage:800 unitCode:5472 maps:{[(0A56,0004) ] [(0A66,0002) ] [(0A66,0002) ] }
    
    //NFC:  [REQUEST] handle:0000 time:00000000 type:0D1C replyLen:0004 reportId:400A reportResult:0000
    //NFC: NovStateMachine.processPayload - AWAIT_CONFIGURATION [APDU] Value:E700 Type:Prst L:22 Payload:001400000201000e0000000000000d1c0004400a0000
    //NFC: readDataFromLinkLayer - OUT L:26 P:e7000016001400000201000e0000000000000d1c0004400a0000
    //NFC:  [PHDLL] Opcode:D1 Header: Sum:83 Seq:03 Payload:e7000016 001400000201000e 0000 00000000 0d1c 0004 400a 0000

    func acceptConfig() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Prst)
        let D : Dpdu = Dpdu(invokeId: self.invokedId, choice: NovMessage.SCONFIRMED_EVENT_REPORT_CHOSEN)
        let R : NovEventRequest = NovEventRequest(handle:0,time:0,type:NovEventReport.EventType.MDC_NOTI_CONFIG.rawValue)
        let P : Data = R.encode(reportId:self.aReport.config().id(),reportResult:0)
        //print("NFC: ", NovEventRequest.parse(data: P).description())
        return A.encode(payload: D.encode(payload: P))
    }
        
    //NFC:  [DPDU] invokeId:0000 Choice:0203 L:62 Payload:0100000800380a4d0002080009430002000009410004000003200953000200000a5700040002504d0951000200010a630004000000000944000400000018
    //NFC : [INFO] > [SPEC] SN:? PN:? SW:? HW:? > [MODEL] name:? > [TIME] relative:00000000 absolute:1970-01-01 00:00:00 +0000

    func askInformation() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Prst)
        let D : Dpdu = Dpdu(invokeId: self.invokedId, choice: NovMessage.SGET_CHOSEN)
        var P : Data = Data()
        let H1 : UInt8 = UInt8((self.aReport.config().handle() >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(self.aReport.config().handle() & 0xFF)
        P.append(contentsOf: [H1, H0])
        P.append(contentsOf: [0, 0])
        P.append(contentsOf: [0, 0])
        return A.encode(payload: D.encode(payload: P))
    }


    static func parse(data: Data) -> NovMessage {
        let msg : NovMessage = sharedInstance
        
        if (data.count < 4) {
            print("NFC: NovMessage.parse - Invalid payload data")
            return msg
        }
                
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
            let dpdu : Dpdu = Dpdu.parse(data: msg.apdu.payload())
            
            msg.invokedId = dpdu.invokeId()
            
            print ("NFC: ", dpdu.description())

            switch (dpdu.choice())
            {
                case CONFIRMED_ACTION_CHOSEN:
                print("NFC: NovMessage.parse - not implemented yet")
                break
                case CONFIRMED_EVENT_REPORT_CHOSEN:
                msg.aReport = NovEventReport.parse(data: dpdu.payload())
                print("NFC : " + msg.aReport.description())
                break
                case SCONFIRMED_EVENT_REPORT_CHOSEN:
                msg.aRequest = NovEventRequest.parse(data: dpdu.payload())
                print("NFC : " + msg.aRequest.description())
                break
                case GET_CHOSEN:
                msg.aInfo = NovEventInfo.parse(data: dpdu.payload())
                print("NFC : " + msg.aInfo.description())
                break
                case SGET_CHOSEN:
                msg.aInfo = NovEventInfo.parse(data: dpdu.payload())
                print("NFC : " + msg.aInfo.description())
                break
                case CONFIRMED_ACTION:
                print("NFC: NovMessage.parse - not implemented yet")
                break
                default:
                print("NFC: NovMessage.parse - unexpected action = " + String(format: "%04X", dpdu.choice()))
                break
            }
            
            break
        }
        
        return msg
    }
    
}
