package WizTestSettings;

use strict;
use warnings;

our $VERSION = do { my @r = ( q$Revision: 1.2 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

Tk::Wizard::Testing - used in wizard testing

=head1 DESCRIPTION

One subroutine, C<add_test_pages>, that adds pages to a wizard.

=cut

use Carp;
use Tk::Wizard;

BEGIN {
	eval { require Log::Log4perl; };
	if($@) {
		print "Log::Log4perl not installed - stubbing.\n";
		no strict qw(refs);
		*{"main::$_"} = sub { } for qw(DEBUG INFO WARN ERROR FATAL);
	} else {
		no warnings;
		require Log::Log4perl::Level;
		Log::Log4perl::Level->import(__PACKAGE__);
		Log::Log4perl->import(":easy");

		if (not Log::Log4perl::initialized()){
			# my ($fn) = $0 =~ /[^\/]+$/;
			my $Log_Conf = q[
				log4perl.logger                   = TRACE, Screen
				log4perl.appender.Screen          = Log::Log4perl::Appender::ScreenColoredLevels
				log4perl.appender.Screen.stderr   = 1
				log4perl.appender.Screen.layout   = PatternLayout::Multiline
				log4perl.appender.Screen.layout.ConversionPattern = %7p | %-70m | %M %L%n
			];

			#	log4perl.appender.File            = Log::Log4perl::Appender::File
			#	log4perl.appender.File.filename   = ] . ($ENV{AD2_TEST_LOG} || "$ENV{HOME}/logs/$fn.log") . q[
			#	log4perl.appender.File.mode       = append
			#	log4perl.appender.File.autoflush  = 1
			#	log4perl.appender.File.layout     = PatternLayout::Multiline
			#	log4perl.appender.File.layout.ConversionPattern = %7p | %-70m | %M %L%n
			Log::Log4perl->init( \$Log_Conf );
		}
	}
}

sub add_test_pages {
	my ($wiz, $args) = (shift, ref($_[0])? shift : {@_});

    my ( $sDirSelect, $sFileSelect, $mc1, $mc2, $mc3 );

	$args->{-wait} ||= 250;

    $sDirSelect = $^O =~ m/MSWin32/i ? 'C:\\' : '/';

    $wiz->addPage(
        sub {
            $wiz->blank_frame(
                -wait     => $args->{-wait},
                -title    => "Intro Page Title ($wiz->{-style} style)",
                -subtitle => "Intro Page Subtitle ($wiz->{-style} style)",
                -text     => sprintf( "This is the Intro Page of %s ($wiz->{-style} style)", __PACKAGE__ ),
            );
          }
    );

    my $s = "This is the text contents for the Tester TextFrame Page ($wiz->{-style} style).
It is stored in a string variable,
and a reference to this string variable is passed to the addTextFramePage() method.";
    $wiz->addTextFramePage(
        -wait       => $args->{-wait},
        -title      => "Tester TextFrame Page Title ($wiz->{-style} style)",
        -subtitle   => "Tester TextFrame Page Subtitle ($wiz->{-style} style)",
        -text       => "This is the text of the Tester TextFrame Page ($wiz->{-style} style)",
        -boxedtext  => \$s,
        -background => 'yellow',
    );
    $wiz->addDirSelectPage(
        -wait       => $args->{-wait},
        -title      => "Tester DirSelect Page Title ($wiz->{-style} style)",
        -subtitle   => "Tester DirSelect Page Subtitle ($wiz->{-style} style)",
        -text       => "This is the Text of the Tester DirSelect Page ($wiz->{-style} style)",
        -nowarnings => 88,
        -variable   => \$sDirSelect,
        -background => 'yellow',
    );
    $wiz->addFileSelectPage(
        -wait       => $args->{-wait},
        -title      => "Tester FileSelect Page Title ($wiz->{-style} style)",
        -subtitle   => "Tester FileSelect Page Subtitle ($wiz->{-style} style)",
        -text       => "This is the Text of the Tester FileSelect Page ($wiz->{-style} style)",
        -variable   => \$sFileSelect,
        -background => 'yellow',
    );
    $wiz->addMultipleChoicePage(
        -wait     => $args->{-wait},
        -title    => "Tester Multiple-Choice Page Title ($wiz->{-style} style)",
        -subtitle => "Tester Multiple-Choice Page Subtitle ($wiz->{-style} style)",
        -text     => sprintf( "This is the Multiple-Choice Page of %s ($wiz->{-style} style)", __PACKAGE__ ),
        -choices  => [
            {
                -variable => \$mc1,
                -title    => "Option number one",
                -subtitle => "This is the first of three options, any of which may be selected.",
                -checked  => 0,
            },
            {
                -variable => \$mc2,
                -title    => "The Second option is here",
                -subtitle =>
                  "This is the description of the second option.\nNote that this one is selected by default.",
                -checked => 1,
            },
            {
                -variable => \$mc3,
                -title    => "This third option has no subtitle.",
                -checked  => 0,
            },
        ],    # -choices
        -background => 'yellow',
    );
    $wiz->addTaskListPage(
        -wait     => $args->{-wait},
        -title    => "Tester Task List Page Title ($wiz->{-style} style)",
        -subtitle => "Tester Task List Page Subtitle ($wiz->{-style} style)",
        -text     => "This is the Text of the Tester Task List Page ($wiz->{-style} style)",
        -continue => 2,
        -tasks    => [
            "This task will succeed"                       => \&_task_good,
            "This task will fail!"                         => \&_task_fail,
            "This task is not applicable"                  => \&_task_na,
            "Wizard will exit as soon as this one is done" => \&_task_good,
        ],
        -background => 'yellow',
    );
    return $wiz;
}    # new

=head2 Show

Before we actually show the Tester Wizard,
we add one final "finish" page.
This allows the user to add more pages to this Tester Wizard,
which will appear after the default pages,
but there will always be a "content-poor" finish page.

=cut

sub Show {
    my $wiz = shift;
    $wiz->addPage(
        sub {
            $wiz->blank_frame(
                -wait  => $wiz->{_wait_},
                -title => "Tester Wizard last page ($wiz->{_style_} style)",
            );
        }
    );
    $wiz->SUPER::Show;
}    # Show

sub _task_good {
    sleep 1;
    return 1;
}    # _task_good

sub _task_na {
    sleep 1;
    return undef;
}    # _task_na

sub _task_fail {
    sleep 1;
    return 0;
}    # _task_fail

1;

__END__

