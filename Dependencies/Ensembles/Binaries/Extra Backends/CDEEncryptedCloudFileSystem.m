//
//  CDEEncryptedCloudFileSystem.m
//  Ensembles
//
//  Created by Thomas Grapperon on 19/02/2015.
//  Copyright (c) 2015 Thomas Grapperon. All rights reserved.
//

#import "CDEEncryptedCloudFileSystem.h"
#import <CommonCrypto/CommonCrypto.h>

#if TARGET_OS_IPHONE
#import <RNCryptor/RNCryptor iOS.h>
#else
#import <RNCryptor/RNEncryptor.h>
#import <RNCryptor/RNDecryptor.h>
#import <RNCryptor/RNCryptor.h>
#endif

extern int
CCKeyDerivationPBKDF( CCPBKDFAlgorithm algorithm, const char *password, size_t passwordLen,
                     const uint8_t *salt, size_t saltLen,
                     CCPseudoRandomAlgorithm prf, uint rounds,
                     uint8_t *derivedKey, size_t derivedKeyLen) __attribute__((weak_import));

static NSString * const CDEDefaultVaultSalt = @"5L8ibqS3plnRXO2l2QiXh7xFH86m5b5Km4Mo0n3H0rLsHR7eKzSfbti7nW049S3I";

static NSString * const CDEEncryptedFilePathExtension = @"cdecrypt";
static NSString * const CDEEncryptedPathPrefix = @"/VAULT_";

@interface CDEEncryptedCloudFileSystemVaultInfo ()

@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *salt;
@property (nonatomic, strong) NSString *passwordDependentPath;

// This constructor is private and used only to manage unreadable vaults.
+ (CDEEncryptedCloudFileSystemVaultInfo *)unreadableVaultInfoWithPath:(NSString *)path;
@end


@implementation CDEEncryptedCloudFileSystemVaultInfo

+ (CDEEncryptedCloudFileSystemVaultInfo *)vaultInfoWithPassword:(NSString *)password
{
    return [self vaultInfoWithPassword:password salt:nil];
}

+ (CDEEncryptedCloudFileSystemVaultInfo *)vaultInfoWithPassword:(NSString *)password salt:(NSString *)salt
{
    if (!password.length) {
        return nil;
    }
    CDEEncryptedCloudFileSystemVaultInfo *info = [CDEEncryptedCloudFileSystemVaultInfo new];
    info.password = [password copy];
    // Defaults to something in any case
    if (!salt.length) {
        info.salt = CDEDefaultVaultSalt;
    }else{
        info.salt = [salt copy];
    }
    return info;
}

+ (CDEEncryptedCloudFileSystemVaultInfo *)unreadableVaultInfoWithPath:(NSString *)path
{
    CDEEncryptedCloudFileSystemVaultInfo *info = [CDEEncryptedCloudFileSystemVaultInfo new];
    info.passwordDependentPath = [path copy];
    return info;
}

- (NSString *)description
{
    return [@"Vault info with path: " stringByAppendingString:self.passwordDependentPath];
}

- (BOOL)isEqual:(id)object
{
    if (object && ![object isKindOfClass:[CDEEncryptedCloudFileSystemVaultInfo class]]) {
        return NO;
    }
    return [self.passwordDependentPath isEqualToString:[object passwordDependentPath]];
}

- (id)copyWithZone:(NSZone *)zone
{
    CDEEncryptedCloudFileSystemVaultInfo *info = [[CDEEncryptedCloudFileSystemVaultInfo allocWithZone:zone] init];
    info.password = [self.password copy];
    info.salt = [self.salt copy];
    info.passwordDependentPath = [self.passwordDependentPath copy];
    return info;
}

- (NSString *)passwordDependentPath
{
    if (_passwordDependentPath) {
        return _passwordDependentPath;
    }
    if (self.password.length == 0) {
        return nil;
    }

    // Open CommonKeyDerivation.h for help

    // This define the number of rounds used in the CCKeyDerivationPBKDF algorithm. Because this code may run on different platforms, one can't
    // use CCCalibratePBKDF. Higher is safer, but longer.
    int rounds = 10000;
    
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    
    NSData *passData = [self.password dataUsingEncoding:NSUTF8StringEncoding];
    NSData *saltData = [self.salt dataUsingEncoding:NSUTF8StringEncoding];
    
    CCKeyDerivationPBKDF(kCCPBKDF2, passData.bytes, passData.length, saltData.bytes, saltData.length, kCCPRFHmacAlgSHA256, rounds, digest, CC_SHA256_DIGEST_LENGTH);

    NSMutableString* passPart = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [passPart appendFormat:@"%02x", digest[i]];
    }
    // No need to use a full SHA256 string (64 chars of hex). The probability of collision is still very small (~16^-10) if we use only the first ten chars.
    // This also avoids to lengthen too much already lengthy paths.
    NSInteger charsToKeep = 10;
    NSAssert(charsToKeep <= CC_SHA256_DIGEST_LENGTH * 2, @"The number of characters must be smaller or equal to CC_SHA256_DIGEST_LENGTH * 2");
    _passwordDependentPath = [[CDEEncryptedPathPrefix stringByAppendingString:[passPart substringToIndex:charsToKeep]] uppercaseString];
    return _passwordDependentPath;
}

