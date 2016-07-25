#import <Foundation/NSDictionary.h>
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURLRequest.h>
#import <PromiseKit/fwd.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

extern NSString const*const PMKURLErrorFailingURLResponse PMK_DEPRECATED("Use PMKURLErrorFailingURLResponseKey");
extern NSString const*const PMKURLErrorFailingData PMK_DEPRECATED("Use PMKURLErrorFailingDataKey");


/**
 To import the `NSURLConnection` category:

    pod "PromiseKit/NSURLConnection"

 Or you can import all categories on `Foudnation`:

    pod "PromiseKit/Foundation"

 Or `NSURLConnection` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"

 PromiseKit automatically deserializes the raw HTTP data response into the
 appropriate rich data type based on the mime type the server provides.
 Thus if the response is JSON you will get the deserialized JSON response.
 PromiseKit supports decoding into strings, JSON and UIImages.

 PromiseKit goes to quite some lengths to provide good `NSError` objects
 for error conditions at all stages of the HTTP to rich-data type
 pipeline. We provide the following additional `userInfo` keys as
 appropriate:
   - `PMKURLErrorFailingDataKey`
   - `PMKURLErrorFailingStringKey`
   - `PMKURLErrorFailingURLResponseKey`

 PromiseKit uses [OMGHTTPURLRQ](https://github.com/mxcl/OMGHTTPURLRQ) to
 make its HTTP requests. PromiseKit only provides a convenience layer
 above OMGHTTPURLQ, thus if you need more power (eg. a multipartFormData
 POST), use OMGHTTPURLRQ to generate the `NSURLRequest` and then pass
 that request to `+promise:`.

 @see https://github.com/mxcl/OMGHTTPURLRQ
*/
@interface NSURLConnection (PromiseKit)

/**
 Makes a GET request to the provided URL.

 @param urlStringFormatOrURL The `NSURL` or string format to request.

 @return A promise that fulfills with three parameters:
 1) The deserialized data response.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.
*/
+ (PMKPromise *)GET:(id)urlStringFormatOrURL, ...;

/**
 Makes a GET request with the provided query parameters.

 @param urlString The `NSURL` or URL string format to request.
 @param parameters The parameters to be encoded as the query string for the GET request.

 @return A promise that fulfills with three parameters:
 1) The deserialized data response.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.
*/
+ (PMKPromise *)GET:(NSString *)urlString query:(NSDictionary *)parameters;

/**
 Makes a POST request to the provided URL passing form URL encoded
 parameters.

 Form URL-encoding is the standard way to POST on the Internet, so
 probably this is what you want. If it doesn’t work, try the `+POST:JSON`
 variant.

 @param urlString The URL to request.
 @param parameters The parameters to be form URL-encoded and passed as the POST body.

 @return A promise that fulfills with three parameters:
 1) The deserialized data response.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.
*/
+ (PMKPromise *)POST:(NSString *)urlString formURLEncodedParameters:(NSDictionary *)parameters;

/**
 Makes a POST request to the provided URL passing JSON encoded parameters.

 @param urlString The URL to request.
 @param JSONParameters The parameters to be JSON encoded and passed as the POST body.

 @return A promise that fulfills with three parameters:
 1) The deserialized data response.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.
*/
+ (PMKPromise *)POST:(NSString *)urlString JSON:(NSDictionary *)JSONParameters;

/**
 Makes a PUT request to the provided URL passing form URL-encoded
 parameters.

 @param urlString The URL to request.
 @param parameters The parameters to be form URL-encoded and passed as the HTTP body.

 @return A promise that fulfills with three parameters:
 1) The deserialized data response.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.
*/
+ (PMKPromise *)PUT:(NSString *)urlString formURLEncodedParameters:(NSDictionary *)params;

/**
 Makes a PUT request to the provided URL passing form URL-encoded
 parameters.

 @param urlString The URL to request.
 @param parameters The parameters to be form URL-encoded and passed as the HTTP body.

 @return A promise that fulfills with three parameters:
 1) The deserialized data response.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.
*/
+ (PMKPromise *)DELETE:(NSString *)urlString formURLEncodedParameters:(NSDictionary *)params;

/**
 Makes an HTTP request using the parameters specified the provided URL
 request.

 @param request The URL request.

 @return A promise that fulfills with three parameters:
 1) The deserialized data response.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.
*/
+ (PMKPromise *)promise:(NSURLRequest *)request;

@end

#pragma clang diagnostic pop
