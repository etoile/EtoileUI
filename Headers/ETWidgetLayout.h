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

@protocol ETWidgetLayoutingContext
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;
@end


@interface ETWidgetLayout : ETLayout
{
	@private
	BOOL _isChangingSelection;
}

- (BOOL) isWidget;
- (BOOL) isOpaque;
- (BOOL) hasScrollers;

/* Nib Support */

- (NSString *) nibName;

/* Layout Context & Layout View Synchronization */

- (void) syncLayoutViewWithItem: (ETLayoutItem *)item;
- (void) syncLayoutViewWithTool: (ETTool *)anTool;
- (void) didChangeSelectionInLayoutView;
- (NSArray *) selectionIndexPaths;

/* Actions */

- (ETLayoutItem *) doubleClickedItem;
- (void) doubleClick: (id)sender;

/* Custom Widget Subclass */

- (Class) widgetViewClass;
- (void) upgradeWidgetView: (id)widgetView toClass: (Class)aClass;

@end
