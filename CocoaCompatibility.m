/*
	CocoaCompatibility.m
 
	GNUstep extensions provided for PreferencesKit Cocoa compatibility
 
	Copyright (C) 2005 Quentin Mathe
 
	Author:  Quentin Mathe
	Date:  November 2005
 
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "CocoaCompatibility.h"


@implementation NSArray (ObjectsWithValueForKey)

#ifndef GNUSTEP

// NOTE: In GNUstep, this method is located in AppKit within GSToolbar.
- (NSArray *) objectsWithValue: (id)value forKey: (NSString *)key 
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

#endif

// FIXME: This method have to be added to GNUstep
- (id) objectWithValue: (id)value forKey: (NSString *)key
{
    return [[self objectsWithValue: value forKey: key] objectAtIndex: 0];
}

@end
