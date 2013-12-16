/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETApplication.h"
#import "ETController.h"
#import "EtoileUIProperties.h"
#import "ETEventProcessor.h"
#import "ETTool.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemBuilder.h"
#import "ETNibOwner.h"
#import "ETPickboard.h"
#import "ETLayoutItemFactory.h"
#import "ETUIStateRestoration.h"
#import "ETUIItemIntegration.h"
#import "ETWidget.h"
#import "ETWindowItem.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

@interface ETApplication (Private)
- (void) _instantiateAppDelegateIfSpecified;
- (void) _buildLayoutItemTree;
- (void) _registerAllAspects;
- (void) _setUpAppMenu;
- (int) _defaultInsertionIndexInAppMenu;
- (void) _buildMainMenuIfNeeded;
- (NSMenu *) _createApplicationMenu;

/* Private Cocoa API */
- (void) setAppleMenu: (NSMenu *)menu;
- (void) setServicesMenu: (NSMenu *)menu;
@end

@implementation ETApplication

/** <override-subclass />
Returns <em>ET</em>.
 
Must be overriden to return the right prefix in subclasses, otherwise the 
application initialization will abort to prevent 
<code>[[ETApp builder] render: ETApp]</code> from returning nil later on.
 
See +[NSObject typePrefix]. */
+ (NSString *) typePrefix
{
	return @"ET";
}

- (id) init
{
	ETAssert([[self className] hasPrefix: [[self class] typePrefix]]);
	SUPERINIT;
	_UIStateRestoration = [ETUIStateRestoration new];
	return self;
}

- (void) dealloc
{
	DESTROY(_nibOwner);
	DESTROY(_UIStateRestoration);
	[super dealloc];
}

- (ETUIStateRestoration *) UIStateRestoration
{
	return _UIStateRestoration;
}

- (void) setDelegate: (id)aDelegate
{
	if ((id)[[self UIStateRestoration] delegate] == (id)[self delegate])
	{
		[[self UIStateRestoration] setDelegate: aDelegate];
	}
	[super setDelegate: aDelegate];
}

/** Returns the application name as visible in the menu bar. */
- (NSString *) name
{
	return [[NSProcessInfo processInfo] processName];
}

/** Returns the application icon from  -applicationIconImage. */
- (NSImage *) icon;
{
	return [self applicationIconImage];
}

/** Returns the layout item representing the application. 

The method returns a local root item which is usually the window group or layer
under the application control. */
- (ETLayoutItemGroup *) layoutItem
{
	return [[ETLayoutItemFactory factory] windowGroup];
}

