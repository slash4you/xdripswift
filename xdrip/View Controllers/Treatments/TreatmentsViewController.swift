//
//  TreatmentsViewController.swift
//  xdrip
//
//  Created by Eduardo Pietre on 23/12/21.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation
import UIKit
import os
import CoreNFC // SLH

class TreatmentsViewController : UIViewController, NFCTagReaderSessionDelegate {
    	
	// MARK: - private properties
	
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryWebServerController)

	/// TreatmentCollection is used to get and sort data.
	private var treatmentCollection: TreatmentCollection?
	
	/// reference to coreDataManager
	private var coreDataManager: CoreDataManager!
	
	/// reference to treatmentEntryAccessor
	private var treatmentEntryAccessor: TreatmentEntryAccessor!
	
	// Outlets
	@IBOutlet weak var titleNavigation: UINavigationItem!
    
	@IBOutlet weak var tableView: UITableView!
	
    private var session : NFCTagReaderSession? // SLH
    
    private var phd : PHDLinkLayerHelper? // SLH
    
    private var engine : NovStateMachine? // SLH
    
    private var transaction : Int = 0 // SLH
    
    private var mlcMax : Int = 255 // SLH
    
    private var mleMax : Int = 255 // SLH
    
    private var cachedResponse : Data = Data() // SLH

    // SLH
    @IBAction func importPencilData(_ sender: UIBarButtonItem) {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC: NFC is not available@")
            return
        }

        if (self.session == nil) {
            self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
            self.phd = PHDLinkLayerHelper()
            self.engine = NovStateMachine()
            self.transaction = 0
            self.mlcMax = 255
            self.mleMax = 255
            self.cachedResponse = Data()
            if let tagSession = self.session {
                tagSession.alertMessage = TextsLibreNFC.holdTopOfIphoneNearSensor
                print("NFC: NFC start session@")
                tagSession.begin()
            }
        }
    }

    // SLH
    func transceiveEMPTY(tag : NFCISO7816Tag, payload: Data) {
        let empty : Data = Data([0x00,0x03,0xD0,0x00,0x00])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xD6, p1Parameter:0x00, p2Parameter:0x00, data: empty, expectedResponseLength:-1)
        print("NFC: transceiveEMPTY - Send Empty command@", empty.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: transceiveEMPTY - Empty response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: transceiveEMPTY - Empty Update response@")
                return
            }
            print("NFC: transceiveEMPTY - Empty response data@", response.toHexString())
            self.transceiveUP( tag: tag, payload: payload )
        }
    }

    // SLH
    func transceiveUP(tag : NFCISO7816Tag, payload: Data) {
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xD6, p1Parameter:0x00, p2Parameter:0x00, data: payload, expectedResponseLength:-1)
        print("NFC: transceiveUP - Send Update command@", payload.toHexString())
        
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: transceiveUP - Update response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: transceiveUP - Invalid Update response@")
                return
            }
            print("NFC: transceiveUP - Update response data@", response.toHexString())
            self.readLengthFromLinkLayer(tag: tag)
        }
    }
    
    // SLH
    func readDataFromLinkLayer(tag: NFCISO7816Tag, offset: Int, remaining: Int, length: Int) -> Void {
        // build arguments
        let O1 : UInt8 = UInt8((offset >> 8) & 0xFF)
        let O0 : UInt8 = UInt8(offset & 0xFF)
        // read data
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:O1, p2Parameter:O0, data: Data(), expectedResponseLength:length)
        print("NFC: readDataFromLinkLayer - Send Read Binary command offset=" + offset.description + " remaining=" + remaining.description + " length=" + length.description)
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: readDataFromLinkLayer - Read Binary response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: readDataFromLinkLayer - Invalid Read Binary response sw1=" + String(format: "%02X", sw1) + " sw2=" + String(format: "%02X", sw2) + " resp.length=" + response.count.description)
                return
            }
            guard (response.count == length) else {
                print("NFC: readDataFromLinkLayer - Invalid Read Binary response length@")
                return
            }

            print("NFC: readDataFromLinkLayer - Read Binary response data@", response.toHexString())

            // cache response
            self.cachedResponse.append(contentsOf: response)
            
            if (remaining <= length) {
                
                if let phd = self.phd, let engine = self.engine {
                    self.transaction += 1
                    if (self.transaction < 12) {
                        
                        let input : Data = phd.unpackInnerPacket(tag: tag, bytes: self.cachedResponse)
                        print("NFC: readDataFromLinkLayer - IN transaction:" + self.transaction.description + " L:" + input.count.description + " P:" + input.toHexString())
                        
                        if (input.count >= 0) {
                            let fsa : Fsa = engine.processPayload(payload: input)
                            switch fsa.action()
                            {
                            case .WRITE_READ:
                                print("NFC: readDataFromLinkLayer - OUT L:" + fsa.data().count.description + " P:" + fsa.data().toHexString())
                                let output: Data = phd.packInnerPacket(tag: tag, bytes: fsa.data())
                                self.transceiveEMPTY(tag: tag, payload: output)
                                break
                            case .READ:
                                self.readLengthFromLinkLayer(tag: tag)
                                break
                            default:
                                print("NFC: readDataFromLinkLayer - no further action (" + fsa.action().description + ")")
                                if let session = self.session {
                                    session.invalidate()
                                }
                                break
                            }
                        } else {
                            print("NFC: readDataFromLinkLayer - unpack data failed")
                        }
                    } else {
                        print("NFC: readDataFromLinkLayer - maximum of transactions reached")
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
    
    // SLH
    func readLengthFromLinkLayer(tag : NFCISO7816Tag) -> Void {
        // clear previous cached response
        self.cachedResponse = Data()
        // read length
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:0x00, p2Parameter:0x00, data: Data(), expectedResponseLength:2)
        print("NFC: readLengthFromLinkLayer - Send Read Length command@")
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: readLengthFromLinkLayer - Read Length response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: readLengthFromLinkLayer - Invalid Read Length response@")
                return
            }
            guard (response.count == 2) else {
                print("NFC: readLengthFromLinkLayer - Invalid Read Length response@")
                return
            }
            let len : Int = Int(response[0]) * 256 + Int(response[1])
            print("NFC: readLengthFromLinkLayer - Expected Binary response length : L=", len)
            
            if (len <= self.mleMax) {
                // read only one chunk
                self.readDataFromLinkLayer(tag: tag, offset: 2, remaining: 0, length: len)
            } else {
                // read several chunks
                self.readDataFromLinkLayer(tag: tag, offset: 2, remaining: len, length: self.mleMax)
            }
        }
    }
    
    // SLH
    func transceiveSN(tag : NFCISO7816Tag) -> Void {
        let buf : Data = Data([ 0xE1, 0x04 ])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xA4, p1Parameter:0x00, p2Parameter:0x0C, data: buf, expectedResponseLength:-1)
        print("NFC: transceiveSN - Send SN command@", buf.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: transceiveSN - SN response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: transceiveSN - Invalid SN response@")
                return
            }
            print("NFC: transceiveSN - SN response data@", response.toHexString())
            self.readLengthFromLinkLayer(tag: tag)
        }
    }

    // SLH
    func readContainer(tag : NFCISO7816Tag) -> Void {
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:0x00, p2Parameter:0x00, data: Data(), expectedResponseLength:15)
        print("NFC: readContainer - Send Read Binary command@")
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: readContainer - Read Binary response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: readContainer - Invalid Read Binary response@")
                return
            }
            guard (response.count == 15) else {
                print("NFC: readContainer - Invalid Read Binary response length@")
                return
            }
            print("NFC: readContainer - Read Binary response data@", response.toHexString())
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
            print("NFC: mleMax=0x", String(format: "%08X", self.mleMax))
            print("NFC: mlcMax=0x", String(format: "%08X", self.mlcMax))
            //print("NFC: t=0x", String(format: "%02X", t))
            //print("NFC: l=0x", String(format: "%02X", l))
            //print("NFC: ident=0x", String(format: "%04X", ident))
            //print("NFC: nmax=0x", String(format: "%04X", nmax))
            //print("NFC: rsec=0x", String(format: "%02X", rsec))
            //print("NFC: wsec=0x", String(format: "%02X", wsec))

            self.transceiveSN(tag: tag)
        }
    }
    
    // SLH
    func transceiveSC(tag : NFCISO7816Tag) -> Void {
        let buf : Data = Data([ 0xE1, 0x03 ])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xA4, p1Parameter:0x00, p2Parameter:0x0C, data: buf, expectedResponseLength:-1)
        print("NFC: transceiveSC - Send SC command@", buf.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: transceiveSC - SC response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: transceiveSC - Invalid SC response@")
                return
            }
            print("NFC: transceiveSC - SC response data@", response.toHexString())
            self.readContainer(tag: tag)
        }
    }

    // SLH
    func transceiveSA(tag : NFCISO7816Tag) -> Void {
        let buf : Data = Data([ 0xD2, 0x76, 0x00, 0x00, 0x85, 0x01, 0x01 ])
        let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xA4, p1Parameter:0x04, p2Parameter:0x00, data: buf, expectedResponseLength:256)
        print("NFC: transceiveSA - Send SA command@", buf.toHexString())
        tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error == nil else {
                if let error = error {
                    print("NFC: transceiveSA - SA response error@", error.localizedDescription)
                }
                return
            }
            guard (sw1 == 0x90 && sw2 == 00) else {
                print("NFC: transceiveSA - Invalid SA response@")
                return
            }
            print("NFC: transceiveSA - SA response data@", response.toHexString())
            self.transceiveSC(tag: tag)
        }
    }
    
    // SLH
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        // Process detected tag objects.
        print("NFC: tagReaderSession - Tag detected@")
            
        guard let firstTag = tags.first else { return }
        guard case .iso7816(let tag) = firstTag else { return }

        session.connect(to: firstTag) { error in
            if let error = error {
                print("NFC: tagReaderSession - Connection failure@", error.localizedDescription)
                return
            }
            print("NFC: tagReaderSession - Tag connected@")
            self.transceiveSC(tag: tag)
        }
    }
    
    // SLH
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("NFC: tagReaderSessionDidBecomeActive - session did become active@")
    }
    
    // SLH
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            // Show an alert when the invalidation reason is not because of a
            // successful read during a single-tag read session, or because the
            // user canceled a multiple-tag read session from the UI or
            // programmatically using the invalidate method call.
            if (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                //DispatchQueue.main.async {
                    print("NFC: tagReaderSession - NFC error, session invalidation@")
                //}
            }
        }
        // To read new tags, a new session instance is required.
        self.session = nil
        self.phd = nil
        self.engine = nil
        self.transaction = 0
        self.mleMax = 255
        self.mlcMax = 255
        self.cachedResponse = Data()
        NovMessage.reset()
    }

    // MARK: - View Life Cycle
	override func viewWillAppear(_ animated: Bool) {
        
		super.viewWillAppear(animated)
		
		// Fixes dark mode issues
		if let navigationBar = navigationController?.navigationBar {
			navigationBar.barStyle = UIBarStyle.blackTranslucent
			navigationBar.barTintColor  = UIColor.black
			navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
		}
		
		self.titleNavigation.title = Texts_TreatmentsView.treatmentsTitle
        
        // add observer for nightScoutTreatmentsUpdateCounter, to reload the screen whenever the value changes
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.nightScoutTreatmentsUpdateCounter.rawValue, options: .new, context: nil)
        
        // add observer for bloodGlucoseUnitIsMgDl, to reload the screen whenever the bg unit changes
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.bloodGlucoseUnitIsMgDl.rawValue, options: .new, context: nil)
        
        // add observer for showSmallBolusTreatmentsInList, to reload the screen whenever the user wants to show or hide the micro-bolus treatments
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.showSmallBolusTreatmentsInList.rawValue, options: .new, context: nil)
        
        // add observer for smallBolusTreatmentThreshold, to reload the screen whenever the user changes the threshold value (this can mean we need to show more, or less, bolus treatments)
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.smallBolusTreatmentThreshold.rawValue, options: .new, context: nil)
        
	}
	

	/// Override prepare for segue, we must call configure on the TreatmentsInsertViewController.
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
		// Check if is the segueIdentifier to TreatmentsInsert.
		guard let segueIndentifier = segue.identifier, segueIndentifier == TreatmentsViewController.SegueIdentifiers.TreatmentsToNewTreatmentsSegue.rawValue else {
			return
		}
		
		// Cast the destination to TreatmentsInsertViewController (if possible).
		// And assures the destination and coreData are valid.
		guard let insertViewController = segue.destination as? TreatmentsInsertViewController else {

			fatalError("In TreatmentsInsertViewController, prepare for segue, viewcontroller is not TreatmentsInsertViewController" )
		}

		// Configure insertViewController with CoreData instance and complete handler.
        insertViewController.configure(treatMentEntryToUpdate: sender as? TreatmentEntry, coreDataManager: coreDataManager, completionHandler: {
            self.reload()
        })
        
	}
	
	
	// MARK: - public functions
	
	/// Configure will be called before this view is presented for the user.
	public func configure(coreDataManager: CoreDataManager) {
        
		// initalize private properties
		self.coreDataManager = coreDataManager
		self.treatmentEntryAccessor = TreatmentEntryAccessor(coreDataManager: coreDataManager)
	
		self.reload()
        
	}
	

	// MARK: - private functions
	
	/// Reloads treatmentCollection and calls reloadData on tableView.
	private func reload() {
        
        if UserDefaults.standard.showSmallBolusTreatmentsInList {
            
            self.treatmentCollection = TreatmentCollection(treatments: treatmentEntryAccessor.getLatestTreatments(howOld: TimeInterval(days: 100)).filter( {!$0.treatmentdeleted} ))
            
        } else {
            
            self.treatmentCollection = TreatmentCollection(treatments: treatmentEntryAccessor.getLatestTreatments(howOld: TimeInterval(days: 100)).filter( {!$0.treatmentdeleted && (($0.treatmentType != .Insulin) || ($0.treatmentType == .Insulin && $0.value >= UserDefaults.standard.smallBolusTreatmentThreshold))} ))
            
        }

		self.tableView.reloadData()
        
	}
    
    // MARK: - overriden functions

    /// when one of the observed settings get changed, possible actions to take
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let keyPath = keyPath {
            if let keyPathEnum = UserDefaults.Key(rawValue: keyPath) {
                
                switch keyPathEnum {
                    
                case UserDefaults.Key.nightScoutTreatmentsUpdateCounter, UserDefaults.Key.bloodGlucoseUnitIsMgDl, UserDefaults.Key.showSmallBolusTreatmentsInList, UserDefaults.Key.smallBolusTreatmentThreshold :
                    // Reloads data and table.
                    self.reload()
                    
                default:
                    break
                }
            }
        }
    }

}


