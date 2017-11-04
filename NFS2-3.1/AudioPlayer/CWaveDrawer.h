//
//  CWaveDrawer.h
//  AudioPlayer
//
//  Created by 陈超 on 15/8/24.
//  Copyright (c) 2015年 陈超. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "WaveSampleProvider.h"


@interface CWaveDrawer : NSImageView<WaveSampleProviderDelegate>
{
    BOOL isFirst;
    CGImageRef WImage;
    CGContextRef currentContext;
    NSMutableArray *meterLevel;
    WaveSampleProvider *wsp;
    CGPoint *sampleData;
    int sampleLength;
    CGPoint *sampleData2;
    int sampleLength2;
}

@property NSURL *fileToDraw;
@property float playProgress;
@property bool isSecondChannel;

- (id)initWithFrame:(CGRect)frame withUrl:(NSURL *)fileToDraw isSecondChannel:(bool)isSecondChannel;
- (NSImage*)getTheImage;
@end