/** Returns the AppKit to EtoileUI builder that converts AppKit windows, views 
etc. to items at launch time.

Will be used to process the top-level objects of the main Nib and each window 
visible on screen when the launch is finished.

By default, returns an ETEtoileUIBuilder instance. */
- (ETLayoutItemBuilder *) builder
{
	return [ETEtoileUIBuilder builderWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
}

/** Converts the top-level objects of the main Nib into equivalent EtoileUI 
constructs if possible.

For example, views or windows become layout item trees owned by the Nib.

For a window visible at launch time, the top-level item that was built will be 
added to the window group. But otherwise top-level items won't have a parent item.

You can override -builder to customize the conversion. */
- (void) rebuildMainNib
{
	[_nibOwner rebuildTopLevelObjectsWithBuilder: [self builder]];

	FOREACH([_nibOwner topLevelItems], topLevelItem, ETLayoutItem *)
	{
		BOOL isVisibleAtLaunchTime = [[[topLevelItem windowItem] window] isVisible];

		if (isVisibleAtLaunchTime)
		{
			[[self layoutItem] addItem: topLevelItem];
		}
	}
}

- (void) _loadMainNib
{
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *nibName = [infoDict objectForKey: @"NSMainNibFile"];
	BOOL hasNibNameEntry = (nil != nibName && NO == [nibName isEqual: @""]);

	if (NO == hasNibNameEntry)
		return;
	
	_nibOwner = [[ETNibOwner alloc] initWithNibName: nibName
	                                         bundle: [NSBundle mainBundle]
	                             objectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];

	BOOL nibLoadFailed = (NO == [_nibOwner loadNibWithOwner: ETApp]);

	if (nibLoadFailed)
	{
		[NSException raise: NSInternalInconsistencyException 
			format: @"Failed to load main nib named '%@'. The application is " 
			"not usable state and will terminate now.", nibName];
		exit(1);
	}
}

/* Register icons and images bundled with EtoileUI as named images. */
- (void) _registerAdditionalImages
{
	NSBundle *etoileUIBundle = [NSBundle bundleForClass: [self class]]; 
	NSArray *imagePaths = [etoileUIBundle pathsForResourcesOfType: @"png" inDirectory: nil];

	imagePaths = [imagePaths arrayByAddingObjectsFromArray: 
		[etoileUIBundle pathsForResourcesOfType: @"tiff" inDirectory: nil]];

	for (NSString *path in imagePaths)
	{
		NSImage *img = [[NSImage alloc] initWithContentsOfFile: path];
		[img setName: [[path lastPathComponent] stringByDeletingPathExtension]];
	}
}

/** <override-dummy />
Will be called just before -run is invoked.

You must call the superclass implementation if you override this method.

This method is a last chance to prepare the application to be run. You can 
use it to do extra initialization that is required even when -run and 
-finishLaunching are not invoked (e.g. when running the EtoileUI UnitKit test 
suite).<br />
You can safely load nibs on both GNUstep and Cocoa in this method (nib loading 
is not supported in -init and +sharedApplication on Cocoa).

See also -finishLaunching which is called after -run is invoked. */
- (void) setUp
{
	// NOTE: Local autorelease pools are used to locate memory corruption more
	// easily. Memory corruption tend to be located in GNUstep unarchiving code.
	// Various UI aspects involve Gorm/Nib files.
	CREATE_AUTORELEASE_POOL(pool);
	[NSView _setUpEtoileUITraits];
	[self _registerAdditionalImages];
	[self _registerAllAspects];
	//RECREATE_AUTORELEASE_POOL(pool);
	[self _instantiateAppDelegateIfSpecified];
	[self _loadMainNib];
	DESTROY(pool);
}

/* The order of the method calls in this method is critical, be very cautious 
with it.

Unlike Cocoa, GNUstep does not load the main menu from the nib before 
-finishLaunching. That means, if you call -_buildMainMenuIfNeeded before 
-[super finishLaunching] on GNUstep, -mainMenu returns nil and therefore 
-_buildMainMenuIfNeeded wrongly creates a main menu. This doesn't play well with 
the main menu to be loaded from the main gorm/nib file, a warning is logged: 
'Services menu not in main menu!'.<br />
See also -_buildMainMenuIfNeeded. 

-_instantiateAppDelegateIfSpecified must also be called before 
-[super finishLaunching], to ensure the delegate will receive NSApplication 
launching notifications. */
- (void) finishLaunching
{
#ifdef GNUSTEP
	[super finishLaunching];
	[self _buildMainMenuIfNeeded];
	[self _setUpAppMenu];
#else
	[self _buildMainMenuIfNeeded];
	[self _setUpAppMenu];
	[super finishLaunching];
#endif

	/* Must be called last, because it processes the loaded nib and the menu. */
	[self _buildLayoutItemTree];
}

/* If ETPrincipalControllerClass key is present in the bundle info plist, 
tries to instantiate the class with the specified name and sets it as the 
application delegate. The delegate will receive -applicationWillFinishLaunching: 
and any subsequent notifications. 

The main controller is never released. */
- (void) _instantiateAppDelegateIfSpecified
{
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];

	if ([[infoDict allKeys] containsObject: @"ETPrincipalControllerClass"] == NO)
		return;

	NSString *className = [infoDict objectForKey: @"ETPrincipalControllerClass"];
	Class delegateClass = NSClassFromString(className);

	if (delegateClass == Nil)
	{
		ETLog(@"WARNING: ETPrincipalControllerClass named %@ cannot be found",
			className);
		return;
	}
	
	id delegate = [delegateClass alloc];

	if ([delegate respondsToSelector: @selector(initWithObjectGraphContext:)])
	{
		delegate = [delegate initWithObjectGraphContext:
			[ETUIObject defaultTransientObjectGraphContext]];
	}
	else
	{
		delegate = [delegate init];
	}
	[self setDelegate: delegate];
}

/** Generates a single layout item tree for the whole application, by mapping
AppKit components to layout items, if those aren't already owned by a layout
item. If an AppKit component is already driven by a layout item, the layout item
tree connected to it will be attached to the main layout item tree that is
getting generated.

The implementation delegates this process to ETEtoileUIBuilder, which traverses
the window and view hierarchy, in order to ouput a new layout item tree whose
root item will be made available through -[ETApplication layoutItem]. */
- (void) _buildLayoutItemTree
{
	return;
	NSArray *items = [[self builder] render: self];
	ETAssert(items != nil);
	ETLayoutItemGroup *itemGroup = [[ETLayoutItemFactory factory] windowGroup];

	for (ETLayoutItem *item in items)
	{
		if ([itemGroup containsItem: item])
			continue;

		[itemGroup addItem: item];
	}
}

