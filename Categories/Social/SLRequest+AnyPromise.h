//
//  Created by merowing on 09/05/2014.
//
//
//

#import <PromiseKit/AnyPromise.h>
#import <Social/SLRequest.h>

/**
 To import the `SLRequest` category:

    use_frameworks!
    pod "PromiseKit/Social"

 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
*/
@interface SLRequest (PromiseKit)

/**
 Performs the request asynchronously.

 @return A promise that fulfills with three parameters:

  1) The response decoded as JSON.
  2) The `NSHTTPURLResponse`.
  3) The raw `NSData` response.

 @warning *Note* If PromiseKit determines the response is not JSON, the first
 parameter will instead be plain `NSData`.
*/
- (AnyPromise *)promise;

@end
