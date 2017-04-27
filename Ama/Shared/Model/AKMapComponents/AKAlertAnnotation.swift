import MapKit
import UIKit

class AKAlertAnnotation: MKPointAnnotation, NSCoding {
    // MARK: Constants
    struct Keys {
        static let id = "AK.alert.annotation.id"
        static let title = "AK.alert.annotation.title"
        static let subtitle = "AK.alert.annotation.subtitle"
        static let locationLat = "AK.alert.annotation.location.lat"
        static let locationLon = "AK.alert.annotation.location.lon"
    }
    
    // MARK: Properties
    var id: String
    var titleLabel: String
    var subtitleLabel: String
    var location: GeoCoordinate
    
    // MARK: Initializers
    init(id: String, titleLabel: String, subtitleLabel: String, location: GeoCoordinate) {
        self.id = id
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel
        self.location = location
        
        super.init()
        self.title = titleLabel
        self.subtitle = subtitleLabel
        self.coordinate = location
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: Keys.id) as! String
        let title = aDecoder.decodeObject(forKey: Keys.title) as! String
        let subtitle = aDecoder.decodeObject(forKey: Keys.subtitle) as! String
        let locationLat = aDecoder.decodeDouble(forKey: Keys.locationLat)
        let locationLon = aDecoder.decodeDouble(forKey: Keys.locationLon)
        
        self.init(id: id, titleLabel: title, subtitleLabel: subtitle, location: GeoCoordinate(latitude: locationLat, longitude: locationLon))
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: Keys.id)
        aCoder.encode(self.titleLabel, forKey: Keys.title)
        aCoder.encode(self.subtitleLabel, forKey: Keys.subtitle)
        aCoder.encode(self.location.latitude, forKey: Keys.locationLat)
        aCoder.encode(self.location.longitude, forKey: Keys.locationLon)
    }
}
