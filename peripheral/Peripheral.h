//
//  ViewController.h
//  peripheral
//
//  Created by Daniela Mota on 5/31/15.
//  Copyright (c) 2015 Daniela Mota. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "Declarations.h"

@interface Peripheral : UIViewController<CBPeripheralDelegate, CBPeripheralManagerDelegate>

//BT properties
@property (strong, nonatomic)       CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic)       CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic)       NSData                    *dataToSend;
@property (nonatomic, readwrite)    NSInteger                 sendDataIndex;

//Texts
@property (weak, nonatomic) IBOutlet UITextField *txtBT;

//Actions

- (IBAction)btnSendBTPressed:(id)sender;


//switch

- (IBAction)swtTwitter:(id)sender;
- (IBAction)swtCorreo:(id)sender;
- (IBAction)swtFacebook:(id)sender;

//outlet

@property (weak, nonatomic) IBOutlet UISwitch *switchF;

@property (weak, nonatomic) IBOutlet UISwitch *switchT;

@property (weak, nonatomic) IBOutlet UISwitch *switchC;

@end

