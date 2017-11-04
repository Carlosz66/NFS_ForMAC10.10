//
//  Sound.m
//  NFS2
//
//  Created by 陈超 on 15/9/26.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import "Sound.h"

@implementation Sound
-(id)init{
    if (self=[super init]) {
        self.libraryObject=[[Library alloc]init];
        self.others=[[NSMutableDictionary alloc]init];
    }
    return self;
}


@end