- (BOOL)cantReadFileAtPath:(NSString *)path
{
    if (path.length >= self.passwordDependentPath.length) {
        return [path rangeOfString:self.passwordDependentPath
                           options:NSCaseInsensitiveSearch
                             range:NSMakeRange(0, path.length)].location == NSNotFound;
    }
    return YES;
}

@end

@interface CDEEncryptedCloudFileSystem (){
    NSFileManager *fileManager;
    NSString *tempDirPath;
    RNCryptorSettings rnCryptorSettings;
}

@end

@implementation CDEEncryptedCloudFileSystem

@synthesize cloudFileSystem = cloudFileSystem;
@synthesize vaultInfo = vaultInfo;

- (instancetype)initWithCloudFileSystem:(id <CDECloudFileSystem>)wrappedFileSystem password:(NSString *)password
{
    return [self initWithCloudFileSystem:wrappedFileSystem vaultInfo:[CDEEncryptedCloudFileSystemVaultInfo vaultInfoWithPassword:password salt:nil]];
}

- (instancetype)initWithCloudFileSystem:(id <CDECloudFileSystem>)wrappedFileSystem vaultInfo:(CDEEncryptedCloudFileSystemVaultInfo *)info
{
    return [self initWithCloudFileSystem:wrappedFileSystem vaultInfo:info crytorSettings:kRNCryptorAES256Settings];
}

- (instancetype)initWithCloudFileSystem:(id<CDECloudFileSystem>)wrappedFileSystem vaultInfo:(CDEEncryptedCloudFileSystemVaultInfo *)info crytorSettings:(RNCryptorSettings)crytorSettings
{
    if (!info) {
        return nil;
    }
    self = [super init];
    if (self) {
        cloudFileSystem = wrappedFileSystem;
        vaultInfo = info;
        rnCryptorSettings = crytorSettings;
        
        fileManager = [[NSFileManager alloc] init];
        tempDirPath = [NSTemporaryDirectory() stringByAppendingFormat:@"/CDEEncryptedCloudFileSystem/%@", [[NSProcessInfo processInfo] globallyUniqueString]];
        
        [self clearTempDir];
    }
        
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:CDEException reason:@"Wrong initializer invoked" userInfo:nil];
}

- (void)dealloc
{
    [[NSFileManager defaultManager] removeItemAtPath:tempDirPath error:NULL];
}

