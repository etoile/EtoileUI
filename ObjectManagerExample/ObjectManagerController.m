//
//  ObjectManagerController.m
//  Container
//
//  Created by Quentin Mathé on 31/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ObjectManagerController.h"

@interface NSObject (EtoileUINSAlertWorkaround)
- (id) layout;
@end

@interface ObjectManagerController (Private)
- (id) configureLayout: (id)layoutObject;
- (void) moveToItem: (ETLayoutItem *)item;
@end

NSString *myFolderUTIString = @"org.etoile.ObjectManagerExample.folder";
NSString *myFileUTIString = @"org.etoile.ObjectManagerExample.file";

@implementation ObjectManagerController

static NSFileManager *fileManager = nil;
static NSString *filePathProperty = @"filePath";

/* Invoked when the application is going to finish its launch because 
the receiver is set as the application's delegate in the nib. */
- (void) applicationWillFinishLaunching: (NSNotification *)notif
{
	fileManager = [NSFileManager defaultManager];

	/* Will turn the nib views and windows into layout item trees */
	[ETApp rebuildMainNib];

	/* Declare pick and drop rules based on UTI types */

	[ETUTI registerTypeWithString: myFileUTIString 
	                  description: nil 
	             supertypeStrings: [NSArray array]
	                     typeTags: nil];
	[ETUTI registerTypeWithString: myFolderUTIString 
	                  description: nil 
	             supertypeStrings: [NSArray array]
	                     typeTags: nil];

	ETUTI *myFileUTI = [ETUTI typeWithString: myFileUTIString];
	ETUTI *myFolderUTI = [ETUTI typeWithString: myFolderUTIString];

	controller = AUTORELEASE([[ETController alloc] init]);
	[controller setAllowedPickTypes: A(myFileUTI, myFolderUTI)];
	[controller setAllowedDropTypes: A(myFileUTI, myFolderUTI) 
	                  forTargetType: myFolderUTI];

	/* Set the start path */

	[mainViewItem setValue: @"/" forProperty: filePathProperty];
	[pathViewItem setValue: @"/" forProperty: filePathProperty];
	
	/* Set up the the main view UI */
	
	[mainViewItem setController: controller];
	// TODO: Should probably be on the controller or the tool.
	//[mainViewItem setAllowsMultipleSelection: YES];	
	[mainViewItem setSource: self];
	[mainViewItem setTarget: self];
	[mainViewItem setDoubleAction: @selector(doubleClickInMainView:)];
	[mainViewItem setHasVerticalScroller: YES];
	[mainViewItem setHasHorizontalScroller: YES];
	[mainViewItem setLayout: [self configureLayout: [ETIconLayout layout]]];

	/* Set up the path view UI */

	[pathViewItem setLayout: [ETLineLayout layout]];
	[[pathViewItem layout] setConstrainedItemSize: NSMakeSize(64, 64)];
	[pathViewItem setSource: self];
	[pathViewItem setTarget: self];
	[pathViewItem setDoubleAction: @selector(doubleClickInPathView:)];

	/* Load the start path content and redisplay */

	[mainViewItem reloadAndUpdateLayout];
	[pathViewItem reloadAndUpdateLayout];
}

- (id) configureLayout: (id)layoutObject
{
	if ([layoutObject isKindOfClass: [ETTableLayout class]])
	{
		NSCell *iconCell = [[NSImageCell alloc] initImageCell: nil];
		NSFormatter *sizeFormatter = AUTORELEASE([[ETByteSizeFormatter alloc] init]);

		[layoutObject setStyle: AUTORELEASE(iconCell) forProperty: @"icon"];
		[layoutObject setDisplayName: @"" forProperty: @"icon"];
		[layoutObject setDisplayName: @"Name" forProperty: @"name"];
		[layoutObject setDisplayName: @"Type" forProperty: @"fileType"];
		[layoutObject setDisplayName: @"Size" forProperty: @"fileSize"];
		[layoutObject setFormatter: sizeFormatter forProperty: @"fileSize"];
		[layoutObject setDisplayName: @"Modification Date" forProperty: @"fileModificationDate"];
	}
	return layoutObject;
}

