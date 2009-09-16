/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#import "MarkupEditorController.h"


@implementation MarkupEditorController

- (void) dealloc
{
	//DESTROY(documentPath);
	
	[super dealloc];
}

- (void) awakeFromNib
{
    /*NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self 
           selector: @selector(viewContainerDidResize:) 
               name: NSViewFrameDidChangeNotification 
             object: viewContainer];*/
	
	[viewContainer setAllowsMultipleSelection: YES];
	[viewContainer setAllowsEmptySelection: YES];
	[viewContainer setSource: [viewContainer layoutItem]];
	[self setUpLayoutOfClass: [ETOutlineLayout class]];
	[viewContainer setHasVerticalScroller: YES];
	[viewContainer setHasHorizontalScroller: YES];
	
	[[ETPickboard localPickboard] showPickPalette];
}

- (void) setUpLayoutOfClass: (Class)layoutClass
{
	id layoutObject = AUTORELEASE([[layoutClass alloc] init]);
		
	[viewContainer setLayout: layoutObject];
	
	if ([layoutObject isKindOfClass: [ETTableLayout class]])
	{
		[layoutObject setDisplayName: @"Property List" forProperty: @"identifier"];
		[layoutObject setDisplayName: @"Type" forProperty: @"className"];
		[layoutObject setDisplayName: @"Value" forProperty: @"stringValue"];
		[layoutObject setDisplayName: @"Name" forProperty: @"displayName"];
		[layoutObject setDisplayName: @"Description" forProperty: @"description"];
		[layoutObject setDisplayedProperties: [NSArray arrayWithObjects: 
			@"className", @"stringValue", @"description", @"displayName", nil]];
	}

	[viewContainer setLayout: layoutObject];
}

- (void) viewContainerDidResize: (NSNotification *)notif
{
    [viewContainer updateLayout];
}

- (IBAction) openDocument:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    
    [op setAllowsMultipleSelection: YES];
    [op setCanCreateDirectories: YES];
    //[op setAllowedFileTypes: nil];
    
    [op beginSheetForDirectory: nil file: nil types: nil 
                modalForWindow: [viewContainer window] 
                 modalDelegate: self 
                didEndSelector: @selector(selectDocumentsPanelDidEnd:returnCode:contextInfo:)
                   contextInfo: nil];
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = nil;
	
	switch ([[sender selectedItem] tag])
	{
		case 0:
			layoutClass = [ETColumnLayout class];
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
		case 6:
			layoutClass = [ETTextEditorLayout class];
			break;
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	[self setUpLayoutOfClass: layoutClass];
}

- (void) handleError: (id)error
{
	if (error == nil)
		return;

	#if 1
	ETLog(@"Error: %@", error);
	#else
	NSAlert *readingAlert = [NSAlert alertWithError: error];
	int button = [readingAlert runModal];
	#endif
	RELEASE(error);
}

- (id) plistNodeFromURL: (NSURL *)URL
{
	NSData *plistData = nil;
	id plistNode = nil;
	NSString *error = nil;
	NSPropertyListFormat format;
    
	plistData = [NSData dataWithContentsOfURL: URL];
	plistNode = [NSPropertyListSerialization propertyListFromData: plistData
		mutabilityOption: kCFPropertyListMutableContainersAndLeaves 
		format: &format errorDescription: &error];
	[self handleError: error]; /* Take care of releasing error object */
	
	return plistNode;
}

- (id) xmlNodeFromURL: (NSURL *)URL
{
	id xmlNode = nil;
	NSError *error = nil;

	xmlNode = [[NSXMLDocument alloc] 
		initWithContentsOfURL: URL options: NSXMLDocumentTidyXML error: &error];
	[self handleError: error]; /* Take care of releasing error object */
	
	return AUTORELEASE(xmlNode);
}

- (void) selectDocumentsPanelDidEnd: (NSOpenPanel *)panel 
	returnCode: (int)returnCode  contextInfo: (void *)contextInfo
{
    NSArray *URLs = [panel URLs];
    NSEnumerator *e = [URLs objectEnumerator];
    NSURL *URL = nil;
	id markupNode = nil;

	[viewContainer removeAllItems];
	//[viewContainer removeAllObjects];
    
    while ((URL = [e nextObject]) != nil)
    {
		if ([[[URL path] pathExtension] isEqual: @"plist"])
		{
			markupNode = [self plistNodeFromURL: URL];
		}
		else
		{
			markupNode = [self xmlNodeFromURL: URL];	
		}
			
		[[viewContainer layoutItem] addObject: markupNode];	
	}        
	
    //[viewContainer reloadAndUpdateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    //[viewContainer setNeedsDisplay: YES];  
}

@end

#ifndef GNUSTEP

@interface NSXMLNode (ETCollection) <ETCollection>
- (BOOL) isOrdered;
- (BOOL) isEmpty;
- (id) content;
- (NSArray *) contentArray;
- (unsigned int) count;
@end

@interface NSXMLElement (ETCollectionMutation) <ETCollectionMutation>
- (void) addObject: (id)object;
- (void) insertObject: (id)object atIndex: (unsigned int)index;
- (void) removeObject: (id)object;
@end

@implementation NSXMLNode (ETCollection)

- (BOOL) isOrdered { return YES; }

- (BOOL) isEmpty { return ([self count] == 0); }

- (id) content { return [self children]; }

- (NSArray *) contentArray { return [self content]; }

- (unsigned int) count { return [self childCount]; }

@end

@implementation NSXMLElement (ETCollectionMutation)

- (void) addObject: (id)object 
{ 
	[self addChild: object];
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{ 
	[self insertChild: object atIndex: index];
}

- (void) removeObject: (id)object
{
	/* Next line is similar to [(NSXMLNode *)object detach] */
	[self removeChildAtIndex: [(NSXMLNode *)object index]];
}

@end

#endif
