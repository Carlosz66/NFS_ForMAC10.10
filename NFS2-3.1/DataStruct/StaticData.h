//
//  StaticData.h
//  NFS2
//
//  Created by 陈超 on 15/9/26.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Library.h"
#import "Sound.h"

@interface StaticData : NSObject

@property Sound *selectedSound;
@property NSMutableArray *searchResultSounds;//contain object which class is Sound
@property Sound *draggingSound;
@property NSMutableArray *sounds;//contain object which class is Sound
@property NSMutableArray *libraries;//contain object which class is Library
@property Library *libraryFile;

@property NSString *ExeclTextString;

@property NSString *libraryPath;
@property NSURL *libraryURL;
@property NSMutableArray<NSString*> *allKeys;//contain object which class is NSString
@property NSMutableArray<NSMutableArray<NSString*>*> *allValues;//contain object which class is Array ;



-(void)loadData;
-(void)scanSoundNodes:(NSXMLElement*)root library:(Library*)lib;
-(void)scanLibraryNodes:(NSXMLElement*)root library:(Library*)lib;
-(void)createXMLFile:(Library*)newRoot  Root:(NSXMLElement*)root;
-(NSMutableArray*)searchSounds:(Library*)lib  key:(NSString*)keyword;
-(void)scanFileSystemAndCreateExcelTxtFile;
-(void)createExcelTxt:(NSURL*)directoryURL;
-(void)ExcelTxtFileToXML;
-(void)createXMLFileSecond:(NSURL*)newRoot Root:(NSXMLElement *)root;
-(void)saveLibrarytoFileSystem:(NSString*)basePath  baseLibrary:(Library*)baseLib;

@end
