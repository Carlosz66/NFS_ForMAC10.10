//
//  Sound.h
//  NFS2
//
//  Created by 陈超 on 15/9/26.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Library.h"
@class Library;
@interface Sound : NSObject

@property Library *libraryObject;
@property NSString *name;
@property NSString *path;
@property NSString *duration;
@property NSString *Description;
@property NSString *point;
@property NSMutableDictionary *others;//Dictionary<String,String>

@end
