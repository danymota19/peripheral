//
//  ViewController.m
//  peripheral
//
//  Created by Daniela Mota on 5/31/15.
//  Copyright (c) 2015 Daniela Mota. All rights reserved.
//

#import "Peripheral.h"

@interface Peripheral ()

@end

@implementation Peripheral

NSString *selectedOption;

/**********************************************************************************************/
#pragma mark - Initialization
/**********************************************************************************************/
- (void)viewDidLoad {
    [super viewDidLoad];
    // Start up the CBPeripheralManager
    self.peripheralManager  = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}
//-------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//-------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // Don't keep it going while we're not showing.
    [self.peripheralManager stopAdvertising];
}

/**********************************************************************************************/
#pragma mark - Buttons functions
/**********************************************************************************************/

- (IBAction)btnSendBTPressed:(id)sender
{
    NSLog(@"btnSendBTPressed");
    // All we advertise is our service's UUID
    if (self.switchF.isOn || self.switchT.isOn ||self.switchC.isOn ) {
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
    }
    
}
/**********************************************************************************************/
#pragma mark - Peripheral Methods
/**********************************************************************************************/
/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState");
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn)
    {
        return;
    }
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
    // Start with the CBMutableCharacteristic
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
    
    // Then the service
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                                                       primary:YES];
    // Add the characteristic to the service
    transferService.characteristics = @[self.transferCharacteristic];
    // And add it to the peripheral manager
    [self.peripheralManager addService:transferService];
}
//-------------------------------------------------------------------------------
/** Catch when someone subscribes to our characteristic, then start sending them data */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    NSString *texto = [self.txtBT.text stringByAppendingString:selectedOption];
    
    // Get the data
    self.dataToSend         = [texto dataUsingEncoding:NSUTF8StringEncoding];

    // Reset the index
    self.sendDataIndex      = 0;
    
    // Start sending
    [self sendData];
}
//-------------------------------------------------------------------------------
/** Recognise when the central unsubscribes*/
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}
//-------------------------------------------------------------------------------
/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
    // Start sending again
    [self sendData];
}
//-------------------------------------------------------------------------------
- (void)sendData
{
    NSLog(@"sendData");
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM)
    {
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend)
        {
            // It did, so mark it as sent
            sendingEOM = NO;
            NSLog(@"Sent: EOM");
        }
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    // Is there any left to send?
    if (self.sendDataIndex >= self.dataToSend.length)
    {
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    while (didSend)
    {
        // Make the next chunk
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            return;
        }
    }
}

- (IBAction)swtFacebook:(id)sender {
    [self.switchC setOn:NO animated:YES];
    [self.switchT setOn:NO animated:YES];
    selectedOption= @"$Facebook";
}

- (IBAction)swtTwitter:(id)sender {
    [self.switchC setOn:NO animated:YES];
    [self.switchF setOn:NO animated:YES];
    selectedOption= @"$Twitter";
}

- (IBAction)swtCorreo:(id)sender {
    [self.switchF setOn:NO animated:YES];
    [self.switchT setOn:NO animated:YES];
    selectedOption= @"$Correo";
}


@end
