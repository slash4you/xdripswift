import Foundation

class TextsNovopenNFC {
    
    static private let filename = "NovopenNFC"
    
    static let scanComplete: String = {
        return NSLocalizedString("scanComplete", tableName: filename, bundle: Bundle.main, value: "Scan Complete", comment: "after scanning NFC, scan complete message")
    }()

    static let holdTopOfIphoneNearSensor: String = {
        return NSLocalizedString("holdTopOfIphoneNearSensor", tableName: filename, bundle: Bundle.main, value: "Hold the top of your iOS device near the pencil to scan", comment: "when NFC scanning is started, this message will appear")
    }()

    static let nfcErrorRetryScan: String = {
        return NSLocalizedString("nfcErrorRetryScan", tableName: filename, bundle: Bundle.main, value: "Error occured while scanning the pencil. Click 'Scan' and try again.", comment: "sometimes NFC scanning creates errors, retrying may solves the problem")
    }()

}
