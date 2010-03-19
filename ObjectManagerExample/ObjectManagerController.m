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
- (void) checkTextualPathForMixedPath;
@end

NSString *myFolderUTIString = @"org.etoile.ObjectManagerExample.folder";
NSString *myFileUTIString = @"org.etoile.ObjectManagerExample.file";

@implementation ObjectManagerController

static NSFileManager *objectManager = nil;

- (void) awakeFromNib
{
	objectManager = [NSFileManager defaultManager];
	
	ASSIGN(path, @"/");
	// TODO: Set mainViewItem and pathViewItem in the nib.
	mainViewItem = [viewContainer layoutItem];
	pathViewItem = [pathContainer layoutItem];

	[self checkTextualPathForMixedPath];

	[ETUTI registerTypeWithString: myFileUTIString 
	                  description: nil 
	             supertypeStrings: [NSArray array]];
	[ETUTI registerTypeWithString: myFolderUTIString 
	                  description: nil 
	             supertypeStrings: [NSArray array]];

	ETUTI *myFileUTI = [ETUTI typeWithString: myFileUTIString];
	ETUTI *myFolderUTI = [ETUTI typeWithString: myFolderUTIString];

	controller = AUTORELEASE([[ETController alloc] init]);
	[controller setAllowedPickTypes: A(myFileUTI, myFolderUTI)];
	[controller setAllowedDropTypes: A(myFileUTI, myFolderUTI) 
	                  forTargetType: myFolderUTI];

	[mainViewItem setController: controller];
	// TODO: Should probably be on the controller or the tool.
	//[mainViewItem setAllowsMultipleSelection: YES];
	[mainViewItem setRepresentedPathBase: path];		
	[mainViewItem setSource: self];
	[mainViewItem setTarget: self];
	[mainViewItem setDoubleAction: @selector(doubleClickInMainView:)];
	[mainViewItem setHasVerticalScroller: YES];
	[mainViewItem setHasHorizontalScroller: YES];
	[mainViewItem setLayout: [self configureLayout: [ETIconLayout layout]]];
	[mainViewItem reloadAndUpdateLayout];

	[pathViewItem setLayout: [ETLineLayout layout]];
	[[pathViewItem layout] setConstrainedItemSize: NSMakeSize(64, 64)];
	[pathViewItem setSource: self];
	[pathViewItem setTarget: self];
	[pathViewItem setDoubleAction: @selector(doubleClickInPathView:)];
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
	NSString *newPath = [item valueForProperty: @"filePath"];
	
	NSLog(@"Moving from path %@ to %@", path, newPath);
	ASSIGN(path, newPath);

	// NOTE: The following is mandatory if you use tree source protocol unlike 
	// with flat source protocol.
	[mainViewItem setRepresentedPathBase: path];
	
	[mainViewItem reloadAndUpdateLayout];
	[pathViewItem reloadAndUpdateLayout];
}

/* Example with path /2/Applications/3 

   We use recursivity to retrieve the head and moves back to the tail component
   by component.
   We process /2, /<filename>/Applications and /<filename>/Applications/3 and 
   we expect /<filename>/Applications/<filename> */
- (NSString *) textualPathForMixedPath: (NSString *)mixedPath
{
	NSString *pathGettingFixed = nil;
	
	/* '/2' is made of two path components */
	if ([[mixedPath pathComponents] count] > 2)
	{
		NSString *beginningOfPath = [self textualPathForMixedPath: [mixedPath stringByDeletingLastPathComponent]];
		if (beginningOfPath == nil)
		{
			return nil;
		}
		pathGettingFixed = [beginningOfPath stringByAppendingPathComponent: [mixedPath lastPathComponent]];
	}
	else
	{
		pathGettingFixed = mixedPath;
	}

	/* -> means moving up in the call stack... lastcall -> lastcall -1 -> lastcall - 2 */
	NSString *componentToCheck = [pathGettingFixed lastPathComponent]; // 2 -> Applications -> 3
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString: componentToCheck];
	
	/* componentToCheck is a number, we have to modify the path */
	if ([[NSCharacterSet decimalDigitCharacterSet] isSupersetOfSet: charSet])
	{
		NSString *pathBase = [pathGettingFixed stringByDeletingLastPathComponent]; // / -> /<filename>/Applications 
		NSArray *files = [[NSFileManager defaultManager] directoryContentsAtPath: pathBase];
		
		if (files != nil && [files count] > 0)
		{
			NSString *file = [files objectAtIndex: [componentToCheck intValue]];
			NSMutableArray *components = [[pathGettingFixed pathComponents] mutableCopy];
			
			[components removeLastObject]; // 2 -> 3
			[components addObject: [file lastPathComponent]]; // <filename> -> <filename>
			
			pathGettingFixed = [NSString pathWithComponents: components];
		}
		else
		{
			pathGettingFixed = nil; /* Path is invalid */
		}
	}
	
	return pathGettingFixed;
}

- (void) checkTextualPathForMixedPath
{
#ifndef GNUSTEP			 
	NSString *testPath = @"/2";
	NSString *fixedPath = [self textualPathForMixedPath: testPath];
	NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);

	testPath = @"/Developer/3";
	fixedPath = [self textualPathForMixedPath: testPath];
	NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);

	testPath = @"/Developer/3/Audio/1";
	fixedPath = [self textualPathForMixedPath: testPath];
	NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);

	testPath = @"/10/3/Audio/1";
	fixedPath = [self textualPathForMixedPath: testPath];
	if (nil != fixedPath)
	{
		NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);
	}

	testPath = @"/1/1";
	fixedPath = [self textualPathForMixedPath: testPath];
	if (nil != fixedPath)
	{
		NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);
	}
#endif
}

/* ETLayoutItemGroupSource informal protocol */

