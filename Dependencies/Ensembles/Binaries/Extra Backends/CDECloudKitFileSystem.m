//
//  CDECloudKitFileSystem.m
//  Ensembles Mac
//
//  Created by Drew McCormack on 9/22/14.
//  Copyright (c) 2014 Drew McCormack. All rights reserved.
//

#import "CDECloudKitFileSystem.h"

NSString * const CDECloudKitRecordZoneNameSchema1 = @"com.mentalfaculty.ensembles.zone.schema1";
NSString * const CDECloudKitRecordZoneNameSchema2 = @"com.mentalfaculty.ensembles.zone.schema2";

const NSQualityOfService CDECloudKitQualityOfService = NSQualityOfServiceUserInitiated;

@interface CDECloudKitFileSystem ()

@property (nonatomic, readwrite, nonnull) CKContainer *container;
@property (nonatomic, readwrite, nonnull) CKDatabase *database;
@property (nonatomic, readwrite) CDECloudKitSchemaVersion schemaVersion;
@property (atomic, readwrite, nullable) CKShare *share;
@property (nonatomic, readonly, nullable) CKRecordID *shareRecordID; // nil if no sharing
@property (nonatomic, readonly, nonnull) NSURL *cacheURL;
@property (nonatomic, readonly, nonnull) NSString *cacheFilename;

@end


@implementation CDECloudKitFileSystem {
    NSOperation *setupOperation;
    NSOperationQueue *operationQueue;
    NSFileManager *fileManager;
    NSMutableDictionary *recordsByFullPath;
    NSMutableDictionary *contentsByDirectoryPath;
    CKServerChangeToken *serverChangeToken;
}

@synthesize database;
@synthesize container;
@synthesize databaseScope;
@synthesize ubiquityContainerIdentifier;
@synthesize rootDirectory;
@synthesize recordZoneID;
@synthesize sharingIdentifier;
@synthesize share;
@synthesize shareRecordID;
@synthesize schemaVersion;
@synthesize shareOwnerName;

static NSOperationQueue *sharedOperationQueue;

+ (void)initialize
{
    if (self == [CDECloudKitFileSystem class]) {
        sharedOperationQueue = [[NSOperationQueue alloc] init];
        sharedOperationQueue.maxConcurrentOperationCount = 1;
        sharedOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
}

- (instancetype)initWithUbiquityContainerIdentifier:(NSString *)ubiquity rootDirectory:(NSString *)rootPath usePublicDatabase:(BOOL)usePublic schemaVersion:(CDECloudKitSchemaVersion)newVersion
{
    NSParameterAssert(ubiquity != nil);
    self = [super init];
    if (self) {
        [self commonInitializationWithUbiquityIdentifier:ubiquity rootDirectory:rootPath schemaVersion:newVersion];

        databaseScope = usePublic ? CDEDatabaseScopePublic : CDEDatabaseScopePrivate;
        recordZoneID = nil;
        shareRecordID = nil;
        
        [self setupDatabase];
        [self setupCloud:^(NSError *error) {
            if (error) CDELog(CDELoggingLevelError, @"Setting up cloud directories in CloudKit failed: %@", error);
        }];
    }
    return self;
}

- (instancetype)initWithPrivateDatabaseForUbiquityContainerIdentifier:(NSString *)ubiquity schemaVersion:(CDECloudKitSchemaVersion)newSchema
{
    NSParameterAssert(ubiquity != nil);
    self = [super init];
    if (self) {
        [self commonInitializationWithUbiquityIdentifier:ubiquity rootDirectory:nil schemaVersion:newSchema];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        databaseScope = CDEDatabaseScopePrivate;
        recordZoneID = [[CKRecordZoneID alloc] initWithZoneName:self.recordZoneName ownerName:CKOwnerDefaultName];
        shareRecordID = nil;
#pragma clang diagnostic pop
        
        [self setupDatabase];
        [self prepareCache];
        [self setupCloud:^(NSError *error) {
            if (error) CDELog(CDELoggingLevelError, @"Setting up cloud directories in CloudKit failed: %@", error);
        }];
    }
    return self;
}

- (instancetype)initWithUbiquityContainerIdentifier:(NSString *)ubiquity sharingIdentifier:(NSString *)newSharingIdentifier shareOwnerName:(NSString *)ownerName
{
    NSParameterAssert(newSharingIdentifier != nil);
    self = [super init];
    if (self) {
        [self commonInitializationWithUbiquityIdentifier:ubiquity rootDirectory:nil schemaVersion:CDECloudKitSchemaVersion2];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        sharingIdentifier = newSharingIdentifier;
        shareOwnerName = [ownerName copy];
        databaseScope = [shareOwnerName isEqualToString:CKOwnerDefaultName] ? CDEDatabaseScopePrivate : CDEDatabaseScopeShared;
        recordZoneID = [[CKRecordZoneID alloc] initWithZoneName:sharingIdentifier ownerName:shareOwnerName];
        shareRecordID = [[CKRecordID alloc] initWithRecordName:sharingIdentifier zoneID:recordZoneID];
#pragma clang diagnostic pop

        [self setupDatabase];
        [self prepareCache];
        [self setupCloud:^(NSError *error) {
            if (error) CDELog(CDELoggingLevelError, @"Setting up cloud directories in CloudKit failed: %@", error);
        }];
    }
    return self;
}

- (void)commonInitializationWithUbiquityIdentifier:(NSString *)ubiquity rootDirectory:(NSString *)rootPath schemaVersion:(CDECloudKitSchemaVersion)schema
{
    fileManager = [[NSFileManager alloc] init];
    operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 1;
    operationQueue.qualityOfService = CDECloudKitQualityOfService;
    
    ubiquityContainerIdentifier = [ubiquity copy];
    rootDirectory = rootPath ? : @"/";
    
    [self clearInMemoryCache];
    
    schemaVersion = schema;
}

#pragma mark - Database

- (void)setupDatabase
{
    self.container = [CKContainer containerWithIdentifier:ubiquityContainerIdentifier];
    switch (databaseScope) {
        case CDEDatabaseScopePrivate:
            self.database = self.container.privateCloudDatabase;
            break;
        case CDEDatabaseScopePublic:
            self.database = self.container.publicCloudDatabase;
            break;
        case CDEDatabaseScopeShared:
            self.database = self.container.sharedCloudDatabase;
            break;
    }
}

#pragma mark - Subscription

- (NSPredicate *)subscriptionPredicate
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileSize > 0"];
    return predicate;
}

