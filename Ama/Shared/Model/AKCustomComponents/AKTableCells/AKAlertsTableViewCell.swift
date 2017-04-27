import UIKit

class AKAlertsTableViewCell: UITableViewCell {
    // MARK: Outlets
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var titleValue: UILabel!
    @IBOutlet weak var radiusValue: UILabel!
    
    // MARK: UITableViewCell Overriding
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
