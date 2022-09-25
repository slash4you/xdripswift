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
    private var length : Int
    private var invokedId : UInt16
    private var closed : Bool
    private var apdu : Apdu
    private var aarq : Aarq
    private var aare : Aare
    private var aReport : NovEventReport
    private var aRequest : NovEventRequest
    private var aInfo : NovEventInfo
    private var aAction : NovConfirmedAction
    private var aSegInfo : NovSegmentList
    private var aSegData : NovSegmentDataXFer
    
    private init() {
        valid = false
        length = -1
        invokedId = 0
        closed = false
        apdu = Apdu()
        aarq = Aarq()
        aare = Aare()
        aReport = NovEventReport()
        aRequest = NovEventRequest()
        aInfo = NovEventInfo()
        aAction = NovConfirmedAction()
        aSegInfo = NovSegmentList()
        aSegData = NovSegmentDataXFer()
    }
    
    static func reset() -> Void {
        sharedInstance.valid = false
        sharedInstance.length = -1
        sharedInstance.invokedId = 0
        sharedInstance.closed = false
        sharedInstance.apdu = Apdu()
        sharedInstance.aarq = Aarq()
        sharedInstance.aare = Aare()
        sharedInstance.aReport = NovEventReport()
        sharedInstance.aRequest = NovEventRequest()
        sharedInstance.aInfo = NovEventInfo()
        sharedInstance.aAction = NovConfirmedAction()
        sharedInstance.aSegInfo = NovSegmentList()
        sharedInstance.aSegData = NovSegmentDataXFer()
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
    
    func isEmpty() -> Bool {
        return length <= 0
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
    
    func specificationIsValid() -> Bool {
        return aInfo.isAsExpected()
    }
    
    func segmentInfoIsValid() -> Bool {
        return aSegInfo.isValid()
    }
    
    func currentSegmentId() -> UInt16 {
        return aSegInfo.id()
    }
    
    func currentSegmentUsage() -> Int32 {
        return aSegInfo.usage()
    }
    
    func segmentDataIsValid() -> Bool {
        return aSegData.isValid()
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

    //NFC:  [DPDU] invokeId:0000 Choice:0203 L:203 Payload:0000 0008 00c5
    //  SYS_ID                       TIME_REL         TIME_INFO
    // 0984000a0008001465004008931b 098f000400518efd 0a45001020001f00ffffffff00001f4000000000
    //  PROD_SPECN      SN=AAREY3                PN=D21491065500000 D21491065500000
    //092d004b00040047 000100010006414152455933 0002000100204432313439313036353530303030302044323134393130363535303030303020
    //  HW=00          SW=01.08.00
    // 00030001000100 00040001000830312e30382e3030
    //  SPEC_LIST                ID_MODEL
    // 0a5a00080001000410480001 0928001c00104e6f766f204e6f726469736b20412f5300084e6f766f50656e00
    //  CONFIG_ID    CERT_DATA_LIST
    // 0a440002400a 0a4b00160002001202010008040000010002a048020200020000
    //NFC : [INFO] handle:0000 > [SPEC] SN:AAREY3 PN:D21491065500000 D21491065500000  SW:01.08.00 HW:? > [MODEL] name:Novo Nordisk A/S > [TIME] relative:00519842 absolute:2022-09-19 16:49:55 +0000

    func askInformation() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Prst)
        let D : Dpdu = Dpdu(invokeId: self.invokedId, choice: NovMessage.SGET_CHOSEN)
        var P : Data = Data()
        let H1 : UInt8 = UInt8((self.aReport.handle() >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(self.aReport.handle() & 0xFF)
        P.append(contentsOf: [H1, H0])
        P.append(contentsOf: [0, 0])
        P.append(contentsOf: [0, 0])
        return A.encode(payload: D.encode(payload: P))
    }

    //NFC:  [DPDU] invokeId:0000 Choice:0207 L:116 Payload:0100 0c0d 006e
    // SEGCNT L   ID  CNT  LEN
    // 0001 006a 0010 0006 0064
    // INSTNO L   VAL
    // 0922  0002 0010
    // SEGMAP L
    // 0a4e 0036 4000000300300006008234010002000100040a5600040005008234020003000100040a66000200060082f0000004000100040a660002
    // OPSTAT L  VAL
    // 0953 0002 0000
    // SEGLBL L
    // 0a58 000a 0008446f7365204c6f67
    // USAGE  L   
    // 097b 0004 00000019
    //  TO   L
    // 0a64 0004 00027100
    // NFC : [ACTION] handle:0100 type:0C0D payload:0001006a0010000600640922000200100a4e00364000000300300006008234010002000100040a5600040005008234020003000100040a66000200060082f0000004000100040a6600020953000200000a58000a0008446f7365204c6f67097b0004000000190a64000400027100
    // NFC : [SEG_LIST] info:[SEG_INFO] processed:false instnum:0010 usage:0019 map:[SEG_MAP] bits:4000 size:3 entries: [ [SEG_ENTRY] classId:0006 OType:3401 metricType:0082 handle:0002 mcount:0001 mlen:0004 val1:0A56 val2:0004 [SEG_ENTRY] classId:0005 OType:3402 metricType:0082 handle:0003 mcount:0001 mlen:0004 val1:0A66 val2:0002 [SEG_ENTRY] classId:0006 OType:F000 metricType:0082 handle:0004 mcount:0001 mlen:0004 val1:0A66 val2:0002]

    func confirmedAction() -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Prst)
        let D : Dpdu = Dpdu(invokeId: self.invokedId, choice: NovMessage.CONFIRMED_ACTION)
        let P : NovConfirmedAction = NovConfirmedAction(handle: NovMessage.STORE_HANDLE, type: NovMessage.MDC_ACT_SEG_GET_INFO)
        return A.encode(payload: D.encode(payload: P.encode_all_segments()))
    }

    //NFC:  [DPDU] invokeId:0000 Choice:0207 L:10 Payload:0100 0c1c 0004 00100000
    //NFC : [ACTION] handle:0100 type:0C1C payload:00100000
    //NFC : [XFER] segmentId:0010 code:0000

    func xferAction(segmentId: UInt16) -> Data {
        let A : Apdu = Apdu(type: Apdu.ApduType.Prst)
        let D : Dpdu = Dpdu(invokeId: self.invokedId, choice: NovMessage.CONFIRMED_ACTION)
        let P : NovConfirmedAction = NovConfirmedAction(handle: NovMessage.STORE_HANDLE, type: NovMessage.MDC_ACT_SEG_TRIG_XFER)
        return A.encode(payload: D.encode(payload: P.encode_segment(segment: segmentId)))
    }
    
    //NFC: readDataFromLinkLayer - OUT L:0 P:
    //NFC:  [PHDLL] Opcode:D1 Header: Sum:8B Seq:11 Payload:
    //NFC: transceiveEMPTY - Send Empty command@ 0003d00000
    //NFC: transceiveEMPTY - Empty response data@
    //NFC: transceiveUP - Send Update command@ 0007d103015048448b
    //NFC: transceiveUP - Update response data@
    //NFC: readLengthFromLinkLayer - Send Read Length command@
    //NFC: readLengthFromLinkLayer - Expected Binary response length : L= 7
    //NFC: readDataFromLinkLayer - Send Read Binary command@
    //NFC: readDataFromLinkLayer - Read Binary response data@ d103015048448c
    //NFC:  [PHDLL] Opcode:D1 Header: Sum:8C Seq:12 Payload:
    //NFC: readDataFromLinkLayer - IN transaction:7 L:0 P:
    //NFC: NovMessage.parse - Invalid payload data
    //NFC: NovStateMachine.processPayload -  [MSG] Valid:false
    //NFC: readDataFromLinkLayer - OUT L:0 P:
    //NFC:  [PHDLL] Opcode:D1 Header: Sum:8D Seq:13 Payload:
    //NFC: transceiveEMPTY - Send Empty command@ 0003d00000
    //NFC: transceiveEMPTY - Empty response data@
    //NFC: transceiveUP - Send Update command@ 0007d103015048448d
    //NFC: transceiveUP - Update response data@
    //NFC: readLengthFromLinkLayer - Send Read Length command@
    //NFC: readLengthFromLinkLayer - Expected Binary response length : L= 259
    //NFC: readDataFromLinkLayer - Send Read Binary command@
    //NFC: readDataFromLinkLayer - Invalid Read Binary response@

    //NFC: readLengthFromLinkLayer - Send Read Length command@
    //NFC: readLengthFromLinkLayer - Expected Binary response length : L= 187
    //NFC: readDataFromLinkLayer - Send Read Binary command length=187
    //NFC: readDataFromLinkLayer - Read Binary response data@ d103b550484484e70000b000ae8001010100a8010000590a360d21009e0010000000000000000c800000900053030bff00001408000000004fc696ff00001908000000004e83d1ff00000f08000000004d9d3aff00003c08000000004d9ab9ff00003c0800000000454fd0ff00001e0800000000454f78ff00000a0800000000445debff00003208000000003bfcd0ff00003c08000000003345bbff00000a080000000031cf39ff000028080000000031ce4fff00004108000000
    //NFC:  [PHDLL] Opcode:D1 Header: Sum:84 Seq:04 Payload:e70000b000ae8001010100a8010000590a360d21009e0010000000000000000c800000900053030bff00001408000000004fc696ff00001908000000004e83d1ff00000f08000000004d9d3aff00003c08000000004d9ab9ff00003c0800000000454fd0ff00001e0800000000454f78ff00000a0800000000445debff00003208000000003bfcd0ff00003c08000000003345bbff00000a080000000031cf39ff000028080000000031ce4fff00004108000000
    //NFC: readDataFromLinkLayer - IN transaction:3 L:180 P:e70000b000ae8001010100a8010000590a360d21009e0010000000000000000c800000900053030bff00001408000000004fc696ff00001908000000004e83d1ff00000f08000000004d9d3aff00003c08000000004d9ab9ff00003c0800000000454fd0ff00001e0800000000454f78ff00000a0800000000445debff00003208000000003bfcd0ff00003c08000000003345bbff00000a080000000031cf39ff000028080000000031ce4fff00004108000000
    //NFC:  [APDU] Value:E700 Type:Prst L:176 Payload:00ae8001010100a8010000590a360d21009e0010000000000000000c800000900053030bff00001408000000004fc696ff00001908000000004e83d1ff00000f08000000004d9d3aff00003c08000000004d9ab9ff00003c0800000000454fd0ff00001e0800000000454f78ff00000a0800000000445debff00003208000000003bfcd0ff00003c08000000003345bbff00000a080000000031cf39ff000028080000000031ce4fff00004108000000
    //NFC:  [DPDU] invokeId:8001 Choice:0101 L:168 Payload:010000590a360d21009e0010000000000000000c800000900053030bff00001408000000004fc696ff00001908000000004e83d1ff00000f08000000004d9d3aff00003c08000000004d9ab9ff00003c0800000000454fd0ff00001e0800000000454f78ff00000a0800000000445debff00003208000000003bfcd0ff00003c08000000003345bbff00000a080000000031cf39ff000028080000000031ce4fff00004108000000
    //NFC : [REPORT] L:158 handle:0100 time:00590A36type:MDC_NOTI_SEGMENT_DATA instance:0010 index:00000000 count:12 doses: [DOSE] valid:true time:2022-09-20 18:37:45 +0000 units:2.0 flags:08000000[DOSE] valid:true time:2022-09-18 07:43:00 +0000 units:2.5 flags:08000000[DOSE] valid:true time:2022-09-17 08:45:51 +0000 units:1.5 flags:08000000[DOSE] valid:true time:2022-09-16 16:22:00 +0000 units:6.0 flags:08000000[DOSE] valid:true time:2022-09-16 16:11:19 +0000 units:6.0 flags:08000000[DOSE] valid:true time:2022-09-10 09:13:34 +0000 units:3.0 flags:08000000[DOSE] valid:true time:2022-09-10 09:12:06 +0000 units:1.0 flags:08000000[DOSE] valid:true time:2022-09-09 16:01:29 +0000 units:5.0 flags:08000000[DOSE] valid:true time:2022-09-03 07:29:02 +0000 units:6.0 flags:08000000[DOSE] valid:true time:2022-08-27 16:49:45 +0000 units:1.0 flags:08000000[DOSE] valid:true time:2022-08-26 14:11:51 +0000 units:4.0 flags:08000000[DOSE] valid:true time:2022-08-26 14:07:57 +0000 units:6.5 flags:08000000


    static func parse(data: Data) -> NovMessage {
        let msg : NovMessage = sharedInstance
        
        msg.length = data.count
        
        if (msg.length < 4) {
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
                let action : NovConfirmedAction = NovConfirmedAction.parse(data: dpdu.payload())
                print("NFC : " + action.description())
                switch (action.type()) {
                case MDC_ACT_SEG_GET_INFO:
                    msg.aSegInfo = NovSegmentList.parse(data: action.payload())
                    print("NFC : " + msg.aSegInfo.description())
                    break
                case MDC_ACT_SEG_TRIG_XFER:
                    msg.aSegData = NovSegmentDataXFer.parse(data: action.payload())
                    print("NFC : " + msg.aSegData.description())
                    break
                default:
                    print("NFC: NovMessage.parse - unexpected action = " + action.type().description)
                    break
                }
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
                msg.aAction = NovConfirmedAction.parse(data: dpdu.payload())
                print("NFC : " + msg.aAction.description())
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
