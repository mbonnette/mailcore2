//
//  test-all-mac.cpp
//  mailcore2
//
//  Created by Hoa Dinh on 11/12/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#include "test-all-mac.h"

#include <MailCore/MailCore.h>

extern "C" {
	extern int mailstream_debug;
}

static mailcore::String * password = NULL;
static mailcore::String * displayName = NULL;
static mailcore::String * email = NULL;
static mailcore::String * hostname = NULL;
static unsigned int port = NULL;
static MCOConnectionType connectionType = NULL;

static void testProviders() {
  NSString *filename =  [[NSBundle bundleForClass:[MCOMessageBuilder class]] pathForResource:@"providers" ofType:@"json"];
  mailcore::MailProvidersManager::sharedManager()->registerProvidersWithFilename(filename.mco_mcString);
  
  NSLog(@"Providers: %s", MCUTF8DESC(mailcore::MailProvidersManager::sharedManager()->providerForEmail(MCSTR("email1@gmail.com"))));
}


MCOIMAPFolder * findTradeFolder(NSArray *folders) {
	MCOIMAPFolder * retFolder = NULL;
	
	for (MCOIMAPFolder * folder in folders) {
		if ( [[folder path] isEqualToString:@"INBOX"] ) {
//			if ( [[folder path] isEqualToString:@"Trades"] ) {
			retFolder = folder;
		}
	}
	return retFolder;
}


NSString * getMessageBody(MCOIMAPSession *session, MCOIMAPFolder *folder, MCOIMAPMessage *msg) {
	
	__block NSString * plainTextBody = NULL;
	
	MCOIMAPFetchParsedContentOperation * op = [session fetchParsedMessageOperationWithFolder:[folder path] uid:[msg uid]];
	
	[op start:^(NSError * __nullable error, MCOMessageParser * parser) {
		
		plainTextBody = [parser plainTextBodyRendering];
	}];
	
	return plainTextBody;
}


void iterateMessages(MCOIMAPSession *session, MCOIMAPFolder *folder) {
	
	//MCOIndexSet *indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(1, 5)];
	MCOIndexSet *indexSet = [MCOIndexSet indexSetWithRange:MCORangeMake(1, UINT64_MAX)];
	
	MCOIMAPFetchMessagesOperation * op = [session fetchMessagesOperationWithFolder:[folder path]
																	   requestKind:MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure
																			  uids:indexSet];
	[op start:^(NSError * __nullable error, NSArray * messages, MCOIndexSet * vanishedMessages) {
		for(MCOIMAPMessage * msg in messages) {
			NSString * body = getMessageBody(session, folder, msg);
			NSLog(@"UID:%u MessageID:%@  %@  %@ ", [msg uid], [[msg header] messageID], [[msg header] subject], body);
		}
	}];
	
}



void testObjC()
{
  MCOIMAPSession *session = [[MCOIMAPSession alloc] init];
  session.username = [NSString mco_stringWithMCString:email];
  session.password = [NSString mco_stringWithMCString:password];
  session.hostname = [NSString mco_stringWithMCString:hostname];
  session.port = port;
  session.connectionType = connectionType;
	
	
  NSLog(@"check account");
  MCOIMAPOperation *checkOp = [session checkAccountOperation];
  [checkOp start:^(NSError *err) {
    NSLog(@"check account done");
    if (err) {
      NSLog(@"Oh crap, an error %@", err);
    } else {
      NSLog(@"CONNECTED");
      NSLog(@"fetch all folders");
      MCOIMAPFetchFoldersOperation *foldersOp = [session fetchAllFoldersOperation];
      [foldersOp start:^(NSError *err, NSArray *folders) {
        NSLog(@"fetch all folders done");
        if (err) {
          NSLog(@"Oh crap, an error %@", err);
        } else {
          NSLog(@"Folder %@", folders);
			
			MCOIMAPFolder *tradeFolder = findTradeFolder(folders);
			NSLog(@"....And the folder is: %@", [tradeFolder path]);
			
			iterateMessages(session, tradeFolder);
        }
      }];
    }
  }];
  
  
  [[NSRunLoop currentRunLoop] run];
// MDB  [session autorelease];
}



void testAllMac()
{
  mailcore::setICUDataDirectory(MCSTR("/usr/local/share/icu"));
  
  mailcore::AutoreleasePool * pool = new mailcore::AutoreleasePool();
  MCLogEnabled = 1;
	mailstream_debug = 1;

	testProviders();
    
//    email = MCSTR("mbonnette@gmail.com");
//    password = MCSTR("6hX-5W7-Kma-Erw");
//    displayName = MCSTR("My gmail");
//    hostname = MCSTR("imap.gmail.com");
//    port = 993;
//    connectionType = MCOConnectionTypeTLS;
//    testObjC();
    
    email = MCSTR("mbonnette");
    password = MCSTR("eigo-enoi-xwct-mxnn");
    displayName = MCSTR("My mac.com");
    hostname = MCSTR("imap.mail.me.com");
    port = 993;
    connectionType = MCOConnectionTypeTLS;
    testObjC();
    
  pool->release();
}
