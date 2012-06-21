////
////  RNCryptor.m
////
////  Copyright (c) 2012 Rob Napier
////
////  This code is licensed under the MIT License:
////
////  Permission is hereby granted, free of charge, to any person obtaining a
////  copy of this software and associated documentation files (the "Software"),
////  to deal in the Software without restriction, including without limitation
////  the rights to use, copy, modify, merge, publish, distribute, sublicense,
////  and/or sell copies of the Software, and to permit persons to whom the
////  Software is furnished to do so, subject to the following conditions:
////
////  The above copyright notice and this permission notice shall be included in
////  all copies or substantial portions of the Software.
////
////  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
////  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
////  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
////  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
////  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
////  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
////  DEALINGS IN THE SOFTWARE.
////
//
#import "RNCryptor.h"
#import "RNCryptor+Private.h"

NSString *const kRNCryptorErrorDomain = @"net.robnapier.RNCryptManager";

@implementation RNCryptor
@synthesize responseQueue = _responseQueue;
@synthesize engine = _engine;
@synthesize queue = _queue;

+ (NSData *)keyForPassword:(NSString *)password withSalt:(NSData *)salt andSettings:(RNCryptorKeyDerivationSettings)keySettings
{
  NSMutableData *derivedKey = [NSMutableData dataWithLength:keySettings.keySize];

  int result = CCKeyDerivationPBKDF(keySettings.PBKDFAlgorithm,         // algorithm
                                    password.UTF8String,                // password
                                    password.length,                    // passwordLength
                                    salt.bytes,                         // salt
                                    salt.length,                        // saltLen
                                    keySettings.PRF,                    // PRF
                                    keySettings.rounds,                 // rounds
                                    derivedKey.mutableBytes,            // derivedKey
                                    derivedKey.length);                 // derivedKeyLen

  // Do not log password here
  // TODO: Is is safe to assert here? We read salt from a file (but salt.length is internal).
  NSAssert(result == kCCSuccess, @"Unable to create AES key for password: %d", result);

  return derivedKey;
}

+ (NSData *)randomDataOfLength:(size_t)length
{
  NSMutableData *data = [NSMutableData dataWithLength:length];

  int result = SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
  NSAssert(result == 0, @"Unable to generate random bytes: %d", errno);

  return data;
}

- (id)init
{
  self = [super init];
  if (self) {
    _responseQueue = dispatch_get_current_queue();
    dispatch_retain(_responseQueue);

    NSString *queueName = [@"net.robnapier." stringByAppendingString:NSStringFromClass([self class])];
    _queue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);

  }
  return self;
}

- (void)dealloc
{
  [self cleanup];
  if (_responseQueue) {
    dispatch_release(_responseQueue);
    _responseQueue = NULL;
  }
}

- (void)cleanup
{
  _engine = nil;

  if (_queue) {
    dispatch_release(_queue);
    _queue = NULL;
  }
}

- (void)setResponseQueue:(dispatch_queue_t)aResponseQueue
{
  if (aResponseQueue) {
    dispatch_retain(aResponseQueue);
  }

  if (_responseQueue) {
    dispatch_release(_responseQueue);
  }

  _responseQueue = aResponseQueue;
}

@end