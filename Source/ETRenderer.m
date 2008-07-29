/*  <title>ETRenderer</title>

	ETRenderer.m
	
	<abstract>Description forthcoming.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2007
 
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

#import "ETRenderer.h"

/* 
   ETComponent : ETFilter
   ETRenderer : ETFilter

   ETEtoileUIRender: ETRenderer
   ETMetaRender : ETRenderer
   SSWebRender (Render as Seaside components)
   ETPropertyListRender
   ETDocumentRender : ETPropertyListRender
   Probably better to have ETDocumentRender not a subclass of ETPropertyListRender
   but rather the first element of a render chain where ETPropertyListRender is
   the second one. ETDocumentRender would eliminate all nodes which are children 
   document parts and produces a document part tree it pass to ETPropertyListRender.
   ETHTMLRender
   ETPDFRender 
   
   ETStyle : ETRenderer
   ETBrush : ETStyle (or ETRenderer don't yet know)
*/

/* [style renderContentOn: webRender]

- renderContentOn: 
{
	webTable = [webRender styleForIdentifier: kTableLayout]
	
	[web render: inputValue]; // input values or context object
} */

@implementation ETRenderer

@end
