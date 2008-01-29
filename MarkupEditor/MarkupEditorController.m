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
		default:
			NSLog(@"Unsupported layout or unknown popup menu selection");
	}
	
	[self setUpLayoutOfClass: layoutClass];
}

- (void) selectDocumentsPanelDidEnd: (NSOpenPanel *)panel 
	returnCode: (int)returnCode  contextInfo: (void *)contextInfo
{
    NSArray *paths = [panel filenames];
    NSEnumerator *e = [paths objectEnumerator];
    NSString *path = nil;
	NSData *plistData = nil;
	id plist = nil;
	NSString *error = nil;
	NSPropertyListFormat format;
	
	[viewContainer removeAllItems];
	//[viewContainer removeAllObjects];
    
    while ((path = [e nextObject]) != nil)
    {
		plistData = [NSData dataWithContentsOfFile: path];
		plist = [NSPropertyListSerialization propertyListFromData: plistData
			mutabilityOption: kCFPropertyListMutableContainersAndLeaves 
			format: &format errorDescription: &error];
			
		if (error == nil)
		{
			[viewContainer addObject: plist];	
		}
		else
		{
			#if 1
			ETLog(@"Error: %@", error);
			#else
			NSAlert *readingAlert = [NSAlert alertWithError: error];
			int button = [readingAlert runModal];
			#endif
			RELEASE(error);
		}
	}        
	
    //[viewContainer reloadAndUpdateLayout];
    
    /* Flow autolayout manager doesn't take care of trigerring or updating the display. */
    //[viewContainer setNeedsDisplay: YES];  
}

@end
