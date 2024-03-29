//
//  Ticket+Additions.m
//  Vibez
//
//  Created by Harry Liddell on 29/07/2015.
//  Copyright (c) 2015 Pikture. All rights reserved.
//

#import "Ticket+Additions.h"


@implementation Ticket (Additions)

+(void)importTickets:(NSArray *)tickets intoContext:(NSManagedObjectContext *)context
{
    NSError* error;
    
    NSArray* allObjects = [Ticket allTicketsInContext:context];
    
    [allObjects makeObjectsPerformSelector:@selector(setHasBeenUpdated:) withObject:@NO];
    
    if(error)
    {
        NSLog(@"error : %@ %s", error.localizedDescription, __PRETTY_FUNCTION__);
    }
    else
    {
        NSArray *parseObjects = [PIKParseManager pfObjectsToDictionary:tickets];
        
        [Ticket sqk_insertOrUpdate:parseObjects
                    uniqueModelKey:@"ticketID"
                   uniqueRemoteKey:@"objectId"
               propertySetterBlock:^(NSDictionary *dictionary, Ticket *managedObject) {
                   
                   PFFile* imageFile = [dictionary[@"event"] objectForKey:@"eventImage"];
                   managedObject.image = imageFile.url;
                   managedObject.ticketID = dictionary[@"objectId"];
                   managedObject.eventName = [dictionary[@"event"] objectForKey:@"eventName"];
                   managedObject.eventID = [dictionary[@"event"] objectId];
                   managedObject.eventDate = [dictionary[@"event"] objectForKey:@"eventDate"];
                   managedObject.username = [dictionary[@"user"] objectForKey:@"username"];
                   managedObject.email = [dictionary[@"user"] objectForKey:@"email"];
                   managedObject.hasBeenUsed = dictionary[@"hasBeenUsed"];
                   managedObject.eventEndDate = [dictionary[@"event"] objectForKey:@"eventLastEntry"];
                   managedObject.venue = [[dictionary[@"event"] objectForKey:@"venue"] objectForKey:@"venueName"];
                   //managedObject.location = [[[dictionary[@"event"] objectForKey:@"eventVenue"] objectForKey:@"location"] stringValue];
                   managedObject.hasBeenUpdated = @YES;
               }
                    privateContext:context
                             error:&error];
        
        if(error)
        {
            NSLog(@"error when importing : %@ %s", error.localizedDescription, __PRETTY_FUNCTION__);
        }
    }
}

+(void)deleteInvalidTicketsInContext:(NSManagedObjectContext *)context
{
    NSError *error;
    
    [Ticket sqk_deleteAllObjectsInContext:context
                            withPredicate:[NSPredicate predicateWithFormat:@"hasBeenUpdated == NO"]
                                    error:&error];
}

+(void)getTicketsForUserFromParseWithSuccessBlock:(void (^)(NSArray *objects))successBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@", [PFUser currentUser]];
    
    [PIKParseManager getAllForClassName:NSStringFromClass([self class]) withPredicate:predicate withIncludeKey:@"event.venue"
                                success:^(NSArray *objects) {
                                    if (successBlock) {
                                        successBlock(objects);
                                    }
                                }
                                failure:^(NSError *error) {
                                    if (failureBlock) {
                                        failureBlock(error);
                                    }
                                }];
}

+ (void)getTicketsForEvent:(PFObject *)event fromParseWithSuccessBlock:(void (^)(NSArray *objects))successBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event = %@", event];
    
    [PIKParseManager getAllForClassName:NSStringFromClass([self class]) withPredicate:predicate withIncludeKey:@"event.venue"
                                success:^(NSArray *objects) {
                                    if (successBlock) {
                                        successBlock(objects);
                                    }
                                }
                                failure:^(NSError *error) {
                                    if (failureBlock) {
                                        failureBlock(error);
                                    }
                                }];
}

+(NSArray *)allTicketsInContext:(NSManagedObjectContext *)context
{
    NSError* error;
    
    NSArray* allObjects = [context executeFetchRequest:[Ticket sqk_fetchRequest]
                                                 error:&error];
    
    if(error)
    {
        NSLog(@"error : %@ %s", error.localizedDescription, __PRETTY_FUNCTION__);
        return nil;
    }
    else
    {
        return allObjects;
    }
}

- (void)saveToParse
{
    [PIKParseManager insertOrUpdatePFObject:[self pfObject]
                              withClassName:NSStringFromClass([self class])
                            remoteUniqueKey:@"objectId"
                                uniqueValue:[self ticketID]
                                    success:^(PFObject *pfObject) {
                                        NSLog(@"Uploaded");
                                    }
                                    failure:^(NSError *error) {
                                        NSLog(@"Error %@ %s", error.localizedDescription, __PRETTY_FUNCTION__);
                                    }];
}

- (PFObject *)pfObject
{
    PFObject *object = [PFObject objectWithClassName:NSStringFromClass([self class])
                                          dictionary:@{@"objectId" : self.ticketID,
                                                       @"hasBeenUsed" : [NSNumber numberWithBool:self.hasBeenUsed]
                                                       }];
    
    return object;
}

+ (void)getAmountOfTicketsUserOwnsOnEvent:(Event *)event withBlock:(void (^)(int, NSError *))block {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Ticket"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    
    PFObject *object;
    
    if ([event eventID]) {
        object = [PFObject objectWithoutDataWithClassName:@"Event" objectId:[event eventID]];
    }
    
    [query whereKey:@"event" equalTo:object];
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        block(count, error);
    }];
}

+ (void)getAmountOfTicketsUserOwnsOnEventPFObject:(PFObject *)event withBlock:(void (^)(int, NSError *))block {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Ticket"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    
    PFObject *object;
    
    if ([event objectForKey:@"eventID"]) {
        object = [PFObject objectWithoutDataWithClassName:@"Event" objectId:[event objectForKey:@"eventID"]];
    } else if ([event objectId]) {
        object = [PFObject objectWithoutDataWithClassName:@"Event" objectId:[event objectId]];
    }
    
    [query whereKey:@"event" equalTo:object];
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        block(count, error);
    }];
}

@end
