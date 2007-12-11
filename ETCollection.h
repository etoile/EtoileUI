/*
	ETCollection.h
	
	NSObject and collection class additions like a collection protocol.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2007
 
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


@interface NSObject (ETCollection)
- (BOOL) isCollection;
@end

/* Collection Access and Mutation Protocols */

@protocol ETCollection
/** Returns the underlying data structure object holding the content or self 
	when the protocol is adopted by a class which is a content data structure 
	by itself (like NSArray, NSDictionary, NSSet etc.). 
	Content by its very nature is always a collection of other objects. As 
	such, content may hold one or no objects (empty collection).
	When adopted, this method must never return nil. */
- (id) content;
/** Returns the content as an NSArray-based collection of objects. 
	When adopted, this method must never return nil, you should generally 
	return an empty NSArray instead. */
- (NSArray *) contentArray;
/** Returns an enumerator which can be used as a conveniency to iterate over 
	the elements of the content one-by-one. */
//- (NSEnumerator *) objectEnumerator;
@end

@protocol ETCollectionMutation
- (void) addObject: (id)object;
- (void) removeObject: (id)object;
@end


/* Adopted by the following Foundation classes  */

@interface NSArray (ETCollection) <ETCollection>
- (id) content;
- (NSArray *) contentArray;
@end

@interface NSDictionary (ETCollection) <ETCollection>
- (id) content;
- (NSArray *) contentArray;
@end

@interface NSSet (ETCollection) <ETCollection>
- (id) content;
- (NSArray *) contentArray;
@end

@interface NSMutableArray (ETCollectionMutation) <ETCollectionMutation>

@end

@interface NSMutableSet (ETCollectionMutation) <ETCollectionMutation>

@end


/* Collection Matching */

@interface NSArray (CollectionMatching)

/* Key Value Matching */

- (NSArray *) objectsMatchingValue: (id)value forKey: (NSString *)key;
- (id) firstObjectMatchingValue: (id)value forKey: (NSString *)key;

/* Predicate Matching */

- (NSArray *) objectsMatchingPredicate: (NSPredicate *)predicate;
- (id) firstObjectMatchingPredicate: (NSPredicate *)predicate;

@end

