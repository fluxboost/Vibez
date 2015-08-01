//
//  VenueFetchedCollectionViewContainerViewController.m
//  Vibez
//
//  Created by Harry Liddell on 21/07/2015.
//  Copyright (c) 2015 Pikture. All rights reserved.
//

#import "VenueFetchedCollectionViewContainerViewController.h"
#import "VenueCollectionViewCell.h"
#import "UIColor+Piktu.h"
#import "UIFont+PIK.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface VenueFetchedCollectionViewContainerViewController () <SQKManagedObjectControllerDelegate>

@end

@implementation VenueFetchedCollectionViewContainerViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]
                                       context:[PIKContextManager mainContext]
                              searchingEnabled:YES];
    
    if (self)
    {
        self.view.backgroundColor = [UIColor pku_blackColor];
        NSFetchRequest *request = [Venue sqk_fetchRequest];
        request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
        //request.fetchBatchSize = 25;
        
        self.controller =
        [[SQKManagedObjectController alloc] initWithFetchRequest:request
                                            managedObjectContext:[PIKContextManager mainContext]];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect otherFrame = [[self.parentViewController.childViewControllers[0] view] frame];
    [self.view setFrame:CGRectMake(CGRectGetMaxX(otherFrame), 0, otherFrame.size.width, otherFrame.size.height)];
    
    
    static NSString *venueCellIdentifier = @"venueCell";
    
    [self.collectionView registerClass:[VenueCollectionViewCell class] forCellWithReuseIdentifier:venueCellIdentifier];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    
    //NSArray *venueData = [[PIKContextManager mainContext] executeFetchRequest:[Venue sqk_fetchRequest] error:nil];
    
    self.showsSectionsWhenSearching = NO;
    self.controller.delegate = self;
    [self.controller performFetch:nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
}

- (void)refresh:(id)sender
{
    [self.refreshControl beginRefreshing];
    
    __weak typeof(self) weakSelf = self;
    
    [Venue getAllFromParseWithSuccessBlock:^(NSArray *objects)
     {
         NSError *error;
         
         NSManagedObjectContext *newPrivateContext = [PIKContextManager newPrivateContext];
         [Venue importVenues:objects intoContext:newPrivateContext];
         [Venue deleteInvalidVenuesInContext:newPrivateContext];
         [newPrivateContext save:&error];
         
         [weakSelf.refreshControl endRefreshing];
         
         if(error)
         {
             NSLog(@"Error : %@. %s", error.localizedDescription, __PRETTY_FUNCTION__);
         }
     }
                              failureBlock:^(NSError *error)
     {
         NSLog(@"Error : %@. %s", error.localizedDescription, __PRETTY_FUNCTION__);
         [weakSelf.refreshControl endRefreshing];
     }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Venue *venue = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    //venue.venueDescription = @"Updated";
    //[[venue managedObjectContext] save:nil];
    //[venue saveToParse];
    
    [self setIndexPathVenueSelected:indexPath];
    [self.parentViewController performSegueWithIdentifier:@"venueToVenueInfoSegue" sender:self];
}

#pragma mark - Fetched Request

- (NSFetchRequest *)fetchRequestForSearch:(NSString *)searchString
{
    NSFetchRequest *request = [Venue sqk_fetchRequest];
    
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
    request.fetchBatchSize = 10;
    NSPredicate *filterPredicate = nil;
    if (searchString.length)
    {
        filterPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchString];
    }
    
    [request setPredicate:filterPredicate];
    
    return request;
}

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureItemCell:(UICollectionViewCell *)theItemCell atIndexPath:(NSIndexPath *)indexPath
{
    //VenueCollectionViewCell *itemCell = (VenueCollectionViewCell *)theItemCell;
    //Venue *venue = [fetchedResultsController objectAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self fetchedResultsController:self.fetchedResultsController
                 configureItemCell:cell
                       atIndexPath:indexPath];
}

#pragma mark - UICollectionView Delegates

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VenueCollectionViewCell *venueCell = (VenueCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"venueCell" forIndexPath:indexPath];
    
    Venue *venue = [self.controller.managedObjects objectAtIndex:indexPath.row];
    
    venueCell.venueNameLabel.text = [venue.name capitalizedString];
    venueCell.venueTownLabel.text = venue.town;
    
    [venueCell.venueImage sd_setImageWithURL:[NSURL URLWithString:venue.image]
                            placeholderImage:[UIImage imageNamed:@"plug.jpg"]
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
     {
         //self.imageSelected = image;
     }];
    
    return venueCell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.controller.managedObjects count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSString *)daySuffixForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger dayOfMonth = [calendar component:NSCalendarUnitDay fromDate:date];
    switch (dayOfMonth) {
        case 1:
        case 21:
        case 31: return @"st";
        case 2:
        case 22: return @"nd";
        case 3:
        case 23: return @"rd";
        default: return @"th";
    }
}

#pragma mark - Collection View Flow Layout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = collectionView.frame.size.width/2;
    CGFloat height = width;
    
    return CGSizeMake(width, height);
}

@end
