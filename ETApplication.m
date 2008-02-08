/*  <title>ETApplication</title>

	ETApplication.m
	
	<abstract>NSApplication subclass implementing Etoile specific behavior.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
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

#import <EtoileUI/ETApplication.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutItemGroup+Factory.h>
#import <EtoileUI/ETLayoutItemBuilder.h>
#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETCompatibility.h>

@interface ETApplication (Private)
- (void) _buildLayoutItemTree;
- (void) _setUpMenu;
@end


@implementation ETApplication

/** Returns the layout item representing the application. 
	The method returns a local root item which is usually the window group or
	layer under the application control. */
- (ETLayoutItemGroup *) layoutItem
{
	return [ETLayoutItemGroup windowGroup];
}

- (void) finishLaunching
{
	[super finishLaunching];
	[self _setUpMenu];
	[self _buildLayoutItemTree];
}

- (void) _buildLayoutItemTree
{
	ETEtoileUIBuilder *builder = [ETEtoileUIBuilder builder];

	[ETLayoutItemGroup setWindowGroup: [builder render: self]];
}

- (void) _setUpMenu
{
	NSMenu *appMenu = [[[self mainMenu] itemAtIndex: 0] submenu];
	NSMenuItem *menuItem = nil;
	int insertionIndex = 0;
	
	#ifndef GNUSTEP
	insertionIndex = [appMenu indexOfItemWithTitle: _(@"Services")];
	#else
	// FIXME: Decide where Live Development menu item must be put, application
	// menu is probably an valid initial choice. Later Services menu could be better.
	#endif
	
	menuItem = [[NSMenuItem alloc] initWithTitle: _(@"Live Development")
		action: @selector(toggleLiveDevelopment:) keyEquivalent:@""];
	[appMenu insertItem: menuItem atIndex: insertionIndex];
	RELEASE(menuItem);
	
	menuItem = [[NSMenuItem alloc] initWithTitle: _(@"Inspect")
		action: @selector(inspect:) keyEquivalent: @""];
	[appMenu insertItem: menuItem atIndex: ++insertionIndex];
	RELEASE(menuItem);
	
	menuItem = [[NSMenuItem alloc] initWithTitle: _(@"Inspect Selection")
		action: @selector(inspectSelection:) keyEquivalent: @""];
	[appMenu insertItem: menuItem atIndex: ++insertionIndex];
	RELEASE(menuItem);
	
	menuItem = [[NSMenuItem alloc] initWithTitle: _(@"Browse")
		action: @selector(browse:) keyEquivalent: @""];
	[appMenu insertItem: menuItem atIndex: ++insertionIndex];
	RELEASE(menuItem);

	menuItem = [[NSMenuItem alloc] initWithTitle: _(@"Browse Layout Item Tree")
		action: @selector(browseLayoutItemTree:) keyEquivalent: @""];
	[appMenu insertItem: menuItem atIndex: ++insertionIndex];
	RELEASE(menuItem);
}

- (IBAction) browseLayoutItemTree: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init];

	[browser setBrowsedObject: [self layoutItem]];
	[[browser panel] makeKeyAndOrderFront: self];
}

- (IBAction) toggleLiveDevelopment: (id)sender
{
	ETLog(@"Toggle live dev");
}

@end