- (void)clearTempDir
{
    [fileManager removeItemAtPath:tempDirPath error:NULL];
    [fileManager createDirectoryAtPath:tempDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
}

- (void)connect:(CDECompletionBlock)completion
{
    [cloudFileSystem connect:^(NSError *error) {
        if (error) {
            if (completion) {
                completion(error);
            }
            return;
        }
        [self checkOrCreateVaultDirectoryWithCompletion:completion];
    }];
}

- (BOOL)isConnected
{
    return cloudFileSystem.isConnected;
}

- (void)fetchUserIdentityWithCompletion:(CDEFetchUserIdentityCallback)completion;
{
    [cloudFileSystem fetchUserIdentityWithCompletion:completion];
}

- (void)performInitialPreparation:(CDECompletionBlock)completion
{
    if ([cloudFileSystem respondsToSelector:@selector(performInitialPreparation:)]) {
        [cloudFileSystem performInitialPreparation:completion];
    }
}

- (void)primeForActivityWithCompletion:(CDECompletionBlock)completion
{
    [cloudFileSystem primeForActivityWithCompletion:completion];
}


- (void)checkOrCreateVaultDirectoryWithCompletion:(CDECompletionBlock)completion{
    [self directoryExistsAtPath:@"" completion:^(BOOL exists, NSError *error) {
        if (!exists) {
            [cloudFileSystem createDirectoryAtPath:vaultInfo.passwordDependentPath completion:completion];
            return;
        }
        if (completion) {
            completion(error);
        }
    }];
}

- (void)repairEnsembleDirectory:(NSString *)ensembleDir completion:(CDECompletionBlock)completion
{
    [cloudFileSystem repairEnsembleDirectory:[self passwordDependentPathForPath:ensembleDir] completion:completion];
}

- (void)fileExistsAtPath:(NSString *)path completion:(CDEFileExistenceCallback)completion
{
    NSString *encryptedPath = [[self passwordDependentPathForPath:path] stringByAppendingPathExtension:CDEEncryptedFilePathExtension];
    [cloudFileSystem fileExistsAtPath:encryptedPath completion:^(BOOL exists, BOOL isDirectory, NSError *error) {
        if (error) {
            if (completion) completion(NO, NO, error);
            return;
        }
        
        if (!exists) {
            [cloudFileSystem fileExistsAtPath:[self passwordDependentPathForPath:path] completion:completion];
            return;
        }
        
        if (completion) completion(exists, isDirectory, nil);
    }];
}

- (void)directoryExistsAtPath:(NSString *)path completion:(CDEDirectoryExistenceCallback)completion
{
    if ([cloudFileSystem respondsToSelector:@selector(directoryExistsAtPath:completion:)]) {
        [cloudFileSystem directoryExistsAtPath:[self passwordDependentPathForPath:path] completion:^(BOOL exists, NSError *error) {
            if (completion) completion(error ? NO : exists, error);
        }];
    }
    else {
        [cloudFileSystem fileExistsAtPath:[self passwordDependentPathForPath:path] completion:^(BOOL exists, BOOL isDirectory, NSError *error) {
            exists = exists && isDirectory;
            if (completion) completion(error ? NO : exists, error);
        }];
    }
}

- (void)createDirectoryAtPath:(NSString *)path completion:(CDECompletionBlock)completion
{
    [cloudFileSystem createDirectoryAtPath:[self passwordDependentPathForPath:path] completion:completion];
}

- (void)removeItemAtPath:(NSString *)fromPath completion:(CDECompletionBlock)completion
{
    NSString *encryptedPath = [[self passwordDependentPathForPath:fromPath] stringByAppendingPathExtension:CDEEncryptedFilePathExtension];
    [cloudFileSystem removeItemAtPath:encryptedPath completion:^(NSError *encryptedFileError) {
        [cloudFileSystem removeItemAtPath:[self passwordDependentPathForPath:fromPath] completion:^(NSError *nonencryptedError) {
            NSError *error = (encryptedFileError && nonencryptedError) ? nonencryptedError : nil;
            if (completion) completion(error);
        }];
    }];
}

- (void)removeItemsAtPaths:(NSArray *)paths completion:(CDECompletionBlock)block
{
    NSMutableArray *allPaths = [[NSMutableArray alloc] initWithArray:paths];
    for (NSString *path in paths) {
        NSString *encryptedPath = [[self passwordDependentPathForPath:path] stringByAppendingPathExtension:CDEEncryptedFilePathExtension];
        [allPaths addObject:encryptedPath];
    }
    
    [cloudFileSystem removeItemsAtPaths:allPaths completion:^(NSError *error) {
        // There can be errors due to encrypted paths not existing, or vice versa. Ignore.
        if (block) block(nil);
    }];
}

- (void)contentsOfDirectoryAtPath:(NSString *)path completion:(CDEDirectoryContentsCallback)completion
{
    [cloudFileSystem contentsOfDirectoryAtPath:[self passwordDependentPathForPath:path] completion:^(NSArray *contents, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        for (id item in contents) {
            // We need to remove the passwordDependentPathForPath: component to keep all of this transparent.
            CDECloudDirectory *directory = item;
            if ([item isKindOfClass:[CDECloudDirectory class]]) {
                directory.path = [directory.path stringByReplacingOccurrencesOfString:[vaultInfo.passwordDependentPath stringByAppendingString:@"/"] withString:@""];
            }
            
            CDECloudFile *file = item;
            if ([item isKindOfClass:[CDECloudFile class]] && [file.name.pathExtension isEqualToString:CDEEncryptedFilePathExtension]) {
                file.name = [file.name stringByDeletingPathExtension];
                file.path = [[file.path stringByReplacingOccurrencesOfString:[vaultInfo.passwordDependentPath stringByAppendingString:@"/"] withString:@""] stringByDeletingPathExtension];
            }
        }
        if (completion) completion(contents, nil);
    }];
}

- (NSString *)tempFilePath
{
    NSString *tempFilePath = [tempDirPath stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    return tempFilePath;
}

- (NSUInteger) fileDownloadMaximumBatchSize
{
    return [cloudFileSystem fileDownloadMaximumBatchSize];
}

- (void)downloadFromPath:(NSString *)fromPath toLocalFile:(NSString *)toPath completion:(CDECompletionBlock)completion
{
    NSString *tempFilePath = [self tempFilePath];
    NSString *encryptedPath = [[self passwordDependentPathForPath:fromPath] stringByAppendingPathExtension:CDEEncryptedFilePathExtension];
    [cloudFileSystem downloadFromPath:encryptedPath toLocalFile:tempFilePath completion:^(NSError *error) {
        if (error) {
            [cloudFileSystem downloadFromPath:[self passwordDependentPathForPath:fromPath] toLocalFile:toPath completion:completion];
            return;
        }
        
        NSError *localError;
        BOOL decrytionSucceeded = NO;

        NSString *tempDecryptedPath = [self decryptedFilePathForFileAtPath:tempFilePath error:&localError];
        if (localError) {
            if (completion) completion(localError);
            [fileManager removeItemAtPath:tempFilePath error:NULL];
            return;
        }
        if (tempDecryptedPath){
            [[NSFileManager defaultManager] moveItemAtPath:tempDecryptedPath toPath:toPath error:&localError];
            if (!localError) {
                decrytionSucceeded = YES;
            }
        }
        [fileManager removeItemAtPath:tempFilePath error:NULL];

        if (completion) completion(decrytionSucceeded ? nil : localError);
    }];
}

- (void)downloadFromPaths:(NSArray *)fromPaths toLocalFiles:(NSArray *)toPaths completion:(CDECompletionBlock)completion
{
    NSMutableArray *tempPaths = [[NSMutableArray alloc] init];
    NSMutableArray *encryptedPaths = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < fromPaths.count; i++) {
        NSString *fromPath = fromPaths[i];
        NSString *tempFilePath = [self tempFilePath];
        NSString *encryptedPath = [[self passwordDependentPathForPath:fromPath] stringByAppendingPathExtension:CDEEncryptedFilePathExtension];
        [tempPaths addObject:tempFilePath];
        [encryptedPaths addObject:encryptedPath];
    }
    
    [cloudFileSystem downloadFromPaths:encryptedPaths toLocalFiles:tempPaths completion:^(NSError *error) {
        if (error) {
            __block NSMutableArray *arrayOfEncryptedPaths = [NSMutableArray arrayWithCapacity:fromPaths.count];
            [fromPaths enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL *stop) {
                [arrayOfEncryptedPaths addObject:[self passwordDependentPathForPath:path]];
            }];
            [cloudFileSystem downloadFromPaths:arrayOfEncryptedPaths toLocalFiles:toPaths completion:completion];
            return;
        }
        
        NSUInteger i = 0;
        NSError *localError = nil;
        BOOL decryptionSucceeded = NO;

        for (NSString *tempFilePath in tempPaths) {
            NSString *toPath = toPaths[i++];
            
            NSString *tempDecryptedPath = [self decryptedFilePathForFileAtPath:tempFilePath error:&localError];
            if (localError) {
                decryptionSucceeded = NO;
            }else if (tempDecryptedPath) {
                [[NSFileManager defaultManager] moveItemAtPath:tempDecryptedPath toPath:toPath error:&localError];
                if (!localError) {
                    decryptionSucceeded = YES;
                }
            }
            [fileManager removeItemAtPath:tempFilePath error:NULL];
            if (!decryptionSucceeded) break;
        }
        
        if (completion) completion(decryptionSucceeded ? nil : localError);
    }];
}

