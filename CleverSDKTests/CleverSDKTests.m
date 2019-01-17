#import "CleverSDK.h"

SpecBegin(InitialSpecs)

describe(@"CleverLoginButton", ^{
    
    __block CleverLoginButton *button;
    
    before(^{
        button = [CleverLoginButton createLoginButton];
    });

    it(@"can set origin", ^{
        expect(button.frame.origin.x).to.beCloseTo(0);
        expect(button.frame.origin.y).to.beCloseTo(0);
        [button setOrigin:CGPointMake(10.0, 20.0)];
        expect(button.frame.origin.x).to.beCloseTo(10);
        expect(button.frame.origin.y).to.beCloseTo(20);
    });

    it(@"can set width", ^{
        expect(button.frame.size.width).to.beCloseTo(240);
        expect(button.frame.size.height).to.beCloseTo(52);
        [button setWidth:300];
        expect(button.frame.size.width).to.beCloseTo(300);
        expect(button.frame.size.height).to.beCloseTo(52);
    });

});

SpecEnd
