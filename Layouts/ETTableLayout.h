/** <title>ETTableLayout</title>

	<abstract>A layout class whichs adapts and wraps a list box or table 
	view widget provided by the widget backend.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
// FIXME: Don't expose NSTableView in the public API.
#import <AppKit/NSOutlineView.h>
#import <EtoileUI/ETWidgetLayout.h>
#import <EtoileUI/ETFragment.h>

/** When a property is editable, a double click triggers the editing even when 
the layout context has a valid double action set.

When the layout is sortable, on a column header click, the content is sorted by 
reusing the sort descriptors set on the controller item controller. When a property 
has no sort descriptor with a matching key at the controller level, the sort 
descriptor bound to the widget table column will be used (and eventually created). */
@interface ETTableLayout : ETWidgetLayout <ETItemPropertyLayout>
{
	NSMutableDictionary *_propertyColumns;
	/* Cached drag image generated before the items are removed */
	NSImage *_dragImage;
	@private
	/* The widget event which initiated the drag when there is one underway */
	NSEvent *_backendDragEvent;
	/* The sort descriptors that combine the table view sort descriptors and the 
	   table column sort descriptor prototypes. */
	NSMutableArray *_currentSortDescriptors;
	NSFont *_contentFont;
	BOOL _sortable;
}

/** @taskunit Item Property Display */

@property (nonatomic, copy) NSArray *displayedProperties;

- (NSString *) displayNameForProperty: (NSString *)property;
- (void) setDisplayName: (NSString *)displayName forProperty: (NSString *)property;
- (BOOL) isEditableForProperty: (NSString *)property;
- (void) setEditable: (BOOL)flag forProperty: (NSString *)property;
- (NSFormatter *) formatterForProperty: (NSString *)property;
- (void) setFormatter: (NSFormatter *)aFormatter forProperty: (NSString *)property;
- (id) styleForProperty: (NSString *)property;
- (void) setStyle: (id)style forProperty: (NSString *)property;
- (id <ETColumnFragment>) columnForProperty: (NSString *)property;

/** @taskunit Sorting */

@property (nonatomic, getter=isSortable) BOOL sortable;

/** @taskunit Fonts */

@property (nonatomic, copy) NSFont *contentFont;

/** @taskunit Widget Backend Access */

@property (nonatomic, readonly) NSArray *allTableColumns;
@property (nonatomic, readonly, strong) NSTableView *tableView;

/** @taskunit Framework Private & Subclassing */

- (NSTableColumn *) tableColumnWithIdentifierAndCreateIfAbsent: (NSString *)property;
- (NSTableColumn *) createTableColumnWithIdentifier: (NSString *)property;
- (BOOL) canRemoveTableColumn: (NSTableColumn *)aTableColumn;
- (BOOL) prepareTableColumn: (NSTableColumn *)aTableColumn isFirst: (BOOL)isFirstColumn;
- (ETLayoutItem *) itemAtRow: (int)rowIndex;
- (id) objectValueForTableColumn: (NSTableColumn *)column 
                             row: (NSInteger)rowIndex 
                            item: (ETLayoutItem *)item;
- (void) setObjectValue: (id)value
         forTableColumn: (NSTableColumn *)column
                   item: (ETLayoutItem *)item;
- (void) trySortRecursively: (BOOL)recursively oldSortDescriptors: (NSArray *)oldDescriptors;

@property (nonatomic, strong) NSEvent *backendDragEvent;
@property (nonatomic, readonly) NSImage *dragImage;

- (NSCell *) preparedCellAtColumn: (NSInteger)column row: (NSInteger)row;

@property (nonatomic, readonly) ETLayoutItem *editedItem;
@property (nonatomic, readonly) NSString *editedProperty;

- (void) controlTextDidEndEditingForItem: (ETLayoutItem *)editedItem
                                property: (NSString *)editedProperty;

@end

/** The class the table views must match to be used with ETTableLayout.

You should not be concerned by this class unless you want to reuse an 
existing NSTableView subclass. In that case, its superclass must be change to 
ETTableView, otherwise an exception will be raised when initializing the layout.

ETTableLayout can automatically upgrade NSTableView to ETTableView.

In future, we hope to eliminate this subclass, but this implies to have 
NSTableView drag and drop support better exposed at the delegate or data source 
level. */
@interface ETTableView : NSTableView
@end


@interface NSTableView (EtoileUI)
@property (nonatomic, readonly, copy) NSArray *visibleTableColumns;
@end
