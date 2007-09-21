/*
	NSObject+Etoile.m
	
	NSObject additions like basic metamodel.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
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

#import <EtoileUI/NSObject+Etoile.h>
#import <EtoileUI/GNUstep.h>

@interface NSObject (PrivateEtoile)
- (ETInstanceVariable *) instanceVariableForName: (NSString *)ivarName;
@end


@implementation NSObject (Etoile) //<ETInspectableObject>

/** Returns a object representing the receiver. Useful when sucblasses override
    root class methods and make them unavailable to introspection. For example,
	ETProtocol represents a protocol but overrides methods like -type, typeName
	-name, -protocols and -protocolNames of NSObject, thereby you can know the 
	properties of the represented protocol, but you cannot access the 
	identically named properties which describes ETProtocol instance itself. */
- (id) metaObject
{
	return nil;
}

- (ETUTI *) type
{
	return [self className];
}

- (NSString *) typeName
{
	return [self type];
}

/** Returns both methods and instance variables for the receiver by default */
/*- (NSArray *) slotNames;
- (id) valueForSlot: (NSString *)slot;
- (void) setValue: (id)value forSlot: (NSString *)slot;*/

- (id) valueForInstanceVariable: (NSString *)ivarName
{
	return [[self instanceVariableForName: ivarName] value];
}

- (void) setValue: (id)value forInstanceVariable: (NSString *)ivarName
{
	[[self instanceVariableForName: ivarName] setValue: value];
}

- (ETMethod *) methodForName: (NSString *)name
{
	// BOOL searchInstanceMethods, BOOL searchSuperClasses
	GSMethod method = GSGetMethod([self class], NSSelectorFromString(name), YES, YES);
	ETMethod *methodObject = [[ETMethod alloc] init];
	
	methodObject->_method = method;
	
	return AUTORELEASE(methodObject);
}

- (void) setMethod: (id)value forName: (NSString *)name
{

}

- (NSArray *) instanceVariables
{
	NSMutableArray *ivars = [NSMutableArray array];
	NSEnumerator *e = [[self instanceVariableNames] objectEnumerator];
	NSString *ivarName = nil;
	
	while ((ivarName = [e nextObject]) != nil)
	{
		[ivars addObject: [self instanceVariableForName: ivarName]];
	}
	
	// FIXME: Return immutable array
	return ivars;
}

- (ETInstanceVariable *) instanceVariableForName: (NSString *)ivarName
{
	ETInstanceVariable *ivarObject = [[ETInstanceVariable alloc] init];
	GSIVar ivar = GSObjCGetInstanceVariableDefinition([self class], ivarName);
	
	ASSIGN(ivarObject->_possessor, self);
	ivarObject->_ivar = ivar;
		
	return AUTORELEASE(ivarObject);
}

- (NSArray *) instanceVariableNames
{
	return GSObjCVariableNames(self);
}

- (NSDictionary *) instancesVariableValues
{
	NSArray *ivarValues = [[self instanceVariables] valueForKey: @"value"];
	NSArray *ivarNames = [[self instanceVariables] valueForKey: @"name"];
	NSDictionary *ivarValueByName =[NSDictionary dictionaryWithObjects: ivarValues forKeys: ivarNames];
	
	return ivarValueByName;
}

- (NSDictionary *) instancesVariableTypes
{
	NSArray *ivarTypes = [[self instanceVariables] valueForKey: @"type"];
	NSArray *ivarNames = [[self instanceVariables] valueForKey: @"name"];
	NSDictionary *ivarTypeByName =[NSDictionary dictionaryWithObjects: ivarTypes forKeys: ivarNames];
	
	return ivarTypeByName;
}

- (id) typeForInstanceVariable: (NSString *)ivarName
{
	return [[self instanceVariableForName: ivarName] type];
}

- (NSArray *) protocolNames
{
	return nil;
}

#if 0
- (NSArray *) protocols
{
	NSMutableArray *protocols = [NSMutableArray array];
	NSEnumerator *e = [[self protocolNames] objectEnumerator];
	NSString *protocolName = nil;
	
	while ((protocolName = [e nextObject]) != nil)
	{
		[protocols addObject: [self protocolForName: protocolName]];
	}
	
	// FIXME: Return immutable array
	return protocols;
}
#endif

