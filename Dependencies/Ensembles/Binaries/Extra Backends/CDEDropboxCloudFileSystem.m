//
//  CDEDropboxCloudFileSystem.m
//
//  Created by Drew McCormack on 4/12/13.
//  Copyright (c) 2013 The Mental Faculty B.V. All rights reserved.
//

#import "CDEDropboxCloudFileSystem.h"

#if TARGET_OS_IPHONE
#import "DropboxSDK.h"
#else
#import <DropboxOSX/DropboxOSX.h>
#endif


static const NSUInteger kCDENumberOfRetriesForFailedAttempt = 5;
static const NSUInteger kCDEMaximumConcurrentRequests = 4;
static const NSUInteger kCDEMaximumConcurrentDeletions = 10;


#pragma mark - File Operations

@interface CDEDropboxOperation : CDEAsynchronousOperation <DBRestClientDelegate>

@property (readonly) DBSession *session;
@property (readonly) DBRestClient *restClient;

- (id)initWithSession:(DBSession *)newSession;

- (void)prepareForNetworkRequests;
- (void)initiateNetworkRequest; // Abstract
- (void)completeWithError:(NSError *)error; // Abstract

@end

@interface CDEDropboxFileExistenceOperation : CDEDropboxOperation

@property (readonly) NSString *path;
@property (readonly) CDEFileExistenceCallback fileExistenceCallback;

- (id)initWithSession:(DBSession *)newSession path:(NSString *)newPath fileExistenceCallback:(CDEFileExistenceCallback)callback;

@end

@interface CDEDropboxDirectoryContentsOperation : CDEDropboxOperation

@property (readonly) NSString *path;
@property (readonly) CDEDirectoryContentsCallback directoryContentsCallback;

- (id)initWithSession:(DBSession *)newSession path:(NSString *)newPath dataFilesArePartitioned:(BOOL)partitioned directoryContentsCallback:(CDEDirectoryContentsCallback)newCallback;

@end

@interface CDEDropboxCreateDirectoryOperation : CDEDropboxOperation

@property (readonly) NSString *path;
@property (readonly) CDECompletionBlock completionCallback;

- (id)initWithSession:(DBSession *)newSession path:(NSString *)newPath completionCallback:(CDECompletionBlock)block;

@end

@interface CDEDropboxRemoveOperation : CDEDropboxOperation

@property (readonly) NSArray *paths;
@property (readonly) CDECompletionBlock completionCallback;

- (id)initWithSession:(DBSession *)newSession paths:(NSArray *)newPaths completionCallback:(CDECompletionBlock)block;

@end

@interface CDEDropboxUploadOperation : CDEDropboxOperation

@property (readonly) NSArray *localPaths, *toPaths;
@property (readonly) CDECompletionBlock completionCallback;

- (id)initWithSession:(DBSession *)newSession localPaths:(NSArray *)newLocalPaths toPaths:(NSArray *)newToPaths completionCallback:(CDECompletionBlock)block;

@end

@interface CDEDropboxDownloadOperation : CDEDropboxOperation

@property (readonly) NSArray *localPaths, *fromPaths;
@property (readonly) CDECompletionBlock completionCallback;

- (id)initWithSession:(DBSession *)newSession fromPaths:(NSArray *)fromPath localPaths:(NSArray *)newLocalPath completionCallback:(CDECompletionBlock)block;

@end


#pragma mark - Main Class

@interface CDEDropboxCloudFileSystem () <DBRestClientDelegate>
@end


@implementation CDEDropboxCloudFileSystem {
    NSOperationQueue *queue;
}

@synthesize session;
@synthesize fileDownloadMaximumBatchSize, fileUploadMaximumBatchSize;

- (instancetype)initWithSession:(DBSession *)newSession
{
    self = [super init];
    if (self) {
        fileUploadMaximumBatchSize = 1;
        fileDownloadMaximumBatchSize = 1;
        session = newSession;
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        if ([queue respondsToSelector:@selector(setQualityOfService:)]) {
            [queue setQualityOfService:NSQualityOfServiceUserInitiated];
        }
    }
    return self;
}

- (void)dealloc
{
    [queue cancelAllOperations];
}