- (void)subscribeForPushNotificationsWithCompletion:(nullable CDECompletionBlock)completion
{
#if TARGET_OS_WATCH
	CDELog(CDELoggingLevelVerbose, @"Ignoring request for push notifications. Not available on watchOS.");
	[self dispatchCompletion:completion withError:nil];
    return;
#endif

	CKNotificationInfo *notificationInfo = [[CKNotificationInfo alloc] init];
	notificationInfo.shouldSendContentAvailable = YES;
	
	if (NSClassFromString(@"CKDatabaseSubscription") && (self.databaseScope == CDEDatabaseScopeShared)) {
		CKDatabaseSubscription * databaseSubscription = [[CKDatabaseSubscription alloc] initWithSubscriptionID:@"CDESharedDatabaseSubscription"];
		databaseSubscription.notificationInfo = notificationInfo;

		CKModifySubscriptionsOperation *operation = [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:@[databaseSubscription] subscriptionIDsToDelete:nil];
		operation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *operationError) {
			if (operationError) CDELog(CDELoggingLevelError, @"Error while saving CKDatabaseSubscription: %@", operationError);
			[self dispatchCompletion:completion withError:operationError];
		};
		operation.qualityOfService = CDECloudKitQualityOfService;
		[self.database addOperation:operation];
	}
    else {
		NSMutableArray *tasks = [[NSMutableArray alloc] init];
		
        // Monitor new files added in cloud
		CDEAsynchronousTaskBlock fileAddedSubscriptionTask = ^(CDEAsynchronousTaskCallbackBlock next) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			NSPredicate *predicate = self.subscriptionPredicate;
			CKSubscription *subscription = [[CKSubscription alloc] initWithRecordType:self.fileSystemNodeRecordType predicate:predicate subscriptionID:@"CDEFileAddedSubscription" options:CKSubscriptionOptionsFiresOnRecordCreation];
            subscription.notificationInfo = notificationInfo;
            [self.database saveSubscription:subscription completionHandler:^(CKSubscription *subscription, NSError *error) {
                next(error, NO);
            }];
#pragma clang diagnostic pop
		};
		[tasks addObject:fileAddedSubscriptionTask];
		
        // Monitor changes to the share, if there is one
		if (NSClassFromString(@"CKDatabaseSubscription")) {
			if ([shareOwnerName isEqualToString:CKCurrentUserDefaultName]) {
				CDEAsynchronousTaskBlock shareSubscriptionTask = ^(CDEAsynchronousTaskCallbackBlock next) {
					NSPredicate *predicate = [NSPredicate predicateWithValue:TRUE];
					CKQuerySubscription *shareSubscription = [[CKQuerySubscription alloc] initWithRecordType:@"cloudkit.share" predicate:predicate subscriptionID:@"CKShareSubscription" options:CKQuerySubscriptionOptionsFiresOnRecordUpdate];
					shareSubscription.notificationInfo = notificationInfo;
					[self.database saveSubscription:shareSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
						next(error, NO);
					}];
				};
				[tasks addObject:shareSubscriptionTask];
			}
		}
		
		NSOperation *subscriptionOperation = [[CDEAsynchronousTaskQueue alloc] initWithTasks:tasks completion:^(NSError *error) {
			if (error) CDELog(CDELoggingLevelError, @"Error while saving CloudKit subscription: %@", error);
            [self dispatchCompletion:completion withError:error];
		}];
		[operationQueue addOperation:subscriptionOperation];
	}
}

#pragma mark - Setup Cloud

- (void)setupCloud:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Setting up cloud directories in CloudKit");
    
    if (!self.database) {
        [self dispatchCompletion:completion withError:[self noConnectionError]];
        return;
    }
    
    CDEAsynchronousTaskBlock zoneTask = ^(CDEAsynchronousTaskCallbackBlock next) {
        [self createZoneIfNecessaryWithCompletion:^(NSError *error) {
            next(error, NO);
        }];
    };
    
    CDEAsynchronousTaskBlock shareTask = ^(CDEAsynchronousTaskCallbackBlock next) {
        [self createShareAndRootDirectoryIfNecessaryWithCompletion:^(NSError *error, BOOL shareOrRootChanged) {
            next(error, NO);
        }];
    };
    
    CDEAsynchronousTaskBlock directoriesTask = ^(CDEAsynchronousTaskCallbackBlock next) {
        [self createRootDirectoryIfNecessaryWithCompletion:^(NSError *error, CKRecord *rootRecord) {
            next(error, NO);
        }];
    };
    
    NSArray *tasks = @[zoneTask, shareTask, directoriesTask];
    setupOperation = [[CDEAsynchronousTaskQueue alloc] initWithTasks:tasks completion:^(NSError *error) {
        if (error) CDELog(CDELoggingLevelError, @"Failed to create root directory: %@", error);
        if (completion) completion(error);
    }];
    
    [operationQueue addOperation:setupOperation];
}

- (NSError *)noConnectionError
{
    NSError *error = [NSError errorWithDomain:CDEErrorDomain code:CDEErrorCodeConnectionError userInfo:@{NSLocalizedDescriptionKey : @"No iCloud connection"}];
    return error;
}

#pragma mark - Shares

- (void)createShareAndRootDirectoryIfNecessaryWithCompletion:(void (^)(NSError *error, BOOL shareOrRootChanged))completion
{
    CDELog(CDELoggingLevelTrace, @"Creating share if necessary");
    if (!sharingIdentifier) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, NO);
        });
        return;
    }
    
    [self fetchShareWithCompletion:^(NSError *fetchShareError, CKShare *newShare) {
        if (fetchShareError.code == CKErrorZoneNotFound && databaseScope == CDEDatabaseScopeShared) {
            if ([self.delegate respondsToSelector:@selector(cloudKitFileSystemSharedZoneDidBecomeUnavailable:)]) {
                [self.delegate cloudKitFileSystemSharedZoneDidBecomeUnavailable:self];
            }
            if (completion) completion(fetchShareError, NO);
        }
        else if (fetchShareError.code == CKErrorUnknownItem && databaseScope == CDEDatabaseScopePrivate) {
            [self createRootDirectoryIfNecessaryWithCompletion:^(NSError *error, CKRecord *rootRecord) {
                if (error) {
                    if (completion) completion(error, NO);
                    return;
                }
                
                [self createShareForRootDirectoryRecord:rootRecord withCompletion:^(NSError *createShareError) {
                    if (!createShareError) {
                        if ([self.delegate respondsToSelector:@selector(cloudKitFileSystemShareIsAvailable:)]) {
                            [self.delegate cloudKitFileSystemShareIsAvailable:self];
                        }
                    }
                    if (completion) completion(createShareError, YES);
                }];
            }];
        }
        else {
            if (fetchShareError) {
                CDELog(CDELoggingLevelError, @"Error fetching share: %@", fetchShareError);
            }
            else if (!self.share || ![self.share.recordChangeTag isEqual:newShare.recordChangeTag]) {
                self.share = newShare;
                if ([self.delegate respondsToSelector:@selector(cloudKitFileSystemShareIsAvailable:)]) {
                    [self.delegate cloudKitFileSystemShareIsAvailable:self];
                }
            }
            
            if (completion) completion(fetchShareError, NO);
        }
    }];
}

