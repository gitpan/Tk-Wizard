
# $Id: 50_Installer.t,v 1.11 2007/10/02 03:04:48 martinthurn Exp $

use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.11 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use File::Path;
use LWP::UserAgent;
use Test::More;
use Tk;

BEGIN {
    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
        exit;
    }    # if
    $mwTest->destroy if Tk::Exists($mwTest);
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my $response = $ua->get('http://search.cpan.org/');
    if ( $response->is_error ) {
        plan skip_all => "LWP cannot get cpan, guess we're not able to get online";
        exit;
    }    # if
    plan tests => 23;
    pass('can get cpan');
    use_ok("Tk::Wizard");
    use_ok("Tk::Wizard::Installer");
}    # end of BEGIN block

my $WAIT      = 100;
my $sTestDir  = 't/temp';
my $rhssFiles = {
    'http://www.cpan.org/'      => "$sTestDir/cpan_index.html",
    'http://www.leegoddard.net' => "$sTestDir/lee.html",
};
my @asDest = values %$rhssFiles;
my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $wizard, 'Tk::Wizard::Installer' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

ok(
    $wizard->configure(
        -preNextButtonAction => sub { &preNextButtonAction($wizard); },
        -finishButtonAction  => sub { pass('Finished'); 1; },
    ),
    'Configure'
);

isa_ok( $wizard->cget( -preNextButtonAction ), "Tk::Callback" );
isa_ok( $wizard->cget( -finishButtonAction ),  "Tk::Callback" );

# Create pages
#
my $SPLASH = $wizard->addPage( sub { page_splash($wizard) } );
is( $SPLASH, 1, 'Splash page is first' );

ok(
    $wizard->addDownloadPage(
        -wait  => $WAIT,
        -files => $rhssFiles,

        #-on_error => 1,
        -no_retry => 1,
    ),
    'addDownloadPage'
);

ok(
    $wizard->addPage(
        sub {
            return $wizard->blank_frame(
                -wait     => $WAIT,
                -title    => "Finished",
                -subtitle => "Please.",
            );
        }
    ),
    'Add finish page'
);

isa_ok( $wizard->{wizardPageList}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{wizardPageList} } ), 3, 'Number of pages' );
foreach ( 1 .. 3 ) {
    isa_ok( $wizard->{wizardPageList}->[0], 'CODE', 'Page in list' );
}    # foreach

foreach my $sFname (@asDest) {
    unlink $sFname;    # Ignore return code
    ok( !-f $sFname, "before test, destination local file $sFname does not exist" );
}    # foreach
ok( $wizard->Show, "Show" );
Tk::Wizard::Installer::MainLoop();
pass("Exited MainLoop");
foreach my $sFname (@asDest) {
    ok( -f $sFname, "destination local file $sFname exists" );
}    # foreach
rmtree $sTestDir;
exit;

sub page_splash {
    my $wizard = shift;
    my ( $frame, @pl ) = $wizard->blank_frame(
        -wait     => $WAIT,
        -title    => "Installer Test",
        -subtitle => "Testing",
    );
    return $frame;
}    # page_splash

sub preNextButtonAction { return 1; }

__END__
