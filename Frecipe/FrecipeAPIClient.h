//
//  FrecipeAPIClient.h
//  Frecipe
//
//  Created by Hara Kang on 13. 4. 28..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "AFHTTPClient.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AFJSONRequestOperation.h"
#import "FrecipeSpinnerView.h"

@interface FrecipeAPIClient : AFHTTPClient

+ (NSURL *)baseUrl;
+ (FrecipeAPIClient *)client;

@end