- (void)fetchShareWithCompletion:(void (^)(NSError *error, CKShare *share))completion
{
    CDELog(CDELoggingLevelTrace, @"Fetching share");
    CKFetchRecordsOperation *operation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[shareRecordID]];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.fetchRecordsCompletionBlock = ^(NSDictionary *recordsByRecordID, NSError *error) {
        NSError *fetchError = error;
        if (fetchError.code == CKErrorPartialFailure) {
            NSDictionary *errorsByRecordID = fetchError.userInfo[CKPartialErrorsByItemIDKey];
            fetchError = errorsByRecordID[shareRecordID];
        }
        CKShare *newShare = nil;
        if (!fetchError) {
            newShare = recordsByRecordID[shareRecordID];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(fetchError, newShare);
        });
    };
    [self.database addOperation:operation];
}

- (void)createShareForRootDirectoryRecord:(CKRecord *)rootRecord withCompletion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Creating share");
    CKShare *newShare = [[CKShare alloc] initWithRootRecord:rootRecord shareID:shareRecordID];
    [newShare setValue:@(YES) forKey:@"isEnsemblesShare"];
    newShare.publicPermission = CKShareParticipantPermissionNone;
    
    if ([self.delegate respondsToSelector:@selector(cloudKitFileSystem:willSaveNewShare:)]) {
        [self.delegate cloudKitFileSystem:self willSaveNewShare:newShare];
    }
    
    CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[newShare, rootRecord] recordIDsToDelete:nil];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error) {
        if (!error) self.share = newShare;
        [self dispatchCompletion:completion withError:error];
    };
    [self.database addOperation:operation];
}

- (void)retrieveShareWithCompletion:(void(^)(NSError * _Nullable error, CKShare * _Nullable share))completion {
    [self createShareAndRootDirectoryIfNecessaryWithCompletion:^(NSError *error, BOOL shareOrRootChanged) {
        if (completion) completion(error, self.share);
    }];
}

+ (void)acceptInvitationToShareWithMetadata:(CKShareMetadata *)metadata completion:(CDECompletionBlock)completion {
    CKAcceptSharesOperation *operation = [[CKAcceptSharesOperation alloc] initWithShareMetadatas:@[metadata]];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.acceptSharesCompletionBlock = ^(NSError *operationError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(operationError);
        });
    };
    [sharedOperationQueue addOperation:operation];
}

#pragma mark - Zones

- (NSString *)recordZoneName
{
    if (sharingIdentifier) return sharingIdentifier;

    NSString *result;
    switch (schemaVersion) {
        case CDECloudKitSchemaVersion1:
            result = CDECloudKitRecordZoneNameSchema1;
            break;
            
        case CDECloudKitSchemaVersion2:
            result = CDECloudKitRecordZoneNameSchema2;
            break;
            
        default:
            result = CKRecordZoneDefaultName;
            break;
    }
    
    return result;
}

- (void)createZoneIfNecessaryWithCompletion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Creating record zone if necessary");
    if (databaseScope != CDEDatabaseScopePrivate || !recordZoneID) {
        [self dispatchCompletion:completion withError:nil];
        return;
    }
    
    [self fetchRecordZoneWithCompletion:^(NSError *fetchZoneError) {
        if (fetchZoneError.code == CKErrorZoneNotFound || fetchZoneError.code == CKErrorUserDeletedZone) {
            [self createRecordZoneWithCompletion:^(NSError *createZoneError){
                [self dispatchCompletion:completion withError:createZoneError];
            }];
        }
        else {
            if (fetchZoneError) CDELog(CDELoggingLevelError, @"Error fetching zone: %@", fetchZoneError);
            [self dispatchCompletion:completion withError:fetchZoneError];
        }
    }];
}
     
- (void)fetchRecordZoneWithCompletion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Fetching record zone");
    CKFetchRecordZonesOperation *operation = [[CKFetchRecordZonesOperation alloc] initWithRecordZoneIDs:@[recordZoneID]];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.fetchRecordZonesCompletionBlock = ^(NSDictionary *zoneRecordsByID, NSError *fetchZoneError) {
        NSError *zoneError = fetchZoneError;
        if (fetchZoneError.code == CKErrorPartialFailure) {
            NSDictionary *errorsByZoneID = fetchZoneError.userInfo[CKPartialErrorsByItemIDKey];
            zoneError = errorsByZoneID[recordZoneID];
        }
        [self dispatchCompletion:completion withError:zoneError];
    };
    [self.database addOperation:operation];
}

- (void)createRecordZoneWithCompletion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Creating record zone");
    CKRecordZone *zone = [[CKRecordZone alloc] initWithZoneName:self.recordZoneName];
    CKModifyRecordZonesOperation *operation = [[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:@[zone] recordZoneIDsToDelete:nil];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.modifyRecordZonesCompletionBlock = ^(NSArray *savedRecordZones, NSArray *deletedRecordZoneIDs, NSError *error) {
        [self dispatchCompletion:completion withError:error];
    };
    [self.database addOperation:operation];
}


#pragma mark - Queries

- (CKQueryOperation *)queryOperationForQuery:(CKQuery *)query queryCursor:(CKQueryCursor *)cursor records:(NSMutableArray *)records completion:(void(^)(NSArray *records, NSError *error))completion
{
    __weak typeof (self) weakSelf = self;
    CKQueryOperation *queryOperation = nil;
    if (query) {
        queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    }
    else {
        queryOperation = [[CKQueryOperation alloc] initWithCursor:cursor];
    }
    queryOperation.qualityOfService = CDECloudKitQualityOfService;
    if (self.recordZoneID) queryOperation.zoneID = self.recordZoneID;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *childRecord) {
        typeof (self) strongSelf = weakSelf;
        if (!strongSelf) return;
        [records addObject:childRecord];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        typeof (self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (cursor) {
            CKQueryOperation *extraOperation = [strongSelf queryOperationForQuery:nil queryCursor:cursor records:records completion:completion];
            [strongSelf.database addOperation:extraOperation];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(error ? nil : records, error);
            });
        }
    };
    
    return queryOperation;
}

- (void)queryAllRecordsWithDesiredKeys:(NSArray *)keys completion:(void(^)(NSArray *records, NSError *error))completion
{
    NSMutableArray *records = [NSMutableArray array];
    CKQuery *itemQuery = [[CKQuery alloc] initWithRecordType:self.fileSystemNodeRecordType predicate:[NSPredicate predicateWithValue:YES]];
    CKQueryOperation *queryOperation = [self queryOperationForQuery:itemQuery queryCursor:nil records:records completion:^(NSArray *records, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(records, error);
        });
    }];
    queryOperation.desiredKeys = keys;
    [queryOperation addDependency:setupOperation];
    [self.database addOperation:queryOperation];
}

