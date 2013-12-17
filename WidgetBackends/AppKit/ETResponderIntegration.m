/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETResponderIntegration.h"
#import "ETUIItemIntegration.h"
#import "NSView+EtoileUI.h"


@implementation  NSResponder (ETResponderSupportAdditions)

- (ETLayoutItem *) candidateFocusedItem
{
	return nil;
}

@end


@implementation  NSView (ETResponderSupportAdditions)

/** Returns the candidate focused item of -owingItem. */
- (ETLayoutItem *) candidateFocusedItem
{
	return [self owningItem];
}

/** <override-dummy />
Returns the item, or a responder subview inside the view.

By default, returns -owingItem but can be overriden to return a custom subview.

See also -[ETLayoutItem responder]. */
- (id) responder
{
	return [self owningItem];
}

@end


@implementation  NSText (ETResponderSupportAdditions)

- (ETLayoutItem *) candidateFocusedItem
{
	if ([self isFieldEditor])
	{
		ETAssert([self delegate] != nil);
	
		/* The delegate is either a view (for a native widget such as a text 
		   field or table view) or an action handler for other editable items 
		   that implements editability using ETActionHandler API. */
		return [(id)[self delegate] candidateFocusedItem];
	}
	return [self candidateFocusedItem];
}

@end


@implementation NSScrollView (ETResponderSupportAdditions)

/** <override-dummy />
Returns the document view inside the scroll view.

See also -[NSView responder]. */
- (id) responder
{
	return [self documentView];
}

@end
