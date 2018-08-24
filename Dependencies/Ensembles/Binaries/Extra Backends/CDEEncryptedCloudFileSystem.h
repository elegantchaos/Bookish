//
//  CDEEncryptedCloudFileSystem.h
//  Ensembles
//
//  This class is not a standard file system. It is used to wrap an existing
//  file system, and encrypt any files going into it.
//  It will decrypt files coming from the cloud as needed.
//  Files are encrypted using a symmetric AES key built upon some user provided
//  password.
//
//  This file system requires the Security framework, and RNCryptor.
//
//  Created by Thomas Grapperon on 19/02/2015.
//  Copyright (c) 2015 Thomas Grapperon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ensembles/Ensembles.h>

#if TARGET_OS_IPHONE
#import <RNCryptor/RNCryptor iOS.h>
#else
#import <RNCryptor/RNCryptor.h>
#endif


/**
 *  VaultInfo are used to initialize the encrypted file system. A vault info can be instanciated via factory methods. A vault depends only on the salt (app defined) and
 *  the user defined password. If the user enters two different passwords, this will create two different vaults, the content of each one being invisible to the other one.
 *  Once instanciated, the password and salt fields are unreachable, but the object responds as expected to the -isEqual: message. 
 *  These objets allow too quickly filter undecryptable files.
 */
@interface CDEEncryptedCloudFileSystemVaultInfo : NSObject<NSCopying>

/**
 *  Initialize a VaultInfo instance. These objects are used to determine which files are potentially accessible by the file system, as well as the encryption password.
 *
 *  @param password Some non empty password.
 *  @param salt     Some salt string specific to the vault. This salt is not the salt used during the encryption of files. In order to bypass files encrypted
 *  with another password without opening them, the app uses a hashed version of the password as an indicator. To prevent attack with rainbow tables,
 *  the password is salted with this salt before being hashed. If nil, the app will use the default salt.
 *  @warning The salt should be the same for every app which should participate to the Ensemble. If you have iOS and OS X versions of the app, you should
 *  set the same salt on both versions. You can use any non empty constant string.
 *
 *  @return a VaultInfo instance, nil if the password is empty.
 */
+ (CDEEncryptedCloudFileSystemVaultInfo *)vaultInfoWithPassword:(NSString *)password salt:(NSString *)salt;

/**
 *  Initialize a VaultInfo instance. These objects are used to determine which files are potentially accessible by the file system,
 *  as well as the encryption password. This VaultInfo object uses the default salt to derive the vault path.
 *
 *  @param password Some non empty password.
 *
 *  @return a VaultInfo instance, nil if the password is empty.
 */
+ (CDEEncryptedCloudFileSystemVaultInfo *)vaultInfoWithPassword:(NSString *)password;

@end


/**
 *  A completion block used when querying the host file system for unaccessible vaults.
 *
 *  @param contents An array of unreadable vaultInfos objets.
 *  @param error    A NSError in case of error, nil otherwise.
 */
typedef void (^CDEUnaccessibleVaultsCallback)(NSArray *contents, NSError *error);


/**
 *  An encrypted cloud file system. The framework uses the user password and some salt to define in a host cloud file system a directory containing encrypted Ensemble files.
 *  The encryption is realized by RNCryptor using by default AES-256, with a key derivated from the user password. Each different password entered induces the creation
 *  of different containers, each one being transparent to the other ones. For an attacker, Ensemble files names are still visible, but their content is encrypted. The vault
 *  name uses only a part of the salted then SHA256 hashed password, so this should provide virtually no information about the password.
 */
@interface CDEEncryptedCloudFileSystem : NSObject <CDECloudFileSystem>

/**
 *  The hosting file system.
 */
@property (nonatomic, readonly) id <CDECloudFileSystem> cloudFileSystem;

/**
 *  The Vault Info characterizing this instance of the file system.
 */
@property (nonatomic, readonly) CDEEncryptedCloudFileSystemVaultInfo *vaultInfo;

/**
 *  Initialize the encrypted file system.
 *
 *  @param wrappedFileSystem A host file system, effectively holding the files.
 *  @param vaultInfo         A VaultInfo instance which will be used to determine which files are accessible by the file system,
 *  as well as the encryption password.
 *  @param crytorSettings    Some RNCryptorSettings. You can find more information about them in RNCryptor.h
 *
 *  @return An encrypted CloudFileSystem.
 */
- (instancetype)initWithCloudFileSystem:(id <CDECloudFileSystem> )wrappedFileSystem
                              vaultInfo:(CDEEncryptedCloudFileSystemVaultInfo *)vaultInfo
                         crytorSettings:(RNCryptorSettings)crytorSettings;

/**
 *  Initialize the encrypted file system using kRNCryptorAES256Settings.
 *
 *  @param wrappedFileSystem A host file system, effectively holding the files.
 *  @param vaultInfo         A VaultInfo instance which will be used to determine which files are accessible by the file system,
 *  as well as the encryption password.
 *
 *  @return An encrypted CloudFileSystem.
 */
- (instancetype)initWithCloudFileSystem:(id <CDECloudFileSystem> )wrappedFileSystem
                              vaultInfo:(CDEEncryptedCloudFileSystemVaultInfo *)vaultInfo;

/**
 *  Initialize the encrypted file system using default salt and with kRNCryptorAES256Settings for encrytion.
 *
 *  @param wrappedFileSystem A host file system, effectively holding the files.
 *  @param password          A non empty password.
 *
 *  @return An encrypted CloudFileSystem.
 */
- (instancetype)initWithCloudFileSystem:(id <CDECloudFileSystem> )wrappedFileSystem
                               password:(NSString *)password;


/**
 *  Provides a list of vaults unreadable by the app. This can be use to warn users of possible passwords mismatchs.
 *
 *  @param vaultInfos An array of CDEEncryptedCloudFileSystemVaultInfo objects. Most of the time, with one ensemble and one password,
 *  only the current vaultInfo is specified.
 *  @param completion A CDEUnaccessibleVaultsCallback block with an array of unaccessible vaults as content, and a NSError in case of failure.
 */
- (void)unreadableVaultsForVaultsInfos:(NSArray *)vaultInfos
                            completion:(CDEUnaccessibleVaultsCallback)completion;

/**
 *  Delete the vault with the specified vault info. This will cause any device effectively using it to deleech. If ever this vault is unreadable this will not
 *  force the calling device to deleech. This method is not intended as a way to deleech ensembles. It is typically used with unreadable vaults infos returned by
 *  -unreadableVaultsForVaultsInfos:completion:.
 *
 *  @param info       A CDEEncryptedCloudFileSystemVaultInfo object.
 *  @param completion A CDECompletionBlock completion block.
 */
- (void)deleteVaultWithVaultInfo:(CDEEncryptedCloudFileSystemVaultInfo *)info
                      completion:(CDECompletionBlock)completion;

@end