#pragma mark - Connection Status

- (BOOL)isConnected
{
    return self.container != nil;
}

- (void)connect:(CDECompletionBlock)completion
{
    [self setupDatabase];
    [self setupCloud:^(NSError *error) {
        [self dispatchCompletion:completion withError:error];
    }];
}

- (void)fetchUserIdentityWithCompletion:(CDEFetchUserIdentityCallback)completion
{
    CDELog(CDELoggingLevelTrace, @"Fetching user identity from CloudKit");
    
    CKFetchRecordsOperation *userFetchOperation = [CKFetchRecordsOperation fetchCurrentUserRecordOperation];
    userFetchOperation.qualityOfService = CDECloudKitQualityOfService;
    userFetchOperation.perRecordCompletionBlock = ^(CKRecord *record, CKRecordID *recordID, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error.code == CKErrorNotAuthenticated) {
                if (completion) completion(nil, nil);
            }
            else {
                if (completion) completion(recordID, error);
            }
        });
    };
    // No dependency on setup here
    [self.container.privateCloudDatabase addOperation:userFetchOperation];
}

#pragma mark - Priming for activity

- (void)primeForActivityWithCompletion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Priming CloudKit cache");

    if (!self.recordZoneID) {
        [self clearInMemoryCache];
        [self dispatchCompletion:completion withError:nil];
        return;
    }
    
    [self createShareAndRootDirectoryIfNecessaryWithCompletion:^(NSError *error, BOOL shareOrRootChanged) {
        if (error) {
            [self dispatchCompletion:completion withError:error];
            return;
        }
        
        [self continuePrimingWithCompletion:completion];
    }];
}

- (void)continuePrimingWithCompletion:(CDECompletionBlock)completion {
    
    if (serverChangeToken == nil) {
        recordsByFullPath = [[NSMutableDictionary alloc] init];
        contentsByDirectoryPath = [[NSMutableDictionary alloc] init];
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CDELog(CDELoggingLevelVerbose, @"Beginning change processing for CloudKit.");
    CKFetchRecordChangesOperation *changesOperation = [[CKFetchRecordChangesOperation alloc] initWithRecordZoneID:self.recordZoneID previousServerChangeToken:serverChangeToken];
    __weak typeof(changesOperation) weakChangesOperation = changesOperation;
    changesOperation.qualityOfService = CDECloudKitQualityOfService;
    changesOperation.desiredKeys = @[@"isDirectory", @"fileSize", @"path"];
#pragma clang diagnostic pop

    changesOperation.recordChangedBlock = ^(CKRecord *record) {
        if (![record.recordType isEqualToString:self.fileSystemNodeRecordType]) return;
        if (![record.recordID.recordName hasPrefix:self.recordIDPrefix]) return;
        
        NSString *fullPath = [self fullPathFromRecordID:record.recordID];
        if (!fullPath) {
            CDELog(CDELoggingLevelError, @"Got a record with no path: %@", record);
            return;
        }
        
        recordsByFullPath[fullPath] = record;

        id <CDECloudItem> item = [self itemForRecord:record];
        if (item.canContainChildren) {
            NSMutableDictionary *contents = contentsByDirectoryPath[fullPath];
            if (!contents) {
                contents = [[NSMutableDictionary alloc] init];
                contentsByDirectoryPath[fullPath] = contents;
            }
        }
        
        NSString *parentDirPath = [fullPath stringByDeletingLastPathComponent];
        if (item && fullPath.length > 1) {
            NSMutableDictionary *contents = contentsByDirectoryPath[parentDirPath];
            if (!contents) {
                contents = [[NSMutableDictionary alloc] init];
                contentsByDirectoryPath[parentDirPath] = contents;
            }
            contents[fullPath] = item;
        }
        
        CDELog(CDELoggingLevelVerbose, @"Processed cloudkit change (insert/update): %@", fullPath);
    };
    
    changesOperation.recordWithIDWasDeletedBlock = ^(CKRecordID *recordID) {
        if (![recordID.recordName hasPrefix:self.recordIDPrefix]) return;
        NSString *fullPath = [self fullPathFromRecordID:recordID];
        NSString *directoryPath = [fullPath stringByDeletingLastPathComponent];
        NSMutableDictionary *contents = contentsByDirectoryPath[directoryPath];
        [contents removeObjectForKey:fullPath];
        [recordsByFullPath removeObjectForKey:fullPath];
        CDELog(CDELoggingLevelVerbose, @"Processed cloudkit deletion: %@", fullPath);
    };

    
    changesOperation.fetchRecordChangesCompletionBlock = ^(CKServerChangeToken *serverToken, NSData *clientTokenData, NSError *error) {
        CDELog(CDELoggingLevelVerbose, @"Completing CloudKit fetch record changes");

        typeof(changesOperation) strongChangesOperation = weakChangesOperation;
        
        if (error) {
            if (serverChangeToken == nil) {
                [self dispatchCompletion:completion withError:error];
            }
            else {
                // Try a complete refetch
                [self clearInMemoryCache];
                [self primeForActivityWithCompletion:completion];
            }
            return;
        }
        
        id oldToken = serverChangeToken;
        serverChangeToken = [serverToken copy];
        if ( ![serverChangeToken isEqual:oldToken] ) {
            [self storeCacheToDisk];
        }
        
        if (strongChangesOperation.moreComing) {
            CDELog(CDELoggingLevelVerbose, @"More changes coming...");
            [self continuePrimingWithCompletion:completion];
            return;
        }
        
        [self dispatchCompletion:completion withError:nil];
    };
    
    [changesOperation addDependency:setupOperation];
    [self.database addOperation:changesOperation];
}

#pragma mark - Cache

- (void)clearInMemoryCache
{
    serverChangeToken = nil;
    recordsByFullPath = nil;
    contentsByDirectoryPath = nil;
}

- (NSString *)cacheFilename
{
    NSData *recordIDData = [NSKeyedArchiver archivedDataWithRootObject:recordZoneID];
    NSString *filename = [recordIDData.cde_md5Checksum stringByAppendingPathExtension:@"cdecloudkitcache.v2"];
    return filename;
}

- (NSURL *)cacheURL {
    NSURL *cacheDirURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
    NSURL *cacheURL = [cacheDirURL URLByAppendingPathComponent:self.cacheFilename];
    return cacheURL;
}

- (void)prepareCache
{
    // Attempt to read in stored data
    NSURL *cacheURL = self.cacheURL;
    NSDictionary *cache = nil;
    @try {
        cache = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheURL.path];
    }
    @catch (NSException *exception) {
        CDELog(CDELoggingLevelError, @"Failed to read in cached data. Resetting cache.");
        [[NSFileManager defaultManager] removeItemAtURL:cacheURL error:NULL];
    }
    
    contentsByDirectoryPath = cache[@"contentsByDirectoryPath"];
    recordsByFullPath = cache[@"recordsByFullPath"];
    serverChangeToken = cache[@"serverChangeToken"];
    
    if (!(contentsByDirectoryPath && recordsByFullPath && serverChangeToken)) {
        [self clearInMemoryCache];
    }
}

