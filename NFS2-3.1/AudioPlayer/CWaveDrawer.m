//
//  CWaveDrawer.m
//  AudioPlayer
//
//  Created by 陈超 on 15/8/24.
//  Copyright (c) 2015年 陈超. All rights reserved.
//

#import "CWaveDrawer.h"
#define kHillSegmentWidth 10

@implementation CWaveDrawer


#pragma mark init method
- (id)initWithFrame:(CGRect)frame withUrl:(NSURL *)fileToDraw isSecondChannel:(bool)isSecondChannel
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.fileToDraw = fileToDraw;
        self.isSecondChannel = isSecondChannel;
        [self prepareDataForDrawing];
    }
    return self;
}


#pragma mark draw the wav
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (BOOL) isOpaque
{
    return NO;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef MYContext =[[NSGraphicsContext currentContext] graphicsPort];

    [self createBitmap];
    
    if (WImage==NULL) {
            fprintf(stderr, "Error:image is null");
            return;
    }
    CGContextDrawImage(MYContext, self.frame, WImage);
    
}

-(void) createBitmap{
    if(sampleLength > 0) {
        //[[NSGraphicsContext currentContext] saveGraphicsState];
        
        CGMutablePathRef halfPath = CGPathCreateMutable();
        CGPathAddLines( halfPath, NULL,sampleData, sampleLength); // magic!
        
        CGMutablePathRef path = CGPathCreateMutable();
        
        double xscale = (NSWidth(self.bounds)-12.0) / (float)sampleLength;
        // Transform to fit the waveform ([0,1] range) into the vertical space
        // ([halfHeight,height] range)
        double halfHeight = floor( NSHeight(self.bounds ) / 2.0 );//waveRect.size.height / 2.0;
        CGAffineTransform xf = CGAffineTransformIdentity;
        xf = CGAffineTransformTranslate( xf, self.bounds.origin.x+6, halfHeight + self.bounds.origin.y);
        xf = CGAffineTransformScale( xf, xscale, halfHeight-6 );
        CGPathAddPath( path, &xf, halfPath );
        
        // Transform to fit the waveform ([0,1] range) into the vertical space
        // ([0,halfHeight] range), flipping the Y axis
        xf = CGAffineTransformIdentity;
        xf = CGAffineTransformTranslate( xf, self.bounds.origin.x+6, halfHeight + self.bounds.origin.y);
        xf = CGAffineTransformScale( xf, xscale, -(halfHeight-6));
        CGPathAddPath( path, &xf, halfPath );
        
        CGPathRelease( halfPath ); // clean up!
        // Now, path contains the full waveform path.
        //NSGraphicsContext * nsGraphicsContext = [NSGraphicsContext currentContext];
        //CGContextRef cr = (CGContextRef) [nsGraphicsContext graphicsPort];
        CGContextRef cr =currentContext =MYCreateBitmapContext(self.bounds.size.width, self.bounds.size.height);

        
        CGContextSetRGBStrokeColor(cr, 47.0/255.0, 47.0/255.0,48.0/255.0, 1.0);
        CGContextAddPath(cr, path);
        CGContextStrokePath(cr);
        
        // gauge draw
        if(_playProgress > 0.0) {
            //CGContextSaveGState(cr);
            NSRect clipRect = self.bounds;
            clipRect.size.width = (clipRect.size.width - 12) * _playProgress;
            clipRect.origin.x = clipRect.origin.x + 6;
            CGContextAddRect(cr, clipRect);
            CGContextClip(cr);
            
            CGContextSetRGBFillColor(cr, 242.0/255.0, 147.0/255.0, 0.0/255.0, 1.0);
            CGContextAddPath(cr, path);
            CGContextFillPath(cr);
            
            //CGContextAddRect(cr, self.bounds);
            //CGContextClip(cr);
            //CGContextRestoreGState(cr);
            CGContextSetRGBStrokeColor(cr, 47.0/255.0, 47.0/255.0,48.0/255.0, 1.0);
            CGContextAddPath(cr, path);
            CGContextStrokePath(cr);
        }
        
        if(WImage!=NULL){
            CGImageRelease(WImage);
        }
        WImage = CGBitmapContextCreateImage(cr);
        
        char *data=CGBitmapContextGetData(cr);
        CGContextRelease(cr);
        if (data!=NULL) {
            free(data);
        }
    
        CGPathRelease(path); // clean up!
    }
    [[NSColor clearColor] setFill];
    //[[NSGraphicsContext currentContext] restoreGraphicsState];
}