- (NSUInteger)fileUploadMaximumBatchSize
{
    return [cloudFileSystem fileUploadMaximumBatchSize];
}

- (void)uploadLocalFile:(NSString *)fromPath toPath:(NSString *)toPath completion:(CDECompletionBlock)completion
{
    
    NSError *localError;
    NSString *tempFilePath = [self tempFilePath];

    tempFilePath = [self encryptedFilePathForFileAtPath:fromPath error:&localError];
    
    if (localError) {
        if (completion) completion(localError);
        return;
    }

    NSString *encryptedPath = [[self passwordDependentPathForPath:toPath] stringByAppendingPathExtension:CDEEncryptedFilePathExtension];
    [cloudFileSystem uploadLocalFile:tempFilePath toPath:encryptedPath completion:^(NSError *error) {
        [fileManager removeItemAtPath:tempFilePath error:NULL];
        if (completion) completion(error);
    }];
}

- (void)uploadLocalFiles:(NSArray *)fromPaths toPaths:(NSArray *)toPaths completion:(CDECompletionBlock)completion
{
    NSMutableArray *tempPaths = [[NSMutableArray alloc] init];
    NSMutableArray *encryptedPaths = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < fromPaths.count; i++) {
        NSString *fromPath = fromPaths[i];
        NSString *toPath = toPaths[i];
        NSError *localError;

        NSString *tempFilePath = [self encryptedFilePathForFileAtPath:fromPath error:&localError];
        if (localError) {
            if (completion) completion(localError);
            return;
        }

        NSString *encryptedPath = [[self passwordDependentPathForPath:toPath] stringByAppendingPathExtension:CDEEncryptedFilePathExtension];
        [tempPaths addObject:tempFilePath];
        [encryptedPaths addObject:encryptedPath];
    }
    
    [cloudFileSystem uploadLocalFiles:tempPaths toPaths:encryptedPaths completion:^(NSError *error) {
        for (NSString *tempPath in tempPaths) [fileManager removeItemAtPath:tempPath error:NULL];
        if (completion) completion(error);
    }];
}