- (void)storeCacheToDisk
{
    if (!(contentsByDirectoryPath && recordsByFullPath && serverChangeToken)) return;
    NSDictionary *cache = @{@"contentsByDirectoryPath" : contentsByDirectoryPath, @"recordsByFullPath" : recordsByFullPath, @"serverChangeToken" : serverChangeToken};
    [NSKeyedArchiver archiveRootObject:cache toFile:self.cacheURL.path];
}

#pragma mark - Fetching Records

// Can return partial failure errors, and NSNull for unfound records
- (void)fetchRecordsAtPaths:(NSArray *)paths completion:(void(^)(NSArray *records, NSError *error))completion
{
    CDELog(CDELoggingLevelTrace, @"Retrieving records for paths: %@", paths);
    
    if (!self.database) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, [self noConnectionError]);
        });
        return;
    }
    
    if (recordsByFullPath) {
        NSArray *records = [paths cde_arrayByTransformingObjectsWithBlock:^(NSString *path) {
            if (path == (id)[NSNull null]) return (id)[NSNull null];
            NSString *fullPath = [self fullPathForPath:path];
            CKRecord *record = recordsByFullPath[fullPath];
            return (id)record ? : (id)[NSNull null];
        }];
        if (completion) completion(records, nil);
        return;
    }
    
    NSArray *recordIDs = [paths cde_arrayByTransformingObjectsWithBlock:^(NSString *path) {
        return [self recordIDForPath:path];
    }];
    
    CKFetchRecordsOperation *operation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.desiredKeys = @[@"isDirectory", @"fileSize", @"path"];
    operation.fetchRecordsCompletionBlock = ^(NSDictionary *recordsByRecordID, NSError *error) {
        NSArray *records = [recordIDs cde_arrayByTransformingObjectsWithBlock:^(CKRecordID *recordID) {
            return recordsByRecordID[recordID] ? : [NSNull null];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(records, error);
        });
    };
    [operation addDependency:setupOperation];
    [self.database addOperation:operation];
}

// Recursively searches for paths
- (void)fetchRecordsDescendedFromPaths:(NSArray *)paths completion:(void(^)(NSArray *records, NSError *error))completion
{
    NSMutableSet *foundRecords = [[NSMutableSet alloc] init];
    [self fetchRecordsAtPaths:paths completion:^(NSArray *records, NSError *error) {
        NSError *localError = error;
        if (localError) {
            BOOL unknownItemError = [self.class partialError:localError onlyIncludesErrorCode:CKErrorUnknownItem];
            if (unknownItemError) localError = nil; // Ignore. A missing record is OK
        }
        
        if (localError) {
            if (completion) completion(nil, localError);
            return;
        }
        
        NSMutableArray *recordsWithoutNull = [records mutableCopy];
        [recordsWithoutNull removeObject:[NSNull null]];
        [foundRecords addObjectsFromArray:recordsWithoutNull];
        
        NSArray *dirRecords = [recordsWithoutNull cde_arrayByFilteringWithBlock:^(CKRecord *record) {
            return [record[@"isDirectory"] boolValue];
        }];
        
        if (dirRecords.count == 0) {
            if (completion) completion(foundRecords.allObjects, nil);
        }
        else {
            // Recurse
            __block NSError *lastError = nil;
            dispatch_group_t group  = dispatch_group_create();
            NSMutableArray *subItems = [[NSMutableArray alloc] init];
            
            // Enter the group for each record
            for (NSUInteger i = 0; i < dirRecords.count; i++) {
                dispatch_group_enter(group);
            }
            
            // Get contents of each directory
            for (CKRecord *dirRecord in dirRecords) {
                NSString *dirPath = dirRecord[@"path"];
                
                // Remove the root from the path, since contentsOfDirectoryAtPath will add it
                if ([dirPath hasPrefix:self.rootDirectory]) {
                    dirPath = [dirPath substringFromIndex:self.rootDirectory.length];
                }
                
                [self contentsOfDirectoryAtPath:dirPath completion:^(NSArray *contents, NSError *error) {
                    if (error) lastError = error;
                    if (contents) [subItems addObjectsFromArray:contents];
                    
                    // Leave group
                    dispatch_group_leave(group);
               }];
            }
            
            // When all is done, process results.
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                if (lastError) {
                    if (completion) completion(nil, lastError);
                    return;
                }
                
                NSArray *subpaths = [subItems valueForKeyPath:@"path"];
                [self fetchRecordsDescendedFromPaths:subpaths completion:^(NSArray *records, NSError *error) {
                    if (error) {
                        if (completion) completion(nil, error);
                        return;
                    }
                    
                    [foundRecords addObjectsFromArray:records];
                    if (completion) completion(foundRecords.allObjects, nil);
                }];
            });
        }
    }];
}

#pragma mark - Records and Paths

- (NSString *)recordIDPrefix
{
    return schemaVersion == CDECloudKitSchemaVersion1 ? @"" : @"CDEFileSystemNode_";
}

- (NSString *)fileSystemNodeRecordType
{
    return schemaVersion == CDECloudKitSchemaVersion1 ? @"CDEItem" : @"CDEFileSystemNode";
}

- (NSString *)fullPathForPath:(NSString *)path
{
    if ([path hasPrefix:@"/"]) path = [path substringFromIndex:1];
    return [self.rootDirectory stringByAppendingString:path];
}

- (CKRecordID *)recordIDForFullPath:(NSString *)recordName
{
    recordName = [self.recordIDPrefix stringByAppendingString:recordName];
    if (recordZoneID) {
        return [[CKRecordID alloc] initWithRecordName:recordName zoneID:recordZoneID];
    }
    else {
        return [[CKRecordID alloc] initWithRecordName:recordName];
    }
}

- (CKRecordID *)recordIDForPath:(NSString *)path {
    return [self recordIDForFullPath:[self fullPathForPath:path]];
}

- (NSString *)fullPathFromRecordID:(CKRecordID *)recordID
{
    NSString *fullPath = recordID.recordName;
    NSUInteger prefixLength = self.recordIDPrefix.length;
    return [fullPath substringFromIndex:prefixLength];
}

#pragma mark - File Handling

