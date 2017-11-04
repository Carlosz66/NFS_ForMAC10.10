//
//  AppDelegate.m
//  NFS2-3.1
//
//  Created by 陈超 on 15/11/7.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property MainViewController *mainViewController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSLog(@"Hello");
    self.mainViewController = [[MainViewController alloc]initWithNibName:@"MainViewController" bundle:nil];
    
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"AudioPlayerView" bundle:nil];
    NSArray *topLevelObjects;
    if (! [nib instantiateWithOwner:self topLevelObjects:&topLevelObjects]) // error
        NSLog(@"Error!!!!! can't load the audioplayerview.xib");
    for (id topLevelObject in topLevelObjects) {
        if ([topLevelObject isKindOfClass:[AudioPlayerView class]]) {
            self.mainViewController.audioPlayerView=topLevelObject;
            break;
        }
    }
    self.window.contentView=self.mainViewController.view;
    //[self.window.contentView addSubview: self.mainViewController.view];
    self.mainViewController.view.frame=self.window.contentView.bounds;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
