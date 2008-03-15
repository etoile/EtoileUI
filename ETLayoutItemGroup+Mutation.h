/*
	ETLayoutItemGroup+Mutation.h
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
 
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
#import <EtoileUI/ETLayoutItemGroup.h>

@class ETLayoutItem, ETEvent;

/* Private Header
   Don't use or override methods exposed here. */
   
#define PROVIDER_SOURCE [[self ancestorContainerProvidingRepresentedPath] source]
#define PROVIDER_CONTAINER [self ancestorContainerProvidingRepresentedPath]


@interface ETLayoutItemGroup (ETMutationHandler)

- (BOOL) hasNewContent;
- (void) setHasNewContent: (BOOL)flag;

/* Mutation Backend
   Handling of Mutations on Layout Item Tree, Model Graph and Source  */

- (void) handleAdd: (ETEvent *)event item: (ETLayoutItem *)item;
- (BOOL) handleModelAdd: (ETEvent *)event item: (ETLayoutItem *)item;
- (void) handleInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index;
- (BOOL) handleModelInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index;
- (void) handleRemove: (ETEvent *)event item: (ETLayoutItem *)item;
- (BOOL) handleModelRemove: (ETEvent *)event item: (ETLayoutItem *)item;

- (void) handleAdd: (ETEvent *)event items: (NSArray *)items;
- (void) handleRemove: (ETEvent *)event items: (NSArray *)items;

/* Collection Protocol Backend */

- (void) handleAdd: (ETEvent *)event object: (id)object;
- (void) handleInsert: (ETEvent *)event object: (id)object;
- (void) handleRemove: (ETEvent *)event object: (id)object;
	
/* Providing */

- (NSArray *) itemsFromRepresentedObject;
/*- (NSArray *) itemsFromSource;
- (NSArray *) itemsFromFlatSource;
- (NSArray *) itemsFromTreeSource;*/

@end