#pragma mark Paths

- (void)setRelativePathToRootInDropbox:(NSString *)newPath
{
    if ([newPath hasPrefix:@"/"]) {
        _relativePathToRootInDropbox = newPath;
    }
    else {
        _relativePathToRootInDropbox = [@"/" stringByAppendingString:newPath];
    }
}

- (NSString *)pathIncludingSubfolderForFilePath:(NSString *)path
{
    NSString *newPath = path;
    
    // Check if path ends with a GUID (32 characters) and located under the 'data' folder
    NSString *dirName = [[path stringByDeletingLastPathComponent] lastPathComponent];
    BOOL isInData = [dirName isEqualToString:@"data"];
    if (path.lastPathComponent.length == 32 && isInData) {
        NSString *guid = path.lastPathComponent;
        NSString *dataSubFolder = [guid substringToIndex:2];
        NSString *dataDir = [path stringByDeletingLastPathComponent];
        NSString *subDir = [dataDir stringByAppendingPathComponent:dataSubFolder];
        newPath = [subDir stringByAppendingPathComponent:guid];
    }
    
    return newPath;
}

- (NSString *)fullDropboxPathForPath:(NSString *)path
{
    if (self.relativePathToRootInDropbox) {
        path = [self.relativePathToRootInDropbox stringByAppendingPathComponent:path];
    }
    
    if (self.partitionDataFilesBetweenSubdirectories) {
        path = [self pathIncludingSubfolderForFilePath:path];
    }
    
    return path;
}

- (NSArray *)fullDropboxPathsForPaths:(NSArray *)paths
{
    if (self.relativePathToRootInDropbox) {
        paths = [paths cde_arrayByTransformingObjectsWithBlock:^(NSString *path) {
            return [self fullDropboxPathForPath:path];
        }];
    }
    return paths;
}


#pragma mark Connecting

- (BOOL)isConnected
{
    return self.session.isLinked;
}

- (void)connect:(CDECompletionBlock)completion
{
    if (self.isConnected) {
        if (completion) completion(nil);
    }
    else if ([self.delegate respondsToSelector:@selector(linkSessionForDropboxCloudFileSystem:completion:)]) {
        [self.delegate linkSessionForDropboxCloudFileSystem:self completion:completion];
    }
    else {
        NSError *error = [NSError errorWithDomain:CDEErrorDomain code:CDEErrorCodeConnectionError userInfo:nil];
        if (completion) completion(error);
    }
}


#pragma mark User Identity

- (void)fetchUserIdentityWithCompletion:(CDEFetchUserIdentityCallback)completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        id token = self.session.userIds.count > 0 ? self.session.userIds[0] : nil;
        if (completion) completion(token, nil);
    });
}


#pragma mark Checking File Existence

- (void)fileExistsAtPath:(NSString *)path completion:(CDEFileExistenceCallback)block
{
    CDEDropboxFileExistenceOperation *operation = [[CDEDropboxFileExistenceOperation alloc] initWithSession:session path:[self fullDropboxPathForPath:path] fileExistenceCallback:block];
    [queue addOperation:operation];
}


#pragma mark Getting Directory Contents

- (void)contentsOfDirectoryAtPath:(NSString *)path completion:(CDEDirectoryContentsCallback)block
{
    CDEDropboxDirectoryContentsOperation *operation = [[CDEDropboxDirectoryContentsOperation alloc] initWithSession:session path:[self fullDropboxPathForPath:path] dataFilesArePartitioned:self.partitionDataFilesBetweenSubdirectories directoryContentsCallback:block];
    [queue addOperation:operation];
}


#pragma mark Creating Directories

- (void)createDirectoryAtPath:(NSString *)path completion:(CDECompletionBlock)block
{
    CDEDropboxCreateDirectoryOperation *operation = [[CDEDropboxCreateDirectoryOperation alloc] initWithSession:session path:[self fullDropboxPathForPath:path] completionCallback:block];
    [queue addOperation:operation];
}


#pragma mark Deleting