- (void)fileExistsAtPath:(NSString *)path completion:(CDEFileExistenceCallback)completion
{
    CDELog(CDELoggingLevelTrace, @"Checking existence of file: %@", path);
    
    [self fetchRecordsAtPaths:@[path] completion:^(NSArray *records, NSError *error) {
        CKRecord *record = CDENSNullToNil(records.lastObject);
        NSError *localError = error;
        
        if (localError && localError.code == CKErrorPartialFailure) {
            BOOL unknownItemError = [self.class partialError:localError onlyIncludesErrorCode:CKErrorUnknownItem];
            if (unknownItemError) localError = nil; // Ignore. A missing record is a valid result
        }
        
        if (localError) {
            if (completion) completion(NO, NO, localError);
            return;
        }
        
        if (record) {
            CDELog(CDELoggingLevelVerbose, @"File exists. Is dir? %@", [record valueForKey:@"isDirectory"]);
            if (completion) completion(YES, [[record valueForKey:@"isDirectory"] boolValue], nil);
        }
        else {
            CDELog(CDELoggingLevelVerbose, @"File doesn't exist");
            if (completion) completion(NO, NO, nil);
        }
    }];
}

- (id)itemForRecord:(CKRecord *)record
{
    NSString *fullPath = [self fullPathFromRecordID:record.recordID];
    NSUInteger rootLength = self.rootDirectory.length;
    id item;
    NSString *name = fullPath.lastPathComponent;
    NSString *path = [fullPath substringFromIndex:rootLength];
    if ([[record valueForKey:@"isDirectory"] boolValue]) {
        CDECloudDirectory *dir = [[CDECloudDirectory alloc] init];
        dir.name = name;
        dir.path = path;
        item = dir;
    }
    else {
        CDECloudFile *file = [[CDECloudFile alloc] init];
        file.name = name;
        file.path = path;
        file.size = [[record valueForKey:@"fileSize"] unsignedLongLongValue];
        item = file;
    }
    return item;
}

#pragma mark - Working with Directories

- (void)contentsOfDirectoryAtPath:(NSString *)path completion:(CDEDirectoryContentsCallback)completion
{
    CDELog(CDELoggingLevelTrace, @"Getting contents of directory at path: %@", path);

    if (!self.database) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, [self noConnectionError]);
        });
        return;
    }
    
    NSString *fullPath = [self fullPathForPath:path];
    if (contentsByDirectoryPath) {
        NSMutableDictionary *contents = contentsByDirectoryPath[fullPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            if (!contents) {
                error = [NSError errorWithDomain:CDEErrorDomain code:CDEErrorCodeDirectoryDoeNotExist userInfo:nil];
            }
            if (completion) completion(contents.allValues, error);
        });
        return;
    }
    
    CKRecordID *dirRecordID = [self recordIDForFullPath:fullPath];
    CKReference *dirReference = [[CKReference alloc] initWithRecordID:dirRecordID action:CKReferenceActionNone];
    
    __weak typeof(self) weakSelf = self;
    NSMutableArray *records = [NSMutableArray array];
    CKQuery *childQuery = [[CKQuery alloc] initWithRecordType:self.fileSystemNodeRecordType predicate:[NSPredicate predicateWithFormat:@"directory = %@", dirReference]];
    childQuery.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]];
    CKQueryOperation *queryOperation = [self queryOperationForQuery:childQuery queryCursor:nil records:records completion:^(NSArray *records, NSError *error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        NSArray *contents = [records cde_arrayByTransformingObjectsWithBlock:^(CKRecord *record) {
            return [strongSelf itemForRecord:record];
        }];
        if (completion) completion(contents, error);
    }];
    queryOperation.desiredKeys = @[@"isDirectory", @"fileSize"];
    [queryOperation addDependency:setupOperation];
    [self.database addOperation:queryOperation];
}

- (void)createRootDirectoryIfNecessaryWithCompletion:(void (^)(NSError *error, CKRecord *rootRecord))completion
{
    CDELog(CDELoggingLevelTrace, @"Creating root directory if necessary");

    if (!self.database) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion([self noConnectionError], nil);
        });
        return;
    }
    
    CKRecordID *dirRecordID = [self recordIDForPath:@"/"];
    
    CKFetchRecordsOperation *operation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[dirRecordID]];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.fetchRecordsCompletionBlock = ^(NSDictionary *recordsByRecordID, NSError *error) {
        CKRecord *rootRecord = recordsByRecordID[dirRecordID];
        if ((error && error.code != CKErrorPartialFailure) || rootRecord) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(rootRecord ? nil : error, rootRecord);
            });
            return;
        }
        
        // Create new record
        CKRecord *record = [self createRootRecord];

        CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
        operation.qualityOfService = CDECloudKitQualityOfService;
        operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecords, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(error, savedRecords.lastObject);
            });
        };
        [self.database addOperation:operation];
    };
    
    // This is part of setup, so no dependency on setup (otherwise deadlock)
    [self.database addOperation:operation];
}

- (CKRecord *)createRootRecord {
    CKRecordID *dirRecordID = [self recordIDForPath:@"/"];
    CKRecord *record = [[CKRecord alloc] initWithRecordType:self.fileSystemNodeRecordType recordID:dirRecordID];
    [record setValue:@YES forKey:@"isDirectory"];
    [record setValue:self.rootDirectory forKey:@"path"];
    return record;
}

- (void)createDirectoryAtPath:(NSString *)path completion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Creating directory at path: %@", path);

    if (!self.database) {
        [self dispatchCompletion:completion withError:[self noConnectionError]];
        return;
    }
    
    NSString *fullPath = [self fullPathForPath:path];
    NSString *parentDirPath = [fullPath stringByDeletingLastPathComponent];
    CKRecordID *parentDirRecordID = [self recordIDForFullPath:parentDirPath];
    CKReference *dirReference = [[CKReference alloc] initWithRecordID:parentDirRecordID action:CKReferenceActionDeleteSelf];
    
    CKRecordID *recordID = [self recordIDForFullPath:fullPath];
    CKRecord *record = [[CKRecord alloc] initWithRecordType:self.fileSystemNodeRecordType recordID:recordID];
    [record setValue:@YES forKey:@"isDirectory"];
    [record setValue:dirReference forKey:@"directory"];
    [record setValue:fullPath forKey:@"path"];
    
    if (sharingIdentifier) {
        CKReference *parentRef = [[CKReference alloc] initWithRecordID:parentDirRecordID action:CKReferenceActionNone];
        record.parent = parentRef;
    }
    
    CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[record] recordIDsToDelete:nil];
    operation.qualityOfService = CDECloudKitQualityOfService;
    [operation addDependency:setupOperation];
    operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecords, NSError *error) {
        [self dispatchCompletion:completion withError:error];
    };
    
    [operation addDependency:setupOperation];
    [self.database addOperation:operation];
}

#pragma mark - Transfer of Files

- (NSUInteger)fileUploadMaximumBatchSize
{
    return 30;
}

- (void)uploadLocalFile:(NSString *)fromPath toPath:(NSString *)toPath completion:(CDECompletionBlock)completion
{
    [self uploadLocalFiles:@[fromPath] toPaths:@[toPath] completion:completion];
}