/// defines perform segue identifiers used within TreatmentsViewController
extension TreatmentsViewController {
	
	public enum SegueIdentifiers:String {
        
		/// to go from TreatmentsViewController to TreatmentsInsertViewController
		case TreatmentsToNewTreatmentsSegue = "TreatmentsToNewTreatmentsSegue"
        
	}
	
}

// MARK: - conform to UITableViewDelegate and UITableViewDataSource

extension TreatmentsViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return self.treatmentCollection?.dateOnlys().count ?? 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let treatmentCollection = treatmentCollection else {
			return 0
		}
		// Gets the treatments given the section as the date index.
		let treatments = treatmentCollection.treatmentsForDateOnlyAt(section)
		return treatments.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "TreatmentsCell", for: indexPath) as? TreatmentTableViewCell, let treatmentCollection = treatmentCollection else {
			fatalError("Unexpected Table View Cell")
		}
		
		let treatment = treatmentCollection.getTreatment(dateIndex: indexPath.section, treatmentIndex: indexPath.row)
		cell.setupWithTreatment(treatment)
        
        // clicking the cell will always open a new screen which allows the user to edit the treatment
        cell.accessoryType = .disclosureIndicator
        
        // set color of disclosureIndicator to ConstantsUI.disclosureIndicatorColor
        cell.accessoryView = DTCustomColoredAccessory(color: ConstantsUI.disclosureIndicatorColor)
        
		return cell
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
            
			guard let treatmentCollection = treatmentCollection else {
				return
			}

			// Get the treatment the user wants to delete.
			let treatment = treatmentCollection.getTreatment(dateIndex: indexPath.section, treatmentIndex: indexPath.row)
			
			// set treatmentDelete to true in coredata.
            treatment.treatmentdeleted = true
            
            // set uploaded to false, so that at next nightscout sync, the treatment will be deleted at NightScout
            treatment.uploaded = false
			
            coreDataManager.saveChanges()
            
            // trigger nightscoutsync
            UserDefaults.standard.nightScoutSyncTreatmentsRequired = true
            
			// Reloads data and table.
			self.reload()
            
		}
	}
	
	func tableView( _ tableView : UITableView,  titleForHeaderInSection section: Int) -> String? {
		
		guard let treatmentCollection = treatmentCollection else {
			return ""
		}
		
		// Title will be the date formatted.
		let date = treatmentCollection.dateOnlyAt(section).date

		let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(ConstantsUI.dateFormatDayMonthYear)

		return formatter.string(from: date)
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		guard let titleView = view as? UITableViewHeaderFooterView else {
			return
		}
		
		// Header background color
		titleView.tintColor = UIColor.gray
		
		// Set textcolor to white and increase font
		if let textLabel = titleView.textLabel {
			textLabel.textColor = UIColor.white
			textLabel.font = textLabel.font.withSize(16)
		}
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 32.0
	}
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.performSegue(withIdentifier: TreatmentsViewController.SegueIdentifiers.TreatmentsToNewTreatmentsSegue.rawValue, sender: treatmentCollection?.getTreatment(dateIndex: indexPath.section, treatmentIndex: indexPath.row))
        
    }
    
}