- (NSArray *) aspectBaseClassNames
{
	return A(@"ETLayout", @"ETTool", @"ETStyle", @"ETItemValueTransformer");
}

/* Asks every aspect base class (ETLayout, ETTool, ETStyle etc.) to 
register the aspects it wants to make available to EtoileUI facilities 
(inspector, etc.) that allow to change the UI at runtime. */
- (void) _registerAllAspects
{
	FOREACH([self aspectBaseClassNames], className, NSString *)
	{ 
		[NSClassFromString(className) registerAspects];
	}
	[ETLayoutItemFactory registerAspects];
}

/* If -mainMenu returns nil, builds a new main menu with -_createApplicationMenu
and installs it by calling -setMainMenu:. Also takes care of calling other set
up methods such -setAppleMenu:, which tend to vary with the platform (GNUstep or
Cocoa).

For now, only used on Mac OS X where no main menu exists if no nib is loaded. On
GNUstep, a minimal main menu is always created. */
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

/* Might become a public method later. */
- (NSMenu *) applicationMenu
{
	return [[[self mainMenu] itemAtIndex: 0] submenu];
}

/* Creates a standard application menu by taking in account the expectations
specific to each platform (GNUstep/Etoile and Cocoa). Only supports Mac OS X for
now.

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

- (void) addGeometryOptionsToMenu: (NSMenu *)menu
{
	[menu addItemWithTitle: _(@"Show Frame")
                     state: [ETLayoutItem showsFrame]
                    target: self
	                action: @selector(toggleFrameShown:) 
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Show Bounding Box")
	                 state: [ETLayoutItem showsBoundingBox]
	                target: self
	                action: @selector(toggleBoundingBoxShown:) 
	         keyEquivalent: @""];
}

- (IBAction) changeWindowGroupLayout: (id)sender
{
	Class layoutClass = [sender representedObject];
	COObjectGraphContext *context = [ETUIObject defaultTransientObjectGraphContext];
	ETLayout *layout = [layoutClass layoutWithObjectGraphContext: context];

	[[[ETLayoutItemFactory factory] windowGroup] setLayout: layout];
}

- (NSMenu *) layoutMenuWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector
{
	NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: aTitle]);

	FOREACH([ETLayout registeredLayoutClasses], layoutClass, Class)
	{
		[menu addItemWithTitle: [layoutClass displayName] 
		                target: aTarget 
		                action: aSelector 
		         keyEquivalent: nil];
		[[menu lastItem] setRepresentedObject: layoutClass];
	}

	Class layoutClass = NSClassFromString(@"ETWindowLayout");
	[menu addItemWithTitle: [layoutClass displayName]
		        target: aTarget 
		        action: aSelector 
		 keyEquivalent: nil];
	[[menu lastItem] setRepresentedObject: layoutClass];

	return menu;
}

/** Returns the visible development menu if there is one already inserted in the
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) developmentMenuItem
{
	NSMenuItem *devMenuItem = (id)[[self mainMenu] itemWithTag: ETDevelopmentMenuTag];
	NSMenu *menu = nil;

	if (devMenuItem != nil)
		return devMenuItem;

	devMenuItem = [NSMenuItem menuItemWithTitle: _(@"Development")
	                                        tag: ETDevelopmentMenuTag
	                                     action: NULL];
	menu = [devMenuItem submenu];

	/* Builds and inserts menu items into the new dev menu */

	[menu addItemWithTitle: _(@"Start Editing Window UI") 
	                action: @selector(startEditingKeyWindowUI:)
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Inspect Window Group UI")
	                action: @selector(inspectWindowGroupUI:)
	         keyEquivalent: @""];
	
	[menu addItemWithTitle: _(@"Inspect Window UI")
	                action: @selector(inspectKeyWindowUI:)
	         keyEquivalent: @""];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItemWithTitle: _(@"Inspect UI")
	                action: @selector(inspectItem:)
	         keyEquivalent: @""];
	
	[menu addItemWithTitle: _(@"Inspect Model")
	                action: @selector(inspectModel:)
	         keyEquivalent: @""];
	
	[menu addItemWithTitle: _(@"Inspect Metamodel")
	                action: @selector(inspectMetamodel:)
	         keyEquivalent: @""];
	
	// TODO: Decide if we should rather use a submenu 'Inspect Selection Aspects'
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItemWithTitle: _(@"Inspect Object For UI")
	                action: @selector(inspectModel:)
	         keyEquivalent: @""];
	
	[menu addItemWithTitle:  _(@"Inspect Object For Model")
	                action: @selector(inspectModel:)
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"New Object From Template…") 
	                action: @selector(showUIBuilderAspectRepository:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"New Object From Type…") 
	                action: @selector(showUIBuilderAspectRepository:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"New Package Description…") 
	                action: @selector(newPackageDescription:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Show UI Aspect Repository") 
	                action: @selector(showUIBuilderAspectRepository:)
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Visual Search")
	                action: @selector(showVisualSearchPanel:) 
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	NSMenu *layoutMenu = [self layoutMenuWithTitle: _(@"Window Group Layout") 
	                                        target: self 
	                                        action: @selector(changeWindowGroupLayout:)];

	[menu addItemWithSubmenu: layoutMenu];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Cut Window")
	                action: @selector(cutWindow:) 
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Copy Window")
	                action: @selector(copyWindow:) 
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Paste Window")
	                action: @selector(pasteWindow:) 
	         keyEquivalent: @""];
	
	[menu addItem: [NSMenuItem separatorItem]];

	// TODO: Don't add geometry options if visible in Arrange menu already
	[self addGeometryOptionsToMenu: menu];

	return devMenuItem;
}

