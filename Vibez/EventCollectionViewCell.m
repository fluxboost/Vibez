//
//  EventCollectionViewCell.m
//  Vibez
//
//  Created by Harry Liddell on 17/04/2015.
//  Copyright (c) 2015 Pikture. All rights reserved.
//

#import "EventCollectionViewCell.h"

@implementation EventCollectionViewCell

-(void)setModel:(NSString *)eventName eventDescription:(NSString *)eventDescription eventGenres:(NSString *)eventGenres eventVenueName:(NSString *)eventVenueName eventDate:(NSString *)eventDate eventImageData:(NSData *)eventImageData eventLocation:(NSString *)eventLocation
{
    self.eventNameLabel.text = eventName;
    self.eventDescriptionLabel.text = eventDescription;
    self.eventGenresLabel.text = eventGenres;
    self.eventDateLabel.text = eventDate;
    self.eventPictureImage = [[UIImageView alloc] initWithImage:[UIImage imageWithData:eventImageData]];
    self.eventCLLocation = [self locationStringToCLLocation:eventLocation];
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        [self setBackgroundColor:[UIColor colorWithRed:44.0f/255.0f green:44.0f/255.0f blue:44.0f/255.0f alpha:1.0f]];
        self.layer.borderColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:0.8f].CGColor;
        self.layer.borderWidth = 0.5f;
    }
    
    return self;
}

-(CLLocation *)locationStringToCLLocation:(NSString *)venueLocation
{
    NSString* latitudeString;
    NSString* longitudeString;
    int increment = 0;
    
    NSArray *lines = [venueLocation componentsSeparatedByString:@" "];
    
    for (NSString *line in lines)
    {
        if(increment == 1)
        {
            latitudeString = line;
        }
        if(increment == 3)
        {
            longitudeString = line;
        }
        
        increment++;
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitudeString floatValue]
                                                      longitude:[longitudeString floatValue]];
    
    return location;
}

@end
