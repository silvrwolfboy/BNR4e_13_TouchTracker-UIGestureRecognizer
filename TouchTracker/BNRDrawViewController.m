//
//  BNRDrawViewController.m
//  TouchTracker
//
//  Created by William Kong on 2014-05-28.
//  Copyright (c) 2014 William Kong. All rights reserved.
//

#import "BNRDrawViewController.h"
#import "BNRDrawView.h"

@implementation BNRDrawViewController

- (void) loadView
{
    self.view  = [[BNRDrawView alloc] init];
}

@end
