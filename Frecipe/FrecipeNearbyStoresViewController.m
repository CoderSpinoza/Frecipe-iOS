//
//  FrecipeNearbyStoresViewController.m
//  Frecipe
//
//  Created by Hara Kang on 13. 8. 14..
//  Copyright (c) 2013년 Frecipe. All rights reserved.
//

#import "FrecipeNearbyStoresViewController.h"
#import "FrecipeStoreViewController.h"
#import <GoogleMaps/GoogleMaps.h>
@interface FrecipeNearbyStoresViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *stores;
@property (strong, nonatomic) NSDictionary *selectedStore;

@end

@implementation FrecipeNearbyStoresViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.storesTableView.dataSource = self;
    self.storesTableView.delegate = self;
    [self fetchStores];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}


- (void)fetchStores {
    NSString *path = @"stores.json";
    
    FrecipeAPIClient *client = [FrecipeAPIClient client];
    NSURLRequest *request = [client requestWithMethod:@"GET" path:path parameters:nil];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.stores = [NSMutableArray arrayWithArray:JSON];
        
        [self.storesTableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%@", error);
    }];
    FrecipeOperationQueue *queue = [FrecipeOperationQueue sharedQueue];
    [queue addOperation:operation];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stores.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StoreCell" forIndexPath:indexPath];
    
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StoreCell"];
    }
    
    NSDictionary *store = [self.stores objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [store objectForKey:@"name"]];
//    cell.font = [UIFont boldSystemFontOfSize:15];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedStore = [self.stores objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    cell.selected = NO;
    [self performSegueWithIdentifier:@"StoreDetail" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"StoreDetail"]) {
        FrecipeStoreViewController *destinationController = segue.destinationViewController;
        
        destinationController.store = self.selectedStore;
        destinationController.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStyleBordered target:destinationController action:@selector(popViewControllerAnimated:)];
    }
}

@end
