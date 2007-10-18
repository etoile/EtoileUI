//
//  ObjectManagerController.m
//  Container
//
//  Created by Quentin Mathé on 31/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ObjectManagerController.h"

@interface ObjectManagerController (Private)
- (void) moveToItem: (ETLayoutItem *)item;
- (NSString *) textualPathForMixedPath: (NSString *)mixedPath;
- (int) numberOfItemsInContainer: (ETContainer *)container;
- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container;
@end


@implementation ObjectManagerController

static NSFileManager *objectManager = nil;

- (void) dealloc
{
	
	[super dealloc];
}

- (void) awakeFromNib
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	objectManager = [NSFileManager defaultManager];
	
	ASSIGN(path, @"/");
    
    [nc addObserver: self 
           selector: @selector(viewContainerDidResize:) 
               name: NSViewFrameDidChangeNotification 
             object: viewContainer];
			 
	NSString *testPath = nil;
	NSString *fixedPath = nil;
	
	testPath = @"/2";
	fixedPath = [self textualPathForMixedPath: testPath];
	NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);
	testPath = @"/Developer/3";
	fixedPath = [self textualPathForMixedPath: testPath];
	NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);
	testPath = @"/Developer/3/Audio/1";
	fixedPath = [self textualPathForMixedPath: testPath];
	NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);
	testPath = @"/10/3/Audio/1";
	fixedPath = [self textualPathForMixedPath: testPath];
	if (fixedPath)
		NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);
	testPath = @"/1/1";
	fixedPath = [self textualPathForMixedPath: testPath];
	if (fixedPath)
		NSLog(@"Mixed path test: %@ -> %@", testPath, fixedPath);
			
	[viewContainer setSource: self];
	[viewContainer setTarget: self];
	[viewContainer setDoubleAction: @selector(doubleClickInViewContainer:)];
	[viewContainer setHasVerticalScroller: YES];
	[viewContainer setHasHorizontalScroller: YES];
	[viewContainer setLayout: AUTORELEASE([[ETStackLayout alloc] init])];
	[viewContainer reloadAndUpdateLayout];
	
	[[pathContainer layout] setConstrainedItemSize: NSMakeSize(64, 64)];
	[pathContainer setSource: self];
	[pathContainer setTarget: self];
	[pathContainer setDoubleAction: @selector(doubleClickInPathContainer:)];
	[pathContainer reloadAndUpdateLayout];
}