- (void)removeItemsAtPaths:(NSArray *)paths completion:(CDECompletionBlock)block
{
    CDEDropboxRemoveOperation *operation = [[CDEDropboxRemoveOperation alloc] initWithSession:session paths:[self fullDropboxPathsForPaths:paths] completionCallback:block];
    [queue addOperation:operation];
}

- (void)removeItemAtPath:(NSString *)path completion:(CDECompletionBlock)block
{
    CDEDropboxRemoveOperation *operation = [[CDEDropboxRemoveOperation alloc] initWithSession:session paths:@[[self fullDropboxPathForPath:path]] completionCallback:block];
    [queue addOperation:operation];
}


#pragma mark Uploading and Downloading

- (void)uploadLocalFiles:(NSArray *)fromPaths toPaths:(NSArray *)toPaths completion:(CDECompletionBlock)block
{
    CDEDropboxUploadOperation *operation = [[CDEDropboxUploadOperation alloc] initWithSession:session localPaths:fromPaths toPaths:[self fullDropboxPathsForPaths:toPaths] completionCallback:block];
    [queue addOperation:operation];
}

- (void)uploadLocalFile:(NSString *)fromPath toPath:(NSString *)toPath completion:(CDECompletionBlock)block
{
    CDEDropboxUploadOperation *operation = [[CDEDropboxUploadOperation alloc] initWithSession:session localPaths:@[fromPath] toPaths:@[[self fullDropboxPathForPath:toPath]] completionCallback:block];
    [queue addOperation:operation];
}

- (void)downloadFromPaths:(NSArray *)fromPaths toLocalFiles:(NSArray *)toPaths completion:(CDECompletionBlock)block
{
    CDEDropboxDownloadOperation *operation = [[CDEDropboxDownloadOperation alloc] initWithSession:session fromPaths:[self fullDropboxPathsForPaths:fromPaths] localPaths:toPaths completionCallback:block];
    [queue addOperation:operation];
}

- (void)downloadFromPath:(NSString *)fromPath toLocalFile:(NSString *)toPath completion:(CDECompletionBlock)block
{
    CDEDropboxDownloadOperation *operation = [[CDEDropboxDownloadOperation alloc] initWithSession:session fromPaths:@[[self fullDropboxPathForPath:fromPath]] localPaths:@[toPath] completionCallback:block];
    [queue addOperation:operation];
}

@end


#pragma mark - Dropbox Operation Classes

@implementation CDEDropboxOperation {
    CDEAsynchronousTaskCallbackBlock retryCallbackBlock;
    BOOL isFinished, isExecuting;
}

@synthesize session = session;
@synthesize restClient = restClient;

- (instancetype)initWithSession:(DBSession *)newSession
{
    self = [super init];
    if (self) {
        session = newSession;
        restClient = [[DBRestClient alloc] initWithSession:newSession];;
        restClient.delegate = self;
    }
    return self;
}

- (void)beginAsynchronousTask
{
    [self prepareForNetworkRequests];
    CDEAsynchronousTaskQueue *taskQueue = [[CDEAsynchronousTaskQueue alloc] initWithTask:^(CDEAsynchronousTaskCallbackBlock next) {
            CDELog(CDELoggingLevelVerbose, @"Attempting network request for operation class: %@", NSStringFromClass(self.class));
            retryCallbackBlock = [next copy];
            [self initiateNetworkRequest];
        }
        repeatCount:kCDENumberOfRetriesForFailedAttempt
        terminationPolicy:CDETaskQueueTerminationPolicyStopOnSuccess
        completion:^(NSError *error) {
            if (error) CDELog(CDELoggingLevelVerbose, @"Cloud file system operation failed: %@ %@", NSStringFromClass(self.class), error);
            [self completeWithError:error];
            retryCallbackBlock = NULL;
            [self endAsynchronousTask];
        }];
    [taskQueue start];
}

- (void)endAsynchronousTask
{
    [restClient cancelAllRequests];
    [super endAsynchronousTask];
}

- (void)prepareForNetworkRequests
{
}

- (void)initiateNetworkRequest
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)completeNetworkRequestWithError:(NSError *)error
{
    if (error) CDELog(CDELoggingLevelVerbose, @"Network request failed with error: %@ %@", NSStringFromClass(self.class), error);
    retryCallbackBlock(error, NO);
}

