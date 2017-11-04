//
//  MainViewController.m
//  NFS2-3.1
//
//  Created by 陈超 on 15/11/7.
//  Copyright © 2015年 陈超. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize audioPlayerView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dataProcesser=[[StaticData alloc]init];
    [dataProcesser loadData];
    dataProcesser.libraryFile.name=@"新剧本";
    
    self.librariesOutlineView.dataSource=self;
    self.librariesOutlineView.delegate=self;
    [self.librariesOutlineView registerForDraggedTypes:@[NSStringPboardType]];
    
    self.libraryFileOutlineView.dataSource=self;
    self.libraryFileOutlineView.delegate=self;
    [self.libraryFileOutlineView registerForDraggedTypes:@[NSStringPboardType]];
    
    self.searchResultTableView.dataSource=self;
    self.searchResultTableView.delegate=self;
    [self.searchResultTableView registerForDraggedTypes:@[NSStringPboardType]];
    

    

    //audioPlayerView=(AudioPlayerView*)[[NSViewController alloc] initWithNibName:@"AudioPlayerView" bundle:nil].view;
    audioPlayerView.frame=NSMakeRect(0, 0, self.audioPlayerViewContainer.frame.size.width, self.audioPlayerViewContainer.frame.size.height);
    [self.audioPlayerViewContainer addSubview:audioPlayerView];
    [audioPlayerView setWaveFormMinScale:0.5 maxScale:2];
    
    
}

