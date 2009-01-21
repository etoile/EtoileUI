/*  <title>ETViewModelLayout</title>

	ETViewModelLayout.h
	
	<abstract>A property inspector implemented as a pluggable layout which 
	supports introspecting an object as both view and model.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
 
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
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileUI/ETLayout.h>

/** See -setDisplayMode:. */
typedef enum _ETLayoutDisplayMode {
	ETLayoutDisplayModeViewProperties = 1,
	ETLayoutDisplayModeViewContent = 2,
	ETLayoutDisplayModeViewObject = 3,
	ETLayoutDisplayModeModelProperties = 4,
	ETLayoutDisplayModeModelContent = 5,
	ETLayoutDisplayModeModelObject = 6
} ETLayoutDisplayMode;


@interface ETViewModelLayout : ETLayout
{
	IBOutlet ETContainer *propertyView;
	IBOutlet NSPopUpButton *popup;
	ETLayoutDisplayMode _displayMode;
	BOOL _shouldInspectRepresentedObjectAsView;
}

- (BOOL) shouldInspectRepresentedObjectAsView;
- (void) setShouldInspectRepresentedObjectAsView: (BOOL)flag; 
- (ETLayoutItem *) inspectedItem;

- (ETLayoutDisplayMode) displayMode;
- (void) setDisplayMode: (ETLayoutDisplayMode)mode;
- (void) switchDisplayMode: (id)sender;

@end

/** Collection protocol (to recursively traverse ivars whose type is object) */
@interface ETInstanceVariable (TraversableIvars) <ETCollection>
- (BOOL) isOrdered;
- (BOOL) isEmpty;
- (id) content;
- (NSArray *) contentArray;
- (NSEnumerator *) objectEnumerator;
@end
