//
//  MainViewController.h
//  NFS2-3.1
//
//  Created by 陈超 on 15/11/7.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AudioPlayerView.h"
#import "StaticData.h"

@interface MainViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    AudioPlayerView *audioPlayerView;
    StaticData *dataProcesser;
    
}

@property AudioPlayerView *audioPlayerView;

@property (weak) IBOutlet NSOutlineView *libraryFileOutlineView;
@property (weak) IBOutlet NSOutlineView *librariesOutlineView;
@property (weak) IBOutlet NSTableView *searchResultTableView;
@property (weak) IBOutlet NSView *audioPlayerViewContainer;
@property (weak) IBOutlet NSTextField *searchBarTextField;


@end