#pragma mark Message Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL result = NO;
    if (@selector(removeItemsAtPaths:completion:) == aSelector ||
        @selector(repairEnsembleDirectory:completion:) == aSelector ||
        @selector(performInitialPreparation:) == aSelector ||
        @selector(primeForActivityWithCompletion:) == aSelector ||
        @selector(fileUploadMaximumBatchSize) == aSelector || @selector(uploadLocalFiles:toPaths:completion:) == aSelector ||
        @selector(fileDownloadMaximumBatchSize) == aSelector || @selector(downloadFromPaths:toLocalFiles:completion:) == aSelector ) {
        result = [cloudFileSystem respondsToSelector:aSelector];
    }
    else {
        result = [super respondsToSelector:aSelector];
    }
    return result;
}

#pragma mark Password dependant path helpers

- (NSString *)passwordDependentPathForPath:(NSString *)path
{
    return [vaultInfo.passwordDependentPath stringByAppendingPathComponent:path];
}

- (void)unreadableVaultsForVaultsInfos:(NSArray *)vaultInfos completion:(CDEUnaccessibleVaultsCallback)completion
{
    [cloudFileSystem contentsOfDirectoryAtPath:@"" completion:^(NSArray *contents, NSError *error) {
        
        if (error) {
            if (completion) {
                completion(nil, error);
            }
        }
        NSMutableArray *arrayOfUnreadableVaults = [NSMutableArray array];

        for (id cloudEntity in contents) {
            if ([cloudEntity respondsToSelector:@selector(path)]) {
                NSString *path = (id)[cloudEntity path];
                for (CDEEncryptedCloudFileSystemVaultInfo *info in vaultInfos) {
                    if ([info cantReadFileAtPath:path]) {
                        [arrayOfUnreadableVaults addObject:[CDEEncryptedCloudFileSystemVaultInfo unreadableVaultInfoWithPath:path]];
                    }
                }
            }
        }
        
        if (completion) {
            completion(arrayOfUnreadableVaults, nil);
        }
    }];
}

- (void)deleteVaultWithVaultInfo:(CDEEncryptedCloudFileSystemVaultInfo *)info completion:(CDECompletionBlock)completion
{
    if (!info) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    [self.cloudFileSystem removeItemAtPath:info.passwordDependentPath completion:completion];
}

#pragma RNCryptor helpers

// Externalized encryption/decryption methods. These simple implementations may need to be refined to handle large files.
- (NSString *)encryptedFilePathForFileAtPath:(NSString *)fromPath error:(NSError **)error
{
    NSData *fromFileData = [NSData dataWithContentsOfFile:fromPath];
    NSString *tempFilePath = [self tempFilePath];
    
    NSData *tempFileData = nil;
    if (vaultInfo.password) {
        tempFileData = [RNEncryptor encryptData:fromFileData withSettings:rnCryptorSettings password:vaultInfo.password error:error];
        if (!*error) {
            [tempFileData writeToFile:tempFilePath options:NSDataWritingAtomic error:error];
        }
    }
    if (!*error) {
        return tempFilePath;
    }
    return nil;
}

- (NSString *)decryptedFilePathForFileAtPath:(NSString *)fromPath error:(NSError **)error
{
    NSData *fromFileData = [NSData dataWithContentsOfFile:fromPath];
    NSString *tempFilePath = [self tempFilePath];
    
    NSData *tempFileData = nil;
    if (vaultInfo.password) {
        tempFileData = [RNDecryptor decryptData:fromFileData withSettings:rnCryptorSettings password:vaultInfo.password  error:error];
        if (!*error) {
            [tempFileData writeToFile:tempFilePath options:NSDataWritingAtomic error:error];
        }
    }
    if (!*error) {
        return tempFilePath;
    }
    return nil;
}

@end
