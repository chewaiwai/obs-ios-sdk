//
//  OBSXMLDictionary.m
//
//  Version 1.4.1
//
//  Created by Nick Lockwood on 15/11/2010.
//  Copyright 2010 Charcoal Design. All rights reserved.
//
//  Get the latest version of OBSXMLDictionary from here:
//
//  https://github.com/nicklockwood/OBSXMLDictionary
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "OBSXMLDictionary.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const OBSXMLDictionaryFrameworkVersionString = @"1.4.1";

NS_ASSUME_NONNULL_END

#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wpartial-availability"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wformat-non-iso"
#pragma GCC diagnostic ignored "-Wgnu"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


@interface OBSXMLDictionaryParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *root;
@property (nonatomic, strong) NSMutableArray *stack;
@property (nonatomic, strong) NSMutableString *text;

@end


@implementation OBSXMLDictionaryParser

+ (OBSXMLDictionaryParser *)sharedInstance
{
    static dispatch_once_t once;
    static OBSXMLDictionaryParser *sharedInstance;
    dispatch_once(&once, ^{
        
        sharedInstance = [[OBSXMLDictionaryParser alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        _collapseTextNodes = YES;
        _stripEmptyNodes = YES;
        _trimWhiteSpace = YES;
        _alwaysUseArrays = NO;
        _preserveComments = NO;
        _wrapRootNode = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    OBSXMLDictionaryParser *copy = [[[self class] allocWithZone:zone] init];
    copy.collapseTextNodes = _collapseTextNodes;
    copy.stripEmptyNodes = _stripEmptyNodes;
    copy.trimWhiteSpace = _trimWhiteSpace;
    copy.alwaysUseArrays = _alwaysUseArrays;
    copy.preserveComments = _preserveComments;
    copy.attributesMode = _attributesMode;
    copy.nodeNameMode = _nodeNameMode;
    copy.wrapRootNode = _wrapRootNode;
    return copy;
}

- (NSDictionary<NSString *, id> *)dictionaryWithParser:(NSXMLParser *)parser
{
    parser.delegate = self;
    [parser parse];
    id result = _root;
    _root = nil;
    _stack = nil;
    _text = nil;
    return result;
}

- (NSDictionary<NSString *, id> *)dictionaryWithData:(NSData *)data
{
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    return [self dictionaryWithParser:parser];
}

- (NSDictionary<NSString *, id> *)dictionaryWithString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self dictionaryWithData:data];
}

- (NSDictionary<NSString *, id> *)dictionaryWithFile:(NSString *)path
{	
	NSData *data = [NSData dataWithContentsOfFile:path];
	return [self dictionaryWithData:data];
}

+ (NSString *)OBSXMLStringForNode:(id)node withNodeName:(NSString *)nodeName
{	
    if ([node isKindOfClass:[NSArray class]])
    {
        NSMutableArray<NSString *> *nodes = [NSMutableArray arrayWithCapacity:[node count]];
        for (id individualNode in node)
        {
            [nodes addObject:[self OBSXMLStringForNode:individualNode withNodeName:nodeName]];
        }
        return [nodes componentsJoinedByString:@"\n"];
    }
    else if ([node isKindOfClass:[NSDictionary class]])
    {
        NSDictionary<NSString *, NSString *> *attributes = [(NSDictionary *)node attributes];
        NSMutableString *attributeString = [NSMutableString string];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, __unused BOOL *stop) {
            [attributeString appendFormat:@" %@=\"%@\"", key.description.OBSXMLEncodedString, value.description.OBSXMLEncodedString];
        }];
        
        NSString *innerOBSXML = [node innerOBSXML];
        if (innerOBSXML.length)
        {
            return [NSString stringWithFormat:@"<%1$@%2$@>%3$@</%1$@>", nodeName, attributeString, innerOBSXML];
        }
        else
        {
            return [NSString stringWithFormat:@"<%@%@/>", nodeName, attributeString];
        }
    }
    else
    {
        return [NSString stringWithFormat:@"<%1$@>%2$@</%1$@>", nodeName, [node description].OBSXMLEncodedString];
    }
}

