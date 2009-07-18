/** <title>ETLayer</title>

	<abstract>Layer class models the traditional layer element, very common in 
	Computer Graphics applications.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItemGroup.h>

/** Each layer instance is basically a special node of the layout item tree. */

@interface ETLayer : ETLayoutItemGroup 
{
	//BOOL _visible;
	BOOL _outOfFlow;
}

- (void) setMovesOutOfLayoutFlow: (BOOL)floating;
- (BOOL) movesOutOfLayoutFlow;

/*- (void) setVisible;
- (BOOL) isVisible;*/

@end


@interface ETWindowLayer : ETLayer
{
	ETWindowItem *_rootWindowItem;
	NSMutableArray *_visibleWindows;
}

- (void) hideHardWindows;
- (void) showHardWindows;
- (void) removeWindowDecoratorItems;
- (void) restoreWindowDecoratorItems;

/* Framework Private */

- (NSRect) rootWindowFrame;

@end

/** A window layout based on WM-based windows, or more precisely the windows 
as implemented by the widget backend (NSWindow in AppKit case). 

For now, only applies to the ETWindowLayer instance returned by 
+[ETLayoutItem windowGroup]. */
@interface ETWindowLayout : ETLayout
{

}

@end
