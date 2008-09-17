
# $Id: 52_Installer.t,v 1.15 2007/11/16 21:36:00 martinthurn Exp $

use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.15 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use File::Path;
use Test::More;
use Tk;
use lib qw(../lib . t/);
use Cwd;

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
    use_ok('WizTestSettings');
}



chdir ".." if getcwd =~ /\Wt$/;
my $WAIT   = $ENV{TEST_INTERACTIVE} ? 0 : 111;

my @form = qw( 1 2 );
my @dest = qw( 3 4 );

my $TEMP_DIR = 't/tmp';
mkdir( $TEMP_DIR, 0777 );
if ( !-d $TEMP_DIR ) {
    mkdir $TEMP_DIR or bail_out($!);
}

my $testdir = "$TEMP_DIR/__perltk_wizard/";
mkdir $testdir or bail_out($!)
	if not -d $testdir;

my $uninstall_db = getcwd."/t/uninstall.db";


# DBM files of uninstaller may be lying around during dev
unlink $uninstall_db.'.dir' if -e $uninstall_db.'.dir';
unlink $uninstall_db.'.pag' if -e $uninstall_db.'.pag';


for (@form) {
    my $form = "$testdir/$_";
    local *OUT;
    ok( open( OUT, '>', $form ), "opened $form for write" ) or bail_out($!);
    ok( print OUT "Tk::Wizard::Installer Test. Please ignore or delete.\n\nThis is file $_\n\n"
        . scalar(localtime) . "\n\n"
        . "wrote contents to $form"
    );
    ok( close OUT, "closed $form");
}

for (@dest) {
    my $sDest = "$testdir/$_";
    unlink $sDest;
    # Make sure destination files to NOT exist:
    ok( !-e $sDest, "destination file $sDest does not exist before test" );
}

if ( $ENV{TEST_INTERACTIVE} ) {
    # Add some stuff that will fail, so we can see what exactly happens:
    unshift @form, 'no_such_file';
    unshift @dest, 'no_such_dir';
}

my $page_count = 0;
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
$page_count++;

ok(
    $wizard->addFileCopyPage(
        -slowdown 	=> $ENV{TEST_INTERACTIVE} ? 2000 : 0,
        -wait     	=> $WAIT,
        -copy     	=> 1,
        -from 		=> [ map { "$testdir/$_" } @form ],
        -to   		=> [ map { "$testdir/$_" } @dest ],
        -uninstall_db => $uninstall_db,
    ),
    'Added File List page'
);
$page_count++;


ok(
    $wizard->addSplashPage(
        -wait     => $WAIT,
        -title    => "Finished",
        -subtitle => "Click 'Finish' to kill the Wizard.",
        -text     => "Please report bugs via rt.cpan.org"
    ),
    'Added finish page'
);
$page_count++;

isa_ok( $wizard->{_pages}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{_pages} } ), $page_count, 'Number of pages' );

foreach my $iPage ( 1 .. $page_count ) {
    isa_ok( $wizard->{_pages}->[ $iPage - 1 ], 'CODE', "Page $iPage in list" );
}

ok( $wizard->Show, "Show" );
MainLoop();
ok( 1, "Exited MainLoop" );






#
# Test uninstaller
#

ok( exists ($wizard->{_uninstall_db_path}),
	"Created value for _uninstall_db_path"
);

diag "_uninstall_db_path = $wizard->{_uninstall_db_path}" if exists $wizard->{_uninstall_db_path};

ok( (-e $wizard->{_uninstall_db_path}.'.dir'),
	"Created .dir file for _uninstall_db_path"
);
ok( (-e $wizard->{_uninstall_db_path}.'.pag'),
	"Created .pag file for _uninstall_db_path"
);



$page_count = 0;
my $un_wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $un_wizard, 'Tk::Wizard::Installer', 'uninstaller' );

# Create pages
#
$un_wizard->addSplashPage(
    -wait     => $WAIT,
    -title    => "Uninstaller Test",
    -subtitle => "Testing Tk::Wizard::Installer uninstaller routine $Tk::Wizard::Installer::VERSION",
    -text     => "Test Installer's uninstall feature for RT #...."
);
$page_count++;

ok(
    $un_wizard->addUninstallPage(
        -wait     	  => $WAIT,
        -uninstall_db => $uninstall_db,
    ),
    'Added Uninstall Page'
);
$page_count++;

ok(
    $un_wizard->addSplashPage(
        -wait     => $WAIT,
        -title    => "Finished",
        -subtitle => "Click 'Finish' to kill the Wizard.",
        -text     => "Please report bugs via rt.cpan.org"
    ),
    'Added finish page'
);
$page_count++;

isa_ok( $un_wizard->{_pages}, 'ARRAY', 'Page list array' );
is( scalar( @{ $un_wizard->{_pages} } ), $page_count, 'Number of pages' );

foreach my $iPage ( 1 .. $page_count ) {
    isa_ok( $un_wizard->{_pages}->[ $iPage - 1 ], 'CODE', "Page $iPage in list" );
}


ok( $un_wizard->Show, "Show" );
MainLoop();
ok( 1, "Exited MainLoop" );

TODO: {
	local $TODO = "Not sure why not unlinking - help please";
	ok( not(-e $uninstall_db.'.dir'), 'removed uninstaller .dir file');
	ok( not(-e $uninstall_db.'.pag'), 'removed uninstaller .pag file');
}

END {
	rmtree $TEMP_DIR;
	unlink $uninstall_db.'.dir';
	unlink $uninstall_db.'.pag';
}

sub bail_out {
    diag @_;
    exit;
}


