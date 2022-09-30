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

class TreatmentsViewController : UIViewController {
    	
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
	
    private var novopenManager : NovopenManager?
        
    @IBAction func importPencilData(_ sender: UIBarButtonItem) {
        if let novopen = self.novopenManager {
            novopen.read()
        }
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
        self.novopenManager = NovopenManager(delegate: self)
        
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

extension TreatmentsViewController : NovopenDelegateProtocol
{
    func receivedInsulinData(serialNumber: String, date: Date, dose: Double) {
        
        // possibly not running on main thread here
        DispatchQueue.main.async {
            print("TreatmentsViewController - received insulin data from pencil SN=" + serialNumber + " -> date=" + date.description + " dose=" + dose.description)
            
            let treatments : [TreatmentEntry] = self.treatmentEntryAccessor.getTreatments(fromDate: date.addingTimeInterval(-1.0), toDate: date.addingTimeInterval(1.0), on: self.coreDataManager.mainManagedObjectContext)

            if (treatments.count == 0) {
                // insertion
                _ = TreatmentEntry(date: date, value: dose, treatmentType: .Insulin, nightscoutEventType: nil, nsManagedObjectContext: self.coreDataManager.mainManagedObjectContext)
                
                // save to coredata
                self.coreDataManager.saveChanges()
                
                self.reload()
                
            }
        }
    }
}
