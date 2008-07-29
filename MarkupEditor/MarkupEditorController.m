/*
	MarkupEditorController.m
	
	An extensible markup editor mainly supporting PLIST and XML.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
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
			
		[viewContainer addObject: markupNode];	
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
