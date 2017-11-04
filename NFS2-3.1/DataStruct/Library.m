//
//  Library.m
//  NFS2
//
//  Created by 陈超 on 15/9/26.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import "Library.h"

@implementation Library

-(id)init{
    if (self=[super init]) {
        self.libraries=[[NSMutableArray alloc]init];
        self.libraryObject=[[NSMutableArray alloc]init];
        self.sounds=[[NSMutableArray alloc]init];
        self.isSelected=NO;
    }
    return self;
}

@end