- (void) viewContainerDidResize: (NSNotification *)notif
{
	if ([viewContainer canUpdateLayout])
		[viewContainer updateLayout];
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = nil;
	
	switch ([[sender selectedItem] tag])
	{
		case 0:
			layoutClass = [ETStackLayout class];
			break;
		case 1:
			layoutClass = [ETLineLayout class];
			break;
		case 2:
			layoutClass = [ETFlowLayout class];
			break;
		case 3:
			layoutClass = [ETTableLayout class];
			break;
		case 4:
			layoutClass = [ETOutlineLayout class];
			break;
		case 5:
			layoutClass = [ETBrowserLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	[viewContainer setLayout: (ETLayout *)AUTORELEASE([[layoutClass alloc] init])];
}

- (IBAction) switchUsesScrollView: (id)sender
{
	if ([sender state] == NSOnState)
	{
		[viewContainer setHasVerticalScroller: YES];
		[viewContainer setHasHorizontalScroller: YES];
	}
	else if ([sender state] == NSOffState)
	{
		[viewContainer setScrollView: nil];
	}
	
	[viewContainer updateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

- (IBAction) scale: (id)sender
{
	[viewContainer setItemScaleFactor: [sender floatValue] / 100];
}

- (void) doubleClickInViewContainer: (id)sender
{
	// NOTE: 'sender' isn't always ETContainer instance. For ETTableLayout it 
	// is the NSTableView instance in use.
	[self moveToItem: [viewContainer doubleClickedItem]];
}

- (void) doubleClickInPathContainer: (id)sender
{
	[self moveToItem: [pathContainer doubleClickedItem]];
}

- (void) moveToItem: (ETLayoutItem *)item
{
	NSString *newPath = [item valueForProperty: @"path"];
	
	NSLog(@"Moving from path %@ to %@", path, newPath);
	ASSIGN(path, newPath);
	// NOTE: The following is mandatory if you use tree source protocol unlike 
	// with flat source protocol.

	[viewContainer setRepresentedPath: path];
	
	[viewContainer reloadAndUpdateLayout];
	[pathContainer reloadAndUpdateLayout];
}

- (NSImageView *) imageViewForImage: (NSImage *)image
{
	if (image != nil)
    {
        NSImageView *view = [[NSImageView alloc] 
            initWithFrame: NSMakeRect(0, 0, 48, 48)];
	
		[image setScalesWhenResized: YES]; 
		[view setImageScaling: NSScaleProportionally];
        [view setImage: image];
		return (NSImageView *)AUTORELEASE(view);
    }

    return nil;
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
		NSString *beginningOfPath = nil;
		
		beginningOfPath = [self textualPathForMixedPath: [mixedPath stringByDeletingLastPathComponent]];
		if (beginningOfPath == nil)
			return nil;
		pathGettingFixed = [beginningOfPath stringByAppendingPathComponent: [mixedPath lastPathComponent]];
	}
	else
	{
		pathGettingFixed = mixedPath;
	}

	/* -> means moving up in the call stack… lastcall -> lastcall -1 -> lastcall - 2 */
	NSString *componentToCheck = [pathGettingFixed lastPathComponent]; // 2 -> Applications -> 3
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString: componentToCheck];
	
	/* componentToCheck is a number, we have to modify the path */
	if ([[NSCharacterSet decimalDigitCharacterSet] isSupersetOfSet: charSet])
	{
		NSString *pathBase = [pathGettingFixed stringByDeletingLastPathComponent];	// / -> /<filename>/Applications 
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

/* ETContainerSource informal protocol */

/* Tree protocol used by TreeContainer */

- (int) container: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)indexPath
{
	//NSString *textualPath = [self textualPathForMixedPath: newPath];
	/* Next line is equal to [[[container layoutItem] representedPath] 
	   stringByAppendingPath: [[container layoutItem] pathForIndexPath: indexPath]]; */
	//NSString *subpath = [[container layoutItem] pathForIndexPath: indexPath];
	NSString *subpath = [indexPath stringByJoiningIndexPathWithSeparator: @"/"];
	NSString *filePath = [[[container layoutItem] representedPath] stringByAppendingPathComponent: subpath];
	
	/* Standardize path by replacing indexes by file names */
	filePath = [self textualPathForMixedPath: filePath];
	
	if ([container isEqual: viewContainer]) /* Browsing Container */
	{
		NSArray *fileObjects = [objectManager directoryContentsAtPath: filePath];

		//NSLog(@"Returns %d as number of items in container %@", [fileObjects count], container);
		
		return [fileObjects count];
	}
	else if ([container isEqual: pathContainer]) /* Path Container */
	{
		return [self numberOfItemsInContainer: container];
	}
	
	return 0;
}

- (ETLayoutItem *) container: (ETContainer *)container itemAtPath: (NSIndexPath *)indexPath
{
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	ETLayoutItem *fileItem = nil;
	
	if ([container isEqual: viewContainer]) /* Browsing Container */
	{
		NSString *subpath = [indexPath stringByJoiningIndexPathWithSeparator: @"/"];
		NSString *filePath = [[[container layoutItem] representedPath] stringByAppendingPathComponent: subpath];
	
		/* Standardize path by replacing indexes by file names */
		filePath = [self textualPathForMixedPath: filePath];
		
		NSDictionary *attributes = [objectManager fileAttributesAtPath: filePath traverseLink: NO];
		NSImage *icon = [wk iconForFile: filePath];
		BOOL isDir = NO;
		
		//NSLog(@"Found path %@ with %@", filePath, newPath);
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: filePath isDirectory: &isDir] && isDir)
		{
			fileItem = [ETLayoutItemGroup layoutItemWithView: [self imageViewForImage: icon]];
		}
		else
		{
			fileItem = [ETLayoutItem layoutItemWithView: [self imageViewForImage: icon]];
		}
		
		// FIXME: better to have a method -setIdentifier: different from -setName:
		[fileItem setName: [filePath lastPathComponent]];
		[fileItem setValue: [filePath lastPathComponent] forProperty: @"name"];
		[fileItem setValue: filePath forProperty: @"path"];
		[fileItem setValue: icon forProperty: @"icon"];
		[fileItem setValue: [NSNumber numberWithInt: [attributes fileSize]] forProperty: @"size"];
		[fileItem setValue: [attributes fileType] forProperty: @"type"];
		//[fileItem setValue: date forProperty	: @"modificationdate"];
		
		//NSLog(@"Returns %@ as layout item in container %@", fileItem, container);
	}
	else if ([container isEqual: pathContainer]) /* Path Container */
	{
		int flatIndex = [indexPath indexAtPosition: [indexPath length] - 1];
		return [self itemAtIndex: flatIndex inContainer: container];
	}

	return fileItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	return [NSArray arrayWithObjects: @"icon", @"name", @"size", @"type", @"modificationdate", nil];
}

/* Flat protocol used by PathContainer

   NOTE: only present for demonstrating purpose. It could be rewritten as part
   of tree protocol methods implemented above. */

- (int) numberOfItemsInContainer: (ETContainer *)container
{
	if ([container isEqual: viewContainer]) /* Browsing Container */
	{
		NSArray *fileObjects = [objectManager directoryContentsAtPath: path];

		//NSLog(@"Returns %d as number of items in container %@", [fileObjects count], container);
		
		return [fileObjects count];
	}
	else if ([container isEqual: pathContainer]) /* Path Container */
	{
		NSArray *pathComponents = [path pathComponents];

		//NSLog(@"Returns %d as number of items in container %@", [pathComponents count], container);
		
		return [pathComponents count];
	}
	
	return 0;
}

- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container
{
	NSWorkspace *wk = [NSWorkspace sharedWorkspace];
	ETLayoutItem *fileItem = nil;
	
	if ([container isEqual: viewContainer]) /* Browsing Container */
	{
		NSArray *fileObjects = [objectManager directoryContentsAtPath: path];
		NSString *filePath = [path stringByAppendingPathComponent: [fileObjects objectAtIndex: index]];
		NSDictionary *attributes = [objectManager fileAttributesAtPath: filePath traverseLink: NO];
		NSImage *icon = [wk iconForFile: filePath];
		
		fileItem = [ETLayoutItem layoutItemWithView: [self imageViewForImage: icon]];
		
		[fileItem setValue: [filePath lastPathComponent] forProperty: @"name"];
		[fileItem setValue: filePath forProperty: @"path"];
		[fileItem setValue: icon forProperty: @"icon"];
		[fileItem setValue: [NSNumber numberWithInt: [attributes fileSize]] forProperty: @"size"];
		[fileItem setValue: [attributes fileType] forProperty: @"type"];
		//[fileItem setValue: date forProperty	: @"modificationdate"];
		
		//NSLog(@"Returns %@ as layout item in container %@", fileItem, container);
	}
	else if ([container isEqual: pathContainer]) /* Path Container */
	{
		NSArray *pathComponents = [path pathComponents];
		NSString *filePath = @"/";
		NSImage *icon = nil;
		
		for (int i = 0; i < index; i++)
			filePath = [filePath stringByAppendingPathComponent: [pathComponents objectAtIndex: i + 1]];
		
		//NSLog(@"Built path is %@ with components %@", filePath, pathComponents);
		
		icon = [wk iconForFile: filePath];
		fileItem = [ETLayoutItem layoutItemWithView: [self imageViewForImage: icon]];	
		
		[fileItem setValue: [filePath lastPathComponent] forProperty: @"name"];
		[fileItem setValue: filePath forProperty: @"path"];
		
		//NSLog(@"Returns %@ as layout item in container %@", fileItem, container);
	}
	
	return fileItem;
}

@end
