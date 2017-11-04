//
//  AudioPlayerView.m
//  AudioPlayer
//
//  Created by 陈超 on 15/8/30.
//  Copyright (c) 2015年 陈超. All rights reserved.
//

#import "AudioPlayerView.h"

@interface AudioPlayerView ()
{
    NSTimer *timer;
}

@property(nonatomic,strong)AVAudioPlayer *audioPlayer;
@property(nonatomic,strong)CWaveDrawer *waveDrawer;
@property(nonatomic,strong)CWaveDrawer *waveDrawer2;



@end

@implementation AudioPlayerView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    self.layer.borderWidth=1;
    self.layer.cornerRadius=10;
    self.layer.borderColor=[[NSColor grayColor]CGColor];
    self.layer.backgroundColor=[[NSColor whiteColor] CGColor];
}

#pragma mark setters and getters

-(void)setFileToPlay:(NSURL *)fileToPlay{
    if (_fileToPlay!=fileToPlay) {
        _fileToPlay=fileToPlay;
        self.audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:_fileToPlay error:nil];
        self.audioPlayer.delegate=self;
        self.audioPlayer.volume=newVolume.floatValue;
        [self initializeUserWindow];
    }
}


#pragma mark action
- (IBAction)play:(NSButton *)sender {
    if (sender.state==NSOnState) {
        if(self.audioPlayer!=nil){
            //play the sound
            [self.audioPlayer play];
            [sender setImage:[NSImage imageNamed:@"music_pause"]];
            //set a timer to update the view
            timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(drawAndMove) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }
    }else{
        if (self.audioPlayer!=nil) {
            //stop playing the sound
            [self.audioPlayer pause];
            [sender setImage:[NSImage imageNamed:@"music_play"]];
            //stop the timer to update the view
            [timer invalidate];
        }
    }
}

- (IBAction)volumeOff:(NSButton *)sender {
    float temp = newVolume.floatValue;
    newVolume=oldVolume;
    oldVolume = [NSNumber numberWithFloat:temp];
    if (self.audioPlayer!=nil) {
        self.audioPlayer.volume=newVolume.floatValue;
    }
    if(sender.state==NSOnState)
        [self.muteButton setImage:[NSImage imageNamed:@"volume_off"]];
    else
        [self.muteButton setImage:[NSImage imageNamed:@"volume_higher"]];
}


#pragma mark userWindow
-(void)initializeUserWindow{
    //user window initialize except for the wavefrom
    if(self.playButton.state==NSOnState)
        [self.playButton setNextState];
    [self.playButton setImage:[NSImage imageNamed:@"music_play"]];
    [self.curTimeLabel setStringValue:@"00:00"];
    int minute = (int)self.audioPlayer.duration/60;
    int second = (int)ceil(self.audioPlayer.duration-((int)self.audioPlayer.duration/60)*60);
    [self.totalTimeLabel setStringValue:[NSString stringWithFormat:@"%.2d:%.2d",minute,second]];
    

    //waveform drawing
    CGFloat width=self.audioPlayer.duration*150;
    if (width<500) {
        width=500;
    }else if(width>1000){
        width=1000;
    }
    self.waveDrawer = [[CWaveDrawer alloc]initWithFrame:CGRectMake(0, 0,width,self.scrollView.frame.size.height) withUrl:self.fileToPlay isSecondChannel:NO];
    self.scrollView.documentView = self.waveDrawer;
    
    self.waveDrawer2 = [[CWaveDrawer alloc]initWithFrame:CGRectMake(0, 0, width, self.scrollView2.frame.size.height) withUrl:self.fileToPlay isSecondChannel:YES];
    self.scrollView2.documentView = self.waveDrawer2;
    
    //for magnify
    [self.waveDrawer addGestureRecognizer:gestureReg];
    [self.waveDrawer2 addGestureRecognizer:gestureReg2];//!!!!!!!!!changed!
    [self setUpMagnifyScale];
}


- (id)initWithFrame:(CGRect)frame{
    if(self=[super initWithFrame:frame]){
        
        NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
        //[nc addObserver:self selector:@selector(handleFileChanged:) name:@"BNRFileChanged" object:nil];
        //[nc addObserver:self selector:@selector(fileSave:) name:@"FileSaved" object:nil];
        [nc addObserver:self selector:@selector(seekAtPoint:) name:@"seekAtPoint" object:nil];
        
        gestureReg=[[NSMagnificationGestureRecognizer alloc] initWithTarget:self action:@selector(handleMagGesture:)];
        gestureReg2=[[NSMagnificationGestureRecognizer alloc] initWithTarget:self action:@selector(handleSecondMagGesture:)];
        
        newVolume=[NSNumber numberWithFloat:0.9];
        oldVolume=[NSNumber numberWithFloat:0];
        //[self.volumeSilder bind:@"floatValue" toObject:self withKeyPath:@"volume" options:nil];
        
    }
    return self;
}


