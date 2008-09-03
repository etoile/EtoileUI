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
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETLayoutItemBuilder.h>
#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETCompatibility.h>

#define DEVMENU_TAG 999

@interface ETApplication (Private)
- (void) _buildLayoutItemTree;
- (void) _setUpAppMenu;
- (int) _defaultInsertionIndexInAppMenu;
- (void) _buildMainMenuIfNeeded;
- (NSMenu *) _createApplicationMenu;

/* Private Cocoa API */
- (void) setAppleMenu: (NSMenu *)menu;
- (void) setServicesMenu: (NSMenu *)menu;
@end

@implementation ETApplication

/** Returns the layout item representing the application. 
	The method returns a local root item which is usually the window group or
	layer under the application control. */
- (ETLayoutItemGroup *) layoutItem
{
	return [ETLayoutItem localRootGroup];
}

- (void) finishLaunching
{
	[super finishLaunching];
	[self _buildMainMenuIfNeeded];
	[self _setUpAppMenu];
	[self _buildLayoutItemTree];
}

/** Generates a single layout item tree for the whole application, by mapping 
    AppKit components to layout items, if those aren't already owned by 
	a layout item. If an AppKit component is already driven by a layout item,
	the layout item tree connected to it will be attached to the main layout 
	item tree that is getting generated.
    The implementation delegates this process to ETEtoileUIBuilder, which 
	traverses the window and view hierarchy, in order to ouput a new layout item 
	tree whose root item will be made available through 
	-[ETApplication layoutItem]. */
- (void) _buildLayoutItemTree
{
	ETEtoileUIBuilder *builder = [ETEtoileUIBuilder builder];

	[ETLayoutItemGroup setWindowGroup: [builder render: self]];
}

/* If -mainMenu returns nil, builds a new main menu with -_createApplicationMenu 
   and installs it by calling -setMainMenu:. Also takes care of calling other 
   set up methods such -setAppleMenu:, which tend to vary with the platform 
   (GNUstep or Cocoa). 
   For now, only used on Mac OS X where no main menu exists if no nib is loaded.
   On GNUstep, a minimal main menu is always created. */
- (void) _buildMainMenuIfNeeded
{
	if ([self mainMenu] != nil)
		return;

	// TODO: Eventually support more submenus...
	//
	// NSArray *mainSubmenus = [NSArray arrayWithObjects: [self applicationMenu],
	//       [self editMenu], [self windowMenu], [self helpMenu], nil];
	//[self setMainMenu: [NSMenu menuWithTitle: @"" submenus: mainSubmenus]];

	NSMenuItem *appMenuItem = [[NSMenuItem alloc] initWithTitle: @"" 
		action: NULL keyEquivalent:@""];
	NSMenu *appMenu = [self _createApplicationMenu];
	NSMenu *mainMenu = [[NSMenu alloc] initWithTitle: @""];	

	[appMenuItem setSubmenu: appMenu];
	[mainMenu addItem: appMenuItem];
	RELEASE(appMenuItem);
	
	// NOTE: -setAppleMenu: must be called before calling -setMainMenu: and is 
	// a private Cocoa API that registers the menu as the application menu 
	// (hence the method is wrongly called -setAppleMenu:). Ditto for 
	// -setServicesMenu:
	[self setAppleMenu: appMenu];
	[self setServicesMenu: [[appMenu itemWithTitle: _(@"Services")] submenu]];
	[self setMainMenu: mainMenu];
	RELEASE(mainMenu);
}

/* Creates a standard application menu by taking in account the expectations 
   specific to each platform (GNUstep/Etoile and Cocoa). Only supports Mac OS X 
   for now.
   See also -_buildMainMenuIfNeeded. */
