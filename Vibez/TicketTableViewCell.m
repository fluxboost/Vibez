//
//  TicketTableViewCell.m
//  Vibez
//
//  Created by Harry Liddell on 12/06/2015.
//  Copyright (c) 2015 Pikture. All rights reserved.
//

#import "TicketTableViewCell.h"

@implementation TicketTableViewCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
   // if (self) {
        self.ticketNameLabel = [[UILabel alloc] init];
        self.ticketVenueLabel = [[UILabel alloc] init];
        self.ticketDateLabel = [[UILabel alloc] init];
        self.ticketImage = [[UIImageView alloc] init];
    //}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end