/* Tree protocol */

- (int) itemGroup: (ETLayoutItemGroup *)baseItem numberOfItemsAtPath: (NSIndexPath *)indexPath
{
	NSString *subpath = [indexPath stringByJoiningIndexPathWithSeparator: @"/"];
	NSString *filePath = [[baseItem representedPath] stringByAppendingPathComponent: subpath];
	
	/* Standardize path by replacing indexes by file names */
	filePath = [self textualPathForMixedPath: filePath];
	
	if ([baseItem isEqual: mainViewItem]) /* Main View */
	{
		NSArray *fileObjects = [objectManager directoryContentsAtPath: filePath];

		//NSLog(@"Returns %d as number of items in container %@", [fileObjects count], container);
		
		return [fileObjects count];
	}
	else if ([baseItem isEqual: pathViewItem]) /* Path View */
	{
		return [self numberOfItemsInItemGroup: baseItem];
	}
	
	return 0;
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtPath: (NSIndexPath *)indexPath
{
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	ETLayoutItem *fileItem = nil;

	if ([baseItem isEqual: mainViewItem]) /* Browsing View */
	{
		NSString *subpath = [indexPath stringByJoiningIndexPathWithSeparator: @"/"];
		NSString *filePath = [[baseItem representedPath] stringByAppendingPathComponent: subpath];
	
		/* Standardize path by replacing indexes by file names */
		filePath = [self textualPathForMixedPath: filePath];
		
		NSDictionary *attributes = [objectManager fileAttributesAtPath: filePath traverseLink: NO];
		NSImage *icon = [wk iconForFile: filePath];
		BOOL isDir = NO;
		
		//NSLog(@"Found path %@ with %@", filePath, newPath);

		/* Force the loading of  128 * 128 icon versions otherwise icons cannot
		   be resized beyond 32 * 32 (when put inside an image view). */
		[icon setSize: NSMakeSize(128, 128)];
		if ([[NSFileManager defaultManager] fileExistsAtPath: filePath isDirectory: &isDir] && isDir)
		{
			fileItem = [[ETLayoutItemFactory factory] itemGroup];
			[fileItem setLayout: [ETNullLayout layout]];
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
		[fileItem setValue: filePath forProperty: @"filePath"];
		[fileItem setValue: [NSNumber numberWithInt: [attributes fileSize]] forProperty: @"fileSize"];
		[fileItem setValue: [attributes fileType] forProperty: @"fileType"];
		//[fileItem setValue: date forProperty: @"fileModificationDate"];
		
		//NSLog(@"Returns %@ as layout item in container %@", fileItem, container);
	}
	else if ([baseItem isEqual: pathViewItem]) /* Path View */
	{
		int flatIndex = [indexPath indexAtPosition: [indexPath length] - 1];
		return [self itemGroup: baseItem itemAtIndex: flatIndex];
	}

	return fileItem;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	return [NSArray arrayWithObjects: @"icon", @"name", @"fileSize", @"fileType", @"fileModificationDate", nil];
}

/* Flat protocol

   NOTE: only present for demonstrating purpose. It could be rewritten as part
   of tree protocol methods implemented above. */

- (int) numberOfItemsInItemGroup: (ETLayoutItemGroup *)baseItem
{
	if ([baseItem isEqual: mainViewItem]) /* Browsing View */
	{
		NSArray *fileObjects = [objectManager directoryContentsAtPath: path];

		//NSLog(@"Returns %d as number of items in %@", [fileObjects count], mainViewItem);
		
		return [fileObjects count];
	}
	else if ([baseItem isEqual: pathViewItem]) /* Path View */
	{
		NSArray *pathComponents = [path pathComponents];

		//NSLog(@"Returns %d as number of items in %@", [pathComponents count], pathViewItem);
		
		return [pathComponents count];
	}
	
	return 0;
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtIndex: (int)index
{
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	ETLayoutItem *fileItem = nil;

	if ([baseItem isEqual: mainViewItem]) /* Browsing View */
	{
		NSArray *fileObjects = [objectManager directoryContentsAtPath: path];
		NSString *filePath = [path stringByAppendingPathComponent: [fileObjects objectAtIndex: index]];
		NSDictionary *attributes = [objectManager fileAttributesAtPath: filePath traverseLink: NO];

		fileItem = [[ETLayoutItemFactory factory] item];

		[fileItem setValue: [filePath lastPathComponent] forProperty: @"name"];
		[fileItem setValue: filePath forProperty: @"filePath"];
		[fileItem setValue: [wk iconForFile: filePath] forProperty: @"icon"];
		[fileItem setValue: [NSNumber numberWithInt: [attributes fileSize]] forProperty: @"fileSize"];
		[fileItem setValue: [attributes fileType] forProperty: @"fileType"];
		//[fileItem setValue: date forProperty	: @"modificationdate"];
		
		//NSLog(@"Returns %@ as layout item in %@", fileItem, mainViewItem);
	}
	else if ([baseItem isEqual: pathViewItem]) /* Path View */
	{
		NSArray *pathComponents = [path pathComponents];
		NSString *filePath = [NSString pathWithComponents: [pathComponents subarrayWithRange: NSMakeRange(0, index + 1)]];

		//NSLog(@"Built path is %@ with components %@", filePath, pathComponents);

		fileItem = [[ETLayoutItemFactory factory] item];
		[fileItem setFrame: NSMakeRect(0, 0, 48, 48)];
		[fileItem setIcon: [wk iconForFile: filePath]];

		[fileItem setValue: [filePath lastPathComponent] forProperty: @"name"];
		[fileItem setValue: filePath forProperty: @"filePath"];
		
		//NSLog(@"Returns %@ as layout item in %@", fileItem, pathViewItem);
	}
	
	return fileItem;
}

@end
