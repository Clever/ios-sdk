#import "CLVSuccessViewController.h"
#import "CLVCleverSDK.h"

@interface CLVSuccessViewController ()

@property (nonatomic, weak) IBOutlet UILabel *codeLabel;
@property (nonatomic, strong) NSString *code;

@end

@implementation CLVSuccessViewController

- (id)initWithCode:(NSString *)code {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.code = code;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.codeLabel.text = self.code;
}

@end
