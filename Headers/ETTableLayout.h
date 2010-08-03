/** <title>ETTableLayout</title>

	<abstract>A layout class whichs adapts and wraps a list box or table 
	view widget provided by the widget backend.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETWidgetLayout.h>
#import <EtoileUI/ETFragment.h>

/** When a property is editable, a double click triggers the editing even when 
the layout context has a valid double action set.

When the layout is sortable, on a column header click, the content is sorted by 
reusing the sort descriptors set on the base item controller. When a property 
has no sort descriptor with a matching key at the controller level, the sort 
descriptor bound to the widget table column will be used (and eventually created). */
@interface ETTableLayout : ETWidgetLayout
{
	NSMutableDictionary *_propertyColumns;
	NSImage *_dragImage; /* Cached drag image generated before the items are removed */

	@private
	/* The widget event which initiated the drag when there is one underway */
	NSEvent *_backendDragEvent;
	/* The sort descriptors that combine the table view sort descriptors and the 
	   table column sort descriptor prototypes. */
	NSMutableArray *_currentSortDescriptors;
	NSFont *_contentFont;
	BOOL _sortable;
}

- (NSArray *) displayedProperties;
- (void) setDisplayedProperties: (NSArray *)properties;
- (NSString *) displayNameForProperty: (NSString *)property;
- (void) setDisplayName: (NSString *)displayName forProperty: (NSString *)property;
- (BOOL) isEditableForProperty: (NSString *)property;
- (void) setEditable: (BOOL)flag forProperty: (NSString *)property;
- (NSFormatter *) formatterForProperty: (NSString *)property;
- (void) setFormatter: (NSFormatter *)aFormatter forProperty: (NSString *)property;
- (id) styleForProperty: (NSString *)property;
- (void) setStyle: (id)style forProperty: (NSString *)property;
- (id <ETColumnFragment>) columnForProperty: (NSString *)property;

- (void) setSortable: (BOOL)isSortable;
- (BOOL) isSortable;

- (NSFont *) contentFont;
- (void) setContentFont: (NSFont *)aFont;

/* Widget Backend Access */

- (NSArray *) allTableColumns;
- (NSTableView *) tableView;

/* Framework Private & Subclassing */

- (NSTableColumn *) tableColumnWithIdentifierAndCreateIfAbsent: (NSString *)property;
- (NSTableColumn *) createTableColumnWithIdentifier: (NSString *)property;
- (BOOL) canRemoveTableColumn: (NSTableColumn *)aTableColumn;
- (BOOL) prepareTableColumn: (NSTableColumn *)aTableColumn isFirst: (BOOL)isFirstColumn;
- (id) objectValueForTableColumn: (NSTableColumn *)column 
                             row: (int)rowIndex 
                            item: (ETLayoutItem *)item;
- (void) trySortRecursively: (BOOL)recursively oldSortDescriptors: (NSArray *)oldDescriptors;
- (NSEvent *) backendDragEvent;
- (void) setBackendDragEvent: (NSEvent *)event;
- (NSImage *) dragImage;

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
- (NSArray *) visibleTableColumns;
@end
