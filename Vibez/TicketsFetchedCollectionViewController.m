//
//  TicketsFetchedCollectionViewController.m
//  Vibez
//
//  Created by Harry Liddell on 28/08/2015.
//  Copyright (c) 2015 Pikture. All rights reserved.
//

#import "TicketsFetchedCollectionViewController.h"
#import <Reachability/Reachability.h>
#import "NSString+PIK.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIColor+Piktu.h"
#import "NSString+PIK.h"
#import "UIFont+PIK.h"
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+iOS.h>


@interface TicketsFetchedCollectionViewController () {
    Reachability *reachability;
    NIKFontAwesomeIconFactory *factory;
    NSDateFormatter* dateFormatter;
    BOOL isRefreshing;
}
@end

@implementation TicketsFetchedCollectionViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    
    self = [super initWithCollectionViewLayout:flowLayout
                                       context:[PIKContextManager mainContext]
                              searchingEnabled:YES];
    
    if (self) {
        self.view.backgroundColor = [UIColor pku_lightBlack];
        reachability = [Reachability reachabilityForInternetConnection];
        [self.collectionView setEmptyDataSetSource:self];
        [self.collectionView setEmptyDataSetDelegate:self];
        [self.collectionView setDelegate:self];
        [self.collectionView setDataSource:self];
        [self.collectionView setAlwaysBounceVertical:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:@"appDidBecomeActive"
                                                   object:nil];
    }
    
    return self;
}

- (void)receivedNotification:(NSNotification *)notification {
    if([[notification name] isEqualToString:@"appDidBecomeActive"]) {
        [self refresh:self];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationItem] setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil]];
    [self.navigationItem setTitle:@"Tickets"];
    
    [self.collectionView registerClass:[TicketCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([TicketCollectionViewCell class])];
    
    [self.searchBar setPlaceholder:@"Search by event"];
    [self.searchBar setBarTintColor:[UIColor pku_lightBlack]];
    [self.searchBar setTranslucent:NO];
    [self.searchBar setBackgroundColor:[UIColor pku_blackColor]];
    [self.searchBar setBarStyle:UIBarStyleBlack];
    [self.searchBar setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
    
    factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE dd MMM"];
    //[[self collectionView] setContentInset:UIEdgeInsetsMake(44,0,0,0)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!isRefreshing) {
        [self refresh:nil];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self searchBar] resignFirstResponder];
}

- (void)refresh:(id)sender
{
    isRefreshing = YES;
    
    __weak typeof(self) weakSelf = self;
    
    if([reachability isReachable])
    {
        [Ticket getTicketsForUserFromParseWithSuccessBlock:^(NSArray *objects)
         {
             NSError *error;
             
             NSManagedObjectContext *newPrivateContext = [PIKContextManager newPrivateContext];
             [Ticket importTickets:objects intoContext:newPrivateContext];
             [Ticket deleteInvalidTicketsInContext:newPrivateContext];
             [newPrivateContext save:&error];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [[self collectionView] reloadData];
                 [[self collectionView] reloadEmptyDataSet];
             });
             
             if(error) {
                 NSLog(@"Error : %@. %s", error.localizedDescription, __PRETTY_FUNCTION__);
             }
             
             [weakSelf.refreshControl endRefreshing];
             isRefreshing = NO;
         }
                                              failureBlock:^(NSError *error)
         {
             NSLog(@"Error : %@. %s", error.localizedDescription, __PRETTY_FUNCTION__);
             isRefreshing = NO;
         }];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The internet connection appears to be offline, please connect and try again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert setTintColor:[UIColor pku_purpleColor]];
        [alert show];
        isRefreshing = NO;
    }
}

#pragma mark - UICollectionView Delegates

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Ticket *ticket = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self setTicketSelected:ticket];
    self.indexPathSelected = indexPath;
    [self.parentViewController performSegueWithIdentifier:@"showTicketToDisplayTicketSegue" sender:self];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TicketCollectionViewCell* cell = (TicketCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TicketCollectionViewCell class]) forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[TicketCollectionViewCell alloc] init];
    }
    
    [self fetchedResultsController:[self fetchedResultsController]
                 configureItemCell:cell
                       atIndexPath:indexPath];
    
    return cell;
}

