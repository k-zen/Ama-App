#import <Foundation/Foundation.h>
#import <Mapbox/Mapbox.h>

@interface AKHeatMap : NSObject
+ (UIImage *)heatMapForMapView:(MGLMapView *)mapView
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
