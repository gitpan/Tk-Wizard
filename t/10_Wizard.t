
# $Id: 10_Wizard.t,v 1.8 2007/06/08 00:57:01 martinthurn Exp $

use strict;

use Cwd;
use ExtUtils::testlib;
use FileHandle;
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
  use_ok('Tk::Wizard');
  } # end of BEGIN block

my $VERSION = do { my @r = ( q$Revision: 1.8 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

autoflush STDOUT 1;

my $root = cwd =~ /\/t$/ ? '..' : '.';

use vars qw/$GET_DIR $GET_FILE $user_chosen_dir $user_chosen_file $SPLASH/;

our $WAIT = 1;

#
# Instantiate Wizard
#
my $looped = 0;
foreach my $style ( 'top', '95' ) {
    my $wizard = new Tk::Wizard(
        -title => "Test v$VERSION For Wizard $Tk::Wizard::VERSION",
        -style => $style,
    );
    isa_ok( $wizard, "Tk::Wizard" );
    $wizard->configure(
        -preNextButtonAction => sub { &preNextButtonAction($wizard); },
        -finishButtonAction  => sub { ok( 1, 'user clicked finish' ); },
    );
    isa_ok( $wizard->cget( -preNextButtonAction ), "Tk::Callback" );

    #
    # Create pages
    #
    $SPLASH = $wizard->addPage( sub { page_splash( $wizard, $looped ) } );
    is( $SPLASH, 1 );
    is( 2, $wizard->addPage( sub { page_one($wizard) } ) );
    is( 3, $wizard->addPage( sub { page_two($wizard) } ) );
    is( 4, $wizard->addPage( sub { page_text_textbox1($wizard) } ) );
    is( 5, $wizard->addPage( sub { page_text_textbox2($wizard) } ) );
    my ( $C1, $C2, $C3 ) = ( undef, "TWooo", 3 );
    is(
        6,
        $wizard->addMultipleChoicePage(
            -wait     => $WAIT,
            -title    => 'Multi',
            -subtitle => 'Multiple Choice Page',
            -text     => "Something here too?",
            -choices  => [
                {
                    -variable => \$C1,
                    -title    => "Option number one",
                    -subtitle =>
"This is the first of three options, each of which may take a value.",
                    -value => '1',
                },
                {
                    -variable => \$C2,
                    -title    => "The Second option is here",
                    -subtitle => "The Lumberjack Song, German version",
                    -value    => 'two',
                    -checked  => 1,
                },
                {
                    -variable => \$C3,
                    -title    => "And no subitle either",
                    -value    => 'two',
                },
            ],
        )
    );
    $GET_DIR = $wizard->addDirSelectPage(
        -wait       => $WAIT,
        -nowarnings => "9",
        -variable   => \$user_chosen_dir,
    );
    is( $GET_DIR, 7 );
    $GET_FILE = $wizard->addFileSelectPage(
        -wait     => $WAIT,
        -variable => \$user_chosen_file,
    );
    is( $GET_FILE, 8 );
    my $iTEXT = $wizard->addTextFrame(
        -wait  => $WAIT,
        -title => "Text Page Title",
        -text  => "Text Page Text",
    );
    is( $iTEXT, 9 );
    my $p = $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait     => $WAIT,
                -title    => "Finished",
                -subtitle => "Please press Finish to leave the Wizard.",
                -text =>
"If you saw some error messages, they came from Tk::DirTree, and show that some of your drives are inacessible - perhaps a CD-ROM drive without media.  Such warnings can be turned off - please see the documentation for details."
            );
        },
    );
    ok($p);
    isa_ok( $wizard->parent, "Tk::MainWindow" );
    $wizard->Show;

    MainLoop();
    ok(1);
    undef $wizard;
}

exit;

sub page_splash {
    my ( $wizard, $looped ) = ( shift, shift );
    my ( $frame, @pl ) = $wizard->blank_frame(
        -wait => $WAIT,
        -title =>
          ( $looped == 0 ? "Welcome to the Wizard" : "Testing the Old Style" ),
        -subtitle => "It's just a test",
        -text =>
"This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
    );
    return $frame;
}

sub page_one {
    my $wizard = shift;
    my $frame  = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Page One",
        -subtitle =>
'The text found in the -subtitle parameter appears here on the screen; quite a long string I trust: and sadly ugly still',
        -text =>
"-text goes here.\n\nTk::Wizard is but a baby, and needs your help to grow into a happy, healthy, well-adjusted widget. Sadly, I've only been using Tk::* for a couple of weeks, and all this packing takes a bit of getting used to. And I'm also working to a deadline on the project which bore this Wizard, so please excuse some coding which is currently rather slip-shod, but which be tightened in the future."
    );
    return $frame;
}

sub page_two {
    my $wizard = shift;
    my $frame  = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Page Two - The Title",
        -text  => "A page without a -subtitle."
    );
    return $frame;
}

sub page_bye {
    my $wizard = shift;

    # diag('start page_bye');
    my $frame = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Page Bye!",
        -text  => "Thanks for testing!"
    );
    return $frame;
}

sub page_text_textbox1 {
    my $wizard = shift;

    # diag('start page_text_textbox1');
    my $text  = "This is in a box";
    my $frame = $wizard->text_frame(
        -wait      => $WAIT,
        -title     => "1: Text from literal",
        -boxedtext => \$text,
    );
    return $frame;
}

sub page_text_textbox2 {
    my $wizard = shift;

    # diag('start page_text_textbox2');
    my $frame = $wizard->text_frame(
        -wait      => $WAIT,
        -title     => "2: Text from filename",
        -boxedtext => $root . '/perl_licence_blab.txt',
    );
    return $frame;
}

sub preNextButtonAction {
    my $wizard = shift;

    # diag("start preNextButtonAction, wizard is $wizard");
    local $_ = $wizard->currentPage;
    if (/^$GET_DIR$/) {

        #$_ = $wizard->callback_dirSelect( \$user_chosen_dir );
        return 1;
        if ( $_ == 1 ) {
            $_ = chdir $user_chosen_dir;
            if ( not $_ ) {
                $wizard->parent->messageBox(
                    -icon  => 'warning',
                    -title => 'Oops',
                    -text  => "Please choose a valid directory.",
                );
            }
        }
        return $_ ? 1 : 0;
    }
    return 1;
}

__END__

