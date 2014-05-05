//
//  INRoseView.m
//  InjectionDemo
//
//  Created by John Holdsworth on 12/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//  $Id: $
//

#import "INRoseView.h"

static float power, radius;

static float psin( float phi ) {
    float s = sin( phi );
    return (s<0?-1:1) * powf( fabs( s ), power ) * radius;
}

static float pcos( float phi ) {
    return psin( phi + M_PI_2 );
}

@interface INRoseView ()

@property (assign, nonatomic) float roseOffset;
@property (assign, nonatomic) float colorOffset;
@property (assign, nonatomic) BOOL animating;

@end

@implementation INRoseView

- (void)awakeFromNib {
    [self animate:self];
}

// edit method and save to see your changes take effect //
- (void)drawRect:(CGRect)rect
{
    // affects "squareness" of the spiral
    // reference to control panel parameter
    power = 1.;

    // spacing between lines
    float dphi = .1;

    // spacing between circuits
    float rphi = .9;

    // Drawing code
	CGContextRef cg = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    radius = rect.size.width/2.;

    // initial parameters for the spiral
    float x0 = radius, y0 = radius+12, phi0 = self.roseOffset, phi1 = self.roseOffset + M_PI,
        colorphi = self.colorOffset;


    // draw lines until angle phi0 catches up with phi1
    while ( phi0 < phi1 ) {
        
        // color rotates around color circle as lines are drawn
        CGFloat Y = .5, U = sin(colorphi), V = cos(colorphi);
        CGFloat R = Y + 1.4075 * V;
        CGFloat G = Y - 0.3455 * U - 0.7169 * V;
        CGFloat B = Y + 1.7790 * U;
        
        CGFloat cols[4] = {R,G,B,1.};
        CGColorRef cgc = CGColorCreate( cs, cols );
        CGContextSetStrokeColorWithColor( cg, cgc );
        CGColorRelease(cgc);
        
        // draw colored line across circle
        CGContextMoveToPoint( cg, x0 + psin( phi0 ), y0 + pcos( phi0 ) );
        CGContextAddLineToPoint( cg, x0 + psin( phi1 ), y0 + pcos( phi1 ) );
        CGContextDrawPath( cg, kCGPathStroke );
        
        // move line and color phase on.
        phi0 += dphi;
        phi1 += dphi * rphi;

        colorphi += dphi * 01.;
    }
    
    CGColorSpaceRelease(cs);
}

- (void)animate {
    if ( !self.animating )
        return;

    // edit and save to see changes
    self.roseOffset -= .09; // rotate rose
    self.colorOffset -= .13; // rotate colors

    [self setNeedsDisplay];

    // object oriented parameter reference
    float delay = 01.;
    [self performSelector:@selector(animate) withObject:nil afterDelay:.05*delay];
}

- (IBAction)animate:sender {
    if ( (self.animating = !self.animating) )
        [self animate];
}

@end