/** Returns the visible Document menu if there is one already inserted in the 
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) documentMenuItem
{
	NSMenuItem *menuItem = (id)[[self mainMenu] itemWithTag: ETDocumentMenuTag];

	if (menuItem != nil)
		return menuItem;

	menuItem = [NSMenuItem menuItemWithTitle: _(@"Document")
	                                     tag: ETDocumentMenuTag
	                                  action: NULL];
	NSMenu *menu = [menuItem submenu];

	[menu addItemWithTitle: _(@"New")
	                action: @selector(newDocument:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"New From Template…")
	                action: @selector(newDocumentFromTemplate:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"New Copy")
	                action: @selector(newDocumentCopy:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Open")
	                action: @selector(openDocument:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Open Selection")
	                action: @selector(openSelection:)
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Close")
	                action: @selector(performClose:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Mark Current Version as…")
	                action: @selector(markDocumentVersion:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Revert to…")
	                action: @selector(revertDocumentTo:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Browse History…")
	                action: @selector(browseDocumentHistory:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Export…")
	                action: @selector(exportDocument:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Show Infos")
	                action: @selector(showDocumentInfos:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Page Setup…")
	                action: @selector(runPageLayout:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Print…")
	                action: @selector(print:)
	         keyEquivalent: @""];

	return menuItem;
}

/** Returns the visible Edit menu if there is one already inserted in the 
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) editMenuItem
{
	NSMenuItem *menuItem = (id)[[self mainMenu] itemWithTag: ETEditMenuTag];

	if (menuItem != nil)
		return menuItem;

	menuItem = [NSMenuItem menuItemWithTitle: _(@"Edit")
	                                     tag: ETEditMenuTag
	                                  action: NULL];
	NSMenu *menu = [menuItem submenu];

	[menu addItemWithTitle: _(@"Undo")
	                action: @selector(undo:)
	         keyEquivalent: @"z"];

	[menu addItemWithTitle: _(@"Redo")
	                action: @selector(redo:)
	         keyEquivalent: @"Z"];

	[menu addItemWithTitle: _(@"Show Undo History")
	                action: @selector(browseUndoHistory:)
	         keyEquivalent: @"u"];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Cut")
	                action: @selector(cut:)
	         keyEquivalent: @"x"];

	[menu addItemWithTitle: _(@"Copy")
	                action: @selector(copy:)
	         keyEquivalent: @"c"];

	[menu addItemWithTitle: _(@"Paste")
	                action: @selector(paste:)
	         keyEquivalent: @"v"];

	[menu addItem: [NSMenuItem separatorItem]];

	unichar deleteKey = NSDeleteCharacter;

	[menu addItemWithTitle: _(@"Delete")
	                action: @selector(delete:)
	         keyEquivalent: [NSString stringWithCharacters: &deleteKey length: 1]];

	[menu addItemWithTitle: _(@"Duplicate")
	                action: @selector(duplicate:)
	         keyEquivalent: @"d"];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Select All")
	                action: @selector(selectAll:)
	         keyEquivalent: @"a"];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Special Characters")
	                action: @selector(selectAll:)
	         keyEquivalent: @"t"];
	[[menu lastItem] setKeyEquivalentModifierMask: NSCommandKeyMask | NSAlternateKeyMask];

	return menuItem;
}

/** Returns the visible Insert menu if there is one already inserted in the 
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) insertMenuItem
{
	NSMenuItem *menuItem = (id)[[self mainMenu] itemWithTag: ETInsertMenuTag];

	if (menuItem != nil)
		return menuItem;

	menuItem = [NSMenuItem menuItemWithTitle: _(@"Insert")
	                                     tag: ETInsertMenuTag
	                                  action: NULL];
	NSMenu *menu = [menuItem submenu];

	[menu addItemWithTitle: _(@"Rectangle")
	                action: @selector(insertRectangle:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Image…")
	                action: @selector(insertImage:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Custom Object…")
	                action: @selector(insertCustomObject:)
	         keyEquivalent: @""];

	return menuItem;
}

/** Returns the visible Arrange menu if there is one already inserted in the 
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) arrangeMenuItem
{
	NSMenuItem *menuItem = (id)[[self mainMenu] itemWithTag: ETArrangeMenuTag];

	if (menuItem != nil)
		return menuItem;

	menuItem = [NSMenuItem menuItemWithTitle: _(@"Arrange")
	                                     tag: ETArrangeMenuTag
	                                  action: NULL];
	NSMenu *menu = [menuItem submenu];

	[menu addItemWithTitle: _(@"Bring Forward")
	                action: @selector(bringForward:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Bring To Front")
	                action: @selector(bringToFront:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"Send Backward")
	                action: @selector(sendBackward:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Send To Back")
	                action: @selector(sendToBack:)
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Group")
	                action: @selector(group:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Ungroup")
	                action: @selector(ungroup:)
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	[self addGeometryOptionsToMenu: menu];

	return menuItem;
}

/* AppKit Widget Backend Glue Code

   TODO: Probably to be reworked/reorganized. */

