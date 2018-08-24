//
//  CDEWebDavCloudFileSystem.m
//
//  Created by Drew McCormack on 2/17/14.
//  Copyright (c) 2014 The Mental Faculty B.V. All rights reserved.
//

#import "CDEWebDavCloudFileSystem.h"


@interface CDEWebDavCloudFileSystem () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, readwrite, assign, getter = isLoggedIn) BOOL loggedIn;
@property (nonatomic, readonly, strong) NSURL *userDirectoryURL;

@end


@interface CDEWebDavResponseParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, readonly) NSArray *cloudItems;

- (id)initWithData:(NSData *)data;

- (BOOL)parse:(NSError * __autoreleasing *)error;

@end


@implementation CDEWebDavCloudFileSystem {
    NSOperationQueue *operationQueue;
    NSURLConnection *connection;
    NSMutableData *connectionData;
    NSInteger connectionStatusCode;
    NSFileHandle *downloadFileHandle;
    NSInputStream *uploadInputStream;
    NSString *uploadFilePath;
    void(^connectionCompletion)(NSError *error, NSInteger statusCode, NSData *responseData);
}

@synthesize username = username;
@synthesize password = password;
@synthesize baseURL = baseURL;
@synthesize loggedIn = loggedIn;

- (instancetype)initWithBaseURL:(NSURL *)newBaseURL
{
    self = [super init];
    if (self) {
        baseURL = newBaseURL;
        loggedIn = NO;
        operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = 1;
        if ([operationQueue respondsToSelector:@selector(setQualityOfService:)]) {
            [operationQueue setQualityOfService:NSQualityOfServiceUserInitiated];
        }
    }
    return self;
}

- (instancetype)init
{
    return [self initWithBaseURL:nil];
}

- (void)dealloc
{
    [operationQueue cancelAllOperations];
}

#pragma mark KVO

+ (NSSet *)keyPathsForValuesAffectingIdentityToken
{
    return [NSSet setWithObject:@"username"];
}

#pragma mark Connecting

- (BOOL)isConnected
{
    return self.isLoggedIn;
}

- (void)connect:(CDECompletionBlock)completion
{
    if (self.isConnected) {
        if (completion) completion(nil);
    }
    else {
        [self loginWithCompletion:^(NSError *error) {
            if (error.code == CDEErrorCodeAuthenticationFailure && self.delegate) {
                [self.delegate webDavCloudFileSystem:self updateLoginCredentialsWithCompletion:^(NSError *error) {
                    if (error) {
                        if (completion) completion(error);
                    }
                    else {
                        // Try the whole process again with new credentials
                        [self connect:completion];
                    }
                }];
            }
            else {
                if (completion) completion(error);
            }
        }];
    }
}

- (void)loginWithCompletion:(CDECompletionBlock)completion
{
    [self contentsOfDirectoryAtPath:@"/" completion:^(NSArray *contents, NSError *error) {
        self.loggedIn = (nil == error);
        if (completion) completion(error);
    }];
}

#pragma mark - User Identity

- (void)fetchUserIdentityWithCompletion:(CDEFetchUserIdentityCallback)completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(self.username, nil);
    });
}

#pragma mark - Checking File Existence

- (void)fileExistsAtPath:(NSString *)path completion:(CDEFileExistenceCallback)completion
{
    [self sendPropertyFindRequestForPath:path depth:0 completion:^(NSError *error, NSInteger statusCode, NSData *responseData) {
        if (error && statusCode != 404) {
            if (completion) completion(NO, NO, error);
        }
        else if (statusCode == 404) {
            if (completion) completion(NO, NO, nil);
        }
        else {
            CDEWebDavResponseParser *parser = [[CDEWebDavResponseParser alloc] initWithData:responseData];
            BOOL succeeded = [parser parse:&error];
            if (!succeeded) {
                if (completion) completion(NO, NO, error);
                return;
            }
            
            BOOL isDir = [parser.cloudItems.lastObject isKindOfClass:[CDECloudDirectory class]];
            if (completion) completion(YES, isDir, nil);
        }
    }];
}

#pragma mark - Checking File Existence

- (void)directoryExistsAtPath:(NSString *)path completion:(CDEDirectoryExistenceCallback)completion
{
    [self sendPropertyFindRequestForPath:path depth:0 completion:^(NSError *error, NSInteger statusCode, NSData *responseData) {
        if (error && statusCode != 404) {
            if (completion) completion(NO, error);
        }
        else if (statusCode == 404) {
            if (completion) completion(NO, nil);
        }
        else {
            CDEWebDavResponseParser *parser = [[CDEWebDavResponseParser alloc] initWithData:responseData];
            BOOL succeeded = [parser parse:&error];
            if (!succeeded) {
                if (completion) completion(NO, error);
                return;
            }
            
            BOOL isDir = [parser.cloudItems.lastObject isKindOfClass:[CDECloudDirectory class]];
            if (completion) completion(isDir, nil);
        }
    }];
}

