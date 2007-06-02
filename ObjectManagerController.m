//
//  ObjectManagerController.m
//  Container
//
//  Created by Quentin Mathé on 31/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ObjectManagerController.h"
#import "ETLayoutItem.h"
#import "ETStackLayout.h"
#import "ETFlowLayout.h"
#import "ETLineLayout.h"
#import "ETTableLayout.h"
#import "ETContainer.h"
#import "GNUstep.h"


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
	
	[viewContainer setSource: self];
	[viewContainer setTarget: self];
	[viewContainer setDoubleAction: @selector(doubleClickInContainer:)];
	[viewContainer setLayout: AUTORELEASE([[ETStackLayout alloc] init])];
	
	[pathContainer setSource: self];
	[pathContainer setTarget: self];
	[pathContainer setDoubleAction: @selector(doubleClickInContainer:)];
}

- (void) viewContainerDidResize: (NSNotification *)notif
{
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
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	[viewContainer setLayout: (ETViewLayout *)AUTORELEASE([[layoutClass alloc] init])];
}

- (IBAction) switchUsesSource: (id)sender
{
	if ([sender boolValue])
	{
		[viewContainer setSource: self];
	}
	else
	{
		[viewContainer setSource: nil];
	}
	
	[viewContainer updateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    [viewContainer setNeedsDisplay: YES];  
}

- (IBAction) switchUsesScrollView: (id)sender
{

}

- (IBAction) scale: (id)sender
{

}

- (void) doubleClickInContainer: (id)sender
{
	ETLayoutItem *item = [sender doubleClickedItem];
	NSString *newPath = [item valueForProperty: @"path"];
	
	NSLog(@"Moving from path %@ to %@", path, newPath);
	ASSIGN(path, newPath);
	
	[viewContainer updateLayout];
	[pathContainer updateLayout];
}

- (NSImageView *) imageViewForImage: (NSImage *)image
{
	if (image != nil)
    {
        NSImageView *view = [[NSImageView alloc] 
            initWithFrame: NSMakeRect(0, 0, [image size].width, [image size].height)];
        
        [view setImage: image];
		return (NSImageView *)AUTORELEASE(view);
    }

    return nil;
}

/* ETContainerSource informal protocol */

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

		NSLog(@"Returns %d as number of items in container %@", [pathComponents count], container);
		
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
		//[fileItem setValue: [wk iconForFile: [image name]] forProperty: @"icon"];
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
		
		NSLog(@"Built path is %@ with components %@", filePath, pathComponents);
		
		icon = [wk iconForFile: filePath];
		fileItem = [ETLayoutItem layoutItemWithView: [self imageViewForImage: icon]];	
		
		[fileItem setValue: [filePath lastPathComponent] forProperty: @"name"];
		[fileItem setValue: filePath forProperty: @"path"];
		
		NSLog(@"Returns %@ as layout item in container %@", fileItem, container);
	}
	
	return fileItem;
}

- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container
{
	return [NSArray arrayWithObjects: @"name", @"size", @"type", @"modificationdate", nil];
}

@end
