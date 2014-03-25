//
//  MainViewController.m
//  F2 Demo
//
//  Created by Nathan Johnson on 1/28/14.
//  Copyright (c) 2014 Markit. All rights reserved.
//

#import "MainViewController.h"
#import "F2AppView.h"


#define kNameKey @"Name"
#define kSymbolKey @"Symbol"
#define kExhangeKey @"Exchange"

//these must be lower case, and no special characters
#define kEventContainerSymbolChange @"containercymbolchange"
#define kEventAppSymbolChange @"appsymbolchange"

@implementation MainViewController{
    F2AppView*                  _f2ChartView;
    F2AppView*                  _f2WatchlistView;
    F2AppView*                  _f2QuoteView;
    F2AppView*                  _f2CustomView;
    NSString*                   _currentSymbol;
    UIView*                     _searchBarContainer;
    UISearchBar*                _searchBar;
    UISearchDisplayController*  _searchDisplayController;
    NSURLSessionDataTask*       _searchTask;
    NSMutableArray*             _symbolArray;
}

#pragma mark UIViewController Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithRed:29.0f/255 green:104.0f/255 blue:153.0f/255 alpha:1]];
    
    float margin = 8;
    _symbolArray = [NSMutableArray new];
    
    _searchBarContainer = [UIView new];
    _searchBarContainer.frame = CGRectMake(margin, 20, 1008, 45);
    _searchBarContainer.backgroundColor = [UIColor whiteColor];
    _searchBarContainer.clipsToBounds = YES;
    [self.view addSubview:_searchBarContainer];
    
    _searchBar = [UISearchBar new];
    _searchBar.delegate = self;
    _searchBar.placeholder=@"Search a Symbol";
    _searchBar.barTintColor = [UIColor clearColor];
    _searchBar.searchBarStyle = UISearchBarStyleProminent;
    _searchBar.tintColor = self.view.backgroundColor;
    _searchBar.frame = _searchBarContainer.bounds;
    [_searchBarContainer addSubview:_searchBar];
    
    _searchDisplayController = [[UISearchDisplayController alloc]initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsDelegate = self;
    
    
    //Create the Watchlist F2 View
    _f2WatchlistView = [[F2AppView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_f2ChartView.frame)+margin, CGRectGetMaxY(_searchBarContainer.frame)+margin, 310, 329)];
    [_f2WatchlistView setDelegate:self];
    [_f2WatchlistView setScrollable:YES];
    [_f2WatchlistView setScale:0.9f];
    [_f2WatchlistView setAppJSONConfig:@"[{\"appId\": \"com_f2_examples_javascript_watchlist\",\"manifestUrl\": \"http://www.openf2.org/Examples/Apps\",\"name\": \"Watchlist\"}]"];
    [_f2WatchlistView registerEvent:@"F2.Constants.Events.APP_SYMBOL_CHANGE" key:kEventAppSymbolChange dataValueGetter:@"data.symbol"];
    [_f2WatchlistView loadApp];
    [self.view addSubview:_f2WatchlistView];
    
    //Create the Quote F2 View
    _f2QuoteView = [[F2AppView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_f2WatchlistView.frame)+margin, CGRectGetMaxY(_searchBarContainer.frame)+margin, 350, 329)];
    [_f2QuoteView setDelegate:self];
    [_f2QuoteView setScrollable:NO];
    [_f2QuoteView setScale:0.9f];
    [_f2QuoteView setAppJSONConfig:@"[{\"appId\": \"com_openf2_examples_javascript_quote\",\"manifestUrl\": \"http://www.openf2.org/Examples/Apps\",\"name\": \"Quote\"}]"];
    [_f2QuoteView registerEvent:@"F2.Constants.Events.CONTAINER_SYMBOL_CHANGE" key:kEventContainerSymbolChange dataValueGetter:@"data.symbol"];
    [_f2QuoteView loadApp];
    [self.view addSubview:_f2QuoteView];
    
    //Create the Chart F2 View
    _f2ChartView = [[F2AppView alloc]initWithFrame:CGRectMake(margin, 768-margin-350, CGRectGetMaxX(_f2QuoteView.frame)-margin, 350)];
    [_f2ChartView setDelegate:self];
    [_f2ChartView setScrollable:NO];
    [_f2ChartView setScale:0.8f];
    [_f2ChartView setAdditionalCss:@"h2 {font-size:23px}"];
    [_f2ChartView setAppJSONConfig:@"[{\"appId\": \"com_openf2_examples_csharp_chart\",\"manifestUrl\": \"http://www.openf2.org/Examples/Apps\",\"name\": \"One Year Price Movement\"}]"];
    [_f2ChartView registerEvent:@"F2.Constants.Events.CONTAINER_SYMBOL_CHANGE" key:kEventContainerSymbolChange dataValueGetter:@"data.symbol"];
    [_f2ChartView loadApp];
    [self.view addSubview:_f2ChartView];
    
    //Create the Custom F2 View
    _f2CustomView = [[F2AppView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_f2QuoteView.frame)+margin, CGRectGetMaxY(_searchBarContainer.frame)+margin, 332, 687)];
    [_f2CustomView setDelegate:self];
    [_f2CustomView setScrollable:YES];
    [_f2CustomView setScale:0.9f];
    [_f2CustomView setAppJSONConfig:@"[{\"appId\": \"com_openf2_examples_csharp_stocknews\",\"manifestUrl\": \"http://www.openf2.org/Examples/Apps\",\"name\": \"Quote\"}]"];
    [_f2CustomView registerEvent:@"F2.Constants.Events.CONTAINER_SYMBOL_CHANGE" key:kEventContainerSymbolChange dataValueGetter:@"data.symbol"];
    [_f2CustomView loadApp];
    [self.view addSubview:_f2CustomView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark "Private" Methods
- (void)searchFor:(NSString *)searchText {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString * searchURL = [NSString stringWithFormat:@"http://dev.markitondemand.com/Api/v2/Lookup/json?input=%@",searchText];
    NSURL *URL = [NSURL URLWithString:searchURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSession *session = [NSURLSession sharedSession];
    _searchTask = [session dataTaskWithRequest:request
                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *sessionError) {
                                 if (!sessionError) {
                                     NSError *JSONerror = nil;
                                     NSArray * responses = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONerror];
                                     if (JSONerror){
                                         NSLog(@"JSONObjectWithData error: %@", JSONerror);
                                     }else{
                                         dispatch_sync(dispatch_get_main_queue(), ^{
                                             _symbolArray = [NSMutableArray arrayWithArray:responses];
                                             [_searchDisplayController.searchResultsTableView reloadData];
                                         });
                                     }
                                 }
                                 dispatch_sync(dispatch_get_main_queue(), ^{
                                     //getting main thread just to be safe
                                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                 });
                                 
                             }];
    [_searchTask resume];
}

