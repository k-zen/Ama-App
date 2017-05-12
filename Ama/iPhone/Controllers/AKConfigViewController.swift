import MapKit
import UIKit

class AKConfigViewController: AKCustomViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Constants
    struct LocalConstants {
        static let AKHeaderHeight: CGFloat = 34.0
        static let AKRowHeight: CGFloat = 160.0
    }
    
    // MARK: Outlets
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var alertNotificationSwitch: UISwitch!
    @IBOutlet weak var alertsTable: UITableView!
    
    // MARK: Actions
    @IBAction func back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customSetup()
    }
    
    // MARK: UITableViewDataSource Implementation
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let e = Func.AKGetUser().userDefinedAlerts[(indexPath as NSIndexPath).row]
        
        let cell = self.alertsTable.dequeueReusableCell(withIdentifier: "Alerts_Table_Cell") as! AKAlertsTableViewCell
        cell.mainContainer.backgroundColor = GlobalConstants.AKTableCellBg
        cell.titleValue.text = String(format: "%@ @ %.1fkm(s) de Radio", e.alertName, e.alertRadius)
        // Configure map.
        cell.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.mapView.userTrackingMode = MKUserTrackingMode.none
        cell.mapView.isUserInteractionEnabled = false
        
        // Load all user defined alerts.
        Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) {
            cell.mapView.addAnnotation(e.alertAnnotation)
        }
        
        Func.AKCenterMapOnLocation(
            mapView: cell.mapView,
            location: e.alertAnnotation.location,
            zoomLevel: ZoomLevel.L09
        )
        
        // Custom L&F.
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.mapView.layer.cornerRadius = GlobalConstants.AKViewCornerRadius
        cell.mapView.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = UIView(frame: CGRect(x: 16.0, y: 0.0, width: tableView.frame.width - 16.0, height: LocalConstants.AKHeaderHeight))
        headerCell.backgroundColor = GlobalConstants.AKTableHeaderCellBg
        
        let title = UILabel(frame: headerCell.frame)
        title.font = UIFont(name: GlobalConstants.AKSecondaryFont, size: 18.0)
        title.textColor = GlobalConstants.AKDefaultFg
        title.text = "Tus Alertas"
        
        // Custom L&F.
        Func.AKAddBorderDeco(
            headerCell,
            color: GlobalConstants.AKTableHeaderCellBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness * 4.0,
            position: CustomBorderDecorationPosition.left
        )
        
        headerCell.addSubview(title)
        
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Func.AKGetUser().userDefinedAlerts.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }
    
    // MARK: UITableViewDelegate Implementation
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Borrar"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            Func.AKGetUser().userDefinedAlerts.remove(at: (indexPath as NSIndexPath).row)
            self.alertsTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return LocalConstants.AKRowHeight }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return LocalConstants.AKHeaderHeight }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return CGFloat.leastNormalMagnitude }
    
    // MARK: Miscellaneous
    func customSetup() {
        self.shouldCheckLoggedUser = true
        self.loadData = { (controller) -> Void in
            if let controller = controller as? AKConfigViewController {
                controller.username.text = Func.AKGetUser().username.capitalized
            }
        }
        self.configureLookAndFeel = { (controller) -> Void in
            if let controller = controller as? AKConfigViewController {
                controller.back.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
            }
        }
        self.setup()
        
        // Custom Components
        self.alertsTable.register(UINib(nibName: "AKAlertsTableViewCell", bundle: nil), forCellReuseIdentifier: "Alerts_Table_Cell")
        
        // Delegates
        self.alertsTable?.dataSource = self
        self.alertsTable?.delegate = self
    }
}
