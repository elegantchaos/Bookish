//
//  CDEDropboxCloudFileSystem.h
//
//  Created by Drew McCormack on 4/12/13.
//  Copyright (c) 2013 The Mental Faculty B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Ensembles/Ensembles.h>

@class CDEDropboxCloudFileSystem;
@class DBSession;


@protocol CDEDropboxCloudFileSystemDelegate <NSObject>

- (void)linkSessionForDropboxCloudFileSystem:(CDEDropboxCloudFileSystem *)fileSystem completion:(CDECompletionBlock)completion;

@end


@interface CDEDropboxCloudFileSystem : NSObject <CDECloudFileSystem>

@property (nonatomic, readonly) DBSession *session;
@property (nonatomic, readwrite, weak) id <CDEDropboxCloudFileSystemDelegate> delegate;
@property (nonatomic, readwrite) NSUInteger fileUploadMaximumBatchSize;
@property (nonatomic, readwrite) NSUInteger fileDownloadMaximumBatchSize;

/// When this is YES, subfolders are added to the 'data' folder to prevent exceeding of the Dropbox folder contents limit (10000).
/// This should only be a problem for apps with very many data blobs. You should not change this setting once your app is in production. Default is NO.
@property (nonatomic, readwrite) BOOL partitionDataFilesBetweenSubdirectories;

/// Stipulate a subfolder in Dropbox. Default nil (root)
@property (nonatomic, readwrite, copy) NSString *relativePathToRootInDropbox;

- (instancetype)initWithSession:(DBSession *)session;

@end
