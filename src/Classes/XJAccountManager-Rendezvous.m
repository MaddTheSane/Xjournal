//
//  XJAccountManager-Rendezvous.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 10 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJAccountManager-Rendezvous.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import <errno.h>

#define kServiceDomain @""
#define kServiceType @"_xjournal._tcp."
#define kServicePort 7777
#define kServiceName [[self defaultAccount] username]

@implementation XJAccountManager (Rendezvous)
- (void)applicationWillTerminate: (NSNotification *)note
{
    [self unpublishNetService];
}

- (void)publishNetService
{
    published = YES;

    if(![self defaultAccount]) return;
    
    servicePort = kServicePort;

    [self createListeningSocket];
    
    //if(!publisher) {
    // lazily instantiate the NSNetService object that will advertise on our behalf.
    if(publisher) {
        [publisher release];
        publisher = nil;
    }
    publisher = [[NSNetService alloc] initWithDomain: kServiceDomain type: kServiceType name: kServiceName port: servicePort];
    [publisher setDelegate:self];
    //}

    if(publisher && listeningSocket) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionReceived:) name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
        [listeningSocket acceptConnectionInBackgroundAndNotify];
        [publisher publish];
    }
}

- (void)unpublishNetService
{
    published = NO;

    [publisher stop];
    [self destroyListeningSocket];
    
    NSLog(@"Unpublished netservice");
}

- (void)connectionReceived: (NSNotification *)aNotification
{
    NSFileHandle * incomingConnection = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    //NSData * representationToSend = [[NSString stringWithFormat:@"Whee! You got it!\n"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData * representationToSend = [self rendezvousDataRepresentation];
    [[aNotification object] acceptConnectionInBackgroundAndNotify];
    [incomingConnection writeData:representationToSend];
    [incomingConnection closeFile];
}

- (void)beginBrowsing
{
    discoveredServices = [[NSMutableArray arrayWithCapacity: 10] retain];
    [browser searchForServicesOfType: kServiceType inDomain: kServiceDomain];
    browsing = YES;
}

- (void)endBrowsing
{
    [discoveredServices release];
    discoveredServices = nil;
    [browser stop];
    browsing = NO;
}

// ----------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------
// Publishing delegate
// ----------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"didNotResolve");
    id errorCode = [errorDict objectForKey: NSNetServicesErrorCode];

    switch([errorCode intValue]) {

        case NSNetServicesCollisionError:
            NSLog(@"NSNetServicesCollisionError");
            break;
        case NSNetServicesNotFoundError:
            NSLog(@"NSNetServicesNotFoundError");
            break;
        case NSNetServicesActivityInProgress:
            NSLog(@"NSNetServicesActivityInProgress");
            break;
        case NSNetServicesBadArgumentError:
            NSLog(@"NSNetServicesBadArgumentError");
            break;
        case NSNetServicesCancelledError:
            NSLog(@"NSNetServicesCancelledError");
            break;
        case NSNetServicesInvalidError:
            NSLog(@"NSNetServicesInvalidError");
            break;
        case NSNetServicesUnknownError:
            NSLog(@"NSNetServicesUnknownError");
            break;
    }
    
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    if([sender isEqualTo: publisher] && waitingToRepublish) {
        NSLog(@"Got service stopped and republishing....");
        [publisher release];
        publisher = nil;
        [self publishNetService];
    }
}

- (void)netServiceWillPublish:(NSNetService *)sender
{
    waitingToRepublish = NO;
}
//- (void)netServiceWillResolve:(NSNetService *)sender {}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    id errorCode = [errorDict objectForKey: NSNetServicesErrorCode];

    switch([errorCode intValue]) {

        case NSNetServicesCollisionError:
            NSLog(@"NSNetServicesCollisionError");
            break;
        case NSNetServicesNotFoundError:
            NSLog(@"NSNetServicesNotFoundError");
            break;
        case NSNetServicesActivityInProgress:
            NSLog(@"NSNetServicesActivityInProgress");
            break;
        case NSNetServicesBadArgumentError:
            NSLog(@"NSNetServicesBadArgumentError");
            break;
        case NSNetServicesCancelledError:
            NSLog(@"NSNetServicesCancelledError");
            break;
        case NSNetServicesInvalidError:
            NSLog(@"NSNetServicesInvalidError");
            break;
        case NSNetServicesUnknownError:
            NSLog(@"NSNetServicesUnknownError");
            break;
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)service
{
    int firstOctet, secondOctet, thirdOctet, fourthOctet;
    NSData * address = [[service addresses] objectAtIndex:0];
    struct sockaddr_in *socketAddress = (struct sockaddr_in *)[address bytes];
    NSString * ipAddressString;
    NSString * portString;
    int socketToRemoteServer;

    firstOctet = (socketAddress->sin_addr.s_addr & 0xFF000000) >> 24;
    secondOctet = (socketAddress->sin_addr.s_addr & 0x00FF0000) >> 16;
    thirdOctet = (socketAddress->sin_addr.s_addr & 0x0000FF00) >> 8;
    fourthOctet = (socketAddress->sin_addr.s_addr & 0x000000FF) >> 0;

    ipAddressString = [NSString stringWithFormat:@"%d.%d.%d.%d", firstOctet, secondOctet, thirdOctet, fourthOctet];
    if([ipAddressString isEqualTo: @"0.0.0.0"] || [ipAddressString isEqualTo: @"127.0.0.1"])
        return; // Bail out.
    
    portString = [NSString stringWithFormat:@"%d", socketAddress->sin_port];

    NSLog(@"Resolved Rendezvous service on %@:%@", ipAddressString, portString);
    
    socketToRemoteServer = socket(AF_INET, SOCK_STREAM, 0);
    if(socketToRemoteServer > 0) {
        NSFileHandle * remoteConnection = [[NSFileHandle alloc] initWithFileDescriptor:socketToRemoteServer closeOnDealloc:YES];
        if(remoteConnection) {
            if(connect(socketToRemoteServer, (struct sockaddr *)socketAddress, sizeof(*socketAddress)) == 0) {
                currentServiceName = [service name];
                [remoteConnection readToEndOfFileInBackgroundAndNotify];
            }
        }
    }
}