/** Overriden to pass events to ETEventProcessor. */
- (void) sendEvent: (NSEvent *)theEvent
{
// NOTE: Temporary GNUstep-owned code below as reminder...
#ifdef GNUSTEP_SENDEVENT
  NSView *v;
  NSEventType type;

  /*
  If the backend reacts slowly, events (eg. mouse down) might arrive for a
  window that has been ordered out (and thus is logically invisible). We
  need to ignore those events. Otherwise, eg. clicking twice on a button
  that ends a modal session and closes the window with the button might
  cause the button to be pressed twice, which causes Bad Things to happen
  when it tries to stop a modal session twice.

  We let NSAppKitDefined events through since they deal with window ordering.
  */
  if (!_f.visible && [theEvent type] != NSAppKitDefined)
    return;

  if (!_f.cursor_rects_valid)
    {
      [self resetCursorRects];
    }

  type = [theEvent type];
  if ([self ignoresMouseEvents] 
      && GSMouseEventMask == NSEventMaskFromType(type))
    {
      return;
    }
#endif

	BOOL widgetBackendDispatch = ([[ETEventProcessor sharedInstance] processEvent: (void *)theEvent] == NO);
	
	//ETLog(@"Send %@ and pass to widget backend %i", theEvent, widgetBackendDispatch);
		
	if (widgetBackendDispatch)
		[super sendEvent: theEvent];
}

/* When a window is the first key or main responder, it must not be tested as 
target directly. */
- (id) _replacementResponderForFirstResponder: (id)aResponder
{
	if ([aResponder isKindOfClass: [NSWindow class]] && [[aResponder contentView] isSupervisorView])
	{
		return [[aResponder contentView] layoutItem];
	}

	return aResponder;
}

- (id) targetForAction: (SEL)aSelector firstResponder: (id)aResponder isMain: (BOOL)isMainChain
{
	if (aSelector == NULL)
		return nil;

	id responder = [self _replacementResponderForFirstResponder: aResponder];
	SEL twoParamSelector = NSSelectorFromString([NSStringFromSelector(aSelector) 
		stringByAppendingString: @"onItem:"]);

	while (responder != nil)
	{
		if ([responder respondsToSelector: aSelector])
		{
			return responder;
		}

		// NOTE: We don't really need this since ETLayoutItem overrides 
		// -respondsToSelector: to check the action handler exactly we do it below...
		if ([responder isLayoutItem] 
		 && [[(ETLayoutItem *)responder actionHandler] respondsToSelector: twoParamSelector])
		{
			return responder;
		}

		/* When we reach a window whose content item is key, we don't check the 
		   next responders above in the item tree. */
		if (isMainChain == NO && [responder conformsToProtocol: @protocol(ETFirstResponderSharingArea)])
		{
			return nil;
		}

		responder = [responder nextResponder];
	}

	return responder;
}

