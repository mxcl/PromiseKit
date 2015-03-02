#import <MapKit/MKMapSnapshotter.h>
#import "PromiseKit/fwd.h"

/**
 To import the `MKSnapshotter` category:

    pod "PromiseKit/MKSnapshotter"

 Or you can import all categories on `MapKit`:

    pod "PromiseKit/MapKit"
*/
@interface MKMapSnapshotter (PromiseKit)

/**
 Starts generating the snapshot using the options set in this object.

 @return A promise that fulfills with the generated `MKMapSnapshot` object.
*/
- (PMKPromise *)promise;

@end
