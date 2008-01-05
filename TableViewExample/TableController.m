/*
	TableController.m
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2007
 
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

#import "TableController.h"


@implementation TableController

- (id) init
{
	self = [super init];
	
	return self;
}

/** All examples in this code could be rewritten with data source. They just 
	shows very basic use of EtoileUI when you don't want to deal with the extra
	burden involved by a data source. A source should be used when you display:
	either a complex object collection or multiple object collections (like a
	file manager). */
- (void) awakeFromNib
{	
	/*
	 * A container based on table layout
	 */

	[tableContainer setLayout: [ETTableLayout layout]];
	
	[[tableContainer layout] setDisplayedProperties: [NSArray arrayWithObject: @"displayName"]];
	[tableContainer setRepresentedPath: @"/"];
	//[tableContainer setAllowsMultipleSelection: YES];
	
	/* ITEM is a macro. 
	   ITEM(@"Red") is a shortcut for [ETLayoutItem layoutItemWithValue: @"Red"] */
	[tableContainer addItem: ITEM(@"Red")];
	[tableContainer addItem: ITEM(@"Green")];
	[tableContainer addItem: ITEM(@"Blue")];
	[tableContainer addItem: ITEM([NSNumber numberWithInt: 3])];
	/* Value will be image object description */
	//[tableContainer addItem: ITEM([NSImage imageNamed: @"NSApplication"])];
	
	/*
	 * A container using a two columns table layout
	 */
	 
	ETLayoutItem *item = nil;
	ETTableLayout *tableLayout2 = [ETTableLayout layout];
	NSArray *visibleColumnIds = [NSArray arrayWithObjects: @"displayName", @"intensity", nil];
	
	[tableLayout2 setDisplayName: @"Name" forProperty: @"displayName"]; 
	[[[tableLayout2 allTableColumns] objectAtIndex: 0] setWidth: 50];
	[tableLayout2 setDisplayName: @"Intensity" forProperty: @"intensity"]; 	
	[tableLayout2 setStyle: AUTORELEASE([[NSSliderCell alloc] init])
	           forProperty: @"intensity"];
	[tableLayout2 setDisplayedProperties: visibleColumnIds];
	[tableContainer2 setLayout: tableLayout2];
	[tableContainer2 setRepresentedPath: @"/"];
	//[tableContainer2 setAllowsMultipleSelection: YES];
		
	#define NUMBER(x) [NSNumber numberWithInt: x]

	item = [ETLayoutItem layoutItem];
	[item setValue: @"Red" forProperty: @"name"];
	[item setValue: NUMBER(10) forProperty: @"intensity"];	
	[tableContainer2 addItem: item];
	
	item = [ETLayoutItem layoutItem];
	[item setValue: @"Green" forProperty: @"name"];
	[item setValue: NUMBER(100) forProperty: @"intensity"];
	[tableContainer2 addItem: item];

	item = [ETLayoutItem layoutItem];
	[item setValue: @"Blue" forProperty: @"name"];
	[item setValue: NUMBER(0) forProperty: @"intensity"];	
	[tableContainer2 addItem: item];
}

// NOTE: willFinishLaunching must be used instead of didFinishLaunching. 
// Otherwise outlineView will be wrapped into an ETView by ETEtoileUIBuilder 
// invoked in -finishLaunching before we took the opportunity to convert it 
// into an ETContainer instance. In other words, didFinishLaunching works
// but results in a misconfigured layout item tree.
- (void) applicationWillFinishLaunching: (NSNotification *)notif
{
	/*
	 * A hierarchical container using a custom outline layout based on an 
	 * outline view
	 */

	/* The following turns outlineView into a layout and inserts a container 
	   as a subview replacement for outlineView (will become wrapped into it 
	   on -updateLayout call). 
	   You could do it by yourself with the following code:
	   
	   id existingSuperview = [outlineView superview];
	   ETLayout *myTableLayout = [ETOutlineLayout layoutWithLayoutView: outlineView];
	   ETContainer *outlineContainer = [[ETContainer alloc] initWithFrame: [outlineView frame]];
	   
	   if ([existingSuperview isContainer]) // existingSuperview must respond to -layoutItem
	   {
	       [existingSuperview addItem: [outlineContainer layoutItem]];
	   }
	   else // existingSuperview isn't a view-based node in a layout item tree
	   {
	       [existingSuperview replaceSubview: outlineView with: outlineContainer];
	   }
	   
	   [outlineContainer setLayout: myTableLayout]; // inject the initial view as a layout
	   RELEASE(outlineContainer);
	   
	   -initWithLayoutView: is a conveniency method that does it for you.
	*/

	// This method cannot be called in -awakeFromNib because NSNibAwaking 
	// doesn't ensure decoded views are sent -awakeFromNib in a particular or
	// sensible order. For example, outlineView may have no superview set in
	// -awakeFromNib context.
	ETContainer *outlineContainer = [[ETContainer alloc] initWithLayoutView: outlineView];
	NSImage *icon = [NSImage imageNamed: @"NSApplicationIcon"];
	
	[[outlineContainer layout] setStyle: AUTORELEASE([[NSImageCell alloc] init])
	                        forProperty: @""];
	[outlineContainer setRepresentedPath: @"/"]; /* Mandatory to handle drop */
	//[outlineContainer setAllowsMultipleSelection: YES];

	/* This line is optional and simply avoids to update outlineContainer on each
	   -addItem: call */
	[outlineContainer setAutolayout: NO];
	id itemGroup = (id)[ETLayoutItemGroup layoutItemWithValue: icon];

	[itemGroup setValue: @"Icon!" forProperty: @"name"];
	[itemGroup addItem: ITEM(icon)];
	[itemGroup addItem: ITEM(icon)];
	[outlineContainer addItem: itemGroup];
	[outlineContainer addItem: ITEM(icon)];
	
	[outlineContainer setAutolayout: YES];
	[outlineContainer updateLayout];
}

@end
