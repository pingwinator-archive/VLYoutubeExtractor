//
//  VLYoutubeExtractor.m
//  VLYoutubeExtractor
//
//  Created by Developer on 05.09.12.
//  Original idea and realization https://github.com/larcus94/LBYouTubeView
//  Copyright (c) 2012 Vasyl Liutikov. All rights reserved.
//

#import "VLYoutubeExtractor.h"
#import "JSONKit.h"

#define kUserAgent  @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
#define kVLYouTubePlayerControllerErrorDomain  @"VLYouTubePlayerControllerErrorDomain"

@interface VLYoutubeExtractor ()

@property (nonatomic, copy) VLYoutubeExtractorBlock completionBlock;

- (NSMutableURLRequest*)prepareRequestForURL:(NSURL*)url;
- (NSString*)_unescapeString:(NSString *)string;
- (void)finishExtractWithURL:(NSURL*)url andError:(NSError*)error;
- (void)extractYouTubeURLFromFile:(NSString *)html;
@end

@implementation VLYoutubeExtractor
@synthesize quality;
@synthesize completionBlock;

- (void)dealloc
{
    self.completionBlock = nil;
    [super dealloc];
}

#pragma mark - public

- (id)init
{
    self = [super init];
    if (self) {
        self.quality = VLYouTubePlayerQualityLarge; // by default load hi quality video
    }
    return self;
}


- (void)extractFromYoutubeId:(NSString*)youtubeId withCompletionHandler:(VLYoutubeExtractorBlock)_completionBlock
{
     [self extractFromURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", youtubeId]] withCompletionHandler:_completionBlock];
}

- (void)extractFromURL:(NSURL*)url withCompletionHandler:(VLYoutubeExtractorBlock)_completionBlock;
{
    NSMutableURLRequest* request = [self prepareRequestForURL:url];
    self.completionBlock = _completionBlock;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   [self finishExtractWithURL:nil andError:error];
                               } else {
                               NSString* html = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                                   [self extractYouTubeURLFromFile:html];
                               }
                           }];
    
}

#pragma mark - private

- (NSMutableURLRequest*)prepareRequestForURL:(NSURL*)url
{
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    return request;
}

- (NSString*)_unescapeString:(NSString*)string
{
    // will cause trouble if you have "abc\\\\uvw"
    // \u   --->    \U
    NSString *esc1 = [string stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    
    // "    --->    \"
    NSString *esc2 = [esc1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    // \\"  --->    \"
    NSString *esc3 = [esc2 stringByReplacingOccurrencesOfString:@"\\\\\"" withString:@"\\\""];
    
    NSString *quoted = [[@"\"" stringByAppendingString:esc3] stringByAppendingString:@"\""];
    NSData *data = [quoted dataUsingEncoding:NSUTF8StringEncoding];
    
    //  NSPropertyListFormat format = 0;
    //  NSString *errorDescr = nil;
    NSString *unesc = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    
    if ([unesc isKindOfClass:[NSString class]]) {
        // \U   --->    \u
        return [unesc stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
    }
    
    return nil;
}

- (void)finishExtractWithURL:(NSURL*)url andError:(NSError*)error
{
    if (self.completionBlock) {
        self.completionBlock(url, error);
    }
}

- (void)extractYouTubeURLFromFile:(NSString*)html 
{
    NSString* JSONStart = nil;
    NSError* error = nil;;
    NSString* JSONStartFull = @"ls.setItem('PIGGYBACK_DATA', \")]}'";
    NSString* JSONStartShrunk = [JSONStartFull stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([html rangeOfString:JSONStartFull].location != NSNotFound)
        JSONStart = JSONStartFull;
    else if ([html rangeOfString:JSONStartShrunk].location != NSNotFound)
        JSONStart = JSONStartShrunk;
    
    if (JSONStart != nil) {
        NSScanner* scanner = [NSScanner scannerWithString:html];
        [scanner scanUpToString:JSONStart intoString:nil];
        [scanner scanString:JSONStart intoString:nil];
        
        NSString* JSON = nil;
        [scanner scanUpToString:@"\");" intoString:&JSON];
        JSON = [self _unescapeString:JSON];
        NSError* decodingError = nil;
        NSDictionary* JSONCode = nil;
        
        // First try to invoke NSJSONSerialization (Thanks Mattt Thompson)
        
        id NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
        SEL NSJSONSerializationSelector = NSSelectorFromString(@"dataWithJSONObject:options:error:");
        if (NSJSONSerializationClass && [NSJSONSerializationClass respondsToSelector:NSJSONSerializationSelector]) {
            JSONCode = [NSJSONSerialization JSONObjectWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&decodingError];
        }
        else {
            JSONCode = [JSON objectFromJSONStringWithParseOptions:JKParseOptionNone error:&decodingError];
        }
        
        if (decodingError) {
            // Failed

            [self finishExtractWithURL:nil andError:decodingError];
            return ;
        }
        else {
            // Success
            
            NSArray* videos = [[[JSONCode objectForKey:@"content"] objectForKey:@"video"] objectForKey:@"fmt_stream_map"];
            NSString* streamURL = nil;
            if (videos.count) {
                NSString* streamURLKey = @"url";
                
                if (self.quality == VLYouTubePlayerQualityLarge) {
                    streamURL = [[videos objectAtIndex:0] objectForKey:streamURLKey];
                }
                else if (self.quality == VLYouTubePlayerQualityMedium) {
                    unsigned int index = MAX(0, videos.count-2);
                    streamURL = [[videos objectAtIndex:index] objectForKey:streamURLKey];
                }
                else {
                    streamURL = [[videos lastObject] objectForKey:streamURLKey];
                }
            }
            
            if (streamURL) {
                [self finishExtractWithURL:[NSURL URLWithString:streamURL] andError:nil];
                return ;
            }
            else {
                error = [NSError errorWithDomain:kVLYouTubePlayerControllerErrorDomain code:2 userInfo:[NSDictionary dictionaryWithObject:@"Couldn't find the stream URL." forKey:NSLocalizedDescriptionKey]];
                [self finishExtractWithURL:nil andError:error];
                return ;
            }
        }
    }
    else {
        error = [NSError errorWithDomain:kVLYouTubePlayerControllerErrorDomain code:3 userInfo:[NSDictionary dictionaryWithObject:@"The JSON data could not be found." forKey:NSLocalizedDescriptionKey]];
        [self finishExtractWithURL:nil andError:error];
        return ;
    }
    
}

@end