-(void)drawAndMove{
    int minute = (int)self.audioPlayer.currentTime/60;
    int second = (int)ceil(self.audioPlayer.currentTime-((int)self.audioPlayer.currentTime/60)*60);
    [self.curTimeLabel setStringValue:[NSString stringWithFormat:@"%.2d:%.2d",minute,second]];
    self.waveDrawer.playProgress=self.audioPlayer.currentTime/self.audioPlayer.duration;
    [self.waveDrawer setNeedsDisplay];
    self.waveDrawer2.playProgress=self.audioPlayer.currentTime/self.audioPlayer.duration;
    [self.waveDrawer2 setNeedsDisplay];
    
}

#pragma mark delegate method

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self.curTimeLabel setStringValue:@"00:00"];
    if(self.playButton.state==NSOnState)
        [self.playButton setNextState];
    [self.playButton setImage:[NSImage imageNamed:@"music_play"]];
    [timer invalidate];
    NSLog(@"done");
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"oh o");
}

/*
#pragma mark open a file
-(void)handleFileChanged:(NSNotification *)note{
    self.fileToPlay = (NSURL *)[[note userInfo]objectForKey:@"fileURL"];
}


#pragma mark save a file
-(void)fileSave:(NSNotification *)note{
    NSURL *fileToSave = (NSURL*)[[note userInfo]objectForKey:@"fileURL"];
    if(self.fileToPlay!=nil){
        NSFileManager *fileManager=[NSFileManager defaultManager];
        NSError *error;
        [fileManager copyItemAtURL:self.fileToPlay toURL:fileToSave error:&error];
        if (error!=noErr) {
            [NSAlert alertWithError:error];
        }else{
            NSAlert *alertWindow=[[NSAlert alloc]init];
            alertWindow.messageText=@"Hello!";
            alertWindow.informativeText=@"File saved!";
            [alertWindow runModal];
        }
    }
    
}
*/
#pragma mark handle scroll view magnify

-(void)handleSecondMagGesture:(NSMagnificationGestureRecognizer *)gestureRecognizer{
    CGRect rect=self.waveDrawer2.frame;
    CGFloat scale=gestureRecognizer.magnification+1.0;
    if((rect.size.width*scale>minWidthOfWaveForm && scale<1)||(rect.size.width*scale<maxWidthOfWaveForm && scale>1))
        [self.waveDrawer2 setFrame:CGRectMake(0, 0, rect.size.width*scale, rect.size.height)];
}


- (void)handleMagGesture:(NSMagnificationGestureRecognizer *)gestureRecognizer{
    CGRect rect=self.waveDrawer.frame;
    CGFloat scale=gestureRecognizer.magnification+1.0;
    if((rect.size.width*scale>minWidthOfWaveForm && scale<1)||(rect.size.width*scale<maxWidthOfWaveForm && scale>1))
        [self.waveDrawer setFrame:CGRectMake(0, 0, rect.size.width*scale, rect.size.height)];
}

-(void)playTheSound{
    [self.audioPlayer play];
    [self.playButton setImage:[NSImage imageNamed:@"music_pause"]];
    [self.playButton setNextState];
    //set a timer to update the view
    timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(drawAndMove) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
}
-(void)setWaveFormMinScale:(CGFloat)minFactor maxScale:(CGFloat)maxFactor{
    minScaleFactor=minFactor;
    maxScaleFactor=maxFactor;
}
-(void)setUpMagnifyScale{
    CGFloat width =self.waveDrawer.frame.size.width;
    minWidthOfWaveForm = width*minScaleFactor;
    maxWidthOfWaveForm = width*maxScaleFactor;
}

#pragma mark handle seek resulting from wave-image

-(void)seekAtPoint:(NSNotification *)note{
    NSNumber *K=[[note userInfo]objectForKey:@"progress"];
    self.audioPlayer.currentTime=K.floatValue*self.audioPlayer.duration;
    [self drawAndMove];
}



@end