-(void)viewDidLayout{
    audioPlayerView.frame = NSMakeRect(0, 0, self.audioPlayerViewContainer.frame.size.width, self.audioPlayerViewContainer.frame.size.height);
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (IBAction)librariesOutlineContextMenu_Click:(NSMenuItem *)sender {
    NSString *command=sender.title;
    if ([command isEqualToString:@"刷新"]) {
        [dataProcesser loadData];
        [self.librariesOutlineView reloadData];
    }else if ([command isEqualToString:@"生成库表"]){
        [dataProcesser scanFileSystemAndCreateExcelTxtFile];
    }else if ([command isEqualToString:@"生成库文件"]){
        [dataProcesser ExcelTxtFileToXML];
    }else if ([command isEqualToString:@"保存所有更改"]){
        NSString *pListPath=[[NSBundle mainBundle] pathForResource:@"ApplicationConfig" ofType:@"plist"];
        NSMutableDictionary *pListData=[NSMutableDictionary dictionaryWithContentsOfFile:pListPath];
        NSString *librariesDirectoryPath=[pListData valueForKey:@"LibrariesDirectory"];
        for(Library *lib in dataProcesser.libraries){
            NSXMLElement *root=[NSXMLElement elementWithName:@"Library"];
            [root addChild:[NSXMLElement elementWithName:@"LibraryName" stringValue:lib.name]];
            [root addChild:[NSXMLElement elementWithName:@"LibraryPath" stringValue:lib.path]];
            NSXMLElement *tree=[NSXMLElement elementWithName:@"Tree"];
            [root addChild:tree];
            [dataProcesser createXMLFile:lib Root:tree];
            NSXMLDocument *XMLDoc=[NSXMLDocument documentWithRootElement:root];
            NSString *XMLPath=[[librariesDirectoryPath stringByAppendingPathComponent:lib.name] stringByAppendingPathExtension:@"xml"];
            [XMLDoc.XMLData writeToFile:XMLPath atomically:false];
        }
    }
}

- (IBAction)libraryFileOutlineContextMenu_Click:(NSMenuItem *)sender {
    NSString *command=sender.title;
    if ([command isEqualToString:@"新建节点"]) {
        if (self.libraryFileOutlineView.selectedRow==-1) {
            return;
        }
        NSObject *item=[self.libraryFileOutlineView itemAtRow:self.libraryFileOutlineView.selectedRow];
        if ([item isMemberOfClass:[Sound class]]) {
            return;
        }
        Library *lib= (Library*)item;
        Library *newLibLeaf = [[Library alloc]init];
        newLibLeaf.name=@"新场景";
        [newLibLeaf.libraryObject addObject:lib];
        [lib.libraries addObject:newLibLeaf];
        [self.libraryFileOutlineView reloadData];
    }
    else if ([command isEqualToString:@"删除节点"]){
        if (self.libraryFileOutlineView.selectedRow==-1) {
            return;
        }
        NSObject *item=[self.libraryFileOutlineView itemAtRow:self.libraryFileOutlineView.selectedRow];
        if ([item isMemberOfClass:[Sound class]]) {
            Sound *sound=(Sound*)item;
            Library *soundLib=[[Library alloc]init];
            NSObject *preItem=item;
            NSInteger preItemIndex=self.libraryFileOutlineView.selectedRow;
            while ([preItem isMemberOfClass:[sound class]]) {
                preItemIndex--;
                preItem=[self.libraryFileOutlineView itemAtRow:preItemIndex];
            }
            soundLib=(Library*)preItem;
            int soundIndex=0;
            while ([soundLib.sounds objectAtIndex:soundIndex]!=sound) {
                soundIndex++;
            }
            [soundLib.sounds removeObjectAtIndex:soundIndex];
        }else if ([item isMemberOfClass:[Library class]]){
            Library *lib=(Library*)item;
            if (lib.libraryObject.count==0) {
                lib.name=@"新剧本";
                lib.sounds=[[NSMutableArray alloc]init];
                lib.libraries=[[NSMutableArray alloc]init];
            }else{
                Library *libLib=[lib.libraryObject objectAtIndex:0];
                int libIndex=0;
                while ([libLib.libraries objectAtIndex:libIndex]!=lib) {
                    libIndex++;
                }
                [libLib.libraries removeObjectAtIndex:libIndex];
            }
        }
        [self.libraryFileOutlineView reloadData];
    }
    else if ([command isEqualToString:@"保存库文件"]){
        NSSavePanel *savePanel=[NSSavePanel savePanel];
        savePanel.nameFieldStringValue=[NSString stringWithFormat:@"%@.xml",dataProcesser.libraryFile.name];
        [savePanel beginWithCompletionHandler:^(NSInteger result) {
            if (result==NSFileHandlingPanelOKButton) {
                NSXMLElement *root=[NSXMLElement elementWithName:@"Library"];
                [root addChild:[NSXMLElement elementWithName:@"LibraryName" stringValue:dataProcesser.libraryFile.name]];
                [root addChild:[NSXMLElement elementWithName:@"LibraryPath" stringValue:savePanel.URL.path]];
                NSXMLElement *tree=[NSXMLElement elementWithName:@"Tree"];
                [root addChild:tree];
                [dataProcesser createXMLFile:dataProcesser.libraryFile Root:tree];
                NSXMLDocument *XMLDoc=[NSXMLDocument documentWithRootElement:root];
                [XMLDoc.XMLData writeToFile:savePanel.URL.path atomically:false];
            }
        }];
    }
    else if ([command isEqualToString:@"打开库文件"]){
        NSOpenPanel *openPanel=[NSOpenPanel openPanel];
        openPanel.allowsMultipleSelection=false;
        openPanel.canChooseDirectories=false;
        openPanel.canChooseFiles=true;
        [openPanel beginWithCompletionHandler:^(NSInteger result) {
            if (result==NSFileHandlingPanelOKButton) {
                dataProcesser.libraryFile=[[Library alloc]init];
                NSError *error=nil;
                NSXMLDocument *excelXMLFile=[[NSXMLDocument alloc] initWithContentsOfURL:openPanel.URL options:0 error:&error];
                if (error!=noErr) {
                    NSLog(@"%@",error);
                    return ;
                }
                NSXMLElement *libraryRoot=[excelXMLFile nodesForXPath:@"Library" error:&error].firstObject;
                if (error!=noErr) {
                    NSLog(@"%@",error);
                    return ;
                }
                NSXMLElement *libraryNameNode=[libraryRoot nodesForXPath:@"LibraryName" error:&error].firstObject;
                if (error!=noErr) {
                    NSLog(@"%@",error);
                    return ;
                }
                NSXMLElement *libraryPathNode=[libraryRoot nodesForXPath:@"LibraryPath" error:&error].firstObject;
                if (error!=noErr) {
                    NSLog(@"%@",error);
                    return ;
                }
                NSXMLElement *treeNode=[libraryRoot nodesForXPath:@"Tree" error:&error].firstObject;
                if (error!=noErr) {
                    NSLog(@"%@",error);
                    return ;
                }
                dataProcesser.libraryFile.isSelected=true;
                dataProcesser.libraryFile.libraryObject=[[NSMutableArray alloc]init];
                dataProcesser.libraryFile.name=libraryNameNode.stringValue;
                dataProcesser.libraryFile.sounds=[[NSMutableArray alloc]init];
                dataProcesser.libraryFile.libraries=[[NSMutableArray alloc]init];
                [dataProcesser scanSoundNodes:treeNode library:dataProcesser.libraryFile];
                [dataProcesser scanLibraryNodes:treeNode library:dataProcesser.libraryFile];
                [self.libraryFileOutlineView reloadData];
            }
            
        }];
    }
    else if ([command isEqualToString:@"导出音频文件"]){
        NSOpenPanel *savePanel=[NSOpenPanel openPanel];
        savePanel.canChooseDirectories=YES;
        savePanel.canChooseFiles=NO;
        [savePanel beginWithCompletionHandler:^(NSInteger result) {
            if (result==NSFileHandlingPanelOKButton) {
                [dataProcesser saveLibrarytoFileSystem:[savePanel.URL.path stringByAppendingPathComponent:dataProcesser.libraryFile.name] baseLibrary:dataProcesser.libraryFile];
            }
        }];
    }
    
}

- (IBAction)searchBarDidEdit:(NSTextField *)sender {
    dataProcesser.searchResultSounds = [[NSMutableArray alloc]init];
    for(Library *lib in dataProcesser.libraries){
        if (lib.isSelected) {
            NSString *keyWord=self.searchBarTextField.stringValue.lowercaseString;
            [dataProcesser.searchResultSounds addObjectsFromArray:[dataProcesser searchSounds:lib key:keyWord]];
        }
    }
    [self.searchResultTableView reloadData];
}

#pragma mark -tableView delegate method

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return dataProcesser.searchResultSounds.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    Sound *sound=[dataProcesser.searchResultSounds objectAtIndex:row];;
    if ([tableColumn.identifier isEqual:@"Point"]) {
        return sound.point;
    }else if ([tableColumn.identifier isEqualToString:@"Name"]){
        return sound.name;
    }else if ([tableColumn.identifier isEqualToString:@"Duration"]){
        return sound.duration;
    }else if ([tableColumn.identifier isEqualToString:@"Description"]){
        return sound.Description;
    }
    return @"";
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    Sound *sound=[dataProcesser.searchResultSounds objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"Point"]) {
        sound.point=(NSString *)object;
    }else if ([tableColumn.identifier isEqualToString:@"Description"]){
        sound.Description=(NSString *)object;
    }
}

