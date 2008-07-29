/*
	ETPaneSwitcherLayout.h

	Description forthcoming.

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>

typedef enum {
	ETPaneSwitcherPositionNone,
	ETPaneSwitcherPositionTop,
	ETPaneSwitcherPositionBottom,
	ETPaneSwitcherPositionLeft,
	ETPaneSwitcherPositionRight
} ETPaneSwitcherPosition;



// ETSwitcherLayout may be a better name?
// Probably going to rename this class ETTwoPaneLayout and introduces ETThreePaneLayout class thereafter
/** Not a subclass of ETPaneLayout since we can use other layout to display 
	panes than ETPaneLayout. For example, we can display panes inline by 
	setting content layout to ETLineLayout. */
@interface ETPaneSwitcherLayout : ETLayout
{
	/* Children layouts */
	//ETLayout *_switcherLayout;
	//ETLayout *_contentLayout;
	/* Internal layout acting on containers of previous layouts, mostly depends
	   of switcher position */
	ETLayout *_internalLayout;
	ETContainer *_internalContainer;
	/* Facility ivars redundant with _internalContainer */
	ETLayoutItem *_switcherItem;
	ETLayoutItem *_contentItem;
	
	ETPaneSwitcherPosition _switcherPosition;
}

- (ETLayout *) switcherLayout;
- (void) setSwitcherLayout: (ETLayout *)layout;
- (ETContainer *) switcherContainer;
- (void) setSwitcherContainer: (ETContainer *)container;

/** By default the content layout is of style pane layout. */
- (ETLayout *) contentLayout;
- (void) setContentLayout: (ETLayout *)layout;
- (ETContainer *) contentContainer;
- (void) setContentContainer: (ETContainer *)container;

- (void ) resetSwitcherContainer;
- (void ) resetContentContainer;

- (ETPaneSwitcherPosition) switcherPosition;
- (void) setSwitcherPosition: (ETPaneSwitcherPosition)position;

// Adds an accessor to control item view size always adjusted to content size (or content container size)

@end

@interface NSObject (ETPaneSwitcherLayoutDelegate)
//- (void) willPositionSwitcher inContainer:
@end
