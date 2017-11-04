//
//  AudioPlayerView.h
//  AudioPlayer
//
//  Created by 陈超 on 15/8/30.
//  Copyright (c) 2015年 陈超. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CWaveDrawer.h"


@interface AudioPlayerView : NSView<AVAudioPlayerDelegate>
{
    NSMagnificationGestureRecognizer *gestureReg;
    NSMagnificationGestureRecognizer *gestureReg2;
    CGFloat minScaleFactor;
    CGFloat maxScaleFactor;
    CGFloat minWidthOfWaveForm;
    CGFloat maxWidthOfWaveForm;
    
    NSNumber *oldVolume;
    NSNumber *newVolume;//float value
}

@property(nonatomic,strong)NSURL *fileToPlay;



@property (strong) IBOutlet NSButton *playButton;
@property (strong) IBOutlet NSScrollView *scrollView;
@property (strong) IBOutlet NSTextField *curTimeLabel;
@property (strong) IBOutlet NSTextField *totalTimeLabel;
@property (weak) IBOutlet NSScrollView *scrollView2;
@property (weak) IBOutlet NSButton *muteButton;


-(void)playTheSound;//call it when reset the url only

-(void)setWaveFormMinScale:(CGFloat)minFactor maxScale:(CGFloat)maxFactor;//set the factor of wave form scaling, factor should be a nonzero number.   

- (id)initWithFrame:(CGRect)frame;//need to init with this method
@end
