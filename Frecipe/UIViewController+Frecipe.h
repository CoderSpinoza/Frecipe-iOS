//
//  UIViewController+Frecipe.h
//  Frecipe
//
//  Created by Hara Kang on 13. 5. 2..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrecipeBadgeView.h"
@interface UIViewController (Frecipe)

- (BOOL)isTall;
- (FrecipeBadgeView *)addNotificationBadge;
@end
