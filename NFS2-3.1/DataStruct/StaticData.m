//
//  StaticData.m
//  NFS2
//
//  Created by 陈超 on 15/9/26.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import "StaticData.h"

@implementation StaticData

-(id)init{
    if (self=[super init]) {
        self.selectedSound=[[Sound alloc]init];
        self.searchResultSounds = [[NSMutableArray alloc]init];
        self.draggingSound = [[Sound alloc]init];
        self.sounds = [[NSMutableArray alloc]init];
        self.libraries = [[NSMutableArray alloc]init];
        self.libraryFile = [[Library alloc]init];
        self.ExeclTextString=@"";
    }
    return  self;
}

-(void)loadData{
    self.selectedSound = [[Sound alloc]init];
    self.searchResultSounds = [[NSMutableArray alloc]init];
    self.sounds = [[NSMutableArray alloc]init];
    self.libraries = [[NSMutableArray alloc]init];
    //self.libraryFile =[[Library alloc]init];
    
    //open directory
    NSString *pListPath = [[NSBundle mainBundle] pathForResource:@"ApplicationConfig" ofType:@"plist"];
    NSMutableDictionary *pListData = [[NSMutableDictionary alloc] initWithContentsOfFile:pListPath];
    if ([pListData objectForKey:@"LibrariesDirectory"]==nil) {
        [pListData setObject:@"" forKey:@"LibrariesDirectory"];
        [pListData writeToFile:pListPath atomically:false];
    }
    __block NSString *librariesDirectoryPath = [pListData valueForKey:@"LibrariesDirectory"];//will it not be string?
    if ([librariesDirectoryPath  isEqual: @""]) {
        NSOpenPanel* openPanel = [NSOpenPanel openPanel];
        openPanel.allowsMultipleSelection=false;
        openPanel.canChooseDirectories=true;
        openPanel.canChooseFiles=false;
        [openPanel beginWithCompletionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                librariesDirectoryPath = openPanel.URL.path;//!!!!!!!!!what is block type
                [pListData setObject:librariesDirectoryPath forKey:@"LibrariesDirectory"];
                [pListData writeToFile:pListPath atomically:false];
            }
        }];
    }
    librariesDirectoryPath = [librariesDirectoryPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //load
    NSError *error;
    NSURL *librariesDirectoryURL = [NSURL URLWithString:librariesDirectoryPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = @[NSURLIsDirectoryKey,NSURLIsHiddenKey,NSURLNameKey,NSURLPathKey];
    NSArray *URLs = [fileManager contentsOfDirectoryAtURL:librariesDirectoryURL includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (error!=noErr) {
        NSLog(@"%@",error);
        return;
    }
    for(NSURL *ExcelXMLFileURL in URLs){
        if ([ExcelXMLFileURL.lastPathComponent.pathExtension isEqualToString:@"xml"]) {
            NSXMLDocument *excelXMLFile;
            excelXMLFile = [[NSXMLDocument alloc] initWithContentsOfURL:ExcelXMLFileURL options:0 error:&error];
            if (error!=noErr) {
                excelXMLFile=nil;
            }
            NSXMLElement *libraryRoot = [excelXMLFile nodesForXPath:@"Library" error:nil].firstObject;
            NSXMLElement *libraryNameNode = [libraryRoot nodesForXPath:@"LibraryName" error:nil].firstObject;
            NSXMLElement *libraryPathNode = [libraryRoot nodesForXPath:@"LibraryPath" error:nil].firstObject;
            NSXMLElement *treeNode = [libraryRoot nodesForXPath:@"Tree" error:nil].firstObject;
            Library *lib = [[Library alloc]init];
            lib.isSelected=true;
            lib.libraryObject=[[NSMutableArray alloc]init];
            lib.name=libraryNameNode.stringValue;
            lib.path=libraryPathNode.stringValue;
            lib.sounds=[[NSMutableArray alloc]init];
            lib.libraries=[[NSMutableArray alloc]init];
            [self scanSoundNodes:treeNode library:lib];
            [self scanLibraryNodes:treeNode library:lib];
            [self.libraries addObject:lib];
            
        }
    }
    
}

-(void)scanSoundNodes:(NSXMLElement *)root library:(Library *)lib{
    NSError *error;
    NSArray *soundNodes = [root nodesForXPath:@"Sound" error:&error];
    if (error!=noErr) {
        NSLog(@"%@",error);
        return;
    }
    for(NSXMLElement *soundNode in soundNodes){
        Sound *sound=[[Sound alloc] init];
        sound.libraryObject=lib;
        NSXMLElement *soundNameNode=[soundNode nodesForXPath:@"Name" error:&error].firstObject;
        if (error!=noErr) {
            NSLog(@"%@",error);
            return;
        }
        NSXMLElement *soundPathNode=[soundNode nodesForXPath:@"Path" error:&error].firstObject;
        if (error!=noErr) {
            NSLog(@"%@",error);
            return;
        }
        NSXMLElement *soundDurationNode=[soundNode nodesForXPath:@"Duration" error:&error].firstObject;
        if (error!=noErr) {
            NSLog(@"%@",error);
            return;
        }
        NSXMLElement *soundDescriptionNode=[soundNode nodesForXPath:@"Description" error:&error].firstObject;
        if (error!=noErr) {
            NSLog(@"%@",error);
            return;
        }
        NSXMLElement *soundPointNode=[soundNode nodesForXPath:@"Point" error:&error].firstObject;
        if (error!=noErr) {
            NSLog(@"%@",error);
            return;
        }
        sound.name=soundNameNode.stringValue;
        sound.path=soundPathNode.stringValue;
        sound.duration=soundDurationNode.stringValue;
        sound.Description=soundDescriptionNode.stringValue;
        sound.point=soundPointNode.stringValue;
        sound.others=[[NSMutableDictionary alloc]init];//Dictionary<String,String>
        NSArray *soundOtherNodes=[soundNode nodesForXPath:@"Other" error:&error];
        for(NSXMLElement *soundOtherNode in soundOtherNodes){
            NSXMLElement *soundOtherNameNode=[soundOtherNode nodesForXPath:@"Name" error:&error].firstObject;
            if (error!=noErr) {
                NSLog(@"%@",error);
                return;
            }
            NSXMLElement *soundOtherValueNode=[soundOtherNode nodesForXPath:@"Value" error:&error].firstObject;
            if (error!=noErr) {
                NSLog(@"%@",error);
                return;
            }
            [sound.others setObject:soundOtherValueNode.stringValue forKey:soundOtherNameNode.stringValue];
        }
        [lib.sounds addObject:sound];
        [self.sounds addObject:sound];
    }
}

-(void)scanLibraryNodes:(NSXMLElement *)root library:(Library *)lib{
    NSError *error;
    NSArray *libraryNodes=[root nodesForXPath:@"Path" error:&error];
    for(NSXMLElement *libraryNode in libraryNodes){
        NSXMLElement *libraryNameNode=[libraryNode nodesForXPath:@"Name" error:&error].firstObject;
        if (error!=noErr) {
            NSLog(@"%@",error);
            return;
        }
        NSXMLElement *TreeNode=[libraryNode nodesForXPath:@"Tree" error:&error].firstObject;
        if (error!=noErr) {
            NSLog(@"%@",error);
            return;
        }
        Library *leafLib = [[Library alloc]init];
        leafLib.isSelected=true;
        [leafLib.libraryObject addObject:lib];
        leafLib.name=libraryNameNode.stringValue;
        leafLib.sounds=[[NSMutableArray alloc]init];
        leafLib.libraries=[[NSMutableArray alloc]init];
        [self scanSoundNodes:TreeNode library:leafLib];
        [self scanLibraryNodes:TreeNode library:leafLib];
        [lib.libraries addObject:leafLib];
    }
}

-(void)createXMLFile:(Library *)newRoot Root:(NSXMLElement *)root{
    for(Sound *sound in newRoot.sounds){
        NSXMLElement *soundNode=[NSXMLElement elementWithName:@"Sound"];
        NSXMLElement *soundNameNode=[NSXMLElement elementWithName:@"Name" stringValue:sound.name];
        NSXMLElement *soundPathNode=[NSXMLElement elementWithName:@"Path" stringValue:sound.path];
        NSXMLElement *soundTimeNode=[NSXMLElement elementWithName:@"Duration" stringValue:sound.duration];
        NSXMLElement *soundDescriptionNode=[NSXMLElement elementWithName:@"Description" stringValue:sound.Description];
        NSXMLElement *soundPointNode=[NSXMLElement elementWithName:@"Point" stringValue:sound.point];
        [soundNode addChild:soundNameNode];
        [soundNode addChild:soundPathNode];
        [soundNode addChild:soundTimeNode];
        [soundNode addChild:soundDescriptionNode];
        [soundNode addChild:soundPointNode];
        for(NSString *key in sound.others){
            NSXMLElement *soundOtherNode=[NSXMLElement elementWithName:@"Other"];
            NSXMLElement *soundOtherNameNode=[NSXMLElement elementWithName:@"Name" stringValue:key];
            NSXMLElement *soundOtherValueNode=[NSXMLElement elementWithName:@"Value" stringValue:[sound.others objectForKey:key]];
            [soundOtherNode addChild:soundOtherNameNode];
            [soundOtherNode addChild:soundOtherValueNode];
            [soundNode addChild:soundOtherNode];
        }
        [root addChild:soundNode];
    }
    for(Library *lib in newRoot.libraries){
        NSXMLElement *pathNode=[NSXMLElement elementWithName:@"Path"];
        NSXMLElement *pathNameNode=[NSXMLElement elementWithName:@"Name" stringValue:lib.name];
        NSXMLElement *pathChildrenNode=[NSXMLElement elementWithName:@"Tree"];
        [self createXMLFile:lib Root:pathChildrenNode];
        [pathNode addChild:pathNameNode];
        [pathNode addChild:pathChildrenNode];
        [root addChild:pathNode];
    }
}

-(NSMutableArray*)searchSounds:(Library *)lib key:(NSString *)keyword{
    NSString *keyWordLow=keyword.lowercaseString;
    NSMutableArray *returnArray=[[NSMutableArray alloc] init];
    NSPredicate *predicate=[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        Sound *sound=evaluatedObject;
        if ([sound.Description.lowercaseString rangeOfString:keyWordLow].length!=0) {
            return true;
        }
        if ([sound.name.lowercaseString rangeOfString:keyWordLow].length!=0) {
            return true;
        }
        return false;
    }];
    [returnArray addObjectsFromArray:[lib.sounds filteredArrayUsingPredicate:predicate]];
    for(Library* liblib in lib.libraries){
        [returnArray addObjectsFromArray:[self searchSounds:liblib key:keyword]];
    }
    return returnArray;
}

-(void)scanFileSystemAndCreateExcelTxtFile{
    NSOpenPanel *openDicrectoryPanel=[NSOpenPanel openPanel];
    openDicrectoryPanel.canChooseDirectories=true;
    openDicrectoryPanel.canChooseFiles=false;
    [openDicrectoryPanel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            self.ExeclTextString=[NSString stringWithFormat:@"%@\t \t \t \r名称\t路径\t时间\t描述\t评价\r", openDicrectoryPanel.URL.path];
            [self createExcelTxt:openDicrectoryPanel.URL];
            NSSavePanel *savePanel=[NSSavePanel savePanel];
            savePanel.nameFieldStringValue=[NSString stringWithFormat:@"%@.txt",openDicrectoryPanel.URL.path.lastPathComponent];
            [savePanel beginWithCompletionHandler:^(NSInteger result) {
                if(result==NSFileHandlingPanelOKButton){
                    UInt encoding=0x80000019;
                    [[self.ExeclTextString dataUsingEncoding:encoding allowLossyConversion:true] writeToURL:savePanel.URL atomically:true];
                }
            }];
        }
    }];
}

