//
//  MainViewController.m
//  OHHTTPStubsDemo
//
//  Created by Olivier Halligon on 11/08/12.
//  Copyright (c) 2012 AliSoftware. All rights reserved.
//

#import "MainViewController.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>


@interface MainViewController ()
// IBOutlets
@property (retain, nonatomic) IBOutlet UISwitch *delaySwitch;
@property (retain, nonatomic) IBOutlet UITextView *textView;
@property (retain, nonatomic) IBOutlet UISwitch *installTextStubSwitch;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UISwitch *installImageStubSwitch;
@end

@implementation MainViewController

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self installTextStub:self.installTextStubSwitch];
    [self installImageStub:self.installImageStubSwitch];
    [OHHTTPStubs onStubActivation:^(NSURLRequest * _Nonnull request, id<OHHTTPStubsDescriptor>  _Nonnull stub, OHHTTPStubsResponse * _Nonnull responseStub) {
        NSLog(@"[OHHTTPStubs] Request to %@ has been stubbed with %@", request.URL, stub.name);
    }];
}
- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setImageView:nil];
    [self setDelaySwitch:nil];
    [super viewDidUnload];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Global stubs activation

- (IBAction)toggleStubs:(UISwitch *)sender
{
    [OHHTTPStubs setEnabled:sender.on];
    self.delaySwitch.enabled = sender.on;
    self.installTextStubSwitch.enabled = sender.on;
    self.installImageStubSwitch.enabled = sender.on;
    
    NSLog(@"Installed (%@) stubs: %@", (sender.on?@"and enabled":@"but disabled"), OHHTTPStubs.allStubs);
}




////////////////////////////////////////////////////////////////////////////////
#pragma mark - Text Download and Stub


- (IBAction)downloadText:(UIButton*)sender
{
    sender.enabled = NO;
    self.textView.text = nil;

    NSString* urlString = @"http://www.opensource.apple.com/source/Git/Git-26/src/git-htmldocs/git-commit.txt?txt";
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    // This is a very handy way to send an asynchronous method, but only available in iOS5+
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         sender.enabled = YES;
         NSString* receivedText = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
         self.textView.text = receivedText;
     }];
}




- (IBAction)installTextStub:(UISwitch *)sender
{
    static id<OHHTTPStubsDescriptor> textStub = nil; // Note: no need to retain this value, it is retained by the OHHTTPStubs itself already
    if (sender.on)
    {
        // Install
        textStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            // This stub will only configure stub requests for "*.txt" files
            return [request.URL.pathExtension isEqualToString:@"txt"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            // Stub txt files with this
            return [[OHHTTPStubsResponse responseWithFileAtPath:OHPathForFile(@"stub.txt", self.class)
                                                     statusCode:200
                                                        headers:@{@"Content-Type":@"text/plain"}]
                    requestTime:self.delaySwitch.on ? 2.f: 0.f
                    responseTime:OHHTTPStubsDownloadSpeedWifi];
        }];
        textStub.name = @"Text stub";
    }
    else
    {
        // Uninstall
        [OHHTTPStubs removeStub:textStub];
    }
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image Download and Stub

- (IBAction)downloadImage:(UIButton*)sender
{
    sender.enabled = NO;
    
    NSString* urlString = @"http://images.apple.com/support/assets/images/products/iphone/hero_iphone4-5_wide.png";
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    // This is a very handy way to send an asynchronous method, but only available in iOS5+
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         sender.enabled = YES;
         self.imageView.image = [UIImage imageWithData:data];
     }];
}

- (IBAction)installImageStub:(UISwitch *)sender
{
    static id<OHHTTPStubsDescriptor> imageStub = nil; // Note: no need to retain this value, it is retained by the OHHTTPStubs itself already :)
    if (sender.on)
    {
        // Install
        imageStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            // This stub will only configure stub requests for "*.png" files
            return [request.URL.pathExtension isEqualToString:@"png"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            // Stub jpg files with this
            return [[OHHTTPStubsResponse responseWithFileAtPath:OHPathForFile(@"stub.jpg", self.class)
                                                     statusCode:200
                                                        headers:@{@"Content-Type":@"image/jpeg"}]
                    requestTime:self.delaySwitch.on ? 2.f: 0.f
                    responseTime:OHHTTPStubsDownloadSpeedWifi];
        }];
        imageStub.name = @"Image stub";
    }
    else
    {
        // Uninstall
        [OHHTTPStubs removeStub:imageStub];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Cleaning

- (IBAction)clearResults
{
    self.textView.text = @"";
    self.imageView.image = nil;
}

@end
