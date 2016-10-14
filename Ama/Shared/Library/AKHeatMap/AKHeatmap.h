#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AKHeatMap : NSObject
+ (UIImage *)heatMapForMapView:(MKMapView *)mapView
                         boost:(float)boost
                     locations:(NSArray *)locations
                       weights:(NSArray *)weights;

+ (UIImage *)heatMapWithRect:(CGRect)rect
                       boost:(float)boost
                      points:(NSArray *)points
                     weights:(NSArray *)weights;

+ (UIImage *)heatMapWithRect:(CGRect)rect
                       boost:(float)boost
                      points:(NSArray *)points
                     weights:(NSArray *)weights
    weightsAdjustmentEnabled:(BOOL)weightsAdjustmentEnabled
             groupingEnabled:(BOOL)groupingEnabled;
@end