-(void)createExcelTxt:(NSURL *)directoryURL{
    NSError *error=nil;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSArray *keys=@[NSURLIsDirectoryKey,NSURLIsHiddenKey,NSURLNameKey,NSURLPathKey];
    NSArray *URLs=[fileManager contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if(error!=noErr){
        NSLog(@"%@",[error localizedDescription]);
        return;
    }
    for(NSURL *url in URLs){
        NSNumber *boolObject;
        NSObject *objectKey;
        [url getResourceValue:&boolObject forKey:NSURLIsDirectoryKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",[error localizedDescription]);
            return;
        }
        BOOL isDirectory =[boolObject boolValue];
        NSLog(@"%d",isDirectory);
        
        [url getResourceValue:&boolObject forKey:NSURLIsHiddenKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",[error localizedDescription]);
            return;
        }
        BOOL isHidden = [boolObject boolValue];
        NSLog(@"%hhd",isHidden);
        
        [url getResourceValue:&objectKey forKey:NSURLNameKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",[error localizedDescription]);
            return;
        }
        NSString *name=(NSString *)objectKey;
        NSLog(@"%@",name);
        
        [url getResourceValue:&objectKey  forKey:NSURLPathKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",[error localizedDescription]);
            return;
        }
        NSString *path=(NSString *)objectKey;
        NSLog(@"%@",path);
        
        if(isDirectory==NO && [path.lastPathComponent.pathExtension isEqualToString:@"wav"])
            self.ExeclTextString = [NSString stringWithFormat:@"%@%@\t%@\t \t \t \r",self.ExeclTextString,name,path];
        else if(isDirectory==YES)
            [self createExcelTxt:url];
        
    }
}

-(void)ExcelTxtFileToXML{
    NSOpenPanel *openDirectoryPanel =[NSOpenPanel openPanel];
    openDirectoryPanel.canChooseDirectories=false;
    openDirectoryPanel.canChooseFiles=true;
    [openDirectoryPanel beginWithCompletionHandler:^(NSInteger result) {
        if(result==NSFileHandlingPanelOKButton){
            NSError *error;
            NSLog(@"%@",openDirectoryPanel.URL);
            NSString *path=openDirectoryPanel.URL.path;
            UInt encoding=0x80000019;
            NSString *excelTxtString=[NSString stringWithContentsOfURL:openDirectoryPanel.URL encoding:encoding error:&error];
            if(error!=noErr){
                NSLog(@"%@",error);
                return;
            }
            self.libraryPath=@"";
            //self.libraryURL=[[NSURL alloc] init];
            self.allKeys=[[NSMutableArray alloc]init];
            self.allValues=[[NSMutableArray alloc]init];
            NSArray *rows=[excelTxtString componentsSeparatedByString:@"\r"];
            for(NSString *row in rows){
                NSLog(@"%@",row);
                NSMutableArray *columns=[NSMutableArray arrayWithArray:[row componentsSeparatedByString:@"\t"]];
                NSLog(@"%@",columns);
                if ([self.libraryPath isEqualToString:@""]) {
                    self.libraryPath = [columns objectAtIndex:0];
                    //NSString *urlStr=@"file:///Users/Carlos/Desktop/music";
                    self.libraryURL = [NSURL fileURLWithPath:self.libraryPath];//[NSURL URLWithString:[self.libraryPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];//;
                }else if (self.allKeys.count==0)
                    self.allKeys=columns;
                else
                    [self.allValues addObject:columns];
            }
            NSXMLElement *root=[NSXMLElement elementWithName:@"Library"];
            [root addChild:[NSXMLElement elementWithName:@"LibraryName" stringValue:self.libraryPath.lastPathComponent]];
            [root addChild:[NSXMLElement elementWithName:@"LibraryPath" stringValue:self.libraryPath]];
            NSXMLElement *tree=[NSXMLElement elementWithName:@"Tree"];
            [root addChild:tree];
            [self createXMLFileSecond:self.libraryURL Root:tree];
            NSXMLDocument *xmlDoc=[NSXMLDocument documentWithRootElement:root];
            [xmlDoc.XMLData writeToFile:[path.stringByDeletingLastPathComponent stringByAppendingPathComponent:[path.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"xml"]] atomically:false];
        }
    }];
    
}

-(void)createXMLFileSecond:(NSURL *)newRoot Root:(NSXMLElement *)root{
    NSError *error;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSArray *keys=@[NSURLIsDirectoryKey,NSURLIsHiddenKey,NSURLNameKey,NSURLPathKey];
    NSArray *URLs=[fileManager contentsOfDirectoryAtURL:newRoot includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if(error!=noErr){
        NSLog(@"%@",error);
        return;
    }
    int keyIndex=0;
    for(NSURL *url in URLs){
        NSObject *objectKey;
        NSNumber *boolObject;
        [url getResourceValue:&boolObject forKey:NSURLIsDirectoryKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",error);
            return;
        }
        BOOL isDirectory = [boolObject boolValue];
        NSLog(@"%hhd",isDirectory);
        
        [url getResourceValue:&boolObject forKey:NSURLIsHiddenKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",error);
            return;
        }
        BOOL isHidden = [boolObject boolValue];
        NSLog(@"%hhd",isHidden);
        
        [url getResourceValue:&objectKey forKey:NSURLNameKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",error);
            return;
        }
        NSString *name=(NSString *)objectKey;
        NSLog(@"%@",name);
        
        [url getResourceValue:&objectKey  forKey:NSURLPathKey error:&error];
        if(error!=noErr){
            NSLog(@"%@",error);
            return;
        }
        NSString *path=(NSString *)objectKey;
        NSLog(@"%@",path);
        if (isDirectory==NO && [path.lastPathComponent.pathExtension isEqual:@"wav"]) {
            NSXMLElement *soundNode=[NSXMLElement elementWithName:@"Sound"];
            NSXMLElement *soundNameNode=[NSXMLElement elementWithName:@"Name" stringValue:path.lastPathComponent.stringByDeletingPathExtension];
            NSXMLElement *soundPathNode=[NSXMLElement elementWithName:@"Path" stringValue:path];
            NSXMLElement *soundTimeNode=[NSXMLElement elementWithName:@"Duration" stringValue:[[self.allValues objectAtIndex:keyIndex] objectAtIndex:2]];
            NSXMLElement *soundDescriptionNode=[NSXMLElement elementWithName:@"Description" stringValue:[[self.allValues objectAtIndex:keyIndex] objectAtIndex:3]];
            NSXMLElement *soundPointNode=[NSXMLElement elementWithName:@"Point" stringValue:[[self.allValues objectAtIndex:keyIndex] objectAtIndex:4]];
            [soundNode addChild:soundNameNode];
            [soundNode addChild:soundPathNode];
            [soundNode addChild:soundTimeNode];
            [soundNode addChild:soundDescriptionNode];
            [soundNode addChild:soundPointNode];
            for (int i=5; i<[self.allValues objectAtIndex:keyIndex].count; i++) {
                NSXMLElement *soundOthersNode=[NSXMLElement elementWithName:@"Other"];
                NSXMLElement *soundOthersNameNode=[NSXMLElement elementWithName:@"Name" stringValue:[self.allKeys objectAtIndex:i]];
                NSXMLElement *soundOthersValueNode=[NSXMLElement elementWithName:@"Value" stringValue:[[self.allValues objectAtIndex:keyIndex] objectAtIndex:i]];
                [soundOthersNode addChild:soundOthersNameNode];
                [soundOthersNode addChild:soundOthersValueNode];
                [soundNode addChild:soundOthersNode];
            }
            keyIndex++;
            [root addChild:soundNode];
        }else if (isDirectory==YES){
            NSXMLElement *pathNode=[NSXMLElement elementWithName:@"Path"];
            NSXMLElement *pathNameNode=[NSXMLElement elementWithName:@"Name" stringValue:path.lastPathComponent];
            NSXMLElement *pathChildrenNode=[NSXMLElement elementWithName:@"Tree"];
            [self createXMLFileSecond:url Root:pathChildrenNode];
            [pathNode addChild:pathNameNode];
            [pathNode addChild:pathChildrenNode];
            [root addChild:pathNode];
        }
    }
}

-(void)saveLibrarytoFileSystem:(NSString *)basePath baseLibrary:(Library *)baseLib{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    for(Sound *sound in baseLib.sounds){
        if (![fileManager fileExistsAtPath:[basePath stringByAppendingPathComponent:sound.path.lastPathComponent]]) {
            NSError *error=nil;
            [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:true attributes:nil error:&error];
            if (error!=noErr) {
                NSLog(@"%@",error);
                return;
            }
            [fileManager copyItemAtPath:sound.path toPath:[basePath stringByAppendingPathComponent:sound.path.lastPathComponent]error:&error];
            if (error!=noErr) {
                NSLog(@"%@",error);
                return;
            }
        }
    }
    for(Library *lib in baseLib.libraries){
        [self saveLibrarytoFileSystem:[basePath stringByAppendingPathComponent:lib.name] baseLibrary:lib];
    }
}

@end
