//
//  CDEWebDavCloudFileSystem.h
//
//  Created by Drew McCormack on 2/17/14.
//  Copyright (c) 2014 The Mental Faculty B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ensembles/Ensembles.h>

@class CDEWebDavCloudFileSystem;


@protocol CDEWebDavCloudFileSystemDelegate <NSObject>

@required

/**
 Invoked if authentication fails. You should request new credentials from the user and set the `username` and `password` properties, and then call the completion callback to indicate you are finished.
 */
- (void)webDavCloudFileSystem:(CDEWebDavCloudFileSystem *)fileSystem updateLoginCredentialsWithCompletion:(CDECompletionBlock)completion;

@optional

/**
 This callback is invoked before a URL request is made. It is useful if you need to update the `baseURL` based on the username or other dynamic quantities. The URL of WebDAV services often includes the username, so the `baseURL` needs to be modified if a new username is adopted.
 */
-(void)webDavCloudFileSystemWillFormURLRequest:(CDEWebDavCloudFileSystem *)fileSystem;

@end


@interface CDEWebDavCloudFileSystem : NSObject <CDECloudFileSystem>

@property (nonatomic, readwrite, copy) NSString *username;
@property (nonatomic, readwrite, copy) NSString *password;
@property (nonatomic, readonly, assign, getter = isLoggedIn) BOOL loggedIn;
@property (nonatomic, readwrite, copy) NSURL *baseURL;

@property (nonatomic, readwrite, weak) id <CDEWebDavCloudFileSystemDelegate> delegate;

/**
 Initialize the file system with a root URL. You can update the URL if needed. For example, if it includes the username, you may need to modify the URL when the user updates credentials.
 */
- (id)initWithBaseURL:(NSURL *)baseURL;

/**
 Attempts to access the service with the username and password provided. You don't necessarily need to call this method yourself, though you can if you wish to verify that the credentials are correct.
 */
- (void)loginWithCompletion:(CDECompletionBlock)completion;

@end
