//
//  VLYoutubeExtractor.h
//  VLYoutubeExtractor
//
//  Created by Developer on 05.09.12.
//  Original idea and realization https://github.com/larcus94/LBYouTubeView
//  Copyright (c) 2012 Vasyl Liutikov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    VLYouTubePlayerQualitySmall       = 0,
    VLYouTubePlayerQualityMedium   = 1,
    VLYouTubePlayerQualityLarge    = 2,
} VLYouTubePlayerQuality;

typedef void (^VLYoutubeExtractorBlock)(NSURL* mediaURL, NSError* error);

@interface VLYoutubeExtractor : NSObject


@property (nonatomic, assign) VLYouTubePlayerQuality quality;

- (void)extractFromURL:(NSURL*)url withCompletionHandler:(VLYoutubeExtractorBlock)completionBlock;
- (void)extractFromYoutubeId:(NSString*)youtubeId withCompletionHandler:(VLYoutubeExtractorBlock)completionBlock;

@end
