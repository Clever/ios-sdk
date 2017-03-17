//
//  PocketSVG.m
//
//  Copyright (c) 2013 Ponderwell, Ariel Elkin, and Contributors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#import "PocketSVG.h"

NSInteger const maxPathComplexity	= 1000;
NSInteger const maxParameters		= 64;
NSInteger const maxTokenLength		= 64;
NSString* const separatorCharString = @"-, CcMmLlHhVvZzqQaAsS";
NSString* const commandCharString	= @"CcMmLlHhVvZzqQaAsS";
unichar const invalidCommand		= '*';



@interface Token : NSObject {
@private
    unichar			command;
    NSMutableArray  *values;
}

- (id)initWithCommand:(unichar)commandChar;
- (void)addValue:(CGFloat)value;
- (CGFloat)parameter:(NSInteger)index;
- (NSInteger)valence;
@property(nonatomic, assign) unichar command;
@end


@implementation Token

+ (Token*) tokenWithCommand:(unichar) commandChar {
    Token *token = [[Token alloc] initWithCommand:commandChar];
#if !__has_feature(objc_arc)
    [token autorelease];
#endif
    
    return token;
}

- (id)initWithCommand:(unichar)commandChar {
    self = [self init];
    if (self) {
        command = commandChar;
        values = [[NSMutableArray alloc] initWithCapacity:maxParameters];
    }
    return self;
}

#if !__has_feature(objc_arc)
- (void) dealloc
{
    [values release];
    
    [super dealloc];
}
#endif

- (void)addValue:(CGFloat)value {
    [values addObject:[NSNumber numberWithDouble:value]];
}

- (CGFloat)parameter:(NSInteger)index {
    return [[values objectAtIndex:index] doubleValue];
}

- (NSInteger)valence
{
    return [values count];
}

- (BOOL)doesValenceMatch:(NSInteger)targetValence {
    NSInteger acutalValance = self.valence;
    if (acutalValance == targetValence) {
        return YES;
    }
    unichar const invalidCommand = self.command;
    NSLog(@"*** PocketSVG Error: %ld parameters for %@ command, expected %ld", (long)acutalValance, [NSString stringWithCharacters:&invalidCommand length:1], (long)targetValence);
    return NO;
}

@synthesize command;

@end


@interface PocketSVG ()

- (NSMutableArray *)parsePath:(NSString *)attr;
- (void) generateBezier:(NSArray *)tokens;

- (void)reset;
- (void)appendSVGMCommand:(Token *)token;
- (void)appendSVGLCommand:(Token *)token;
- (void)appendSVGCCommand:(Token *)token;
- (void)appendSVGSCommand:(Token *)token;

@end


@implementation PocketSVG

@synthesize bezier;

+ (CGPathRef)pathFromSVGFileNamed:(NSString *)nameOfSVG
{
    PocketSVG *pocketSVG = [PocketSVG pocketSVGFromSVGPathNodeDAttr:[self parseSVGNamed:nameOfSVG]];
    
#if TARGET_OS_IPHONE
    
    pocketSVG.bezier.flatness = 1;
    
    return pocketSVG.bezier.CGPath;
#else
    return [PocketSVG getCGPathFromNSBezierPath:pocketSVG.bezier];
#endif
}

+ (CGPathRef)pathFromSVGFileAtURL:(NSURL *)svgFileURL
{
    NSString *svgString = [[self class] svgStringAtURL:svgFileURL];
    return [[self class] pathFromSVGString:svgString];
}

+ (CGPathRef)pathFromSVGString:(NSString *)svgString
{
    NSString *dAttribute = [self dStringFromRawSVGString:svgString];
    return [self pathFromDAttribute:dAttribute];
}

+ (CGPathRef)pathFromDAttribute:(NSString *)dAttribute
{
    PocketSVG *pocketSVG = [PocketSVG pocketSVGFromSVGPathNodeDAttr:dAttribute];
#if TARGET_OS_IPHONE
    return pocketSVG.bezier.CGPath;
#else
    return [PocketSVG getCGPathFromNSBezierPath:pocketSVG.bezier];
#endif
}

- (id)initFromSVGFileNamed:(NSString *)nameOfSVG{
    return [self initFromSVGPathNodeDAttr:[[self class] parseSVGNamed:nameOfSVG]];
}

- (id)initWithURL:(NSURL *)svgFileURL
{
    NSString *svgString = [[self class] svgStringAtURL:svgFileURL];
    
    return [self initFromSVGPathNodeDAttr:[[self class] dStringFromRawSVGString:svgString]];
}

