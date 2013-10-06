//
//  MTWInAppPurchase.m
//  BlendLab
//
//  Created by CaiYu on 13-8-8.
//  Copyright (c) 2013年 Meituwan. All rights reserved.
//

#import "MTWInAppPurchase.h"

#define kUserDefaultsKey @"BoughtProducts"

@interface MTWInAppPurchase () {
    NSMutableDictionary *productsDic;
}

@end

@implementation MTWInAppPurchase

+ (MTWInAppPurchase*)sharedPurchase
{
    static MTWInAppPurchase *sharedPurchase;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPurchase=[[MTWInAppPurchase alloc]init];
    });
    return sharedPurchase;
}

- (id)init
{
    self=[super init];
    if (self) {
        productsDic=[[NSMutableDictionary alloc]init];
        [[SKPaymentQueue defaultQueue]addTransactionObserver:self];
    }
    return self;
}

- (void)requestProducts
{
    SKProductsRequest *request=[[SKProductsRequest alloc]initWithProductIdentifiers:self.productIDs];
    request.delegate=self;
    [request start];
}

- (void)buy:(NSString *)productID
{
    SKProduct *product=[productsDic valueForKey:productID];
    if (product==nil) {
        return;
    }
    SKPayment *payment=[SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue]addPayment:payment];
}

- (void)restore
{
    [[SKPaymentQueue defaultQueue]restoreCompletedTransactions];
}

- (BOOL)canBuy
{
    return [SKPaymentQueue canMakePayments];
}

- (NSArray*)haveBoughtProducts
{
    return [[NSUserDefaults standardUserDefaults]valueForKey:kUserDefaultsKey];
}

- (BOOL)boughtProduct:(NSString *)productID
{
    NSArray *boughtProducts=[self haveBoughtProducts];
    return [boughtProducts containsObject:productID];
}

- (NSString*)getPriceWithLocale:(NSString *)productID
{
    SKProduct *product=[productsDic valueForKey:productID];
    if (product==nil) {
        return @"$1.99";
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    return formattedString;
}

- (void)setProductIDs:(NSSet *)productIDs
{
    _productIDs=productIDs;
    productsDic=[[NSMutableDictionary alloc]init];
}

- (void)clearAllBuyRecords
{
    NSMutableArray *products=[[NSMutableArray alloc]init];
    [[NSUserDefaults standardUserDefaults]setObject:products forKey:kUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

#pragma mark -
#pragma mark SKProductsRequest Delegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products) {
        [productsDic setObject:product forKey:product.productIdentifier];
    }
    [self.delegate productsRequestResponce];
}

#pragma mark SKPayment Transaction Observer
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            {
                NSMutableArray *products=[[NSMutableArray alloc]initWithArray:[self haveBoughtProducts]];
                if (![products containsObject:transaction.payment.productIdentifier]) {
                    [products addObject:transaction.payment.productIdentifier];
                    [[NSUserDefaults standardUserDefaults]setObject:products forKey:kUserDefaultsKey];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                    [self.observer buySuccess:transaction.payment.productIdentifier];
                }
                [[SKPaymentQueue defaultQueue]finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored:
            {
                NSMutableArray *products=[[NSMutableArray alloc]initWithArray:[self haveBoughtProducts]];
                if (![products containsObject:transaction.payment.productIdentifier]) {
                    [products addObject:transaction.payment.productIdentifier];
                    [[NSUserDefaults standardUserDefaults]setObject:products forKey:kUserDefaultsKey];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                    [self.observer restoreSuccess:transaction.payment.productIdentifier];
                }
                [[SKPaymentQueue defaultQueue]finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateFailed:
            {
                [[SKPaymentQueue defaultQueue]finishTransaction:transaction];
                [self.observer buyFailed:transaction.payment.productIdentifier];
            }
                
            default:
                break;
        }
    }
}

@end
