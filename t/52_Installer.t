
# $Id: 52_Installer.t,v 1.15 2007/11/16 21:36:00 martinthurn Exp $

use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.15 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use File::Path;
use Test::More;
use Tk;
use lib "../lib";



BEGIN {
    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan "no_plan";    # TODO Can't count tests atm
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok("Tk::Wizard::Installer");
}    # end of BEGIN block

my $WAIT   = $ENV{TEST_INTERACTIVE} ? 0 : 111;
my @asFrom = qw( 1 2 );
my @asDest = qw( 3 4 );

our $TEMP_DIR = 't/tmp';
mkdir( $TEMP_DIR, 0777 );
if ( !-d $TEMP_DIR ) {
    mkdir $TEMP_DIR or bail_out($!);
}    # if
my $testdir = "$TEMP_DIR/__perltk_wizard";
if ( !-d $testdir ) {
    mkdir $testdir or bail_out($!);
}    # if
for (@asFrom) {
    my $sFrom = "$testdir/$_";
    local *OUT;
    ok( open( OUT, '>', $sFrom ), qq'opened $sFrom for write' ) or bail_out($!);
    ok(
        print( OUT "Tk::Wizard::Installer Test. Please ignore or delete.\n\nThis is file $_\n\n"
              . scalar(localtime) . "\n\n"
        ),
        qq'wrote contents to $sFrom'
    );
    ok( close OUT, qq'closed $sFrom' );
}    # for 1,2
for (@asDest) {
    my $sDest = "$testdir/$_";
    unlink $sDest;

    # Make sure destination files to NOT exist:
    ok( !-e $sDest, qq'destination file $sDest does not exist before test' );
}    # for 3,4
if ( $ENV{TEST_INTERACTIVE} ) {

    # Add some stuff that will fail, so we can see what exactly happens:
    unshift @asFrom, 'no_such_file';
    unshift @asDest, 'no_such_dir';
}    # if

my $iPageCount = 0;
my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $wizard, 'Tk::Wizard::Installer' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

ok( $wizard->configure( -finishButtonAction => sub { ok( 1, 'Finished' ); 1 }, ), 'Configured' );
isa_ok( $wizard->cget( -finishButtonAction ), "Tk::Callback" );

# Create pages
#
my $SPLASH = $wizard->addSplashPage(
    -wait     => $WAIT,
    -title    => "Installer Test",
    -subtitle => "Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
    -text     => "Test Installer's addFileListPage feature for RT #19300."
);
is( $SPLASH, 1, 'Splash page is first' );
$iPageCount++;
ok(
    $wizard->addLicencePage(
        -wait     => $WAIT,
        -filepath => 't/dos.txt',
    ),
    'added DOS license page'
);
$iPageCount++;
ok(
    $wizard->addLicencePage(
        -wait     => $WAIT,
        -filepath => 't/unix.txt',
    ),
    'added UNIX license page'
);
$iPageCount++;
ok(
    $wizard->addLicencePage(
        -wait     => $WAIT,
        -filepath => 't/extra.txt',
    ),
    'added "extra" license page'
);
$iPageCount++;
ok(
    $wizard->addFileListPage(
        -slowdown => $ENV{TEST_INTERACTIVE} ? 2000 : 0,
        -wait     => $WAIT,
        -copy     => 1,
        -from => [ map { "$testdir/$_" } @asFrom ],
        -to   => [ map { "$testdir/$_" } @asDest ],
    ),
    'added File List page'
);
$iPageCount++;
ok(
    $wizard->addSplashPage(
        -wait     => $WAIT,
        -title    => "Finished",
        -subtitle => "Click 'Finish' to kill the Wizard.",
        -text     => "Please report bugs via rt.cpan.org"
    ),
    'Added finish page'
);
$iPageCount++;

isa_ok( $wizard->{wizardPageList}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{wizardPageList} } ), $iPageCount, 'Number of pages' );
foreach my $iPage ( 1 .. $iPageCount ) {
    isa_ok( $wizard->{wizardPageList}->[ $iPage - 1 ], 'CODE', qq'Page $iPage in list' );
}    # foreach

ok( $wizard->Show, "Show" );
MainLoop();
ok( 1, "Exited MainLoop" );

rmtree $TEMP_DIR;

sub bail_out {
    diag @_;
    exit;
}    # bail_out

__END__
