//
//  A3Label.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-20.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import "A3Label.h"

@implementation A3Label

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = {self.topInset, self.leftInset,
        self.bottomInset, self.rightInset};
    
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

- (void) sizeToFit {
    [super sizeToFit];
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width+self.leftInset+self.rightInset, self.frame.size.height+self.topInset+self.bottomInset);
}

@end