-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if ([tableColumn.identifier isEqualToString:@"Point"]) {
        return true;
    }else if ([tableColumn.identifier isEqualToString:@"Description"]){
        return true;
    }
    return false;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    dataProcesser.selectedSound=[dataProcesser.searchResultSounds objectAtIndex:row];
    return true;
}

-(void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
    if ([tableColumn.identifier isEqualToString:@"Point"]) {
        [dataProcesser.searchResultSounds sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            Sound *sound1=obj1;
            Sound *sound2=obj2;
            if ([sound1.point isEqualToString:@""]) {
                return false;
            }
            if ([sound2.point isEqualToString:@""]) {
                return true;
            }
            return ((int)(sound1.point)>(int)(sound2.point));
        }];
        [self.searchResultTableView reloadData];
    }else if ([tableColumn.identifier isEqualToString:@"Name"]){
        [dataProcesser.searchResultSounds sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            Sound *sound1=obj1;
            Sound *sound2=obj2;
            return [sound1.name compare:sound2.name]==NSOrderedAscending;
        }];
        [self.searchResultTableView reloadData];
    }else if ([tableColumn.identifier isEqualToString:@"Duration"]){
        [dataProcesser.searchResultSounds sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            Sound *sound1=obj1;
            Sound *sound2=obj2;
            NSMutableArray *oneCount=[NSMutableArray arrayWithArray:[sound1.duration componentsSeparatedByString:@":"]];
            NSMutableArray *twoCount=[NSMutableArray arrayWithArray:[sound2.duration componentsSeparatedByString:@":"]];
            for (NSInteger i=oneCount.count; i<3; i++) {
                [oneCount insertObject:@"00:" atIndex:0];
            }
            for (NSInteger i=twoCount.count; i<3; i++) {
                [twoCount insertObject:@"00:" atIndex:0];
            }
            for (int i=0; i<3; i++) {
                if ((int)[oneCount objectAtIndex:i]>(int)[twoCount objectAtIndex:i])
                    return true;
                else if ((int)[oneCount objectAtIndex:i]<(int)[twoCount objectAtIndex:i])
                    return false;
            }
            return true;
            
        }];
        [self.searchResultTableView reloadData];
    }
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation{
    NSView *sourceView = [info draggingSource];
    if ((sourceView == self.libraryFileOutlineView || sourceView==self.librariesOutlineView) && tableView==self.searchResultTableView) {
        dataProcesser.searchResultSounds=[[NSMutableArray alloc] init];
        [dataProcesser.searchResultSounds addObject:dataProcesser.draggingSound];
        [self.searchResultTableView reloadData];
        return true;
    }
    return false;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation{
    return NSDragOperationEvery;
}

-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard{
    NSData *data=[NSKeyedArchiver archivedDataWithRootObject:@""];
    [pboard declareTypes:@[NSStringPboardType] owner:self];
    dataProcesser.draggingSound=[dataProcesser.searchResultSounds objectAtIndex:rowIndexes.lastIndex];
    return true;
}

#pragma mark -outlineView delegate method

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView]) {
        if (item == nil) {
            return dataProcesser.libraries.count;
        }else if ([item isMemberOfClass:[Library class]]){
            Library *lib=item;
            return lib.sounds.count+lib.libraries.count;
        }
    }else if ([outlineView isEqual:self.libraryFileOutlineView]){
        if (item==nil) {
            return 1;
        }else if ([item isMemberOfClass:[Library class]]){
            Library *lib=item;
            return lib.sounds.count + lib.libraries.count;
        }
    }
    return 0;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView]) {
        if ([item isMemberOfClass:[Library class]]) {
            Library *lib=item;
            NSInteger leafcount=lib.sounds.count+lib.libraries.count;
            if (leafcount!=0) {
                return true;
            }
        }
    }else if ([outlineView isEqual:self.libraryFileOutlineView]){
        if ([item isMemberOfClass:[Library class]]) {
            Library *lib=item;
            NSInteger leafcount=lib.sounds.count+lib.libraries.count;
            if (leafcount!=0) {
                return true;
            }
        }
    }
    return false;
}//Returns a Boolean value that indicates whether the a given item is expandable.

