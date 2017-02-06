import UIKit

class AKConfigViewController: AKCustomViewController, UITableViewDataSource, UITableViewDelegate
{
    // MARK: Constants
    struct LocalConstants {
        static let AKHeaderHeight: CGFloat = 40
        static let AKRowHeight: CGFloat = 52
    }
    
    // MARK: Outlets
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var alertNotificationSwitch: UISwitch!
    @IBOutlet weak var alertsTable: UITableView!
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.customSetup()
    }
    
    // MARK: UITableViewDataSource Implementation
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let e = GlobalFunctions.instance(false).AKObtainMasterFile().user.userDefinedAlerts[(indexPath as NSIndexPath).row]
        
        let cell = self.alertsTable.dequeueReusableCell(withIdentifier: "Alerts_Table_Cell") as! AKAlertsTableViewCell
        cell.mainContainer.backgroundColor = GlobalConstants.AKTableCellBg
        cell.titleValue.text = e.alertName
        cell.radiusValue.text = String(format: "%.1fkm", e.alertRadius)
        
        // Custom L&F.
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        GlobalFunctions.instance(false).AKAddBorderDeco(
            cell,
            color: GlobalConstants.AKTableCellLeftBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.left
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let headerCell = UIView(frame: CGRect(x: 8, y: 0, width: 276, height: LocalConstants.AKHeaderHeight))
        headerCell.backgroundColor = GlobalConstants.AKTableHeaderCellBg
        
        let title = UILabel(frame: headerCell.frame)
        title.font = UIFont(name: GlobalConstants.AKDefaultFont, size: 20.0)
        title.textColor = GlobalConstants.AKDefaultFg
        title.text = "Alertas"
        
        // Custom L&F.
        GlobalFunctions.instance(false).AKAddBorderDeco(
            headerCell,
            color: GlobalConstants.AKTableHeaderLeftBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.left
        )
        
        headerCell.addSubview(title)
        
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return GlobalFunctions.instance(false).AKObtainMasterFile().user.userDefinedAlerts.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }
    
    // MARK: UITableViewDelegate Implementation
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    {
        return "Borrar"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == UITableViewCellEditingStyle.delete {
            GlobalFunctions.instance(false).AKObtainMasterFile().user.userDefinedAlerts.remove(at: (indexPath as NSIndexPath).row)
            self.alertsTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        return UITableViewCellEditingStyle.delete
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return LocalConstants.AKRowHeight }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return LocalConstants.AKHeaderHeight }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return CGFloat.leastNormalMagnitude }
    
    // MARK: Miscellaneous
    func customSetup()
    {
        super.setup()
        
        // Custom Components
        self.alertsTable.register(UINib(nibName: "AKAlertsTableViewCell", bundle: nil), forCellReuseIdentifier: "Alerts_Table_Cell")
        
        // Add UITableView's DataSource & Delegate.
        self.alertsTable?.dataSource = self
        self.alertsTable?.delegate = self
        
        // Custom L&F.
        GlobalFunctions.instance(false).AKAddBorderDeco(
            self.infoContainer,
            color: GlobalConstants.AKTableHeaderLeftBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.left
        )
    }
}
