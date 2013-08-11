/** <title>ETApplication</title>

	<abstract>NSApplication subclass implementing Etoile specific behavior.</abstract>

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItemBuilder, ETLayoutItemGroup, ETNibOwner, ETUIStateRestoration;

#define ETApp (ETApplication *)[ETApplication sharedApplication]

/** If you use a custom NSApplication subclass, you must subclass ETApplication 
instead of NSApplication to make it Etoile-native.

This subclass installs the event handling model of EtoileUI. This model 
involves both a custom event and action dispatch that takes over the AppKit 
one.

ETApplication also provides various actions and menus to better support 
live development support at runtime. 

If ETPrincipalControllerClass key is present in the info plist of your 
application bundle, the specified class will be instantiated at launch time and 
sets as the application delegate. As an NSApplication-subclass delegate, it will 
receive -applicationWillFinishLaunching: and any subsequent notifications. This 
is available as a simple conveniency, when you don't want to rely on a main nib 
file or write a custom main() function.<br />
For initializing the principal controller, ETApplication tries to use 
-initWithObjectGraphContext: and +[ETUIObject defaultTransientObjectGraphContext], 
or -init if the former initializer is not supported.

ETApplication manages the main Nib top-level objects and will release them when 
the application is terminated.

To render the AppKit view hierarchy packaged in the main Nib into a layout item 
tree, you can implement -applicationDidFinishLaunching: in the Application's 
delegate and invoke -rebuildMainNib here. For a concrete example, see 
PhotoViewExample and ObjectManagerExample.<br />
Don't use -applicationWillFinishLaunching or -awakeFromNib, otherwise the view 
hierarchy won't be in a valid state because -awakeFromNib won't have been sent 
to all the objects in the Nib.<br />
For other Nibs to be loaded, see ETNibOwner. */
@interface ETApplication : NSApplication 
{
	@private
	ETNibOwner *_nibOwner;
	ETUIStateRestoration *_UIStateRestoration;
	BOOL _wasProcessingContinuousActionEvents;
}

+ (NSString *) typePrefix;

/** @taskunit UI State Restoration */

- (ETUIStateRestoration *) UIStateRestoration;

- (NSString *) name;
- (NSImage *) icon;

- (ETLayoutItemGroup *) layoutItem;
- (ETLayoutItemBuilder *) builder;
- (void) rebuildMainNib;

- (void) setUp;

/* Menu Factory */

- (NSMenuItem *) developmentMenuItem;
- (NSMenuItem *) documentMenuItem;
- (NSMenuItem *) editMenuItem;
- (NSMenuItem *) insertMenuItem;
- (NSMenuItem *) arrangeMenuItem;

/* Actions */

- (id) targetForAction: (SEL)aSelector to: (id)aTarget from: (id)sender;
- (IBAction) browseLayoutItemTree: (id)sender;
- (IBAction) toggleFrameShown: (id)sender;
- (IBAction) toggleBoundingBoxShown: (id)sender;
- (IBAction) toggleDevelopmentMenu: (id)sender;
- (IBAction) showVisualSearchPanel: (id)sender;

@end


int ETApplicationMain(int argc, const char **argv);

/** Informal protocol to register related aspects (e.g. every layout). */
@interface NSObject (ETAspectRegistration)
/** Can be implemented by an aspect base class to trigger the automatic 
registration of its aspect prototypes at the application launch time.

e.g. ETLayout will register ETTableLayout, ETIconLayout instances etc. */
- (void) registerAspects;
@end

/** Informal protocol to implement menu actions, usually in the topmost controller. */
@interface NSObject (ETStandardMenuActions)
/** Can be implemented to show a history browser opened on the main undo track.

See -[ETLayoutItemFactory historyBrowserWithRepresentedObject:] and COTrack in 
CoreObject. */
- (IBAction) browseUndoHistory: (id)sender;
@end

enum 
{
	ETDevelopmentMenuTag = 30000,
	ETDocumentMenuTag,
	ETObjectMenuTag, /* Used in Object Managers */
	ETEditMenuTag,
	ETInsertMenuTag,
	ETArrangeMenuTag, 
};

/** NSMenuItem conveniency additions. */
@interface NSMenuItem (Etoile)
+ (NSMenuItem *) menuItemWithTitle: (NSString *)aTitle 
                               tag: (int)aTag
                            action: (SEL)anAction;
@end

/** NSMenu conveniency additions. */
@interface NSMenu (Etoile)
- (NSMenuItem *) lastItem;
- (void) addItemWithTitle: (NSString *)aTitle
                    state: (NSInteger)aState
                   target: (id)aTarget
                   action: (SEL)anAction
            keyEquivalent: (NSString *)aKey;
- (void) addItemWithTitle: (NSString *)aTitle
                   target: (id)aTarget
                   action: (SEL)anAction
            keyEquivalent: (NSString *)aKey;
- (void) addItemWithSubmenu: (NSMenu *)aMenu;
@end