-(NSCell*)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView]) {
        if ([tableColumn.identifier isEqualToString:@"isLibraryChecked"]) {
            if ([item isMemberOfClass:[Library class]]) {
                Library *lib=item;
                if (lib.libraryObject.count!=0) {
                    return [[NSTextFieldCell alloc] initTextCell:@""];
                }
            }else if ([item isMemberOfClass:[Sound class]])
                return [[NSTextFieldCell alloc] initTextCell:@""];
        }
    }
    else if ([outlineView isEqual:self.libraryFileOutlineView]){
        //nothing to do
    }
    return nil;
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView]) {
        if (item==nil) {
            return [dataProcesser.libraries objectAtIndex:index];
        }else if ([item isMemberOfClass:[Library class]]){
            Library *lib=item;
            if(index<lib.sounds.count)
                return [lib.sounds objectAtIndex:index];
            else
                return [lib.libraries objectAtIndex:(index-lib.sounds.count)];
        }
    }else if ([outlineView isEqual:self.libraryFileOutlineView]){
        if (item==nil) {
            return dataProcesser.libraryFile;
        }else if ([item isMemberOfClass:[Library class]]){
            Library *lib=item;
            if(index<lib.sounds.count)
                return [lib.sounds objectAtIndex:index];
            else
                return [lib.libraries objectAtIndex:(index-lib.sounds.count)];
        }
    }
    return item;
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView]) {
        if (item==nil) {
            return @"";
        }
        if ([tableColumn.identifier isEqualToString:@"isLibraryChecked"]) {
            if ([item isMemberOfClass:[Library class]]) {
                Library *lib=item;
                if(lib.libraryObject.count==0)
                    return [NSNumber numberWithBool:lib.isSelected];//-----------------------ERROR MayBe-----------------------------
            }
        }else{
            if ([item isMemberOfClass:[Library class]]) {
                Library *lib=item;
                return lib.name;
            }else if ([item isMemberOfClass:[Sound class]]){
                Sound *sound=item;
                return sound.name;
            }
        }
    }else if ([outlineView isEqual:self.libraryFileOutlineView]){
        if(item==nil)
            return @"";
        else{
            if ([item isMemberOfClass:[Library class]]) {
                Library *lib=item;
                return lib.name;
            }else if ([item isMemberOfClass:[Sound class]]){
                Sound *sound=item;
                return sound.name;
            }
        }
    }
    return @"";
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView]) {
        if ([tableColumn.identifier isEqualToString:@"isLibraryChecked"]) {
            if ([item isMemberOfClass:[Library class]]) {
                Library *lib=item;
                if(lib.libraryObject.count==0)
                    return true;
            }
        }
    }else if ([outlineView isEqual:self.libraryFileOutlineView]){
        if([item isMemberOfClass:[Library class]])
            return true;
    }
    return false;
}

