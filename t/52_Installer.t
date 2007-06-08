
# $Id: 52_Installer.t,v 1.10 2007/06/08 00:57:01 martinthurn Exp $

use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.10 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More ;
use Tk;

BEGIN
  {
  my $mwTest;
  eval { $mwTest = Tk::MainWindow->new };
  if ($@)
    {
    plan skip_all => 'Test irrelevant without a display';
    }
  else
    {
    plan "no_plan"; # TODO Can't count tests atm
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  use_ok("Tk::Wizard::Installer");
  } # end of BEGIN block

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
        print( OUT
"Tk::Wizard::Installer Test. Please ignore or delete.\n\nThis is file $_\n\n"
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

my $iPageCount = 0;
my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $wizard, 'Tk::Wizard::Installer' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

ok(
    $wizard->configure(
        -preNextButtonAction => sub { &preNextButtonAction($wizard) },
        -finishButtonAction  => sub { ok( 1, 'Finished' ); 1 },
    ),
    'Configured'
);

isa_ok( $wizard->cget( -preNextButtonAction ), "Tk::Callback" );
isa_ok( $wizard->cget( -finishButtonAction ),  "Tk::Callback" );

# Create pages
#
my $SPLASH = $wizard->addPage( sub { page_splash($wizard) } );
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
        -wait => $WAIT,
        -copy => 1,
        -from => [ map { "$testdir/$_" } @asFrom ],
        -to   => [ map { "$testdir/$_" } @asDest ],
    ),
    'added File List page'
);
$iPageCount++;
ok(
    $wizard->addPage(
        sub {
            return $wizard->blank_frame(
                -wait     => $WAIT,
                -title    => "Finished",
                -subtitle => "Please press Finish to leave the Wizard.",
                -text     => "Please report bugs via rt.cpan.org - thanks!"
            );
        }
    ),
    'Add finish page'
);
$iPageCount++;

isa_ok( $wizard->{wizardPageList}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{wizardPageList} } ), $iPageCount, 'Number of pages' );
foreach my $iPage ( 1 .. $iPageCount ) {
    isa_ok( $wizard->{wizardPageList}->[ $iPage - 1 ],
        'CODE', qq'Page $iPage in list' );
}    # foreach

ok( $wizard->Show, "Show" );
Tk::Wizard::Installer::MainLoop();
ok( 1, "Exited MainLoop" );

for (@asFrom) {
    unlink $testdir . "/$_";
}    # for
for (@asDest) {
    my $sDest = "$testdir/$_";
    ok( -e ($sDest), qq'File copied to $sDest' );
    unlink $sDest or diag "Can not remove $sDest: $!";
}    # for

unlink $testdir;

sub page_splash {
    my $wizard = shift;
    my ( $frame, @pl ) = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Installer Test",
        -subtitle =>
          "Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
        -text => "Test Installer's addFileListPage feature for RT #19300."
    );
    return $frame;
}    # page_splash

sub preNextButtonAction { return 1; }

sub bail_out {
    diag @_;
    exit;
}    # bail_out

__END__
