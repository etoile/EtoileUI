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
#import <EtoileFoundation/ETTransform.h>

@class ETLayoutItem, ETLayout, ETLayoutItemFactory;

/** By inheriting from ETFilter, ETTransform instances can be chained together 
in a filter/transform unit. For example, you can combine several tree builder 
into a new builder to implement a new transform. */
@interface ETLayoutItemBuilder : ETTransform
{
	ETLayoutItemFactory *itemFactory;
}

+ (id) builder;

@end


/** Generates a layout item tree from an AppKit-based application. */
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
- (id) renderWidgetLayoutView: (id)aView;
- (id) renderMenu: (NSMenu *)menu;

@end