- (void)uploadLocalFiles:(NSArray *)fromPaths toPaths:(NSArray *)toPaths completion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Uploading from paths %@ to paths %@", fromPaths, toPaths);
    
    if (!self.database) {
        [self dispatchCompletion:completion withError:[self noConnectionError]];
        return;
    }
    
    NSMutableArray *records = [[NSMutableArray alloc] init];
    [fromPaths enumerateObjectsUsingBlock:^(NSString *fromPath, NSUInteger idx, BOOL *stop) {
        NSString *toPath = toPaths[idx];
        
        NSString *filePath = [self fullPathForPath:toPath];
        NSString *dirPath = [filePath stringByDeletingLastPathComponent];
        CKRecordID *dirRecordID = [self recordIDForFullPath:dirPath];
        CKReference *dirReference = [[CKReference alloc] initWithRecordID:dirRecordID action:CKReferenceActionNone];
        
        NSError *error = nil;
        NSURL *fromURL = [NSURL fileURLWithPath:fromPath];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:fromPath error:&error];
        if (!fileAttributes) {
            [self dispatchCompletion:completion withError:error];
            *stop = YES;
            return;
        }
        
        CKRecordID *fileRecordID = [self recordIDForFullPath:filePath];
        CKRecord *fileRecord = [[CKRecord alloc] initWithRecordType:self.fileSystemNodeRecordType recordID:fileRecordID];
        [fileRecord setValue:@NO forKey:@"isDirectory"];
        [fileRecord setValue:dirReference forKey:@"directory"];
        [fileRecord setValue:filePath forKey:@"path"];
        [fileRecord setValue:@(fileAttributes.fileSize) forKey:@"fileSize"];
        
        if (sharingIdentifier) {
            fileRecord.parent = dirReference;
        }
        
        CKAsset *asset = [[CKAsset alloc] initWithFileURL:fromURL];
        switch (schemaVersion) {
            case CDECloudKitSchemaVersion1:
            {
                NSString *dataFileIDString = [NSString stringWithFormat:@"DataFile_%@", filePath];
                CKRecordID *datafileID = [self recordIDForFullPath:dataFileIDString];
                CKRecord *mediaRecord = [[CKRecord alloc] initWithRecordType:@"CDEDataFile" recordID:datafileID];
                CKReference *fileRef = [[CKReference alloc] initWithRecord:fileRecord action:CKReferenceActionNone];
                [mediaRecord setValue:fileRef forKey:@"file"];
                [mediaRecord setValue:asset forKey:@"data"];
                [records addObject:fileRecord];
                [records addObject:mediaRecord];
            }
                break;
            case CDECloudKitSchemaVersion2:
                [fileRecord setValue:asset forKey:@"data"];
                [records addObject:fileRecord];
                break;
                
            default:
                CDELog(CDELoggingLevelError, @"Invalid schema");
                break;
        }
    }];
    
    CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:records recordIDsToDelete:nil];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecords, NSError *error) {
        // Ignore errors for already existing data. This can arise if the CloudKit queries are not
        // fully up-to-date due to caching and other server-side details
        if (error.code == CKErrorPartialFailure) {
            BOOL allErrorsAreDueToExistingObjects = [self.class partialError:error onlyIncludesErrorCode:CKErrorServerRecordChanged];
            if (allErrorsAreDueToExistingObjects) {
                CDELog(CDELoggingLevelWarning, @"Some records failed to upload due to existing items. Usually due to out-of-date query caching on CloudKit. Will self correct. Ignoring: %@", error);
                error = nil;
            }
        }
        
        [self dispatchCompletion:completion withError:error];
    };
    
    [operation addDependency:setupOperation];
    [self.database addOperation:operation];
}

- (NSUInteger)fileDownloadMaximumBatchSize
{
    return 30;
}

- (void)downloadFromPath:(NSString *)fromPath toLocalFile:(NSString *)toPath completion:(CDECompletionBlock)completion
{
    [self downloadFromPaths:@[fromPath] toLocalFiles:@[toPath] completion:completion];
}

- (void)downloadFromPaths:(NSArray *)fromPaths toLocalFiles:(NSArray *)toPaths completion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Downloading from paths %@ to path %@", fromPaths, toPaths);

    if (!self.database) {
        [self dispatchCompletion:completion withError:[self noConnectionError]];
        return;
    }
    
    NSMutableArray *recordIDs = [[NSMutableArray alloc] init];
    NSMutableDictionary *toPathsByRecordID = [[NSMutableDictionary alloc] init];
    [fromPaths enumerateObjectsUsingBlock:^(NSString *fromPath, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [self fullPathForPath:fromPath];
        NSString *toPath = toPaths[idx];
        BOOL firstSchema = (schemaVersion == CDECloudKitSchemaVersion1);
        NSString *dataFileIDString = firstSchema ? [@"DataFile_" stringByAppendingString:filePath] : filePath;
        CKRecordID *dataFileID = [self recordIDForFullPath:dataFileIDString];
        [recordIDs addObject:dataFileID];
        toPathsByRecordID[dataFileID] = toPath;
    }];
    
    CKFetchRecordsOperation *operation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.desiredKeys = @[@"data"];
    operation.fetchRecordsCompletionBlock = ^(NSDictionary *recordsByRecordID, NSError *error) {
        if (error) {
            [self performRepairsIfNecessaryForError:error];
            [self dispatchCompletion:completion withError:error];
            return;
        }
        
        BOOL success = YES;
        NSError *copyError = nil;
        NSFileManager *fm = [[NSFileManager alloc] init];
        for (CKRecordID *dataFileID in recordsByRecordID) {
            CKRecord *dataFileRecord = recordsByRecordID[dataFileID];
            CKAsset *asset = [dataFileRecord valueForKey:@"data"];
            
            success = [fm copyItemAtURL:asset.fileURL toURL:[NSURL fileURLWithPath:toPathsByRecordID[dataFileID]] error:&copyError];
            if (!success) break;
        }
        
        [self dispatchCompletion:completion withError:(success ? nil : copyError)];
    };
    
    [operation addDependency:setupOperation];
    [self.database addOperation:operation];
}

#pragma mark - Removal of Files

- (void)removeItemAtPath:(NSString *)path completion:(CDECompletionBlock)completion
{
    [self removeItemsAtPaths:@[path] completion:completion];
}

