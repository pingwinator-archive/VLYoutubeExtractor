//
//  VLViewController.h
//  VLYoutubeExtractor
//
//  Created by Developer on 05.09.12.
//  Copyright (c) 2012 Vasyl Liutikov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLViewController : UIViewController

@property (retain, nonatomic) IBOutlet UITextField *fullUrlField;
@property (retain, nonatomic) IBOutlet UITextField *videoIdField;
@property (retain, nonatomic) IBOutlet UITextView *resuiltTextView;


- (IBAction)extractByFullUrl:(id)sender;
- (IBAction)extractByFullVideoId:(id)sender;
- (IBAction)openInSafari:(id)sender;

@end