- (void)completeWithError:(NSError *)error
{
    [self doesNotRecognizeSelector:_cmd];
}

@end


@implementation CDEDropboxFileExistenceOperation {
    BOOL fileExists, isDirectory;
}

@synthesize fileExistenceCallback = fileExistenceCallback;
@synthesize path = path;

- (instancetype)initWithSession:(DBSession *)newSession path:(NSString *)newPath fileExistenceCallback:(CDEFileExistenceCallback)newCallback
{
    self = [super initWithSession:newSession];
    if (self) {
        path = [newPath copy];
        fileExistenceCallback = [newCallback copy];
    }
    return self;
}

- (void)prepareForNetworkRequests
{
    fileExists = NO;
    isDirectory = NO;
}

- (void)initiateNetworkRequest
{
    [self.restClient loadMetadata:path];
}

- (void)completeWithError:(NSError *)error
{
    fileExistenceCallback(fileExists, isDirectory, error);
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    fileExists = !metadata.isDeleted;
    isDirectory = metadata.isDirectory;
    [self completeNetworkRequestWithError:nil];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    if (error.code == 404) {
        fileExists = NO;
        isDirectory = NO;
        [self completeNetworkRequestWithError:nil];
    }
    else {
        [self completeNetworkRequestWithError:error];
    }
}

@end


@implementation CDEDropboxDirectoryContentsOperation {
    CDECloudDirectory *directory;
    NSMutableSet *allDataSubdirectories;
    NSMutableSet *processedDataSubdirectories;
    NSMutableSet *requestedDataSubdirectories;
    BOOL dataFilesArePartitioned;
}

@synthesize path = path;
@synthesize directoryContentsCallback = directoryContentsCallback;

- (id)initWithSession:(DBSession *)newSession path:(NSString *)newPath dataFilesArePartitioned:(BOOL)partitioned directoryContentsCallback:(CDEDirectoryContentsCallback)newCallback
{
    self = [super initWithSession:newSession];
    if (self) {
        path = [newPath copy];
        directoryContentsCallback = [newCallback copy];
        dataFilesArePartitioned = partitioned;
    }
    return self;
}

- (void)initiateNetworkRequest
{
    [self reset];
    [self.restClient loadMetadata:path];
}

