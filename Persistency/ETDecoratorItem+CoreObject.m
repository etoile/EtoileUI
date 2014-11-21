/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2014
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import "ETDecoratorItem.h"
#import "ETScrollableAreaItem.h"
#import "ETTitleBarItem.h"
#import "ETView.h"
// FIXME: Move related code to the Appkit widget backend (perhaps in a category or subclass)
#import "ETWidgetBackend.h"
#import "ETWindowItem.h"

@interface ETScrollableAreaItem ()
- (NSScrollView *) scrollView;
@end

@interface ETDecoratorItem (CoreObject)
@end

@interface ETScrollableAreaItem (CoreObject)
@end

@interface ETTitleBarItem (CoreObject)
@end

@interface ETWindowItem (CoreObject)
@end


@implementation ETDecoratorItem (CoreObject)

- (void) prepareTransientSupervisorView
{
	if ([self acceptsDecoratorItem: nil] == NO)
		return;

	[self setSupervisorView: AUTORELEASE([ETView new])
	                   sync: ETSyncSupervisorViewFromItem];
}

- (void) willLoadObjectGraph
{
	[super willLoadObjectGraph];

	if ([self decoratedItem] == nil)
		return;

	BOOL acceptsDecorator = [self acceptsDecoratorItem: nil];

	/* Keep the decorated/decorator item connected together but break the 
	   connection between their views */
	[self handleUndecorateItem: [self decoratedItem]
	            supervisorView: [[self decoratedItem] supervisorView]
	                    inView: (acceptsDecorator ? [self displayView] : nil)];
}

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	if ([self decoratedItem] == nil)
		return;

	BOOL acceptsDecorator = [self acceptsDecoratorItem: nil];

	[self handleDecorateItem: [self decoratedItem]
	          supervisorView: [[self decoratedItem] supervisorView]
	                  inView: (acceptsDecorator ? [self displayView] : nil)];
}

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];
	[self prepareTransientSupervisorView];
}

@end


@implementation ETScrollableAreaItem (CoreObject)

- (NSData *) serializedScrollView
{
	return [NSKeyedArchiver archivedDataWithRootObject: [self scrollView]];
}

- (void) setSerializedScrollView: (NSScrollView *)aScrollView
{
	ETAssert(_deserializedScrollView == nil);
	ASSIGN(_deserializedScrollView, aScrollView);
}

- (void) restoreScrollViewFromDeserialization
{
	[[self supervisorView] setWrappedView: _deserializedScrollView];
	DESTROY(_deserializedScrollView);
}

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];

	[self restoreScrollViewFromDeserialization];
	/* Start observing the clip view frame changes */
	[self prepareTransientState];
}

@end


@implementation ETTitleBarItem (CoreObject)

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];
	[self prepareTransientState];
}

@end


@implementation ETWindowItem (CoreObject)

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];
	[self prepareTransientState];
}

@end