- (id) targetInResponderChainForAction: (SEL)aSelector from: (id)sender
{
	ETTool *tool = [ETTool activeTool];
	id firstKeyResponder = [tool firstKeyResponder];
	id firstMainResponder = [tool firstMainResponder];
	BOOL keyAndMainIdentical = (firstKeyResponder == firstMainResponder);
	id responder = [self targetForAction: aSelector 
	                      firstResponder: firstKeyResponder 
	                              isMain: keyAndMainIdentical];

	if (responder != nil)
	{
		//ETLog(@"Found key responder %@ for %@", responder, NSStringFromSelector(aSelector));
		return responder;
	}
	
	// FIXME: On GNUstep, we have...
	//if (_session != 0)
    //return nil;

	if (keyAndMainIdentical == NO)
	{
		responder = [self targetForAction: aSelector 
	 	                   firstResponder: firstMainResponder 
		                           isMain: YES];

		if (responder != nil)
		{
			//ETLog(@"Found main responder %@ for %@", responder, NSStringFromSelector(aSelector));
			return responder;
		}
	}

	if ([self respondsToSelector: aSelector])
	{
		return self;
	}

	if ([self delegate] != nil && [[self delegate] respondsToSelector: aSelector])
	{
		return [self delegate];
	}

	/* EtoileUI is not compatible with NSDocument architecture that's why 
	   the next block is disabled. We keep it to remember where 
	   NSDocumentControllercontroller is inserted in the responder chain.

	if ([NSDocumentController isDocumentBasedApplication]
	 && [[NSDocumentController sharedDocumentController] respondsToSelector: aSelector])
    {
		return [NSDocumentController sharedDocumentController];
    } */

	return nil;
}

/** Returns the target in a way similar to -[NSApplication targetForAction:to:from] 
but involves a responder chain which is not exactly the same.

The first key and main responder are retrieved on the active 
tool (see ETTool) rather than on the key and main windows.

If the sender is a layout item, returns nil if the item view is a widget. We 
prevent two actions to be sent at the same time, in case an action is set 
on the item view.*/
- (id) targetForAction: (SEL)aSelector to: (id)aTarget from: (id)sender
{
	if (aSelector == NULL || [[[sender ifResponds] view] isWidget])
		return nil;
	
	if (aTarget == nil)
		return [self targetInResponderChainForAction: aSelector from: sender];

	return ([aTarget respondsToSelector: aSelector] ? aTarget : nil);
}

#ifdef GNUSTEP
// TODO: GNUstep should implement -targetForAction: logic in 
// -targetForAction:to:from: and not the other way around. In Cocoa, 
// -targetForAction: calls -targetForAction:to:from: unlike GNUstep.
- (id) targetForAction: (SEL)aSelector
{
	return [self targetForAction: aSelector to: nil from: nil];
}
#endif

/* Notifies the item that owns the sender (can be itself) that the widget value 
changed, and gives it a chance to propagate it to other parties such as its 
represented object. */
- (void) notifyOwnerItemOfSenderValueChange: (id)sender
{
	if ([sender isView] == NO || [[sender superview] isSupervisorView] == NO)
		return;

	ETLayoutItem *senderItem = [(ETView *)[sender superview] layoutItem];

	/* Decorator items don't respond to -didChangeViewValue: */
	if ([senderItem isLayoutItem] == NO || [sender conformsToProtocol: @protocol(ETWidget)] == NO)
		return;

	if ([[ETEventProcessor sharedInstance] beginContinuousActionsForItem: senderItem])
	{
		ETLog(@" === Begin processing continuous actions == ");
		[senderItem subjectDidBeginEditingForProperty: [senderItem editedProperty]
		                              fieldEditorItem: nil];
	}

	id value = [(id <ETWidget>)sender objectValue];
	[senderItem didChangeViewValue: [(id <ETWidget>)sender currentValueForObjectValue: value]];

	if ([[ETEventProcessor sharedInstance] endContinuousActionsForItem: senderItem])
	{
		[senderItem subjectDidEndEditingForProperty: [senderItem editedProperty]];
		ETLog(@" === End processing continuous actions == ");
	}
}