#pragma mark - Getting Directory Contents

- (void)contentsOfDirectoryAtPath:(NSString *)path completion:(CDEDirectoryContentsCallback)completion
{
    if (![path hasSuffix:@"/"]) path = [path stringByAppendingString:@"/"];
    [self sendPropertyFindRequestForPath:path depth:1 completion:^(NSError *error, NSInteger statusCode, NSData *responseData) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        CDEWebDavResponseParser *parser = [[CDEWebDavResponseParser alloc] initWithData:responseData];
        BOOL succeeded = [parser parse:&error];
        if (!succeeded) {
            if (completion) completion(nil, error);
            return;
        }
        
        // Remove the directory itself from the results
        NSArray *items = parser.cloudItems;
        items = items.count > 1 ? [items subarrayWithRange:NSMakeRange(1, items.count-1)] : @[];
        
        if (completion) completion(items, nil);
    }];
}

#pragma mark - Creating Directories

- (void)createDirectoryAtPath:(NSString *)path completion:(CDECompletionBlock)completion
{
    NSMutableURLRequest *request = [self mutableURLRequestForPath:path];
    request.HTTPMethod = @"MKCOL";
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    [self sendURLRequest:request completion:^(NSError *error, NSInteger statusCode, NSData *responseData) {
        if (completion) completion(error);
    }];
}

#pragma mark - Deleting

- (void)removeItemAtPath:(NSString *)path completion:(CDECompletionBlock)completion
{
    NSMutableURLRequest *request = [self mutableURLRequestForPath:path];
    request.HTTPMethod = @"DELETE";
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    [self sendURLRequest:request completion:^(NSError *error, NSInteger statusCode, NSData *responseData) {
        if (completion) completion(error);
    }];
}


#pragma mark - Uploading and Downloading

- (void)uploadLocalFile:(NSString *)fromPath toPath:(NSString *)toPath completion:(CDECompletionBlock)completion
{
    uploadFilePath = [fromPath copy];
    uploadInputStream = [NSInputStream inputStreamWithFileAtPath:fromPath];
    
    NSMutableURLRequest *request = [self mutableURLRequestForPath:toPath];
    request.HTTPMethod = @"PUT";
    request.HTTPBodyStream = uploadInputStream;
    request.timeoutInterval = 3600.0;

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fromPath error:NULL];
    unsigned long long result = attributes.fileSize;
    NSString *lengthAsString = [NSString stringWithFormat:@"%llu", result];
    [request setValue:lengthAsString forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    [self sendURLRequest:request completion:^(NSError *error, NSInteger statusCode, NSData *responseData) {
        if (completion) completion(error);
    }];
}

- (void)downloadFromPath:(NSString *)fromPath toLocalFile:(NSString *)toPath completion:(CDECompletionBlock)completion
{
    NSMutableURLRequest *request = [self mutableURLRequestForPath:fromPath];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 60.0;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtPath:toPath error:NULL];
    [fileManager createFileAtPath:toPath contents:nil attributes:nil];
    downloadFileHandle = [NSFileHandle fileHandleForWritingAtPath:toPath];
    
    [self sendURLRequest:request completion:^(NSError *error, NSInteger statusCode, NSData *responseData) {
        [downloadFileHandle closeFile];
        downloadFileHandle = nil;
        if (completion) completion(error);
    }];
}

#pragma mark - Requests

- (NSMutableURLRequest *)mutableURLRequestForPath:(NSString *)path
{
    // Give calling code chance to update the base URL
    if ([self.delegate respondsToSelector:@selector(webDavCloudFileSystemWillFormURLRequest:)]) {
        [self.delegate webDavCloudFileSystemWillFormURLRequest:self];
    }
    
    NSURL *url = [self.userDirectoryURL URLByAppendingPathComponent:path];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    
    return request;
}

- (NSURL *)userDirectoryURL
{
    return self.baseURL;
}

- (void)sendURLRequest:(NSURLRequest *)request completion:(void(^)(NSError *error, NSInteger statusCode, NSData *responseData))completion
{
    [connection cancel];
    connectionData = [NSMutableData data];
    connectionCompletion = [completion copy];
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)sendPropertyFindRequestForPath:(NSString *)path depth:(NSInteger)depth completion:(void(^)(NSError *error, NSInteger statusCode, NSData *responseData))completion
{
    NSMutableURLRequest *request = [self mutableURLRequestForPath:path];
    request.HTTPMethod = @"PROPFIND";
    
    [request setValue:[NSString stringWithFormat:@"%li", (long)depth] forHTTPHeaderField:@"Depth"];
    
    static NSString *xml = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?><D:propfind xmlns:D=\"DAV:\"><D:prop><D:href/><D:resourcetype/><D:creationdate/><D:getlastmodified/><D:getcontentlength/><D:response/></D:prop></D:propfind>";
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[xml dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self sendURLRequest:request completion:completion];
}

