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

@protocol ETColumnFragment

- (void) setWidth: (NSUInteger)width;
- (NSUInteger) width;
- (void) setMinWidth: (NSUInteger)width;
- (NSUInteger) minWidth; 
- (void) setMaxWidth: (NSUInteger)width;
- (NSUInteger) maxWidth;
- (void) setResizingMask: (NSUInteger)mask;
- (NSUInteger) resizingMask;

@end


@interface ETTableLayout : ETWidgetLayout
{
	NSMutableDictionary *_propertyColumns;
	int _lastChildDropIndex;

	@private
	/* The sort descriptors that combine the table view sort descriptors and the 
	   table column sort descriptor prototypes. */
	NSMutableArray *_currentSortDescriptors;
	NSFont *_contentFont;
	NSEvent *_lastDragEvent;
}

- (NSArray *) displayedProperties;
- (void) setDisplayedProperties: (NSArray *)properties;
- (NSString *) displayNameForProperty: (NSString *)property;
- (void) setDisplayName: (NSString *)displayName forProperty: (NSString *)property;
- (BOOL) isEditableForProperty: (NSString *)property;
- (void) setEditable: (BOOL)flag forProperty: (NSString *)property;
- (id) styleForProperty: (NSString *)property;
- (void) setStyle: (id)style forProperty: (NSString *)property;
- (id <ETColumnFragment>) columnForProperty: (NSString *)property;

- (NSFont *) contentFont;
- (void) setContentFont: (NSFont *)aFont;

/* Widget Backend Access */

- (NSArray *) allTableColumns;
- (void) setAllTableColumns: (NSArray *)columns;
- (NSTableView *) tableView;

/* Subclassing */

- (NSTableColumn *) tableColumnWithIdentifierAndCreateIfAbsent: (NSString *)identifier;
// TODO: Moves this method into an NSTableColumn category
- (NSTableColumn *) _createTableColumnWithIdentifier: (NSString *)property;
- (NSEvent *) lastDragEvent;
- (void) setLastDragEvent: (NSEvent *)event;

@end
