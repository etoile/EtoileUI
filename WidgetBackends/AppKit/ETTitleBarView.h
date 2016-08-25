/** <title>ETTitleBarView</title>
 
	<abstract>Private class providing the AppKit view for ETTitleBarItem</abstract>
 
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETUIItem;


@interface ETTitleBarView : NSView
{
	@private
    BOOL _highlighted;
}

- (instancetype) initWithFrame: (NSRect)frame;

@property (nonatomic, copy) NSString *titleString;

@property (nonatomic, getter=isExpanded, readonly) BOOL expanded;

@property (nonatomic, assign) id target;
@property (nonatomic) SEL action;

@end