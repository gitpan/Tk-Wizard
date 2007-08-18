
# $Id: Tester.pm,v 1.4 2007/08/18 00:21:00 martinthurn Exp $

package Tk::Wizard::Tester;

use strict;
use warnings;

our
$VERSION = do { my @r = ( q$Revision: 1.4 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

Tk::Wizard::Tester - A Test Wizard

  use Tk::Wizard::Tester;
  my $wizard = new Tk::Wizard::Tester(
                                      -debug => 0,
                                      -wait => 250,
                                     );
  $wizard->Show;
  MainLoop;

=cut

use Carp;
use Tk::Wizard;
use base 'Tk::Wizard';

=head1 DESCRIPTION

This module shows off -- I mean demonstrates -- most, if not all, of the
basic features of the Tk::Wizard distribution.

It is used in the automatic tests during the `make test` phase,
and it is used by the module authors for manual testing and debugging.

=head1 METHODS

=head2 new

Create a new Tester wizard.

=cut

sub new
  {
  my $class = shift;
  # This is NOT a clone mechanism:
  return if ref($class);
  # Process our arguments, and set default values:
  my %args = @_;
  $args{-wait} = 300 if ! defined($args{-wait});
  my $sStyle = $args{-style} || 'top';
  $args{-debug} ||= 0;
  my $iWin32 = ($^O =~ m!win32|cygwin!i);
  # Create a new Wizard:
  my $self = $class->SUPER::new(
                                -debug => $args{-debug},
                                -title => qq'Wizard Tester ($sStyle style)',
                                -style => $sStyle,
                               );
  $self->{_wait_} = $args{-wait};
  $self->{_style_} = $sStyle;
  # Add pages to the Wizard:
  my ($sDirSelect, $sFileSelect, $mc1, $mc2, $mc3);
  $sDirSelect = $iWin32 ? 'C:\\' : '/';
  $self->addPage(sub
                   {
                   $self->blank_frame(
                                      -wait => $args{-wait},
                                      -title => "Intro Page Title ($sStyle style)",
                                      -subtitle => "Intro Page Subtitle ($sStyle style)",
                                      -text => sprintf("This is the Intro Page of %s ($sStyle style)", __PACKAGE__),
                                     );
                   } # sub
                ); # add_page
  my $s = "This is the text contents for the Tester TextFrame Page ($sStyle style).
It is stored in a string variable,
and a reference to this string variable is passed to the addTextFramePage() method.";
  $self->addTextFramePage(
                          -wait => $args{-wait},
                          -title => "Tester TextFrame Page Title ($sStyle style)",
                          -subtitle => "Tester TextFrame Page Subtitle ($sStyle style)",
                          -text => "This is the text of the Tester TextFrame Page ($sStyle style)",
                          -boxedtext => \$s,
                         );
  $self->addDirSelectPage(
                          -wait => $args{-wait},
                          -title => "Tester DirSelect Page Title ($sStyle style)",
                          -subtitle => "Tester DirSelect Page Subtitle ($sStyle style)",
                          -text => "This is the Text of the Tester DirSelect Page ($sStyle style)",
                          -nowarnings => 88,
                          -variable => \$sDirSelect,
                         );
  $self->addFileSelectPage(
                           -wait => $args{-wait},
                           -title => "Tester FileSelect Page Title ($sStyle style)",
                           -subtitle => "Tester FileSelect Page Subtitle ($sStyle style)",
                           -text => "This is the Text of the Tester FileSelect Page ($sStyle style)",
                           -variable => \$sFileSelect,
                          );
  $self->addMultipleChoicePage(
                               -wait => $args{-wait},
                               -title => "Tester Multiple-Choice Page Title ($sStyle style)",
                               -subtitle => "Tester Multiple-Choice Page Subtitle ($sStyle style)",
                               -text => sprintf("This is the Multiple-Choice Page of %s ($sStyle style)",
                                                __PACKAGE__),
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
                                                -subtitle => "This is the description of the second option.\nNote that this one is selected by default.",
                                                -checked  => 1,
                                               },
                                               {
                                                -variable => \$mc3,
                                                -title    => "This third option has no subtitle.",
                                                -checked  => 0,
                                               },
                                            ], # -choices
                              );
  $self->addTaskListPage(
                         -wait => $args{-wait},
                         -title => "Tester Task List Page Title ($sStyle style)",
                         -subtitle => "Tester Task List Page Subtitle ($sStyle style)",
                         -text => "This is the Text of the Tester Task List Page ($sStyle style)",
                         -continue => 2,
                         -tasks    => [
                                       "This task will succeed" => \&_task_good,
                                       "This task will fail!" => \&_task_fail,
                                       "This task is not applicable" => \&_task_na,
                                       "Wizard will exit as soon as this one is done" => \&_task_good,
                                      ],
                        );
  return $self;
  } # new


=head2 Show

Before we actually show the Tester Wizard,
we add one final "finish" page.
This allows the user to add more pages to this Tester Wizard,
which will appear after the default pages,
but there will always be a "content-poor" finish page.

=cut

sub Show
  {
  my $self = shift;
  $self->addPage(sub { $self->blank_frame(
                                          -wait => $self->{_wait_},
                                          -title => "Tester Wizard last page ($self->{_style_} style)",
                                         )
                       });
  $self->SUPER::Show;
  } # Show

sub _task_good
  {
  sleep 1;
  return 1;
  } # _task_good

sub _task_na
  {
  sleep 1;
  return undef;
  } # _task_na

sub _task_fail
  {
  sleep 1;
  return 0;
  } # _task_fail

1;

__END__

=head1 AUTHOR

Martin Thurn, C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut



