/**  <title>ETTitleBarItem</title>

	<abstract>ETDecoratorItem subclass which makes decorates a layout item with
	a title bar, allowing the item to be collapsed (like window shading in some
	window managers).</abstract>

	Copyright (C) 2009 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2009
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETDecoratorItem.h>
#import <EtoileUI/ETTitleBarView.h>

@class ETView, ETUIItem;

/** ETView also offers a customizable title bar. The title bar visibility can
 always be turned on or off. By default, it's turned off. If you are in 
 Live Development mode, most view title bars are usually visible and are 
 tuned for live UI editing with various buttons to switch between available
 edition modes like view, model, object, component etc. By clicking and 
 dragging a title bar in Live Development you can edit your UI layout. 
 Outside of Live Development mode, title bars support collapse and expand
 operations (think of it as window shading at view level) which is useful
 to build complex inspectors or very flexible UI based on disclosable views.
 Title bar support also means an ETContainer embedding ETView instances and 
 using a layout of type ETFreeLayout will give you a built-in window manager.
 Title bar views can be customized at application-level by setting a title
 bar view prototype to be reused by all instances. Instance-by-instance 
 customization is also possible by calling -setTitleBarView:, in this case
 calling +setTitleBarViewPrototype: will never be reflected at instance 
 level until you call -setTitleBarView: nil which resets the title bar to 
 the class-shared prototype.
 */
@interface ETTitleBarItem : ETDecoratorItem
{
	ETTitleBarView *_titleBarView;
	NSView *_contentView;
}

- (id) initWithSupervisorView: (ETView *)supervisorView;
- (id) init;

- (void) tile;

- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (ETView *)decoratedView 
                     inView: (ETView *)parentView;

- (void) handleUndecorateItem: (ETUIItem *)item
               supervisorView: (NSView *)decoratedView 
                       inView: (ETView *)parentView;
- (NSRect) contentRect;
- (void) toggleExpanded: (id)sender;


@end
