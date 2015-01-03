//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by William Kong on 2014-05-28.
//  Copyright (c) 2014 William Kong. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;
@property (nonatomic, weak) BNRLine *selectedLine;
@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
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
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan = YES;
        [self addGestureRecognizer:doubleTapRecognizer];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan = YES;
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        [self addGestureRecognizer:tapRecognizer];
        
        self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(longPress:)];
        [self addGestureRecognizer:self.longPressRecognizer];
        
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(moveLine:)];
        self.moveRecognizer.delegate = self;
        // does the gesture recognizer eat UIResponder events like touchesBegan:withEvent:?
        self.moveRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:self.moveRecognizer];
    }
    
    return self;
}

#pragma mark - Drawing and Stroke management methods
- (void)deleteLine:(id)sender
{
    if (!self.selectedLine)
        return;
    
    // remove line from _finishedLines
    [self.finishedLines removeObject:self.selectedLine];
    
    // redraw everything
    [self setNeedsDisplay];
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
    
    if (self.selectedLine) {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
}

// Returns a line close to a point
- (BNRLine *)lineAtPoint:(CGPoint)p
{
    // loop through finished lines to find a line close to p
    for (BNRLine *l in self.finishedLines) {
        CGPoint start = l.begin;
        CGPoint end = l.end;
        
        // check a few points on the line
        for (float t=0.0; t <= 1.0; t += 0.5) {
            float x = start.x + t *(end.x - start.x);
            float y = start.y + t *(end.y - start.y);
            
            // if the tapped point is within 20 points, return this line
            if (hypot(x - p.x, y - p.y) < 20.0) {
                NSLog(@"line selected");
                return l;
            }
        }
    }
    
    // no line close enough
    return nil;
}

- (void)strokeLine:(BNRLine *)line
{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
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

#pragma mark - GestureRecognizer Actions
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

// action-message for DoubleTapGestureRecognizer
- (void)doubleTap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized double tap");
    
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

// action-message for TapGestureRecognizer
- (void)tap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");
    
    CGPoint point = [gr locationInView:self];
    self.selectedLine = [self lineAtPoint:point];
    
    if (self.selectedLine) {
        // make ourselves the target of menu item action messages
        [self becomeFirstResponder];
        
        // grab menu controller
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        // create a new 'Delete' UIMenuItem
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete"
                                                            action:@selector(deleteLine:)];
        // set the array
        menu.menuItems = @[deleteItem];
        
        // tell menu where it should be displayed
        [menu setTargetRect:CGRectMake(point.x, point.y, 2,2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    } else {
        // hide menu if no line selected
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
}

// action-message for LongPressGestureRecognizer
- (void)longPress:(UIGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        NSLog(@"Recognized long tap");
        
        CGPoint point = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        }
    } else if (gr.state == UIGestureRecognizerStateEnded) {
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}

// action-message for PanGestureRecognizer
- (void)moveLine:(UIPanGestureRecognizer *)gr
{
    // if we haven't selected a line, don't do anything here
    if (!self.selectedLine || [UIMenuController sharedMenuController].menuVisible) {
        return;
    }
    
    // when pan recognizer changes its position...
    if (gr.state == UIGestureRecognizerStateChanged) {
        NSLog(@"Pan gesture state changed");
        
        // how far has pan moved
        CGPoint translation =  [gr translationInView:self];
        
        // add translation to current beginning and end points of line
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;
        
        // set the new beginning and end points of line
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
        
        // redraw
        [self setNeedsDisplay];
        
        [gr setTranslation:CGPointZero inView:self];
    }
}

#pragma mark - UIGestureRecognizerDelegate protocol messages
// returns YES if the recognizer will share its touches with other recognizers
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.moveRecognizer && otherGestureRecognizer == self.longPressRecognizer) {
        NSLog(@"Pan Gesture recognizer now sharing touches");
        return YES;
    }
    return NO;
}



@end
