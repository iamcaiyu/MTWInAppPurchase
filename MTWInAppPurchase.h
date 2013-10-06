//
//  MTWInAppPurchase.h
//  BlendLab
//
//  Created by CaiYu on 13-8-8.
//  Copyright (c) 2013年 Meituwan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol MTWInAppPurchaseDelegate;
@protocol MTWInAppPurchasePaymentObserver;

@interface MTWInAppPurchase : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSSet *productIDs;
@property (nonatomic, weak) id<MTWInAppPurchaseDelegate> delegate;
@property (nonatomic, weak) id<MTWInAppPurchasePaymentObserver> observer;

- (void)buy:(NSString*)productID;
- (void)restore;
- (BOOL)canBuy;
- (void)requestProducts;
- (NSArray*)haveBoughtProducts;
- (BOOL)boughtProduct:(NSString*)productID;
- (NSString*)getPriceWithLocale:(NSString*)productID;
- (void)clearAllBuyRecords;

+ (MTWInAppPurchase*)sharedPurchase;

@end

@protocol MTWInAppPurchaseDelegate <NSObject>

- (void)productsRequestResponce;

@end

@protocol MTWInAppPurchasePaymentObserver <NSObject>

- (void)buySuccess:(NSString*)productID;
- (void)buyFailed:(NSString*)productID;
- (void)restoreSuccess:(NSString*)productID;

@end
