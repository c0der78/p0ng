//
//  A3GameCenterProtocol.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-20.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class A3GameCenter;

@protocol A3GameCenterProtocol <NSObject>

- (void) matchFound: (A3GameCenter *) gameCenter;

@end
