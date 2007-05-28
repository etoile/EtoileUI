/*
	CocoaCompatibility.h
 
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

#import <Foundation/Foundation.h>

// NOTE: For now, this header is included not only with Cocoa but with GNUstep
// too because -objectWithValue:forKey is not implemented in GNUstep,
// moreover -objectsWithValue:forKey: is not part of Foundation for now.


@interface NSArray (ObjectsWithValueForKey)

// FIXME: This method is included in GSToolbar.h, but we don't
// import it, then to avoid compiler warning with next method
// -objectWithValue:forKey:  which is calling it, we have to redeclare it in
// GNUstep PreferencesKit even if it is not used, until it is made
// public in NSArray or -objectWithValue:forKey is implemented in GNUstep.
- (id) objectsWithValue: (id)value forKey: (NSString *)key;

- (id) objectWithValue: (id)value forKey: (NSString *)key;

@end
