---
category: cookbook
layout: default
---

#  Building a Web API class

Most web APIs require authentication, usually in the headers. The convenience methods on `NSURLConnection` that PromiseKit provides will not be sufficient here. They are deliberately simple for the 90% usage.

We will use <a href="https://github.com/mxcl/OMGHTTPURLRQ">OMGHTTPURLRQ</a> to construct `NSURLRequest`s that we will then will pass to PromiseKit. You already have OMGHTTPURLRQ because PromiseKit imports it in order to generate requests for its `NSURLConnection` categories.

OMGHTTPURLRQ is a useful helper library that does the difficult work required in correctly constructing REST-style API requests.

{% highlight objectivec %}
@interface MyAPI

/**
 thens an array of Kittens
*/
+ (PMKPromise *)fetchKittens:(NSInteger)count;

/**
 thens result JSON dictionary
*/
+ (PMKPromise *)uploadKitten:(NSData *)imageData;

@end

@implementation MyAPI

static inline void auth(NSMutableURLRequest *rq) {
    [rq setValue:username forHTTPHeader:@"x-auth-user"];
    [rq setValue:token forHTTPHeader:@"x-auth-token"];
}

+ (PMKPromise *)fetchKittens:(NSInteger)count {
    id url = [HOST stringByAppendingString:path];
    NSMutableURLRequest *rq = [OMGHTTPURLRQ GET:url];
    auth(rq);
    return [NSURLConnection promise:rq];
}

+ (PMKPromise *)uploadKitten:(NSData *)imageData {
    id url = [HOST stringByAppendingString:path];
    
    OMGMultipartFormData *multipartFormData = [OMGMultipartFormData new];
    [multipartFormData addFile:imageData parameterName:@"kitten1" filename:@"kitten1.jpg" contentType:@"image/jpeg"];
    NSMutableURLRequest *rq = [OMGHTTPURLRQ POST:url:multipartFormData];

    auth(rq);

    return [NSURLConnection promise:rq];
}

@end

{% endhighlight %}


`OMGHTTPURLRQ` is a low level HTTP library that can encode any request as you need, then use `NSURLConnection`’s `+promise` method to promise it.

<div><a class="pagination" href="/promises-and-ux">Next: Promises &amp; <abbr title="User Experience">UX</abbr></a></div>
