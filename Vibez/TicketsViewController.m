//
//  TicketsViewController.m
//  Vibez
//
//  Created by Harry Liddell on 10/07/2015.
//  Copyright (c) 2015 Pikture. All rights reserved.
//

#import "TicketsViewController.h"
#import "UIFont+PIK.h"
#import "TicketsFetchedTableViewController.h"
#import "DisplayTicketViewController.h"

@interface TicketsViewController () {
    PFUser* user;
    TicketsFetchedTableViewController *fetchVC;
}
@end

@implementation TicketsViewController

#pragma mark - General Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavBar:@"TICKETS"];
    [[self navigationItem] setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil]];
    //[self.view setBackgroundColor:[UIColor pku_lightBlack]];

    fetchVC = self.childViewControllers.firstObject;
}

-(void)setNavBar:(NSString*)titleText
{
    self.navigationItem.title = titleText;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"showTicketToDisplayTicketSegue"])
    {
        DisplayTicketViewController *destinationVC = segue.destinationViewController;
        [destinationVC setTicket:[fetchVC ticketSelected]];
    }
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(IBAction)unwindToTickets:(UIStoryboardSegue *)segue {
    [fetchVC refresh:self];
}

@end