- (void)clearConnectionData
{
    connectionCompletion = NULL;
    connectionData = nil;
    downloadFileHandle = nil;
}

#pragma mark - Connection Delegates

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    connectionStatusCode = httpResponse.statusCode;
    connectionData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (downloadFileHandle)
        [downloadFileHandle writeData:data];
    else
        [connectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    BOOL authFailed = (connectionStatusCode == 401);
    if (authFailed) self.password = nil;
    
    BOOL statusOK = (connectionStatusCode >= 200 && connectionStatusCode < 300);
    if (!statusOK) {
        NSInteger code = authFailed ? CDEErrorCodeAuthenticationFailure : CDEErrorCodeServerError;
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"HTTP status code was %ld", (long)connectionStatusCode]};
        NSError *error = [NSError errorWithDomain:CDEErrorDomain code:code userInfo:userInfo];
        if (connectionCompletion) connectionCompletion(error, connectionStatusCode, nil);
    }
    else {
        if (connectionCompletion) connectionCompletion(nil, connectionStatusCode, connectionData);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    BOOL isAuthError = ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication);
    if (isAuthError) self.password = nil;
    if (connectionCompletion) connectionCompletion(error, -1, nil);
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSURLProtectionSpace *space = [challenge protectionSpace];
    
    if ([space.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] ||
        [space.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    else if (self.username && self.password && challenge.previousFailureCount == 0) {
		NSURLCredential *credentials = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
		[challenge.sender useCredential:credentials forAuthenticationChallenge:challenge];
		return;
	}
    else {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
    uploadInputStream = [NSInputStream inputStreamWithFileAtPath:uploadFilePath];
    return uploadInputStream;
}

@end


@implementation CDEWebDavResponseParser {
    NSXMLParser *xmlParser;
    NSMutableArray *mutableCloudItems;
    NSMutableString *characters;
    NSMutableDictionary *currentItemDictionary;
    
}

-(id)initWithData:(NSData *)data
{
    self = [super init];
    if ( self ) {
        xmlParser = [[NSXMLParser alloc] initWithData:data];
        xmlParser.delegate = self;
        mutableCloudItems = [[NSMutableArray alloc] init];
        xmlParser.delegate = self;
        characters = [[NSMutableString alloc] init];
    }
    return self;
}

- (NSArray *)cloudItems
{
    return [mutableCloudItems copy];
}

- (BOOL)element:(NSString *)element matchesNamespacedElement:(NSString *)other
{
    if ([element caseInsensitiveCompare:other] == NSOrderedSame) return YES;
    
    NSString *stringWithNamespace = [@"D:" stringByAppendingString:element];
    if ([stringWithNamespace caseInsensitiveCompare:other] == NSOrderedSame) return YES;
    
    NSString *stringWithOtherNamespace = [@"lp1:" stringByAppendingString:element];
    if ([stringWithOtherNamespace caseInsensitiveCompare:other] == NSOrderedSame) return YES;
    
    return NO;
}

- (BOOL)parse:(NSError * __autoreleasing *)error
{
    BOOL result = [xmlParser parse];
    *error = result ? nil : xmlParser.parserError;
    return result;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    characters.string = @"";
    if ([self element:elementName matchesNamespacedElement:@"D:response"]) {
        currentItemDictionary = [[NSMutableDictionary alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([self element:elementName matchesNamespacedElement:@"D:href"]) {
        currentItemDictionary[@"path"] = [characters copy];
    }
    else if ([self element:elementName matchesNamespacedElement:@"D:collection"]) {
        currentItemDictionary[@"isDirectory"] = @(YES);
    }
    else if ([self element:elementName matchesNamespacedElement:@"D:getcontentlength"]) {
        currentItemDictionary[@"fileSize"] = @(characters.longLongValue);
    }
    else if ([self element:elementName matchesNamespacedElement:@"lp1:getcontentlength"]) {
        currentItemDictionary[@"fileSize"] = @(characters.longLongValue);
    }
    else if ([self element:elementName matchesNamespacedElement:@"D:response"] && currentItemDictionary[@"path"]) {
        NSNumber *isDir = currentItemDictionary[@"isDirectory"];
        
        id item;
        if (isDir && isDir.boolValue) {
            CDECloudDirectory *cloudDir = [[CDECloudDirectory alloc] init];
            cloudDir.path = currentItemDictionary[@"path"];
            cloudDir.name = [cloudDir.path lastPathComponent];
            item = cloudDir;
        }
        else {
            CDECloudFile *cloudFile = [[CDECloudFile alloc] init];
            cloudFile.path = currentItemDictionary[@"path"];
            cloudFile.name = [cloudFile.path lastPathComponent];
            cloudFile.size = [currentItemDictionary[@"fileSize"] unsignedLongLongValue];
            item = cloudFile;
        }
        
        [mutableCloudItems addObject:item];
        
        currentItemDictionary = nil;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [characters appendString:string];
}

@end


