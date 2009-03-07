/*  <title>Controls+Etoile</title>

	Controls+Etoile.m
	
	<abstract>NSControl class and subclass additions.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
 
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

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "Controls+Etoile.h"
#import "NSView+Etoile.h"
#import "NSImage+Etoile.h"
#import "ETCompatibility.h"


@implementation NSControl (Etoile)

/** Returns YES to indicate that the receiver is a widget (or control in AppKit 
terminology) on which actions should be dispatched. */
- (BOOL) isWidget
{
	return YES;
}

/* Copying */

/** Returns a view copy of the receiver. The superview of the resulting copy is
	always nil. The whole subview tree is also copied, in other words the new
	object is a deep copy of the receiver.
    Also updates the copy for NSControl specific properties such target and 
    action. */
- (id) copyWithZone: (NSZone *)zone
{
	NSControl *viewCopy = (NSControl *)[super copyWithZone: zone];

	/* Access and updates target and action properties of the enclosed cell */
	[viewCopy setTarget: [self target]];
	[viewCopy setAction: [self action]];

	RETAIN(viewCopy);
	return viewCopy;
}

/* Property Value Coding */

- (NSArray *) properties
{
	// NOTE: objectValue property is exposed by NSObject+Model
	// TODO: selectedTag, selectedCell and currentEditor are read only. 
	// Eventually expose cellClass as class property.
	NSArray *properties = [NSArray arrayWithObjects: @"cell", @"enabled", 
		@"selectedTag", @"selectedCell", @"alignement", @"font", @"formatter", 
		@"baseWritingDirection", @"currentEditor", @"target", @"action", 
		@"continuous", @"tag",@"refusesFirstResponder", @"ignoresMultiClick", nil]; 
	
	return [[super properties] arrayByAddingObjectsFromArray: properties];
}
@end

		
@implementation NSTextField (Etoile)

/** Returns 96 for width and 22 for height, the current values used by default 
    in IB on Mac OS X. */
+ (NSRect) defaultFrame
{
	return NSMakeRect(0, 0, 96, 22);
}

- (NSArray *) properties
{
	// TODO: Declare properties.
	NSArray *properties = [NSArray array]; 
	
	return [[super properties] arrayByAddingObjectsFromArray: properties];
}

@end
