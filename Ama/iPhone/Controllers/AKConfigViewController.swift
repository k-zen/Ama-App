import MapKit
import UIKit

class AKConfigViewController: AKCustomViewController {
    // MARK: Outlets
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var alertNotificationSwitch: UISwitch!
    
    // MARK: Actions
    @IBAction func back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customSetup()
    }
    
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
    }
}