- (IBAction) changeLayout: (id)sender
{
	ETLayout *layout = nil;
	
	switch ([[sender selectedItem] tag])
	{
		case 0:
			layout = [ETColumnLayout layout];
			break;
		case 1:
			layout = [ETLineLayout layout];
			break;
		case 2:
			layout = [ETFlowLayout layout];
			break;
		case 3:
			layout = [ETTableLayout layout];
			break;
		case 4:
			layout = [ETOutlineLayout layout];
			break;
		case 5:
			layout = [ETBrowserLayout layout];
			break;
		case 6:
			layout = [ETFreeLayout layout];
			break;
		case 7:
			layout = [ETIconLayout layout];
			break;
		case 8:
			layout = [ETViewModelLayout layout];
			break;
		case 9:
			layout = [ETPaneLayout masterDetailLayout];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	[mainViewItem setLayout: [self configureLayout: layout]];
}

- (IBAction) switchUsesScrollView: (id)sender
{
	if ([sender state] == NSOnState)
	{
		[mainViewItem setHasVerticalScroller: YES];
		//[mainViewItem setHasHorizontalScroller: YES];
	}
	else if ([sender state] == NSOffState)
	{
		[mainViewItem setHasVerticalScroller: NO];
		//[mainViewItem setHasHorizontalScroller: NO];
	}
	
	[mainViewItem updateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [mainViewItem setNeedsDisplay: YES];  
}

- (IBAction) scale: (id)sender
{
	[mainViewItem setItemScaleFactor: [sender floatValue]];
}

- (IBAction) search: (id)sender
{
	NSString *searchString = [sender stringValue];

	if ([searchString isEqual: @""])
	{
		[controller setFilterPredicate: nil];
	}
	else
	{
		[controller setFilterPredicate: [NSPredicate predicateWithFormat: @"displayName contains %@", searchString]];
	}
}

- (void) doubleClickInMainView: (id)sender
{
	[self moveToItem: [mainViewItem doubleClickedItem]];
}

- (void) doubleClickInPathView: (id)sender
{
	[self moveToItem: [pathViewItem doubleClickedItem]];
}

- (void) moveToItem: (ETLayoutItem *)item
{
	NSString *newPath = [item valueForProperty: filePathProperty];
	NSString *oldPath = [mainViewItem valueForProperty: filePathProperty];
	
	NSLog(@"Moving from path %@ to %@", oldPath , newPath);

	[mainViewItem setValue: newPath forProperty: filePathProperty];

	[mainViewItem reloadAndUpdateLayout];
	[pathViewItem reloadAndUpdateLayout];
}

/* ETLayoutItemGroup Source Protocol */

- (int) baseItem: (ETLayoutItemGroup *)baseItem numberOfItemsInItemGroup: (ETLayoutItemGroup *)itemGroup
{
	if ([baseItem isEqual: mainViewItem]) /* Browsing View */
	{
		NSString *dirPath = [itemGroup valueForProperty: filePathProperty];
		NSArray *fileObjects = [fileManager directoryContentsAtPath: dirPath];

		NSLog(@"Returns %d as number of items in %@", [fileObjects count], mainViewItem);
		
		return [fileObjects count];
	}
	else if ([baseItem isEqual: pathViewItem]) /* Path View */
	{
		NSArray *pathComponents = [[mainViewItem valueForProperty: filePathProperty] pathComponents];

		NSLog(@"Returns %d as number of items in %@", [pathComponents count], pathViewItem);
		
		return [pathComponents count];
	}
	
	return 0;
}

- (ETLayoutItem *) fileItemWithPath: (NSString *)filePath
{
	ETLayoutItem *fileItem = nil;
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	NSDictionary *attributes = [fileManager fileAttributesAtPath: filePath traverseLink: NO];
	NSImage *icon = [wk iconForFile: filePath];
	BOOL isDir = NO;
	
	NSLog(@"Create file item with path %@ ", filePath);

	/* Force the loading of  128 * 128 icon versions otherwise icons cannot
	   be resized beyond 32 * 32 (when put inside an image view). */
	[icon setSize: NSMakeSize(128, 128)];
	if ([fileManager fileExistsAtPath: filePath isDirectory: &isDir] && isDir)
	{
		fileItem = [[ETLayoutItemFactory factory] itemGroup];
		[fileItem setLayout: nil];
		[fileItem setSubtype: [ETUTI typeWithString: myFolderUTIString]];
	}
	else
	{
		fileItem = [[ETLayoutItemFactory factory] item];
		[fileItem setSubtype: [ETUTI typeWithString: myFileUTIString]];
	}
	
	// FIXME: better to have a method -setIdentifier: different from -setName:
	[fileItem setName: [filePath lastPathComponent]];
	[fileItem setIcon: icon];
	[fileItem setValue: filePath forProperty: filePathProperty];
	[fileItem setValue: [NSNumber numberWithInt: [attributes fileSize]] forProperty: @"fileSize"];
	[fileItem setValue: [attributes fileType] forProperty: @"fileType"];
	//[fileItem setValue: date forProperty: @"fileModificationDate"];

	return fileItem;
}

- (ETLayoutItem *) baseItem: (ETLayoutItemGroup *)baseItem 
                itemAtIndex: (int)index 
                inItemGroup: (ETLayoutItemGroup *)itemGroup 
{
	if ([baseItem isEqual: mainViewItem]) /* Browsing View */
	{
		NSString *dirPath = [itemGroup valueForProperty: filePathProperty];
		NSArray *fileNames = [fileManager directoryContentsAtPath: dirPath];
		NSString *filePath = [dirPath stringByAppendingPathComponent: [fileNames objectAtIndex: index]];

		return [self fileItemWithPath: filePath];		
	}
	else if ([baseItem isEqual: pathViewItem]) /* Path View */
	{
		NSArray *pathComponents = [[mainViewItem valueForProperty: filePathProperty] pathComponents];
		NSString *filePath = [NSString pathWithComponents: 
			[pathComponents subarrayWithRange: NSMakeRange(0, index + 1)]];

		return [self fileItemWithPath: filePath];
	}
	return nil;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	return [NSArray arrayWithObjects: @"icon", @"name", @"fileSize", @"fileType", @"fileModificationDate", nil];
}

@end