- (BOOL) sendAction: (SEL)aSelector to: (id)aTarget from: (id)sender
{
	/* Tell owning item about sender value changes to ensure 
	   -subjectDidBeginEditingForProperty:fieldEditorItem: and 
	   -subjectDidEndEditingForProperty: are called, even when the target or the
	   action are nil.
	   -[NSControl sendAction:to:] in GNUstep uses the same trick to propagate 
	   value change for bindings. */
	[self notifyOwnerItemOfSenderValueChange: sender];

	id responder = [self targetForAction: aSelector to: aTarget from: sender];

	if (responder == nil)
		return NO;

	NSMethodSignature *sig = [responder methodSignatureForSelector: aSelector];
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature: sig];
		
	if ([sig numberOfArguments] == 3) /* action: */
	{
		[inv setTarget: responder];
		[inv setSelector: aSelector];
		[inv setArgument: &sender atIndex: 2];
	}
	else if ([sig numberOfArguments] == 4) /* action:onItem: */
	{
		SEL twoParamSelector = NSSelectorFromString([NSStringFromSelector(aSelector) 
			stringByAppendingString: @"onItem:"]);

		[inv setTarget: [responder actionHandler]];
		[inv setSelector: twoParamSelector];
		[inv setArgument: &sender atIndex: 2];
		[inv setArgument: &responder atIndex: 3];
	}

	[inv invoke];

	return YES;
}

/* Actions */

/** Opens a browser on -layoutItem.

See also -[NSObject browse:]. */
- (IBAction) browseLayoutItemTree: (id)sender
{
	// FIXME: Implement
}

/** Disables or enables the frame drawing in the layout item tree.

See also [ ETLayoutItem +setShowsFrame: ].  */
- (IBAction) toggleFrameShown: (id)sender
{
	[ETLayoutItem setShowsFrame: ![ETLayoutItem showsFrame]];
	[sender setState: [ETLayoutItem showsFrame]];
	FOREACH([[self layoutItem] items], item, ETLayoutItem *)
	{
		[item setNeedsDisplay: YES];
	}
}

/** Disables or enables the bounding box drawing in the layout item tree.

See also [ETLayoutItem +setShowsBoundingBox: ]. */
- (IBAction) toggleBoundingBoxShown: (id)sender
{
	[ETLayoutItem setShowsBoundingBox: ![ETLayoutItem showsBoundingBox]];
	[sender setState: [ETLayoutItem showsBoundingBox]];
	FOREACH([[self layoutItem] items], item, ETLayoutItem *)
	{
		[item setNeedsDisplay: YES];
	}
}

/** Hides or shows the special menu that gives access to various EtoileUI 
utilities related to debugging, introspection etc. */
- (IBAction) toggleDevelopmentMenu: (id)sender
{
	NSMenuItem *devMenuItem = (id)[[self mainMenu] 
		itemWithTag: ETDevelopmentMenuTag];

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

- (IBAction) newPackageDescription: (id)sender
{
	[[ETPackageDescription descriptionWithName: @"Untitled"] view: sender];
}

- (IBAction) didChangeVisualSearchString: (id)sender
{
	NSString *searchString = [sender stringValue];
	ETController *controller = [[self layoutItem] controller];

	if  (nil == controller)
	{
		[[self layoutItem] setController: AUTORELEASE([[ETController alloc] init])];
		controller = [[self layoutItem] controller];
	}

	if ([searchString isEqual: @""])
	{
		[controller setFilterPredicate: nil];
	}
	else
	{
		ETLayoutItem *searchItem = [[[self layoutItem] items] 
			firstObjectMatchingValue: @"visualSearch" forKey: kETIdentifierProperty];

		// FIXME: The search panel is not filtered out here because 
		// We should have query object that lets us specify objects/items to 
		// be ignored and pass it to ETLayoutItemGroup rather than the predicate.
		ETLog(@"Visual search item display name %@", [searchItem displayName]);
		[controller setFilterPredicate: [NSPredicate predicateWithFormat: @"displayName contains %@", searchString]];
	}
}

/** Shows a search panel to visually filter the layout item tree recursively.

Any items that don't match the query is hidden until the search is cancelled. */
- (IBAction) showVisualSearchPanel: (id)sender
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItem *searchFieldItem = 
		[itemFactory searchFieldWithTarget: self action: @selector(didChangeVisualSearchString:)];

	[searchFieldItem setIdentifier: @"visualSearch"];
	[searchFieldItem setSize: NSMakeSize(300, 30)];

	[[itemFactory windowGroup] addItem: searchFieldItem];
}