- (NSMenu *) _createApplicationMenu
{
	// TODO: Append the app name to aboutTitle, hideTitle and quitTitle
	NSMenu *appMenu = AUTORELEASE([[NSMenu alloc] initWithTitle: @""]);
	NSString *aboutTitle = _(@"About");
	NSString *hideTitle = _(@"Hide");
	NSString *quitTitle = _(@"Quit");

	[appMenu addItemWithTitle: aboutTitle 
	                   action: @selector(about:) 
				keyEquivalent: @""];
	[appMenu addItemWithTitle: _(@"Preferences...") 
	                   action: NULL 
				keyEquivalent: @","];
				
	[appMenu addItem: [NSMenuItem separatorItem]];
	
	[appMenu addItemWithTitle: _(@"Services") 
					   action: NULL 
				keyEquivalent: @""];
	[[appMenu itemWithTitle: _(@"Services")] 
		setSubmenu: AUTORELEASE([[NSMenu alloc] initWithTitle: @""])];
		
	[appMenu addItem: [NSMenuItem separatorItem]];
	
	[appMenu addItemWithTitle: hideTitle 
	                   action: @selector(hide:) 
				keyEquivalent: @"h"];
	[appMenu addItemWithTitle: _(@"Hide Others") 
	                   action: @selector(hideOtherApplications:) 
				keyEquivalent: @""];
	[appMenu addItemWithTitle: _(@"Show All") 
	                   action: @selector(unhideAllApplications:) 
				keyEquivalent: @""];
				
	[appMenu addItem: [NSMenuItem separatorItem]];
	
	[appMenu addItemWithTitle: quitTitle 
	                   action: @selector(terminate:) 
				keyEquivalent: @"q"];  
   
   return appMenu;
}

- (void) _setUpAppMenu
{
	NSMenu *appMenu = [self applicationMenu];

	[appMenu insertItemWithTitle: _(@"Show Development Menu") 
	                      action: @selector(toggleDevelopmentMenu:) 
	               keyEquivalent: @""
	                     atIndex: [self _defaultInsertionIndexInAppMenu]];
}

- (int) _defaultInsertionIndexInAppMenu
{
	NSMenu *appMenu = [self applicationMenu];
	int insertionIndex = -1; 
	
#ifdef GNUSTEP
	if ([[appMenu menuRepresentation] isHorizontal])
		insertionIndex = [appMenu indexOfItemWithTitle: _(@"Hide")];
#else
	insertionIndex = [appMenu indexOfItemWithTitle: _(@"Services")];
#endif

	/* Fall back and vertical menu case on GNUstep */
	if (insertionIndex == -1)
		insertionIndex = [appMenu numberOfItems];

	return insertionIndex;
}

- (NSMenu *) applicationMenu
{
	return [[[self mainMenu] itemAtIndex: 0] submenu];
}

/** Returns the visible development menu if there is one already inserted in the 
	menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) developmentMenuItem
{
	NSMenuItem *devMenuItem = [[self mainMenu] itemWithTag: DEVMENU_TAG];
	NSMenu *menu = nil;

	if (devMenuItem != nil)
		return devMenuItem;

	devMenuItem = [[NSMenuItem alloc] initWithTitle: _(@"Development")
		action: NULL keyEquivalent:@""];
	[devMenuItem setTag: DEVMENU_TAG];
	menu = [[NSMenu alloc] initWithTitle: _(@"Development")];
	[devMenuItem setSubmenu: menu];
	RELEASE(menu);

	/* Builds and inserts menu items into the new dev menu */

	[menu addItemWithTitle: _(@"Live Development") 
	                action: @selector(toggleLiveDevelopment:) 
	         keyEquivalent:@""];

	[menu addItemWithTitle: _(@"Inspect")
	                action: @selector(inspect:) 
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"Inspect Selection")
	                action: @selector(inspectSelection:) 
	         keyEquivalent: @""];
	
	[menu addItemWithTitle: _(@"Browse")
	                action: @selector(browse:) 
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Browse Layout Item Tree")
	                action: @selector(browseLayoutItemTree:) 
             keyEquivalent: @""];

	return AUTORELEASE(devMenuItem);
}

- (IBAction) browseLayoutItemTree: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init];

	[browser setBrowsedObject: [self layoutItem]];
	[[browser panel] makeKeyAndOrderFront: self];
}

- (IBAction) toggleDevelopmentMenu: (id)sender
{
	NSMenuItem *devMenuItem = [[self mainMenu] itemWithTag: DEVMENU_TAG];

	if (devMenuItem == nil) /* Show dev menu */
	{
		// TODO: Insert before Hide and Quit for vertical menu
		[[self mainMenu] addItem: [self developmentMenuItem]];
		[sender setTitle: _(@"Hide Development Menu")];
	}
	else /* Hide dev menu */
	{
		[[self mainMenu] removeItem: devMenuItem];
		[sender setTitle: _(@"Show Development Menu")];
	}
}

- (IBAction) toggleLiveDevelopment: (id)sender
{
	ETLog(@"Toggle live dev");
}

@end
