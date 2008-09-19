#! perl -w

# $Id: 77_dirselect.t,v 1.7 2007/08/18 00:44:16 martinthurn Exp $

=head1 NAME

200_tasklist.t - test a tasklist

=head1 DESCRIPTION

User story: http://rt.cpan.org/Ticket/Display.html?id=34610

Strangely, after the &update fix, I only see the error in
the user's error script, when it uses C<slee>.

=cut

use strict;

use ExtUtils::testlib;
use FileHandle;
use Cwd;
use Test::More;
use Tk;
use lib qw(../lib . t/);

use Tk::PNG;
use Tk::JPEG;

my $VERSION = do { my @r = ( q$Revision: 2.079 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

BEGIN {
    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
		# plan skip_all => 'Tk::JPEG errors';
        plan tests => 11;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard' => $VERSION);
    use_ok('WizTestSettings');

	# use Log::Log4perl qw(:easy);
	# Log::Log4perl->easy_init($INFO);
}

our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 1;

autoflush STDOUT 1;
chdir ".." if getcwd =~ /\Wt$/;

my $wizard = Tk::Wizard->new(
    -title => "Test version $VERSION For Tk::Wizard version $Tk::Wizard::VERSION",
    -debug => 88,
);

isa_ok( $wizard, "Tk::Wizard" );
my $fn = getcwd . "/t/chick.jpg";
ok(-e( $fn ), "pic") or BAIL_OUT;

$wizard->configure(
    -finishButtonAction  => sub { pass('user clicked finish'); 1; },
	-imagepath    		 => $fn,
);
isa_ok( $wizard->cget( -finishButtonAction ),  "Tk::Callback" );

#
# Create pages
#
is(
    $wizard->addPage( sub {
		$wizard->blank_frame(
			-wait  => $WAIT,
			-title => "Test Wizard",
		);
	}),
    1,
    'splash is 1'
);

is(
    $wizard->addPage( sub {
		$wizard->blank_frame(
			-wait  => $WAIT,
			-title => "Test Wizard",
		);
	}),
	2,
	'this is two'
);

is(
    $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait  => $WAIT,
                -title => "Bye!",
                -text  => "Thanks for testing!"
            );
        }
    ),
    3,
    'bye is 3'
);

$wizard->Show;
pass('after Show');
MainLoop();
pass('after MainLoop');
undef $wizard;


__END__