- (void)socketHandleNotification: (NSNotification *)note
{
    NSData *readData = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];

    [self initialiseRendezvousRepresentation: readData serviceName: currentServiceName];

    [[NSNotificationCenter defaultCenter] postNotificationName: XJRendezvousAccountsUpdated object:self];
}

// ----------------------------------------------------------------------------------------
// Browse delegate
// ----------------------------------------------------------------------------------------

//- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {}
//- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {}
//- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing {}
//- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser{}
//- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser {}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [discoveredServices addObject: aNetService];
    [aNetService setDelegate: self];
    [aNetService resolve];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [discoveredServices removeObject: aNetService];
    [self removeDiscoveredAccountsFromService: [aNetService name]];

    if(!moreComing) {
        [[NSNotificationCenter defaultCenter] postNotificationName: XJRendezvousAccountsUpdated object:self];
    }
}

// ----------------------------------------------------------------------------------------
// Other Rendezvous-specific stuff
// ----------------------------------------------------------------------------------------
- (void)handleIPAddressChange
{
    if(published) {
        NSLog(@"Handle IP Address Change");
        if(!gotFirstIPNotification) {
            gotFirstIPNotification = YES;
            [self unpublishNetService];
            [self endBrowsing];
            [discoveredAccounts release];
            discoveredAccounts = nil;
        }
        else {
            gotFirstIPNotification = NO;
            discoveredAccounts = [[NSMutableDictionary dictionaryWithCapacity: 10] retain];
            [self publishNetService];
            [self beginBrowsing];
        }
    }
}

- (void)publishFirstAccount: (NSNotification *)note
{
    return;
}

- (NSData *)rendezvousDataRepresentation
{
    NSMutableData *data;
    NSKeyedArchiver *archiver;

    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    // Customize archiver here
    [archiver encodeObject: [accounts allValues] forKey: @"accounts"];
    [archiver finishEncoding];
    [archiver release];
    return data;
}

- (void)initialiseRendezvousRepresentation: (NSData *)data serviceName: (NSString *)sName
{
    NSLog(@"initialiseRendezvousRepresentation.  For service name: %@", sName);
    
    if(data && [data length] > 0) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSArray *unarchivedAccounts = [[unarchiver decodeObjectForKey: @"accounts"] retain];
        [unarchiver finishDecoding];
        
        if(unarchivedAccounts && sName) // Just make sure we don't try to insert nil
            [discoveredAccounts setObject: unarchivedAccounts forKey: sName];
        
        [unarchivedAccounts release]; // Crashing here sometimes.
        [unarchiver release];
    }
}

- (void)removeDiscoveredAccountsFromService: (NSString *)service
{
    [discoveredAccounts removeObjectForKey: service];
}

- (NSArray *)discoveredAccounts
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [[discoveredAccounts allValues] objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        [array addObjectsFromArray: object];
    }
    return array;
}

- (void)createListeningSocket
{
    if(!listeningSocket) {
        // Here, create the socket from traditional BSD socket calls, and then set up an NSFileHandle with that to listen for incoming connections.
        int fdForListening;
        struct sockaddr_in serverAddress;
        
        // In order to use NSFileHandle's acceptConnectionInBackgroundAndNotify method, we need to create a file descriptor that is itself a socket, bind that socket, and then set it up for listening. At this point, it's ready to be handed off to acceptConnectionInBackgroundAndNotify.
        if((fdForListening = socket(AF_INET, SOCK_STREAM, 0)) > 0) {
            memset(&serverAddress, 0, sizeof(serverAddress));
            serverAddress.sin_family = AF_INET;
            serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
            serverAddress.sin_port = htons(servicePort);
            
            // This is a little bit cagey. Since NSNetServices allows us to publish the service and discover it without any prior knowledge, we can just chase up the ports until we hit one that we can bind. Then, we'll use that port to initialize the NSNetService with. This takes care of starting and stopping the service inside of the TCP standoff when you can't just immediately rebind a port.
            while(bind(fdForListening, (struct sockaddr *)&serverAddress, sizeof(serverAddress)) < 0) {
                servicePort++;
                serverAddress.sin_port = htons(servicePort);
            }
            NSLog(@"Bound listening socket");
            // Once we're here, we know bind must have returned, so we can start the listen
            if(listen(fdForListening, 1) == 0) {
                listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor:fdForListening closeOnDealloc:YES];
            }
        }
    }
}

- (void)destroyListeningSocket
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
    // There is at present no way to get an NSFileHandle to -stop- listening for events, so we'll just have to tear it down and recreate it the next time we need it.
    [listeningSocket release];
    listeningSocket = nil;    
}
@end