/** Cuts the item corresponding to the current key window.

The cut item is put on the active pickboard. */
- (IBAction) cutWindow: (id)sender
{
	ETLayoutItem *item = [[[ETTool activeTool] keyItem] windowBackedAncestorItem];

	if (nil == item)
		return;

	[[ETPickboard activePickboard] pushObject: item metadata: nil];
	[item removeFromParent];
}

/** Copies the item corresponding to the current key window.

The copied item is put on the active pickboard. */
- (IBAction) copyWindow: (id)sender
{
	ETLayoutItem *item = [[[ETTool activeTool] keyItem] windowBackedAncestorItem];

	if (nil == item)
		return;

	[[ETPickboard activePickboard] pushObject: AUTORELEASE([item deepCopy]) metadata: nil];
}

/** Paste the current item on the active pickbord into the window group.

See -[ETLayoutItemFactory windowGroup]. */
- (IBAction) pasteWindow: (id)sender
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItem *item = [[ETPickboard activePickboard] firstObject];

	if (nil == item)
		return;

	[[itemFactory windowGroup] addItem: AUTORELEASE([item deepCopy])];
}

@end


/** Sets up the Etoile application with the infos provided by the application 
bundle Informations property list, then returns the application object.

First, instatiate the principal class (NSPrincipalClass) which must be 
ETApplication or a subclass. Then loads the main nib/gorm (NSMainNibFile) when 
there is one specified.

When the principal class is invalid or the nib loading fails, this method 
will respectively raise NSInvalidArgumentException or NSInternalInconsistencyException. */
int ETApplicationMain(int argc, const char **argv)
{
	CREATE_AUTORELEASE_POOL(pool);

	NSDictionary *infos = [[NSBundle mainBundle] infoDictionary];
	NSString *appClassName = [infos objectForKey: @"NSPrincipalClass"];
	Class appClass = NSClassFromString(appClassName);

	if (Nil == appClass || NO == [appClass isSubclassOfClass: [ETApplication class]])
	{
		[NSException raise: NSInvalidArgumentException format: @"Principal "
			"class must be ETApplication or a subclass unlike %@ identified by " 
			"'%@' key in the bundle property list", appClass, appClassName];
    }

	id app = [appClass sharedApplication];
 
	[app setUp];
	[app run];

	DESTROY(app);
	DESTROY(pool);

	return 0;
}


@implementation NSMenuItem (Etoile)

/** Returns an autoreleased menu item already associated with an empty submenu. */ 
+ (NSMenuItem *) menuItemWithTitle: (NSString *)aTitle 
                               tag: (int)aTag
                            action: (SEL)anAction
{
	NSMenuItem *menuItem = AUTORELEASE([[NSMenuItem alloc] initWithTitle: aTitle
		action: anAction keyEquivalent: @""]);

	[menuItem setTag: aTag];
	NSMenu *menu = [[NSMenu alloc] initWithTitle: aTitle];
	[menuItem setSubmenu: menu];
	RELEASE(menu);

	return menuItem;
}

@end

@implementation NSMenu (Etoile)

/** Returns the last menu item. */
- (NSMenuItem *) lastItem
{
	return [[self itemArray] lastObject];
}

/** Adds a menu item initialized with the given parameters to the receiver. */ 
- (void) addItemWithTitle: (NSString *)aTitle
                    state: (NSInteger)aState
                   target: (id)aTarget
                   action: (SEL)anAction
            keyEquivalent: (NSString *)aKey
{
	NSMenuItem *menuItem = AUTORELEASE([[NSMenuItem alloc] initWithTitle: aTitle
		action: anAction keyEquivalent: @""]);
	[menuItem setTarget: aTarget];
	[menuItem setState: aState];
	[self addItem: menuItem];
}

/** Adds a menu item initialized with the given parameters to the receiver. */ 
- (void) addItemWithTitle: (NSString *)aTitle
                   target: (id)aTarget
                   action: (SEL)anAction
            keyEquivalent: (NSString *)aKey
{
	[self addItemWithTitle: aTitle 
	                 state: NSOffState 
	                target: aTarget 
	                action: anAction
	         keyEquivalent: aKey];
}

/** Adds a menu item with a submenu to the receiver. 

The submenu title is set as the menu item title. */ 
- (void) addItemWithSubmenu: (NSMenu *)aMenu
{
	NSMenuItem *menuItem = AUTORELEASE([[NSMenuItem alloc] initWithTitle: [aMenu title]
		action: NULL keyEquivalent: @""]);
	[menuItem setSubmenu: aMenu];
	[self addItem: menuItem];
}

@end
