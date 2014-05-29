//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by William Kong on 2014-05-28.
//  Copyright (c) 2014 William Kong. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView ()
@property (nonatomic, strong) BNRLine *currentLine;
@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;
@end

@implementation BNRDrawView

#pragma mark - View life cycle
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor grayColor];
        self.finishedLines = [[NSMutableArray alloc] init];
        self.linesInProgress = [[NSMutableDictionary alloc] init];
        self.multipleTouchEnabled = YES;
        
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(doubleTap:)];
        [self addGestureRecognizer:doubleTapRecognizer];
    }
    
    return self;
}

#pragma mark - Drawing methods
- (void)strokeLine:(BNRLine *)line
{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

- (void)drawRect:(CGRect)rect
{
    // Draw finished lines in black
    [[UIColor blackColor] set];
    
    for (BNRLine *line in self.finishedLines) {
        [self strokeLine:line];
    }
    
    
    [[UIColor redColor] set];
        
    for (NSValue *key in self.linesInProgress) {
        [self strokeLine:self.linesInProgress[key]];
    }
}

#pragma mark - Responder Touch events
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        CGPoint location = [t locationInView:self];
        
        BNRLine *line = [[BNRLine alloc] init];
        line.begin = location;
        line.end = location;
        
        // + (NSValue *)valueWithNonretainedObject:(id)anObject
        // - is useful if you want to add an object to a collection but don’t want
        // the collection to create a strong reference to it.
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        self.linesInProgress[key] = line;
    }
    
    // marks the receiver’s entire bounds rectangle as needing to be redrawn.
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];
        
        line.end = [t locationInView:self];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];
        
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // remove all lines in progress
    [self.linesInProgress removeAllObjects];
    
    [self setNeedsDisplay];
}

#pragma mark - Gesture Actions
- (void)doubleTap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized double tap");
    
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

@end