+ (NSString *)svgStringAtURL:(NSURL *)svgFileURL
{
    NSError *error = nil;
    
    NSString *svgString = [NSString stringWithContentsOfURL:svgFileURL
                                                   encoding:NSStringEncodingConversionExternalRepresentation
                                                      error:&error];
    if (error) {
        NSLog(@"*** PocketSVG Error: Couldn't read contents of SVG file named %@:", svgFileURL);
        NSLog(@"%@", error);
        return nil;
    }
    return svgString;
}



/********
 Returns the content of the SVG's d attribute as an NSString
 */
+ (NSString *)parseSVGNamed:(NSString *)nameOfSVG{
#if !TARGET_INTERFACE_BUILDER
    NSBundle *bundle = [NSBundle mainBundle];
#else
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
#endif
    
    NSString *pathOfSVGFile = [bundle pathForResource:nameOfSVG ofType:@"svg"]; // Use 'bundleForClass' instead of 'mainBundle' for Interface Builder Designable compatibility.
    
    if(pathOfSVGFile == nil){
        NSLog(@"*** PocketSVG Error: No SVG file named \"%@\".", nameOfSVG);
        return nil;
    }
    
    NSError *error = nil;
    NSString *mySVGString = [NSString stringWithContentsOfFile:pathOfSVGFile encoding:NSStringEncodingConversionExternalRepresentation error:&error];
    
    if(error != nil){
        NSLog(@"*** PocketSVG Error: Couldn't read contents of SVG file named %@:", nameOfSVG);
        NSLog(@"%@", error);
        return nil;
    }
    
    return [[self class] dStringFromRawSVGString:mySVGString];
}