-(void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureItemCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    TicketCollectionViewCell *ticketCell = (TicketCollectionViewCell *)cell;
    Ticket *ticket = [fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDate *date = [ticket eventDate];
    
    NSMutableString* dateFormatString = [[NSMutableString alloc] initWithString:[dateFormatter stringFromDate:date]];
    
    [dateFormatString insertString:[NSString daySuffixForDate:date] atIndex:6];
    
    ticketCell.ticketNameLabel.text = ticket.eventName;
    ticketCell.ticketDateLabel.text = dateFormatString;
    
    NSLog(@"%@, %@", [ticket eventName], [ticket hasBeenUsed]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIColor *color = [[UIColor alloc] init];
        
        if ([[ticket hasBeenUsed] isEqualToNumber:@NO]) {
            color = [UIColor greenColor];
        } else {
            color = [UIColor redColor];
        }
        
        [factory setColors:@[color, color]];
        [ticketCell.isValidImage setImage:[factory createImageForIcon:NIKFontAwesomeIconTicket]];
        
        [ticketCell.ticketImage sd_setImageWithURL:[NSURL URLWithString:ticket.image]
                                  placeholderImage:[UIImage imageNamed:@"plug.jpg"]
                                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                             if(error)
                                             {
                                                 NSLog(@"Error : %@. %s", error.localizedDescription, __PRETTY_FUNCTION__);
                                             }
                                         }];
    });
}

- (NSFetchRequest *)fetchRequestForSearch:(NSString *)searchString
{
    NSFetchRequest *request;
    
    //request = [self fetchRequestForSingleInstanceOfEntity:@"Ticket" groupedBy:@"eventID"];
    request = [Ticket sqk_fetchRequest]; //Create ticket additions
    
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"eventDate" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"eventID" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"hasBeenUsed" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"ticketID" ascending:YES]];
    
    NSMutableSet *subpredicates = [NSMutableSet set];
    
    if (searchString.length)
    {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"eventName CONTAINS[cd] %@", searchString]];
    }
    
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"eventEndDate >= %@", [NSDate date]]];
    //[subpredicates addObject:[self fetchRequestForSingleInstanceOfEntity:@"Ticket" groupedBy:@"eventID"]];
    [request setPredicate:[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subpredicates.allObjects]];
    
    return request;
}

- (NSPredicate *) fetchRequestForSingleInstanceOfEntity:(NSString*)entityName groupedBy:(NSString*)attributeName
{
    __block NSMutableSet *uniqueAttributes = [NSMutableSet set];
    
    NSPredicate *filter = [NSPredicate predicateWithBlock:^(id evaluatedObject, NSDictionary *bindings) {
        if( [uniqueAttributes containsObject:[evaluatedObject valueForKey:attributeName]] )
            return NO;
        
        [uniqueAttributes addObject:[evaluatedObject valueForKey:attributeName]];
        return YES;
    }];
    
    return filter;
}

#pragma mark - DZN Empty Data Set Delegates

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return nil;
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No tickets found";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont pik_montserratBoldWithSize:20.0f],
                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"You currently have no tickets, get tickets from the Find tab and feel the Vibes.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont pik_avenirNextRegWithSize:14.0f],
                                 NSForegroundColorAttributeName: [UIColor pku_greyColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    return YES;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    [self refresh:self];
}

-(void)emptyDataSetDidTapView:(UIScrollView *)scrollView
{
    [self refresh:self];
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont pik_montserratBoldWithSize:16.0f], NSForegroundColorAttributeName : [UIColor pku_purpleColor]};
    
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"TAP TO REFRESH", @"TAP TO REFRESH") attributes:attributes];
}
#pragma mark - Collection View Flow Layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = collectionView.frame.size.width;
    CGFloat height = 70;//collectionView.frame.size.height/5.5;
    
    return CGSizeMake(width, height);
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self collectionView] setEmptyDataSetSource:nil];
    [[self collectionView] setEmptyDataSetDelegate:nil];
}

@end