- (void)completeWithError:(NSError *)error
{
    directoryContentsCallback(directory.contents, error);
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    // Create directory only once.
    // This delegate can be called multiple times when partitionDataFilesBetweenSubdirectories is YES.
    if (!directory) {
        directory = [CDECloudDirectory new];
        directory.path = metadata.path;
        directory.name = metadata.filename;
        directory.contents = [[NSMutableArray<CDECloudItem> alloc] init];
    }
    
    if (dataFilesArePartitioned) {
        [self processLoadedMetadataWithDataFilesPartitioned:metadata];
    }
    else {
        [self processLoadedMetadata:metadata finished:YES];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    [self reset];
    [self completeNetworkRequestWithError:error];
}

- (void)processLoadedMetadataWithDataFilesPartitioned:(DBMetadata *)metadata
{
    NSString *parentDirPath = [metadata.path stringByDeletingLastPathComponent].lastPathComponent;
    if ([metadata.path.lastPathComponent isEqualToString:@"data"] && metadata.contents.count > 0) {
        allDataSubdirectories = [NSMutableSet set];
        processedDataSubdirectories = [NSMutableSet set];
        requestedDataSubdirectories = [NSMutableSet set];

        for (DBMetadata *child in metadata.contents) {
            [allDataSubdirectories addObject:child.path];
        }
        
        [self loadMetadataForNextBatchOfDataSubdirectories];
    }
    else if ([parentDirPath isEqualToString:@"data"]) {
        [processedDataSubdirectories addObject:metadata.path];
        BOOL finished = [processedDataSubdirectories isEqualToSet:allDataSubdirectories];
        [self processLoadedMetadata:metadata finished:finished];
        if (!finished) [self loadMetadataForNextBatchOfDataSubdirectories];
    }
    else {
        [self processLoadedMetadata:metadata finished:YES];
    }
}

- (void)processLoadedMetadata:(DBMetadata *)metadata finished:(BOOL)finished
{
    for (DBMetadata *child in metadata.contents) {
        // Dropbox inserts parenthesized indexes when two files with
        // same name are uploaded. Ignore these files.
        if ([child.filename rangeOfString:@")"].location != NSNotFound) continue;
        
        if (child.isDirectory) {
            CDECloudDirectory *dir = [CDECloudDirectory new];
            dir.name = child.filename;
            dir.path = child.path;
            [(NSMutableArray<CDECloudItem> *)directory.contents addObject:dir];
        }
        else {
            CDECloudFile *file = [CDECloudFile new];
            file.name = child.filename;
            file.path = child.path;
            file.size = child.totalBytes;
            [(NSMutableArray<CDECloudItem> *)directory.contents addObject:file];
        }
    }
    
    if (finished) [self completeNetworkRequestWithError:nil];
}

- (void)loadMetadataForNextBatchOfDataSubdirectories
{
    // If all previous 'data' subdir metadata requests arrived, request some more
    NSUInteger count = 0;
    if ([requestedDataSubdirectories isEqualToSet:processedDataSubdirectories]) {
        for (NSString *dataSubFolder in allDataSubdirectories) {
            if (![requestedDataSubdirectories containsObject:dataSubFolder]) {
                [requestedDataSubdirectories addObject:dataSubFolder];
                [self.restClient loadMetadata:dataSubFolder];
                if (++count == kCDEMaximumConcurrentRequests) break;
            }
        }
    }
}

- (void)reset
{
    directory = nil;
    requestedDataSubdirectories = nil;
    processedDataSubdirectories = nil;
    allDataSubdirectories = nil;
}

@end


@implementation CDEDropboxCreateDirectoryOperation

@synthesize path;
@synthesize completionCallback;

- (id)initWithSession:(DBSession *)newSession path:(NSString *)newPath completionCallback:(CDECompletionBlock)newCallback
{
    self = [super initWithSession:newSession];
    if (self) {
        path = [newPath copy];
        completionCallback = [newCallback copy];
    }
    return self;
}

- (void)initiateNetworkRequest
{
    [self.restClient createFolder:self.path];
}

- (void)completeWithError:(NSError *)error
{
    self.completionCallback(error);
}

- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
    [self completeNetworkRequestWithError:nil];
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
    [self completeNetworkRequestWithError:error];
}

@end


@implementation CDEDropboxRemoveOperation {
    NSUInteger filesRemaining;
    NSUInteger remainingThisBatch;
    NSError *lastError;
}

@synthesize paths;
@synthesize completionCallback;

- (id)initWithSession:(DBSession *)newSession paths:(NSArray *)newPaths completionCallback:(CDECompletionBlock)newCallback
{
    self = [super initWithSession:newSession];
    if (self) {
        paths = [newPaths copy];
        completionCallback = [newCallback copy];
    }
    return self;
}

- (void)initiateNetworkRequest
{
    filesRemaining = paths.count;
    lastError = nil;
    
    if (filesRemaining == 0) {
        [self completeNetworkRequestWithError:nil];
        return;
    }
    
    [self beginNextBatch];
}

- (void)beginNextBatch
{
    remainingThisBatch = MIN(filesRemaining, kCDEMaximumConcurrentDeletions);
    NSUInteger start = paths.count - filesRemaining;
    NSArray *batch = [paths subarrayWithRange:NSMakeRange(start, remainingThisBatch)];
    for (NSString *path in batch) {
        [self.restClient deletePath:path];
    }
}

- (void)completeWithError:(NSError *)error
{
    self.completionCallback(error);
}

- (void)completeDeletion
{
    if (--filesRemaining == 0) {
        [self completeNetworkRequestWithError:lastError];
    }
    else if (--remainingThisBatch == 0) {
        [self beginNextBatch];
    }
}

- (void)restClient:(DBRestClient *)client deletedPath:(NSString *)path
{
    [self completeDeletion];
}

