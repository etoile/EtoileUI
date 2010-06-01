/** <title>ETTitleBarView</title>
 
	<abstract>Private class providing the AppKit view for ETTitleBarItem</abstract>
 
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETView.h>

@class ETLayoutItem, ETUIItem;


@interface ETTitleBarView : NSView
{
	@private
	id _target;
	SEL _action;
}

- (id) initWithFrame: (NSRect)frame;

- (void) setTitleString: (NSString *)title;
- (NSString *) titleString;

- (BOOL) isExpanded;

- (void) setTarget: (id)target;
- (id) target;
- (void) setAction: (SEL)action;
- (SEL) action;

@end