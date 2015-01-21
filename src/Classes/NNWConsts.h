//
//  NNWConsts.h
//  Xjournal
//
//  Created by C.W. Betts on 1/20/15.
//
//

#ifndef Xjournal_NNWConsts_h
#define Xjournal_NNWConsts_h

#import <Foundation/Foundation.h>

// NetNewsWire Integration
typedef NS_ENUM(AEKeyword, NetNewsWireTypes) {
    NNWEditDataItemAppleEventClass = 'EBlg',
    NNWEditDataItemAppleEventID = 'oitm',
    NNWDataItemTitle = 'titl',
    NNWDataItemDescription = 'desc',
    NNWDataItemSummary = 'summ',
    NNWDataItemLink = 'link',
    NNWDataItemPermalink = 'plnk',
    NNWDataItemSubject = 'subj',
    NNWDataItemCreator = 'crtr',
    NNWDataItemCommentsURL = 'curl',
    NNWDataItemGUID = 'guid',
    NNWDataItemSourceName = 'snam',
    NNWDataItemSourceHomeURL = 'hurl',
    NNWDataItemSourceFeedURL = 'furl'
};

#endif
