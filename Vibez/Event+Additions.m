//
//  Event+Additions.m
//  Vibez
//
//  Created by Harry Liddell on 26/06/2015.
//  Copyright (c) 2015 Pikture. All rights reserved.
//

#import "Event+Additions.h"

@implementation Event (Additions)

+(void)importEvents:(NSArray *)events intoContext:(NSManagedObjectContext *)context
{
    NSError* error;
    
    NSArray* allObjects = [Event allEventsInContext:context];
    
    [allObjects makeObjectsPerformSelector:@selector(setHasBeenUpdated:) withObject:@NO];
    
    if(error)
    {
        NSLog(@"error : %@ %s", error.localizedDescription, __PRETTY_FUNCTION__);
    }
    else
    {
        NSArray *parseObjects = [PIKParseManager pfObjectsToDictionary:events];
        
        [Event sqk_insertOrUpdate:parseObjects
                   uniqueModelKey:@"eventID"
                  uniqueRemoteKey:@"objectId"
              propertySetterBlock:^(NSDictionary *dictionary, Event *managedObject) {
                  
                  //                  PFFile* imageFile = dictionary[@"venueImage"];
                  //                  [imageFile getDataInBackgroundWithBlock:^(NSData *result, NSError *error)
                  //                  {
                  //                      if(!error)
                  //                      {
                  //                          managedObject.image = result;
                  //                          NSLog(@"completed image data");
                  //                      }
                  //                      else
                  //                      {
                  //                          NSLog(@"error : %@", error.localizedDescription);
                  //                      }
                  //                  }];
                  
                  managedObject.eventID = dictionary[@"objectId"];
                  managedObject.name = dictionary[@"eventName"];
                  managedObject.eventDescription = dictionary[@"eventDescription"];
                  managedObject.eventVenue = dictionary[@"eventVenue"];
                  managedObject.startDate = dictionary[@"eventDate"];
                  managedObject.lastEntry = dictionary[@"eventLastEntry"];
                  managedObject.endDate = dictionary[@"eventEnd"];
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

+(void)deleteInvalidEventsInContext:(NSManagedObjectContext *)context
{
    NSError *error;
    
    [Event sqk_deleteAllObjectsInContext:context
                           withPredicate:[NSPredicate predicateWithFormat:@"hasBeenUpdated == NO"]
                                   error:&error];
}

+(void)getAllFromParseWithSuccessBlock:(void (^)(NSArray *objects))successBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [PIKParseManager getAllForClassName:NSStringFromClass([self class])
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

+(NSArray *)allEventsInContext:(NSManagedObjectContext *)context
{
    NSError* error;
    
    NSArray* allObjects = [context executeFetchRequest:[Event sqk_fetchRequest]
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
                                uniqueValue:self.eventID
                                    success:^(PFObject *pfObject) {
                                        NSLog(@"Uploaded");
                                    }
                                    failure:^(NSError *error) {
                                        NSLog(@"Error %@ %s", error.localizedDescription, __PRETTY_FUNCTION__);
                                    }];
}

- (PFObject *)pfObject
{
    return [PFObject objectWithClassName:NSStringFromClass([self class])
                              dictionary:@{@"objectId" : self.eventID,
                                           @"eventDescription" : self.eventDescription,
                                           @"eventName" : self.name}];
}

@end