- (void)endText
{
	if (_trimWhiteSpace)
	{
		_text = [[_text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
	}
	if (_text.length)
	{
        NSMutableDictionary *top = _stack.lastObject;
		id existing = top[OBSXMLDictionaryTextKey];
        if ([existing isKindOfClass:[NSArray class]])
        {
            [existing addObject:_text];
        }
        else if (existing)
        {
            top[OBSXMLDictionaryTextKey] = [@[existing, _text] mutableCopy];
        }
		else
		{
			top[OBSXMLDictionaryTextKey] = _text;
		}
	}
	_text = nil;
}

- (void)addText:(NSString *)text
{	
	if (!_text)
	{
		_text = [NSMutableString stringWithString:text];
	}
	else
	{
		[_text appendString:text];
	}
}

- (void)parser:(__unused NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName attributes:(NSDictionary *)attributeDict
{	
	[self endText];
	
	NSMutableDictionary<NSString *, id> *node = [NSMutableDictionary dictionary];
	switch (_nodeNameMode)
	{
        case OBSXMLDictionaryNodeNameModeRootOnly:
        {
            if (!_root)
            {
                node[OBSXMLDictionaryNodeNameKey] = elementName;
            }
            break;
        }
        case OBSXMLDictionaryNodeNameModeAlways:
        {
            node[OBSXMLDictionaryNodeNameKey] = elementName;
            break;
        }
        case OBSXMLDictionaryNodeNameModeNever:
        {
            break;
        }
	}
    
	if (attributeDict.count)
	{
        switch (_attributesMode)
        {
            case OBSXMLDictionaryAttributesModePrefixed:
            {
                for (NSString *key in attributeDict)
                {
                    node[[OBSXMLDictionaryAttributePrefix stringByAppendingString:key]] = attributeDict[key];
                }
                break;
            }
            case OBSXMLDictionaryAttributesModeDictionary:
            {
                node[OBSXMLDictionaryAttributesKey] = attributeDict;
                break;
            }
            case OBSXMLDictionaryAttributesModeUnprefixed:
            {
                [node addEntriesFromDictionary:attributeDict];
                break;
            }
            case OBSXMLDictionaryAttributesModeDiscard:
            {
                break;
            }
        }
	}
	
	if (!_root)
	{
        _root = node;
        _stack = [NSMutableArray arrayWithObject:node];
        if (_wrapRootNode)
        {
            _root = [NSMutableDictionary dictionaryWithObject:_root forKey:elementName];
            [_stack insertObject:_root atIndex:0];
        }
	}
	else
	{
        NSMutableDictionary<NSString *, id> *top = _stack.lastObject;
		id existing = top[elementName];
        if ([existing isKindOfClass:[NSArray class]])
        {
            [(NSMutableArray *)existing addObject:node];
        }
        else if (existing)
        {
            top[elementName] = [@[existing, node] mutableCopy];
        }
        else if (_alwaysUseArrays)
        {
            top[elementName] = [NSMutableArray arrayWithObject:node];
        }
		else
		{
			top[elementName] = node;
		}
		[_stack addObject:node];
	}
}

- (NSString *)nameForNode:(NSDictionary<NSString *, id> *)node inDictionary:(NSDictionary<NSString *, id> *)dict
{
	if (node.nodeName)
	{
		return node.nodeName;
	}
	else
	{
		for (NSString *name in dict)
		{
			id object = dict[name];
			if (object == node)
			{
				return name;
			}
			else if ([object isKindOfClass:[NSArray class]] && [(NSArray *)object containsObject:node])
			{
				return name;
			}
		}
	}
	return nil;
}

- (void)parser:(__unused NSXMLParser *)parser didEndElement:(__unused NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName
{	
	[self endText];
    
    NSMutableDictionary<NSString *, id> *top = _stack.lastObject;
    [_stack removeLastObject];
    
	if (!top.attributes && !top.childNodes && !top.comments)
    {
        NSMutableDictionary<NSString *, id> *newTop = _stack.lastObject;
        NSString *nodeName = [self nameForNode:top inDictionary:newTop];
        if (nodeName)
        {
            id parentNode = newTop[nodeName];
            NSString *innerText = top.innerText;
            if (innerText && _collapseTextNodes)
            {
                if ([parentNode isKindOfClass:[NSArray class]])
                {
                    parentNode[[parentNode count] - 1] = innerText;
                }
                else
                {
                    newTop[nodeName] = innerText;
                }
            }
            else if (!innerText)
            {
                if (_stripEmptyNodes)
                {
                    if ([parentNode isKindOfClass:[NSArray class]])
                    {
                        [(NSMutableArray *)parentNode removeLastObject];
                    }
                    else
                    {
                        [newTop removeObjectForKey:nodeName];
                    }
                }
                else if (!_collapseTextNodes)
                {
                    top[OBSXMLDictionaryTextKey] = @"";
                }
            }
        }
	}
}

- (void)parser:(__unused NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[self addText:string];
}

- (void)parser:(__unused NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
	[self addText:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
}

- (void)parser:(__unused NSXMLParser *)parser foundComment:(NSString *)comment
{
	if (_preserveComments)
	{
        NSMutableDictionary<NSString *, id> *top = _stack.lastObject;
		NSMutableArray<NSString *> *comments = top[OBSXMLDictionaryCommentsKey];
		if (!comments)
		{
			comments = [@[comment] mutableCopy];
			top[OBSXMLDictionaryCommentsKey] = comments;
		}
		else
		{
			[comments addObject:comment];
		}
	}
}

@end


@implementation NSDictionary(OBSXMLDictionary)

+ (NSDictionary<NSString *, id> *)dictionaryWithOBSXMLParser:(NSXMLParser *)parser
{
	return [[[OBSXMLDictionaryParser sharedInstance] copy] dictionaryWithParser:parser];
}

+ (NSDictionary<NSString *, id> *)dictionaryWithOBSXMLData:(NSData *)data
{
	return [[[OBSXMLDictionaryParser sharedInstance] copy] dictionaryWithData:data];
}

+ (NSDictionary<NSString *, id> *)dictionaryWithOBSXMLString:(NSString *)string
{
	return [[[OBSXMLDictionaryParser sharedInstance] copy] dictionaryWithString:string];
}

+ (NSDictionary<NSString *, id> *)dictionaryWithOBSXMLFile:(NSString *)path
{
	return [[[OBSXMLDictionaryParser sharedInstance] copy] dictionaryWithFile:path];
}

- (nullable NSDictionary<NSString *, NSString *> *)attributes
{
	NSDictionary<NSString *, NSString *> *attributes = self[OBSXMLDictionaryAttributesKey];
	if (attributes)
	{
		return attributes.count? attributes: nil;
	}
	else
	{
		NSMutableDictionary<NSString *, id> *filteredDict = [NSMutableDictionary dictionaryWithDictionary:self];
        [filteredDict removeObjectsForKeys:@[OBSXMLDictionaryCommentsKey, OBSXMLDictionaryTextKey, OBSXMLDictionaryNodeNameKey]];
        for (NSString *key in filteredDict.allKeys)
        {
            [filteredDict removeObjectForKey:key];
            if ([key hasPrefix:OBSXMLDictionaryAttributePrefix])
            {
                filteredDict[[key substringFromIndex:OBSXMLDictionaryAttributePrefix.length]] = self[key];
            }
        }
        return filteredDict.count? filteredDict: nil;
	}
	return nil;
}

- (nullable NSDictionary *)childNodes
{	
	NSMutableDictionary *filteredDict = [self mutableCopy];
	[filteredDict removeObjectsForKeys:@[OBSXMLDictionaryAttributesKey, OBSXMLDictionaryCommentsKey, OBSXMLDictionaryTextKey, OBSXMLDictionaryNodeNameKey]];
	for (NSString *key in filteredDict.allKeys)
    {
        if ([key hasPrefix:OBSXMLDictionaryAttributePrefix])
        {
            [filteredDict removeObjectForKey:key];
        }
    }
    return filteredDict.count? filteredDict: nil;
}

- (nullable NSArray *)comments
{
	return self[OBSXMLDictionaryCommentsKey];
}

- (nullable NSString *)nodeName
{
	return self[OBSXMLDictionaryNodeNameKey];
}

- (id)innerText
{	
	id text = self[OBSXMLDictionaryTextKey];
	if ([text isKindOfClass:[NSArray class]])
	{
		return [text componentsJoinedByString:@"\n"];
	}
	else
	{
		return text;
	}
}

- (NSString *)innerOBSXML
{	
	NSMutableArray *nodes = [NSMutableArray array];
	
	for (NSString *comment in [self comments])
	{
        [nodes addObject:[NSString stringWithFormat:@"<!--%@-->", [comment OBSXMLEncodedString]]];
	}
    
    NSDictionary *childNodes = [self childNodes];
	for (NSString *key in childNodes)
	{
		[nodes addObject:[OBSXMLDictionaryParser OBSXMLStringForNode:childNodes[key] withNodeName:key]];
	}
	
    NSString *text = [self innerText];
    if (text)
    {
        [nodes addObject:[text OBSXMLEncodedString]];
    }
	
	return [nodes componentsJoinedByString:@"\n"];
}

- (NSString *)OBSXMLString
{
    if (self.count == 1 && ![self nodeName])
    {
        //ignore outermost dictionary
        return [self innerOBSXML];
    }
    else
    {
        return [OBSXMLDictionaryParser OBSXMLStringForNode:self withNodeName:[self nodeName] ?: @"root"];
    }
}

- (nullable NSArray *)arrayValueForKeyPath:(NSString *)keyPath
{
    id value = [self valueForKeyPath:keyPath];
    if (value && ![value isKindOfClass:[NSArray class]])
    {
        return @[value];
    }
    return value;
}

- (nullable NSString *)stringValueForKeyPath:(NSString *)keyPath
{
    id value = [self valueForKeyPath:keyPath];
    if ([value isKindOfClass:[NSArray class]])
    {
        value = ((NSArray *)value).firstObject;
    }
    if ([value isKindOfClass:[NSDictionary class]])
    {
        return [(NSDictionary *)value innerText];
    }
    return value;
}

- (nullable NSDictionary<NSString *, id> *)dictionaryValueForKeyPath:(NSString *)keyPath
{
    id value = [self valueForKeyPath:keyPath];
    if ([value isKindOfClass:[NSArray class]])
    {
        value = [value count]? value[0]: nil;
    }
    if ([value isKindOfClass:[NSString class]])
    {
        return @{OBSXMLDictionaryTextKey: value};
    }
    return value;
}

@end


@implementation NSString (OBSXMLDictionary)

- (NSString *)OBSXMLEncodedString
{	
	return [[[[[self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]
               stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"]
              stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"]
             stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"]
            stringByReplacingOccurrencesOfString:@"\'" withString:@"&apos;"];
}

@end
