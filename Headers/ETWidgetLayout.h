/** <title>ETWidgetLayout</title>

	<abstract>An abstract layout class whose subclasses adapt and wrap complex 
	widgets provided by widget backends such as tree view, popup menu, etc. and 
	turn them into pluggable layouts.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>

@class COObjectGraphContext;

/** Extensions to ETLayoutingContext protocol. */
@protocol ETWidgetLayoutingContext
/** See -[ETLayoutItemGroup itemAtIndexPath:]. */
- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path;
/** See -[ETLayoutItemGroup setSelectionIndexPaths:]. */
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;
/** See -[ETLayoutItemGroup sortWithSortDescriptors:recursively:]. */
- (void) sortWithSortDescriptors: (NSArray *)descriptors recursively: (BOOL)recursively;
@end

/** A layout view can be inserted in a superview bound to a parent item and
yet not be visible.<br />
For example, if an ancestor item of the parent uses an opaque layout, the layout
view can be inserted in the parent view but the parent view (or another ancestor 
superview which owns it) might not be inserted as a subview in the visible view 
hierarchy of the layout item tree. */
@interface ETWidgetLayout : ETLayout
{
	@private
	IBOutlet NSView *layoutView;
	BOOL _isChangingSelection;
}

/** @taskunit Initialization */

+ (Class) layoutClassForLayoutView: (NSView *)layoutView;
- (id) initWithLayoutView: (NSView *)aView
       objectGraphContext: (COObjectGraphContext *)aContext;

/** @taskunit Attribute and Type Querying */

- (BOOL) isWidget;
- (BOOL) isOpaque;
- (BOOL) hasScrollers;

/** @taskunit Nib Support */

- (NSString *) nibName;

/** @taskunit Layout View */

- (void) setLayoutView: (NSView *)aView;
- (NSView *) layoutView;
- (void) setUpLayoutView;
- (void) syncLayoutViewWithItem: (ETLayoutItem *)item;
- (void) syncLayoutViewWithTool: (ETTool *)anTool;

/** @taskunit Selection */

- (void) didChangeSelectionInLayoutView;
- (NSArray *) selectionIndexPaths;

/** @taskunit Actions */

- (ETLayoutItem *) doubleClickedItem;
- (IBAction) doubleClick: (id)sender;

/** @taskunit Custom Widget Subclass */

- (Class) widgetViewClass;
- (void) upgradeWidgetView: (id)widgetView toClass: (Class)aClass;

@end