- (void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error
{
    if (error.code != DBErrorFileNotFound && error.code != 404) lastError = error;
    [self completeDeletion];
}

@end


@implementation CDEDropboxUploadOperation {
    NSMutableSet *successfullyUploadedFiles;
    NSUInteger filesUploading;
    NSError *lastError;
}

@synthesize localPaths;
@synthesize toPaths;
@synthesize completionCallback;

- (id)initWithSession:(DBSession *)newSession localPaths:(NSArray *)newLocalPaths toPaths:(NSArray *)newToPaths completionCallback:(CDECompletionBlock)newCallback
{
    self = [super initWithSession:newSession];
    if (self) {
        localPaths = [newLocalPaths copy];
        toPaths = [newToPaths copy];
        completionCallback = [newCallback copy];
    }
    return self;
}

- (void)initiateNetworkRequest
{
    lastError = nil;
    successfullyUploadedFiles = [NSMutableSet set];
    filesUploading = localPaths.count;
    
    if (filesUploading == 0) {
        [self completeNetworkRequestWithError:nil];
        return;
    }
    
    NSEnumerator *toEn = [toPaths objectEnumerator];
    NSEnumerator *localEn = [localPaths objectEnumerator];
    NSString *toPath, *localPath;
    while ( (toPath = [toEn nextObject]) && (localPath = [localEn nextObject]) ) {
        [self.restClient uploadFile:[toPath lastPathComponent] toPath:[toPath stringByDeletingLastPathComponent] withParentRev:nil fromPath:localPath];
    }
}

- (void)completeWithError:(NSError *)error
{
    self.completionCallback(error);
}

- (void)completeFileUpload
{
    if (--filesUploading == 0) {
        if (lastError) {
            for (NSString *file in successfullyUploadedFiles) {
                [self.restClient deletePath:file];
            }
        }
        
        [self completeNetworkRequestWithError:lastError];
    }
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata
{
    [successfullyUploadedFiles addObject:destPath];
    [self completeFileUpload];
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
    CDELog(CDELoggingLevelError, @"Error uploading a file to Dropbox: %@", error);
    lastError = error;
    [self completeFileUpload];
}

@end


@implementation CDEDropboxDownloadOperation {
    NSError *lastError;
    NSMutableSet *successfullyDownloadedFiles;
    NSUInteger filesDownloading;
}

@synthesize localPaths;
@synthesize fromPaths;
@synthesize completionCallback;

- (id)initWithSession:(DBSession *)newSession fromPaths:(NSArray *)newFromPaths localPaths:(NSArray *)newLocalPaths completionCallback:(CDECompletionBlock)block
{
    self = [super initWithSession:newSession];
    if (self) {
        localPaths = [newLocalPaths copy];
        fromPaths = [newFromPaths copy];
        completionCallback = [block copy];
    }
    return self;
}

- (void)initiateNetworkRequest
{
    lastError = nil;
    successfullyDownloadedFiles = [NSMutableSet set];
    filesDownloading = fromPaths.count;
    
    if (filesDownloading == 0) {
        [self completeNetworkRequestWithError:nil];
        return;
    }
    
    NSEnumerator *fromEn = [fromPaths objectEnumerator];
    NSEnumerator *localEn = [localPaths objectEnumerator];
    NSString *fromPath, *localPath;
    while ( (fromPath = [fromEn nextObject]) && (localPath = [localEn nextObject]) ) {
        [self.restClient loadFile:fromPath atRev:nil intoPath:localPath];
    }
}

- (void)completeWithError:(NSError *)error
{
    self.completionCallback(error);
}

- (void)completeFileLoad
{
    if (--filesDownloading == 0) {
        if (lastError) {
            for (NSString *file in successfullyDownloadedFiles) {
                NSError *error;
                if (![[NSFileManager defaultManager] removeItemAtPath:file error:&error]) {
                    CDELog(CDELoggingLevelError, @"Could not delete a file: %@", error);
                }
            }
        }
        
        [self completeNetworkRequestWithError:lastError];
    }
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath
{
    [successfullyDownloadedFiles addObject:destPath];
    [self completeFileLoad];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
    CDELog(CDELoggingLevelError, @"Error downloading a file from Dropbox: %@", error);
    lastError = error;
    [self completeFileLoad];
}

@end