CGContextRef MYCreateBitmapContext(int pixelWidth,int pixelHeight){
    CGContextRef context=NULL;
    CGColorSpaceRef colorSpace;
    void *data;
    int bitmapBytesCount;
    int bitmapBytesPerRow;
    
    bitmapBytesPerRow=4*pixelWidth;
    bitmapBytesCount=bitmapBytesPerRow*pixelHeight;
    
    colorSpace=CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    data=calloc(1,bitmapBytesCount);
    if (data==NULL) {
        fprintf(stderr, "Error:Memory not allocated!");
        return NULL;
    }
    
    context=CGBitmapContextCreate(data, pixelWidth, pixelHeight, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    if (context==NULL) {
        fprintf(stderr, "Error:Context created failed");
        return  NULL;
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

#pragma mark handle mouse event


-(void)mouseUp:(NSEvent *)theEvent{
    NSPoint p=[theEvent locationInWindow];
    NSPoint upPoint=[self convertPoint:p fromView:nil];
    float progress=upPoint.x/self.frame.size.width;
    NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"seekAtPoint" object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:progress] forKey:@"progress"]];
    NSLog(@"mouseUp");
}


#pragma mark get meter level
-(void)prepareDataForDrawing{
    wsp = [[WaveSampleProvider alloc] initWithURL:self.fileToDraw];
    [wsp createSampleData];
    wsp.delegate=self;
}

- (void) setSampleData:(float *)theSampleData length:(int)length
{
    //[progress setHidden:FALSE];
    //[progress startAnimation:self];
    sampleLength = 0;
    
    length += 2;
    CGPoint *tempData = (CGPoint *)calloc(sizeof(CGPoint),length);
    tempData[0] = CGPointMake(0.0,0.0);
    tempData[length-1] = CGPointMake(length-1,0.0);
    for(int i = 1; i < length-1;i++) {
        tempData[i] = CGPointMake(i, theSampleData[i]);
    }
    
    CGPoint *oldData = sampleData;
    
    sampleData = tempData;
    sampleLength = length;
    
    if(oldData != nil) {
        free(oldData);
    }
    
    free(theSampleData);
    //[progress setHidden:TRUE];
    //[progress stopAnimation:self];
    [self setNeedsDisplay:YES];
}




#pragma mark waveSampleDelegate
-(void)sampleProcessed:(WaveSampleProvider *)provider{
    if (wsp.status==LOADED) {
        int length=0;
        float *fdata;
        if(!self.isSecondChannel)
            fdata=[wsp dataForResolution:8000 lenght:&length];
        else
            fdata=[wsp dataForResolution2:8000 lenght:&length];
        [self setSampleData:fdata length:length];
        printf("sample has been loaded");
    }
}

/*
#pragma mark create NSImage
- (NSImage*)getTheImage{
    return self.image;
}

- (NSImage*) imageFromCGImageRef:(CGImageRef)tImage
{
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);

    CGContextRef imageContext = nil;
    NSImage* newImage = nil;
    
    // Get the image dimensions.
    
    imageRect.size.height = CGImageGetHeight(tImage);
    
    imageRect.size.width = CGImageGetWidth(tImage);

    
    // Create a new image to receive the Quartz image data.
    
    newImage = [[NSImage alloc] initWithSize:imageRect.size];

    [newImage lockFocus];
    
    
    // Get the Quartz context and draw.
    
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext]graphicsPort];
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, tImage);

    [newImage unlockFocus];
    
    return newImage;
    
}
*/
@end