+ (NSString*)dStringFromRawSVGString:(NSString*)svgString{
    //Uncomment the two lines below to print the raw data of the SVG file:
    //NSLog(@"*** PocketSVG: Raw SVG data of %@:", nameOfSVG);
    //NSLog(@"%@", mySVGString);
    
    svgString = [svgString stringByReplacingOccurrencesOfString:@"id=" withString:@""];
    
    NSArray *components = [svgString componentsSeparatedByString:@"d="];
    
    if([components count] < 2){
        NSLog(@"*** PocketSVG Error: No d attribute found in SVG file.");
        return nil;
    }
    
    NSString *dString = [components lastObject];
    dString = [dString substringFromIndex:1];
    NSRange d = [dString rangeOfString:@"\""];
    dString = [dString substringToIndex:d.location];
    dString = [dString stringByReplacingOccurrencesOfString:@" " withString:@","];
    
    NSArray *dStringWithPossibleWhiteSpace = [dString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    dString = [dStringWithPossibleWhiteSpace componentsJoinedByString:@""];
    
    //Uncomment the line below to print the raw path data of the SVG file:
    //NSLog(@"*** PocketSVG: Path data of %@ is: %@", nameOfSVG, dString);
    
    return dString;
}

- (id)initFromSVGPathNodeDAttr:(NSString *)attr
{
    self = [super init];
    if (self) {
        pathScale = 0;
        [self reset];
        separatorSet    = [NSCharacterSet characterSetWithCharactersInString:separatorCharString];
        commandSet      = [NSCharacterSet characterSetWithCharactersInString:commandCharString];
        tokens          = [self parsePath:attr];
        
#if !__has_feature(objc_arc)
        [separatorSet retain];
        [commandSet retain];
        [tokens retain];
#endif
        
        [self generateBezier:tokens];
    }
    return self;
}

#if !__has_feature(objc_arc)
- (void) dealloc
{
    [separatorSet release];
    [commandSet release];
    [tokens release];
    [bezier release];
    [super dealloc];
}
#endif

+ (PocketSVG*)pocketSVGFromSVGPathNodeDAttr:(NSString *)attr
{
    PocketSVG *pocketSVG = [[PocketSVG alloc] initFromSVGPathNodeDAttr:attr];
    
#if !__has_feature(objc_arc)
    [pocketSVG autorelease];
#endif
    
    return pocketSVG;
}

#pragma mark - Private methods

/*
	Tokenise pseudocode, used in parsePath below

	start a token
	eat a character
	while more characters to eat
		add character to token
		while in a token and more characters to eat
			eat character
			add character to token
		add completed token to store
		start a new token
	throw away empty token
*/

- (NSMutableArray *)parsePath:(NSString *)attr
{
    NSMutableArray *stringTokens = [NSMutableArray arrayWithCapacity: maxPathComplexity];
    
    NSInteger index = 0;
    while (index < [attr length]) {
        unichar	charAtIndex = [attr characterAtIndex:index];
        //Jagie:Skip whitespace
        if (charAtIndex == 32) {
            index ++;
            continue;
        }
        NSMutableString *stringToken = [NSMutableString stringWithCapacity:maxTokenLength];
        [stringToken setString:@""];
        
        if (charAtIndex != ',') {
            [stringToken appendString:[NSString stringWithFormat:@"%c", charAtIndex]];
        }
        if (![commandSet characterIsMember:charAtIndex] && charAtIndex != ',') {
            // mnk 20150312 fix for scientific notation
            while ( (++index < [attr length]) && (![separatorSet characterIsMember:(charAtIndex = [attr characterAtIndex:index])] || ([attr characterAtIndex:index-1] == 'e') || ([attr characterAtIndex:index-1] == 'E'))) {
                [stringToken appendString:[NSString stringWithFormat:@"%c", charAtIndex]];
            }
        }
        else {
            index++;
        }
        
        if ([stringToken length]) {
            [stringTokens addObject:stringToken];
        }
    }
    
    if ([stringTokens count] == 0) {
        NSLog(@"*** PocketSVG Error: Path string is empty of tokens");
        return nil;
    }
    
    // turn the stringTokens array into Tokens, checking validity of tokens as we go
    NSMutableArray* localTokens = [NSMutableArray arrayWithCapacity: maxPathComplexity];
    index = 0;
    NSString *stringToken = [stringTokens objectAtIndex:index];
    unichar command = [stringToken characterAtIndex:0];
    while (index < [stringTokens count]) {
        if (![commandSet characterIsMember:command]) {
            NSLog(@"*** PocketSVG Error: Path string parse error: found float where expecting command at token %ld in path %s.",
                  (long)index, [attr cStringUsingEncoding:NSUTF8StringEncoding]);
            return nil;
        }
        Token *token = [Token tokenWithCommand:command];
        
        // There can be any number of floats after a command. Suck them in until the next command.
        while ((++index < [stringTokens count]) && ![commandSet characterIsMember:
                                                     (command = [(stringToken = [stringTokens objectAtIndex:index]) characterAtIndex:0])]) {
            
            NSScanner *floatScanner = [NSScanner scannerWithString:stringToken];
            float value;
            if (![floatScanner scanFloat:&value]) {
                NSLog(@"*** PocketSVG Error: Path string parse error: expected float or command at token %ld (but found %s) in path %s.",
                      (long)index, [stringToken cStringUsingEncoding:NSUTF8StringEncoding], [attr cStringUsingEncoding:NSUTF8StringEncoding]);
                return nil;
            }
            // Maintain scale.
            pathScale = (fabsf(value) > pathScale) ? fabsf(value) : pathScale;
            [token addValue:value];
        }
        
        // now we've reached a command or the end of the stringTokens array
        [localTokens	addObject:token];
    }
    
    return localTokens;
}

- (void) generateBezier:(NSArray *)inTokens
{
#if TARGET_OS_IPHONE
    bezier = [[UIBezierPath alloc] init];
#else
    bezier = [[NSBezierPath alloc] init];
#endif
    
    [self reset];
    for (Token *thisToken in inTokens) {
        unichar command = [thisToken command];
        switch (command) {
            case 'M':
            case 'm':
                [self appendSVGMCommand:thisToken];
                break;
            case 'L':
            case 'l':
            case 'H':
            case 'h':
            case 'V':
            case 'v':
                [self appendSVGLCommand:thisToken];
                break;
            case 'C':
            case 'c':
                [self appendSVGCCommand:thisToken];
                break;
            case 'T':
            case 't':
            case 'Q':
            case 'q':
                [self appendSVGQCommand:thisToken];
                break;
            case 'S':
            case 's':
                [self appendSVGSCommand:thisToken];
                break;
            case 'Z':
            case 'z':
                [bezier closePath];
                break;
            default:
                NSLog(@"*** PocketSVG Error: Cannot process command : '%c'", command);
                break;
        }
    }
}

- (void)reset
{
    lastPoint = CGPointMake(0, 0);
    _controlPointType = PocketSVGControlPointInvalid;
}

- (void)appendSVGMCommand:(Token *)token
{
    _controlPointType = PocketSVGControlPointInvalid;
    if (![token doesValenceMatch:2]) {
        return;
    }
    NSInteger index = 0;
    BOOL isRelative = [token command] == 'm';
    CGFloat x = [token parameter:index++] + (isRelative ? lastPoint.x : 0);
    CGFloat y = [token parameter:index] + (isRelative ? lastPoint.y : 0);
    lastPoint = CGPointMake(x, y);
#if TARGET_OS_IPHONE
        [bezier moveToPoint:lastPoint];
#else
        [bezier moveToPoint:NSPointFromCGPoint(lastPoint)];
#endif
}

- (void)appendSVGLCommand:(Token *)token
{
    _controlPointType = PocketSVGControlPointInvalid;
    NSInteger index = 0;
    while (index < [token valence]) {
        CGFloat x = 0;
        CGFloat y = 0;
        switch ( [token command] ) {
            case 'l':
                x = lastPoint.x;
                y = lastPoint.y;
            case 'L':
                if (![token doesValenceMatch:2]) {
                    return;
                }
                x += [token parameter:index++];
                y += [token parameter:index++];
                break;
            case 'h' :
                x = lastPoint.x;
            case 'H' :
                if (![token doesValenceMatch:1]) {
                    return;
                }
                x += [token parameter:index++];
                y = lastPoint.y;
                break;
            case 'v' :
                y = lastPoint.y;
            case 'V' :
                if (![token doesValenceMatch:1]) {
                    return;
                }
                y += [token parameter:index++];
                x = lastPoint.x;
                break;
            default:
                NSLog(@"*** PocketSVG Error: Unrecognised L style command.");
                return;
        }
        lastPoint = CGPointMake(x, y);
#if TARGET_OS_IPHONE
        [bezier addLineToPoint:lastPoint];
#else
        [bezier lineToPoint:NSPointFromCGPoint(lastPoint)];
#endif
        index++;
    }
}

- (void)appendSVGQCommand:(Token *)token
{
    NSInteger index = 0;
    BOOL hasLastControlPoint = _controlPointType == PocketSVGControlPointQ;
    while (index < [token valence]) {
        CGFloat x = 0;
        CGFloat y = 0;
        CGFloat x1 = 0;
        CGFloat y1 = 0;
        switch ([token command]) {
            case 't':
                x = lastPoint.x;
                y = lastPoint.y;
            case 'T':
                if (![token doesValenceMatch:2]) {
                    _controlPointType = PocketSVGControlPointInvalid;
                    return;
                }
                x += [token parameter:index++];
                y += [token parameter:index++];
                x1 = (hasLastControlPoint) ? lastControlPoint.x : lastPoint.x;
                y1 = (hasLastControlPoint) ? lastControlPoint.y : lastPoint.y;
                break;
            case 'q' :
                x = lastPoint.x;
                y = lastPoint.y;
                x1 = x;
                y1 = y;
            case 'Q' :
                if (![token doesValenceMatch:4]) {
                    _controlPointType = PocketSVGControlPointInvalid;
                    return;
                }
                x1 += [token parameter:index++];
                y1 += [token parameter:index++];
                x += [token parameter:index++];
                y += [token parameter:index++];
                break;
            default:
                NSLog(@"*** PocketSVG Error: Unrecognised Q style command.");
                
        }
        lastControlPoint    = CGPointMake(x1, y1);
        _controlPointType   = PocketSVGControlPointQ;
#if TARGET_OS_IPHONE
        lastPoint           = CGPointMake(x, y);
        [bezier addQuadCurveToPoint:lastPoint
                       controlPoint:lastControlPoint];
#else
        // Solve cubic bezier with cubic coefficent = 0 to get quadratic
        CGFloat scalar      = 2/3;
        CGPoint startPoint  = lastPoint;
        lastPoint           = CGPointMake(x, y);
        [bezier curveToPoint:NSPointFromCGPoint(lastPoint)
               controlPoint1:NSPointFromCGPoint(CGPointMake(startPoint.x + scalar*(lastControlPoint.x - startPoint.x), startPoint.y + scalar*(lastControlPoint.y - startPoint.y)))
               controlPoint2:NSPointFromCGPoint(CGPointMake(startPoint.x + scalar*(lastControlPoint.x - lastPoint.x), startPoint.y + scalar*(lastControlPoint.y - lastPoint.y)))];
#endif
    }
}


- (void)appendSVGCCommand:(Token *)token
{
    // we must have 6 floats here (x1, y1, x2, y2, x, y).
    if (![token doesValenceMatch:6]) {
        _controlPointType = PocketSVGControlPointInvalid;
        return;
    }
    NSInteger index = 0;
    BOOL isRelative = [token command] == 'c';
    CGFloat x1 = [token parameter:index++] + (isRelative ? lastPoint.x : 0);
    CGFloat y1 = [token parameter:index++] + (isRelative ? lastPoint.y : 0);
    CGFloat x2 = [token parameter:index++] + (isRelative ? lastPoint.x : 0);
    CGFloat y2 = [token parameter:index++] + (isRelative ? lastPoint.y : 0);
    CGFloat x  = [token parameter:index++] + (isRelative ? lastPoint.x : 0);
    CGFloat y  = [token parameter:index++] + (isRelative ? lastPoint.y : 0);
    lastPoint = CGPointMake(x, y);
#if TARGET_OS_IPHONE
    [bezier addCurveToPoint:lastPoint
              controlPoint1:CGPointMake(x1,y1)
              controlPoint2:CGPointMake(x2, y2)];
#else
    [bezier curveToPoint:NSPointFromCGPoint(lastPoint)
           controlPoint1:NSPointFromCGPoint(CGPointMake(x1,y1))
           controlPoint2:NSPointFromCGPoint(CGPointMake(x2, y2))];
#endif
    lastControlPoint = CGPointMake(x2, y2);
    _controlPointType = PocketSVGControlPointS;
}

- (void)appendSVGSCommand:(Token *)token
{
    // we must have 4 floats here (x2, y2, x, y).
    if (![token doesValenceMatch:4]) {
        _controlPointType = PocketSVGControlPointInvalid;
        return;
    }
    NSInteger index = 0;
    BOOL isRelative = [token command] == 's';
    BOOL hasLastControlPoint = _controlPointType == PocketSVGControlPointS;
    CGFloat x2 = [token parameter:index++] + (isRelative ? lastPoint.x : 0);
    CGFloat y2 = [token parameter:index++] + (isRelative ? lastPoint.y : 0);
    CGFloat x  = [token parameter:index++] + (isRelative ? lastPoint.x : 0);
    CGFloat y  = [token parameter:index++] + (isRelative ? lastPoint.y : 0);
    CGFloat x1 = hasLastControlPoint ? lastPoint.x + (lastPoint.x - lastControlPoint.x) : lastPoint.x;
    CGFloat y1 = hasLastControlPoint ? lastPoint.y + (lastPoint.y - lastControlPoint.y) : lastPoint.y;
    lastPoint = CGPointMake(x, y);
#if TARGET_OS_IPHONE
    [bezier addCurveToPoint:lastPoint
              controlPoint1:CGPointMake(x1,y1)
              controlPoint2:CGPointMake(x2, y2)];
#else
    [bezier curveToPoint:NSPointFromCGPoint(lastPoint)
           controlPoint1:NSPointFromCGPoint(CGPointMake(x1,y1))
           controlPoint2:NSPointFromCGPoint(CGPointMake(x2, y2))];
#endif
    lastControlPoint = CGPointMake(x2, y2);
    _controlPointType = PocketSVGControlPointS;

}

#if !TARGET_OS_IPHONE
//NSBezierPaths don't have a CGPath property, so we need to fetch their CGPath manually.
//This comes from the "Creating a CGPathRef From an NSBezierPath Object" section of
//https://developer.apple.com/library/mac/#documentation/cocoa/Conceptual/CocoaDrawingGuide/Paths/Paths.html

+ (CGPathRef)getCGPathFromNSBezierPath:(NSBezierPath *)quartzPath
{
    int i;
    NSInteger numElements;
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [quartzPath elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        
        for (i = 0; i < numElements; i++)
        {
            switch ([quartzPath elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    //TODO:
    //At this stage, immutablePath is upside down. I'm currently flipping it back using CGAffineTransforms,
    //the path rotates fine, but its positioning needs to be fixed.
    
    CGAffineTransform flip = CGAffineTransformMake(1, 0, 0, -1, 0, CGPathGetBoundingBox(immutablePath).size.height);
    CGAffineTransform moveDown = CGAffineTransformMakeTranslation(0, -100);
    CGAffineTransform trans = CGAffineTransformConcat(flip, moveDown);
    CGPathRef betterPath = CGPathCreateCopyByTransformingPath(immutablePath, &trans);
    return betterPath;
}
#endif


@end
