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

#import <EtoileUI/ETCollection.h>


@implementation NSArray (ETCollection)

- (id) content
{
	return self;
}

- (NSArray *) contentArray
{
	return self;
}

@end

@implementation NSDictionary (ETCollection)

- (id) content
{
	return self;
}

- (NSArray *) contentArray
{
	return [self allValues];
}

@end

@implementation NSSet (ETCollection)

- (id) content
{
	return self;
}

- (NSArray *) contentArray
{
	return [self allObjects];
}

@end

/* Collection Matching 

   NOTE: Quite useful until we have a better HOM-like API...
   In future, we should have object filtering like select, detect, map etc. 
   declared by an ETFilteringCollection protocol which adopts ETCollection. */

@implementation NSArray (CollectionMatching)

// FIXME: Optimize a bit probably
- (NSArray *) objectsMatchingValue: (id)value forKey: (NSString *)key
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *values = [self valueForKey: key];
    int i, n = 0;
    
    if (values == nil)
        return nil;
    
    n = [values count];
    
    for (i = 0; i < n; i++)
    {
        if ([[values objectAtIndex: i] isEqual: value])
        {
            [result addObject: [self objectAtIndex: i]];
        }
    }
    
    if ([result count] == 0)
        return nil;
    
    return result;
}

- (id) firstObjectMatchingValue: (id)value forKey: (NSString *)key
{
    return [[self objectsMatchingValue: value forKey: key] objectAtIndex: 0];
}

// NOTE: Not sure the next two methods are really interesting but it makes API
// a bit more consistent.

- (NSArray *) objectsMatchingPredicate: (NSPredicate *)predicate;
{
	return [self filteredArrayUsingPredicate: predicate];
}

- (id) firstObjectMatchingPredicate: (NSPredicate *)predicate
{
	return [[self filteredArrayUsingPredicate: predicate] objectAtIndex: 0];	
}

@end
