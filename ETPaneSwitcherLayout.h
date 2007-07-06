//
//  ETPaneSwitcherLayout.h
//  Container
//
//  Created by Quentin Mathé on 07/06/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETViewLayout.h"


// ETSwitcherLayout may be a better name?
/** Not a subclass of ETPaneLayout since we can use other layout to display 
	panes than ETPaneLayout. For example, we can display panes inline by 
	setting content layout to ETLineLayout. */
@interface ETPaneSwitcherLayout : ETViewLayout
{
	/* Children layouts */
	//ETViewLayout *_switcherLayout;
	//ETViewLayout *_contentLayout;
	/* Internal layout acting on containers of previous layouts, mostly depends
	   of switcher position */
	ETViewLayout *_internalLayout;
	ETContainer *_internalContainer;
	/* Facility ivars redundant with _internalContainer */
	ETLayoutItem *_switcherItem;
	ETLayoutItem *_contentItem;
}

- (ETViewLayout *) switcherLayout;
- (void) setSwitcherLayout: (ETViewLayout *)layout;
- (ETContainer *) switcherContainer;
- (void) setSwitcherContainer: (ETContainer *)container;

/** By default the content layout is of style pane layout. */
- (ETViewLayout *) contentLayout;
- (void) setContentLayout: (ETViewLayout *)layout;
- (ETContainer *) contentContainer;
- (void) setContentContainer: (ETContainer *)container;

- (void ) resetSwitcherContainer;
- (void ) resetContentContainer;

- (int) switcherPosition;
- (void) setSwitcherPosition: (int)position;

// Adds an accessor to control item view size always adjusted to content size (or content container size)

@end

@interface NSObject (ETPaneSwitcherLayoutDelegate)
//- (void) willPositionSwitcher inContainer:
@end