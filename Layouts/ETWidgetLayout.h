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
#import <EtoileUI/ETGraphicsBackend.h>
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
- (instancetype) initWithLayoutView: (NSView *)aView
       objectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

/** @taskunit Attribute and Type Querying */

@property (nonatomic, readonly) BOOL isWidget;
@property (nonatomic, getter=isOpaque, readonly) BOOL opaque;
@property (nonatomic, readonly) BOOL hasScrollers;

/** @taskunit Nib Support */

@property (nonatomic, readonly) NSString *nibName;

/** @taskunit Layout View */

@property (nonatomic, strong) NSView *layoutView;

- (void) setUpLayoutView;
- (void) syncLayoutViewWithItem: (ETLayoutItem *)item;
- (void) syncLayoutViewWithTool: (ETTool *)anTool;

/** @taskunit Selection */

- (void) didChangeSelectionInLayoutView;

@property (nonatomic, readonly) NSArray *selectionIndexPaths;

/** @taskunit Actions */

@property (nonatomic, readonly) ETLayoutItem *doubleClickedItem;

- (IBAction) doubleClick: (id)sender;

@property (nonatomic, readonly, strong) id responder;

/** @taskunit Custom Widget Subclass */

@property (nonatomic, readonly) Class widgetViewClass;

- (void) upgradeWidgetView: (id)widgetView toClass: (Class)aClass;

@end