- (void)goForSymbol:(NSString *)symbol {
    if (![_currentSymbol isEqualToString:symbol]) {
        _currentSymbol = symbol;
        [_f2ChartView sendJavaScript:[NSString stringWithFormat:@"F2.Events.emit(F2.Constants.Events.CONTAINER_SYMBOL_CHANGE, { 'symbol': '%@' });",symbol]];
        [_f2QuoteView sendJavaScript:[NSString stringWithFormat:@"F2.Events.emit(F2.Constants.Events.CONTAINER_SYMBOL_CHANGE, { 'symbol': '%@' });",symbol]];
        [_f2CustomView sendJavaScript:[NSString stringWithFormat:@"F2.Events.emit(F2.Constants.Events.CONTAINER_SYMBOL_CHANGE, { 'symbol': '%@' });",symbol]];
    }
}

#pragma mark UISearchBarDelegate Methods
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [_searchTask cancel];
    if (searchText.length>0) {
        [self searchFor:searchText];
    }else{
        [_symbolArray removeAllObjects];
        [_searchDisplayController.searchResultsTableView reloadData];
    }
}

#pragma mark UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _symbolArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"searchResultCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"searchResultCell"];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = self.view.backgroundColor;
    }
    NSDictionary * symbol = [_symbolArray objectAtIndex:indexPath.row];
    [cell.textLabel setText:symbol[kSymbolKey]];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ - %@",symbol[kNameKey],symbol[kExhangeKey]]];
    return cell;
}

#pragma mark UITableViewDelegate Methods
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary * symbol = [_symbolArray objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [_searchDisplayController setActive:NO animated:YES];
    _searchBar.text = [NSString stringWithFormat:@"%@ %@",symbol[kSymbolKey],symbol[kNameKey]];
    [self goForSymbol:symbol[kSymbolKey]];
}

#pragma mark F2AppViewDelegate methods
-(void)F2View:(F2AppView *)appView messageRecieved:(NSString *)message withKey:(NSString *)key{
    if ([key isEqualToString:kEventContainerSymbolChange]) {
        NSLog(@"Container Symbol Change");
    }else if ([key isEqualToString:kEventAppSymbolChange]){
        NSLog(@"App Symbol Change");
        [self goForSymbol:message];
        [_searchBar setText:message];
    }
}

@end