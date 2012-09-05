//
//  VLViewController.m
//  VLYoutubeExtractor
//
//  Created by Developer on 05.09.12.
//  Copyright (c) 2012 Vasyl Liutikov. All rights reserved.
//

#import "VLViewController.h"
#import "VLYoutubeExtractor.h"

@interface VLViewController ()

@property (nonatomic, retain) VLYoutubeExtractor* extractor;
@property (nonatomic, copy) VLYoutubeExtractorBlock resultBlock;

@end

@implementation VLViewController


@synthesize fullUrlField;
@synthesize videoIdField;
@synthesize resuiltTextView;
@synthesize extractor;
@synthesize resultBlock;

- (void)dealloc
{
    self.extractor = nil;
    self.fullUrlField = nil;
    self.videoIdField = nil;
    self.resuiltTextView = nil;
    self.resultBlock = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.extractor = [[[VLYoutubeExtractor alloc] init] autorelease];
    self.resultBlock = ^(NSURL* url, NSError* error){
        if (!error) {
            self.resuiltTextView.text = [url relativeString];
        }
    };
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)extractByFullUrl:(id)sender
{
    if ([self.fullUrlField.text length]) {
        [self.extractor extractFromURL:[NSURL URLWithString:self.fullUrlField.text] withCompletionHandler:self.resultBlock];
    }
}
- (IBAction)extractByFullVideoId:(id)sender
{
    if ([self.videoIdField.text length]) {
        [self.extractor extractFromYoutubeId:self.videoIdField.text withCompletionHandler:self.resultBlock];
    }
}
- (IBAction)openInSafari:(id)sender
{
    if ([self.resuiltTextView.text length]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.resuiltTextView.text]];
    }
}

@end
