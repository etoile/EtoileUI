/** <title>ETLayoutItemBuilder</title>

	<abstract>Builder classes that can render document formats or object graphs
	into a layout item tree.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class COObjectGraphContext;
@class ETLayoutItem, ETLayout, ETLayoutItemFactory;

@interface ETLayoutItemBuilder : NSObject
{
	ETLayoutItemFactory *itemFactory;
}

+ (id) builderWithObjectGraphContext: (COObjectGraphContext *)aContext;

- (id) render: (id)anObject;

@end


/** Generates a layout item tree from an AppKit-based application.

For now, NSTabView and NSSplitView are rendered into a ETLayoutItem with a view, 
and not into a layout when -allowsWidgetLayout returns YES. */
@interface ETEtoileUIBuilder: ETLayoutItemBuilder
{
	@private
	BOOL _allowsWidgetLayout;
}

- (BOOL) allowsWidgetLayout;
- (void) setAllowsWidgetLayout: (BOOL)allowed;

- (id) renderApplication: (NSApplication *)app;
- (id) renderPasteboards: (NSArray *)pasteboards;
- (id) renderPasteboard: (NSPasteboard *)pasteboard;
- (id) renderWindows: (NSArray *)windows;
- (id) renderWindow: (NSWindow *)window;
- (id) renderView: (id)view;
- (id) renderWidgetLayoutView: (NSView *)aView;
- (id) renderMenu: (NSMenu *)menu;

@end