-(void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView]) {
        if ([tableColumn.identifier isEqualToString:@"isLibraryChecked"]) {
            if ([item isMemberOfClass:[Library class]]) {
                Library *lib=item;
                if(lib.libraryObject.count==0){
                    NSNumber *numObject=(NSNumber*)object;
                    lib.isSelected =numObject.boolValue ;
                }
            }
        }
    }else if ([outlineView isEqual:self.libraryFileOutlineView]){
        if ([item isMemberOfClass:[Library class]]) {
            Library *lib=item;
            lib.name=(NSString*)object;
        }
    }
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
    if ([outlineView isEqual:self.librariesOutlineView] || [outlineView isEqual:self.libraryFileOutlineView]) {
        if ([item isMemberOfClass:[Sound class]]) {
            dataProcesser.selectedSound=(Sound *)item;
            audioPlayerView.fileToPlay=[NSURL fileURLWithPath:dataProcesser.selectedSound.path];
            [audioPlayerView playTheSound];
        }
    }
    return true;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard{
    if ([outlineView isEqual:self.librariesOutlineView] || [outlineView isEqual:self.libraryFileOutlineView]) {
        if ([items.lastObject isMemberOfClass:[Sound class]]) {
            NSData *data=[NSKeyedArchiver archivedDataWithRootObject:@""];
            [pasteboard declareTypes:@[NSStringPboardType] owner:self];
            dataProcesser.draggingSound = (Sound *)items.lastObject;
            return true;
        }
    }
    return false;
}

-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index{
    return NSDragOperationEvery;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index{
    NSView *sourceView=[info draggingSource];
    if (([sourceView isEqual:self.searchResultTableView ] || [sourceView isEqual:self.librariesOutlineView]) && [outlineView isEqual:self.libraryFileOutlineView] && [item isMemberOfClass:[Library class]]) {
        Library *lib=item;
        [lib.sounds addObject:dataProcesser.draggingSound];
        [self.libraryFileOutlineView reloadData];
        return true;
    }
    return false;
}

@end

