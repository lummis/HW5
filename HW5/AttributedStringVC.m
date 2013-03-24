//
//  AttributedStringVC.m
//  SPoT HW4
//
//  Created by Robert Lummis on 3/20/13.
//  Copyright (c) 2013 ElectricTurkeySoftware. All rights reserved.
//

#import "AttributedStringVC.h"

@interface AttributedStringVC ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation AttributedStringVC

-(void)setText:(NSAttributedString *)text {
    _text = text;
    self.textView.attributedText = text;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.textView.attributedText = self.text;
}

@end
