//
//  Library.h
//  NFS2
//
//  Created by 陈超 on 15/9/26.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sound.h"
@class Sound;
@interface Library : NSObject

@property BOOL isSelected;
@property NSString *name;
@property NSString *path;
@property NSMutableArray *libraryObject;//contain object which class is library
@property NSMutableArray *sounds;//contain object which class is sound
@property NSMutableArray *libraries;//contain object which class is library

@end