- (NSArray *) methods
{
	NSMutableArray *methods = [NSMutableArray array];
	NSEnumerator *e = [[self methodNames] objectEnumerator];
	NSString *methodName = nil;
	
	while ((methodName = [e nextObject]) != nil)
	{
		[methods addObject: [self methodForName: methodName]];
	}
	
	// FIXME: Return immutable array
	return methods;
}

- (NSArray *) methodNames
{
	return GSObjCMethodNames(self);
}

#if 0
- (NSArray *) instanceMethods;
- (NSArray *) instanceMethodNames;
- (NSArray *) classMethods;
- (NSArray *) classMethodNames;

- (void) addMethod: (ETMethod *)method;
- (void) removeMethod: (ETMethod *)method;
/** Method swizzling */
- (void) replaceMethod: (ETMethod *)method byMethod: (ETMethod *)method;

/** Low level methods used to implement method list edition */
- (void) bindMethod: (ETMethod *) toSelector: (SEL)selector;
- (void) bindSelector: (SEL) toMethod: (ETMethod *)method;
#endif

@end

@implementation ETInstanceVariable

- (id) possessor
{
	return _possessor;
}

- (NSString *) name
{
	const char *ivarName = _ivar->ivar_name;
		
	return [NSString stringWithCString: ivarName];
}

// FIXME: Replace by ETUTI class later
- (ETUTI *) type
{
	const char *ivarType = _ivar->ivar_type;
		
	return [NSString stringWithCString: ivarType];
}

- (NSString *) typeName
{
	return [self type];
}

- (id) value
{
	id ivarValue = nil;
	const char *ivarType = _ivar->ivar_type;
	int ivarOffset = _ivar->ivar_offset;
	
	// FIXME: More type support
	if(ivarType[0] == '@')
		GSObjCGetVariable([self possessor], ivarOffset, sizeof(id), (void **)&ivarValue);
		
	return ivarValue;
}

/** Pass NSValue to set primitive types */
- (void) setValue: (id)value
{
	const char *ivarType = _ivar->ivar_type;
	int ivarOffset = _ivar->ivar_offset;
	
	// FIXME: More type support
	if(strcmp(ivarType, "@"))
		GSObjCSetVariable([self possessor], ivarOffset, sizeof(id), (void **)&value);
}

@end

@implementation ETMethod 

/*- (BOOL) isInstanceMethod
{
	
}

- (BOOL) isClassMethod
{

}*/

- (NSString *) name
{
	return NSStringFromSelector([self selector]);
}

- (SEL) selector
{
	return _method->method_name;
}

- (NSMethodSignature *) methodSignature
{
	// FIXME: Build sig with member char *method_types of GSMethod
	return nil;
}

@end

/** A Protocol counterpart for Foundation and NSObject root class */
@implementation ETProtocol

- (NSString *) name
{
	return nil;
	//return [NSString stringWithCString: [_protocol name]];
}

- (ETUTI *) type
{
	return [self name];
}

- (NSString *) typeName
{
	return [self name];
}

// FIXME: Add methods like -allAncestorProtocols -allAncestorProtocolNames

/* Overriden NSObject methods to return eventual protocols adopted by the 
   represented protcol */
- (NSArray *) protocolNames
{	
	//return [[self protocols] valueForKey: @"name"];
	return nil;
}

- (NSArray *) protocols
{
	/*Class pClass = [_protocol class];
	struct objc_protocol_list pIterator = pClass->objc_protocols;
	NSMutableArray *protocols = [NSMutableArray array];
	
	do 
	{
		Protocol *p = (Protocol *)pIterator->List;
		ETProtocol *protocol = [[ETProtocol alloc] init];
		
		protocol->_protocol = p;
		[protocols addObject: protocol];
		RELEASE(protocol)
		pIterator = pIterator->next;
		
	} while (pInterator->next != NULL)

	return AUTORELEASE(protocols);*/
	return nil;
}

@end
