/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETApplication.h"
#import "ETEventProcessor.h"
#import "ETTool.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem+Factory.h"
#import "ETLayoutItemBuilder.h"
#import "ETNibOwner.h"
#import "ETObjectBrowserLayout.h"
#import "ETLayoutItemFactory.h"
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

- (void) dealloc
{
	DESTROY(_nibOwner);
	[super dealloc];
}

/** Returns the layout item representing the application. 

The method returns a local root item which is usually the window group or layer
under the application control. */
- (ETLayoutItemGroup *) layoutItem
{
	return [ETLayoutItem localRootGroup];
}

/** Returns the AppKit to EtoileUI builder that converts AppKit windows, views 
etc. to items at launch time.

Will be used to process the top-level objects of the main Nib and each window 
visible on screen when the launch is finished.

By default, returns an ETEtoileUIBuilder instance. */
- (ETLayoutItemBuilder *) builder
{
	return [ETEtoileUIBuilder builder];
}

/** Converts the top-level objects of the main Nib into equivalent EtoileUI 
constructs if possible.

For example, views or windows become layout item trees owned by the Nib.

You can override -builder to customize the conversion. */
- (void) rebuildMainNib
{
	[_nibOwner rebuildTopLevelObjectsWithBuilder: [self builder]];
}

- (void) _loadMainNib
{
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *nibName = [infoDict objectForKey: @"NSMainNibFile"];
	BOOL hasNibNameEntry = (nil != nibName && NO == [nibName isEqual: @""]);

	if (NO == hasNibNameEntry)
		return;
	
	_nibOwner = [[ETNibOwner alloc] initWithNibName: nibName bundle: [NSBundle mainBundle]];

	BOOL nibLoadFailed = (NO == [_nibOwner loadNibWithOwner: ETApp]);

	if (nibLoadFailed)
	{
		[NSException raise: NSInternalInconsistencyException 
			format: @"Failed to load main nib named '%@'. The application is " 
			"not usable state and will terminate now.", nibName];
		exit(1);
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
	[self _registerAllAspects];
	DESTROY(pool);
	RECREATE_AUTORELEASE_POOL(pool);
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

	[self setDelegate: [[delegateClass alloc] init]];
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
	ETEtoileUIBuilder *builder = [ETEtoileUIBuilder builder];

	[ETLayoutItemGroup setWindowGroup: [builder render: self]];
}

- (NSArray *) aspectBaseClassNames
{
	return A(@"ETLayout", @"ETTool", @"ETStyle");
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

- (NSMenu *) applicationMenu
{
	return [[[self mainMenu] itemAtIndex: 0] submenu];
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

	[menu addItemWithTitle: _(@"Live Development") 
	                action: @selector(toggleLiveDevelopment:) 
	         keyEquivalent:@""];

	[menu addItemWithTitle: _(@"Inspect Item")
	                action: @selector(inspectItem:) 
	         keyEquivalent: @""];

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

	[menu addItem: [NSMenuItem separatorItem]];

	[self addGeometryOptionsToMenu: menu];

	return devMenuItem;
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
target directly, but indirectly through its content item where it will be 
present upstream in the next responder chain. */
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

		responder = [responder nextResponder];
	}

	return responder;
}

/** Returns the target in a way similar to -[NSApplication targetForAction:to:from] 
but involves a responder chain which is not exactly the same.

The first key and main responder are retrieved on the active 
tool (see ETTool) rather than on the key and main windows.

The responder chain is extended to include ETPersistencyController right after
the application delegate when CoreObject is available. */
- (id) targetForAction: (SEL)aSelector to: (id)aTarget from: (id)sender
{
	if (aSelector == NULL)
		return nil;
	
	if ([aTarget respondsToSelector: aSelector])
		return aTarget;

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

	ETLayoutItemGroup *windowGroup = [[ETLayoutItemFactory factory] windowGroup];
	responder = [self targetForAction: aSelector 
	                   firstResponder: windowGroup
	                           isMain: YES];

	if (responder != nil)
	{
		//ETLog(@"Found responder %@ for %@", responder, NSStringFromSelector(aSelector));
		return responder;
	}

	/* In the long run, we might want to make things simpler and only rely on 
	   -nextResponder to model the responder chain. This would eliminate the 
	   code below. 
	   The hardcoded responder chain below is present to ensure a better 
	   compatibility with existing GNUstep/Cocoa code.
	   We already have controllers in the responder chain, that's why a pure 
	   EtoileUI responder chain would probably skip the app and window delegates.
	 
	   widget window -> window group -> window group controller -> app object -> persistency controller 
	
	   Both the persistency controller and the window group controller could be 
	   used as document manager in a document editor. To make the overall 
	   architecture even simpler, we could remove ETPersistencyController as 
	   the last responder, turn it into an ETController subclass and set it as 
	   the window group controller. Object Managers and Document Editor might 
	   have needs that vary a bit in term of CoreObject integration, so we 
	   could provide specialized ETPersistencyController subclasses (but 
	   ETPersistencyController might support well enough with a richer API). 
	   The managed documents can be any node in the layout item tree and not 
	   just the nodes owned by the window group (as in NSDocument architecture).
	   ETPersistencyController was initially positioned upstream to mimic 
	   NSDocumentManager and as a way to prevent the framework user to draw any 
	   assumption on where the documents are located in the layout item tree. */

	if ([self respondsToSelector: aSelector])
	{
		return self;
	}

	id delegate = [self delegate];
	if (delegate != nil && [delegate respondsToSelector: aSelector])
	{
		return delegate;
	}

	/* EtoileUI is not compatible with NSDocument architecture that's why 
	   the next block is disabled. We keep it to remember where 
	   NSDocumentControllercontroller is inserted in the responder chain.

	if ([NSDocumentController isDocumentBasedApplication]
	 && [[NSDocumentController sharedDocumentController] respondsToSelector: aSelector])
    {
		return [NSDocumentController sharedDocumentController];
    } */

	Class persistencyControllerClass = NSClassFromString(@"ETPersistencyController");
	if ([[persistencyControllerClass sharedInstance] respondsToSelector: aSelector])
	{
		return [persistencyControllerClass sharedInstance]; 
	}

	return nil;
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
	if ([senderItem isLayoutItem] == NO)
		return;

	if ([sender respondsToSelector: @selector(objectValue)])
	{
		[senderItem didChangeViewValue: [sender objectValue]];
	}
}

- (BOOL) sendAction: (SEL)aSelector to: (id)aTarget from: (id)sender
{
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
	[self notifyOwnerItemOfSenderValueChange: sender];

	return YES;
}

/* Actions */

- (IBAction) browseLayoutItemTree: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init];

	[browser setBrowsedObject: [self layoutItem]];
	[[browser panel] makeKeyAndOrderFront: self];
}

- (IBAction) toggleFrameShown: (id)sender
{
	[ETLayoutItem setShowsFrame: ![ETLayoutItem showsFrame]];
	[sender setState: [ETLayoutItem showsFrame]];
	FOREACH([[self layoutItem] items], item, ETLayoutItem *)
	{
		[item setNeedsDisplay: YES];
	}
}

- (IBAction) toggleBoundingBoxShown: (id)sender
{
	[ETLayoutItem setShowsBoundingBox: ![ETLayoutItem showsBoundingBox]];
	[sender setState: [ETLayoutItem showsBoundingBox]];
	FOREACH([[self layoutItem] items], item, ETLayoutItem *)
	{
		[item setNeedsDisplay: YES];
	}
}

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

- (IBAction) toggleLiveDevelopment: (id)sender
{
	ETLog(@"Toggle live dev");
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