- (void)removeItemsAtPaths:(NSArray *)paths completion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Removing items at paths: %@", paths);
    
    [self fetchRecordsDescendedFromPaths:paths completion:^(NSArray *records, NSError *error) {
        CDELog(CDELoggingLevelVerbose, @"Fetched records for removal: %@", records);

        if (error) {
            CDELog(CDELoggingLevelError, @"Error while fetching for deletion: %@", error);
            if (completion) completion(error);
            return;
        }
        
        // Sort records so files are deleted first, then directories
        // This will hopefully make it less of a problem if it fails halfway.
        records = [records sortedArrayUsingComparator:^(CKRecord *r1, CKRecord *r2) {
            NSUInteger w1 = ([r1[@"isDirectory"] boolValue] ? 1 : 0);
            NSUInteger w2 = ([r2[@"isDirectory"] boolValue] ? 1 : 0);
            return [@(w1) compare:@(w2)];
        }];
        
        NSArray *recordIDs = [records valueForKeyPath:@"recordID"];
        [self removeItemsWithRecordIDs:recordIDs completion:completion];
    }];
}

- (void)removeItemsWithRecordIDs:(NSArray *)recordIDs completion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelVerbose, @"Removing items with recordIDs: %@", recordIDs);

    // Handle in batches, because CloudKit will error at about 400 items
    NSMutableArray *tasks = [[NSMutableArray alloc] init];
    [recordIDs cde_enumerateObjectsInBatchesWithBatchSize:200 usingBlock:^(NSArray *batchRecordIDs, NSUInteger batchesRemaining, BOOL *stop) {
        CDEAsynchronousTaskBlock task = ^(CDEAsynchronousTaskCallbackBlock next) {
            CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:batchRecordIDs];
            operation.qualityOfService = CDECloudKitQualityOfService;
            operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecords, NSError *error) {
                // Ignore errors for already removed data. This can arise if the CloudKit queries are not
                // fully up-to-date due to caching and other server-side details
                if (error.code == CKErrorPartialFailure) {
                    BOOL errorsAreDueToAlreadyRemovedItems = [self.class partialError:error onlyIncludesErrorCode:CKErrorServerRecordChanged];
                    if (errorsAreDueToAlreadyRemovedItems) {
                        CDELog(CDELoggingLevelWarning, @"Some records failed to be removed. Usually due to out-of-date query caching or other devices removing items. Will self correct. Ignoring: %@", error);
                        error = nil; // Ignore
                    }
                }
                
                next(error, NO);
            };
            [self.database addOperation:operation];
        };
        [tasks addObject:task];
    }];
    CDEAsynchronousTaskQueue *taskQueue = [[CDEAsynchronousTaskQueue alloc] initWithTasks:tasks completion:completion];
    [taskQueue addDependency:setupOperation];
    [operationQueue addOperation:taskQueue];
}

- (void)removeAllItemsWithCompletion:(CDECompletionBlock)completion
{
    CDELog(CDELoggingLevelTrace, @"Deleting all cloudkit data");
    
    if (!self.database) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion([self noConnectionError]);
        });
        return;
    }
    
    // For some reason, CloudKit queries sometimes fail to find all records. Probably server side bug.
    // So we first prime, and remove any found records using the fetch changes. Then we will use a query as backup.
    CDEAsynchronousTaskBlock fetchChangesTask = ^(CDEAsynchronousTaskCallbackBlock next) {
        [self primeForActivityWithCompletion:^(NSError *error) {
            if (error) {
                CDELog(CDELoggingLevelError, @"Error while priming for deletion: %@", error);
                next(error, NO);
                return;
            }
            
            NSArray *recordIDs = [recordsByFullPath.allValues valueForKeyPath:@"recordID"] ? : @[];
            [self removeItemsWithRecordIDs:recordIDs completion:^(NSError *error) {
                next(error, NO);
            }];
        }];
    };
    
    // Task to remove all records matching a query
    CDEAsynchronousTaskBlock queryTask = ^(CDEAsynchronousTaskCallbackBlock next) {
        [self queryAllRecordsWithDesiredKeys:@[] completion:^(NSArray *records, NSError *error) {
            if (error) {
                CDELog(CDELoggingLevelError, @"Error while querying records for deletion: %@", error);
                next(error, NO);
                return;
            }
            
            NSArray *recordIDs = [records valueForKeyPath:@"recordID"];
            [self removeItemsWithRecordIDs:recordIDs completion:^(NSError *error) {
                next(error, NO);
            }];
        }];
    };
    
    CDEAsynchronousTaskQueue *tasksQueue = [[CDEAsynchronousTaskQueue alloc] initWithTasks:@[fetchChangesTask, queryTask] completion:^(NSError *error) {
        if (error) CDELog(CDELoggingLevelError, @"Error while removing all itemsfetchChangesTask: %@", error);
        [self dispatchCompletion:completion withError:error];
    }];
    [tasksQueue start];
}

#pragma mark - Error Handling

- (void)performRepairsIfNecessaryForError:(NSError *)error
{
    if (error.code != CKErrorPartialFailure) return;
    
    NSDictionary *errorsByRecordID = error.userInfo[CKPartialErrorsByItemIDKey];
    NSMutableArray *recordIDsForRemoval = [[NSMutableArray alloc] init];
    [errorsByRecordID enumerateKeysAndObjectsUsingBlock:^(CKRecordID *recordID, NSError *recordError, BOOL *stop) {
        static NSString * const dataFilePrefix = @"DataFile_";
        if ([recordID.recordName hasPrefix:dataFilePrefix] && (recordError.code == CKErrorUnknownItem)) {
            NSString *itemIDString = [recordID.recordName substringFromIndex:dataFilePrefix.length];
            CKRecordID *itemRecordID = [self recordIDForFullPath:itemIDString];
            [recordIDsForRemoval addObject:itemRecordID];
        }
        else if ([recordID.recordName hasPrefix:@"CDEFileSystemNode_"]) {
            [recordIDsForRemoval addObject:recordID];
        }
    }];
    
    if (recordIDsForRemoval.count == 0) return;
    
    CDELog(CDELoggingLevelWarning, @"Located some items in CloudKit without data. Removing: %@", recordIDsForRemoval);
    
    CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:recordIDsForRemoval];
    operation.qualityOfService = CDECloudKitQualityOfService;
    operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecords, NSError *error) {
        if (error) {
            CDELog(CDELoggingLevelError, @"Error occurred while removing items without data in CloudKit: %@", error);
        }
        else {
            CDELog(CDELoggingLevelError, @"Deleted records with no data attached: %@", deletedRecords);
        }
    };
    
    [operation addDependency:setupOperation];
    [self.database addOperation:operation];
}

+ (BOOL)partialError:(NSError *)error onlyIncludesErrorCode:(NSInteger)code
{
    BOOL allErrorsAreDueToExistingObjects = YES;
    NSDictionary *errorsByItemID = error.userInfo[CKPartialErrorsByItemIDKey];
    for (NSError *error in errorsByItemID.objectEnumerator) {
        if (error.code != code) allErrorsAreDueToExistingObjects = NO;
    }
    return allErrorsAreDueToExistingObjects;
}

#pragma mark - Completion

- (void)dispatchCompletion:(CDECompletionBlock)completion withError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(error);
    });
}

@end
