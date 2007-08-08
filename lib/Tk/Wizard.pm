
# $Id: Wizard.pm,v 2.38 2007/08/08 04:16:58 martinthurn Exp $

package Tk::Wizard;

use strict;
if ( $^V and $^V gt v5.8.0 )
  {
  eval "use warnings";
  } # if

use constant DEBUG_FRAME => 0;

our
$VERSION = do { my @r = ( q$Revision: 2.38 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $sdir = ($^O =~ m/MSWin32/i) ? 'Folder' : 'Directory';
my $sDir = ucfirst $sdir;

=head1 NAME

Tk::Wizard - GUI for step-by-step interactive logical process

=cut

use Carp;
use Config;
use Cwd;
use Data::Dumper;
use File::Path;
use Tk;
use Tk::DialogBox;
use Tk::DirTree;
use Tk::LabFrame;
use Tk::Frame;
use Tk::MainWindow;
use Tk::ROText;
use Tk::Wizard::Image;

use vars qw( @EXPORT @ISA );
BEGIN
  {
  require Exporter;    # Exporting Tk's MainLoop so that
  @ISA    = ( "Exporter", );    # I can just use strict and Tk::Wizard without
  @EXPORT = ("MainLoop");       # having to use Tk
  } # end of BEGIN block

our $DEFAULT_WIDTH  = 550;        # 400
our $DEFAULT_HEIGHT = 360;        # 316

use base qw[Tk::Derived Tk::Toplevel ];
Tk::Widget->Construct('Wizard');

use vars qw/ %LABELS @asTaglinePackArgs /;

# See INTERNATIONALISATION
%LABELS = (
           # Buttons
           BACK   => "< Back",
           NEXT   => "Next >",
           FINISH => "Finish",
           CANCEL => "Cancel",
           HELP   => "Help",
           OK     => "OK",
          );

=head1 SYNOPSIS

  use Tk::Wizard;
  my $wizard = new Tk::Wizard;
  #
  # OR
  # my $MW = Tk::MainWindow->new;
  # my $wizard = $MW->Wizard();
  #
  $wizard->configure( -property=>'value');
  $wizard->cget( "-property");
  $wizard->addPage(
    ... code-ref to anything returning a Tk::Frame ...
  );
  $wizard->addPage( sub {
    return $wizard->blank_frame(
      -title    => "Page Title",
      -subtitle => "Sub-title",
      -text    => "Some text.",
      -wait    => $milliseconds_b4_proceeding_anyway,
    );
  });
  $wizard->Show;
  MainLoop;
  exit;

To avoid 50 lines of SYNOPSIS, please see the files included with the
distribution in the test directory: F<t/*.t>.  These are just Perl
files that are run during the C<make test> phase of installation: you
may rename them without harm once you have installed the module.

=head1 CHANGES

The widget now works from within a C<MainWindow>, or creates its own as necessary for backwards comparability.

The option C<-image_dir> has been deprecated, and the once-used binary
images have been dropped from the distribution in favour of Base64-
encoded images. More and other details in F<ChangeLog>.

=head1 DEPENDENCIES

C<Tk> and modules of the current standard Perl Tk distribution.

On MS Win32 only: C<Win32API::File>.

=head1 EXPORTS

  MainLoop();

This is so that I can say C<use strict; use Tk::Wizard> without
having to C<use Tk>. You can always C<use Tk::Wizard ()> to avoid
importing this.

=head1 DESCRIPTION

In the context of this name space, a Wizard is defined as a graphic user interface (GUI)
that presents information, and possibly performs tasks, step-by-step via a series of
different pages. Pages (or 'screens', or 'Wizard frames') may be chosen logically depending
upon user input.

The C<Tk::Wizard> module automates a large part of the creation of a wizard program
to collect information and then perform some complex task based upon it.

The wizard feel is largely based upon the Microsoft(TM,etc) wizard style: the default is
similar to that found in Windows 2000, though the more traditional Windows 95-like feel is also
supported (see the C<-style> entry in L<WIDGET-SPECIFIC OPTIONS>. Sub-classing the
module to provide different look-and-feel is highly encourage: please see
L<NOTES ON SUB-CLASSING Tk::Wizard>. If anyone would like to do a I<Darwin> or
I<Aqua> version, please let me know how you would like to handle the buttons. I'm not
hot on advertising widgets.

NB: B<THIS IS STILL AN ALPHA RELEASE: ALL CONTRIBUTIONS ARE WELCOME!>

Please read L<CAVEATS, BUGS, TODO>.

=head1 ADVERTISED SUB-WIDGETS

Still untested. Use:

  $wizard->Subwidget('buttonPanel');

=over 4

=item buttonPanel

The C<Frame> that holds the navigation buttons and optional help button.

=item nextButton

=item backButton

=item cancelButton

=item helpButton

The buttons in the C<buttonPanel>.

=item tagLine

The line above the C<buttonpanel>, a Tk::Frame object.

=item tagText

The grayed-out text above the C<buttonpanel>, a Tk::Label object.

=item tagBox

A Tk::Frame holding the tagText and tagLine.

=item imagePane

Either the image on the first and last pages. Also: for C<95> C<style> wizards: the same;
for C<style> C<top> (default) Wizards, the box at the top of the wizard. What a terrible sentence.

=item wizardFrame

The frame that holds the content frame.

=back

=head1 STANDARD OPTIONS

=over 4

=item -title

Text that appears in the title bar.

=item -background

Main background colour of the Wizard's window.

=item -width -height

Size of the wizard. This is adjustable per-page - every method that adds a page will accept these options and pass them on to the main Wizard window.

=back

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:   style

=item Class:  Style

=item Switch: -style

Sets the display style of the Wizard.

The default no-value or value of C<top> gives the Wizard will be a Windows 2000-like
look, with the initial page being a version of the traditional
style with a white background, and subsequent pages being C<SystemButtonFace> coloured,
with a white strip at the top holding a title and subtitle, and a smaller image (see
C<-topimagepath>, below).

The old default of C<95> is still available, if you wish to create a traditional,
Windows 95-style wizard, with every page being C<SystemButtonFace> coloured, with a
large image on the left (C<-imagepath>, below).

=item Name:   imagepath

=item Class:  Imagepath

=item Switch: -imagepath

Path to an image that will be displayed on the left-hand side
of the screen.  (Dimensions are not constrained.) One of either:

=over 4

=item *

Path to a file from which to construct a L<Tk::Photo|Tk::Photo>
object without the format being specified;
No checking is done, but paths ought to be absolute, as no effort
is made to maintain or restore any initial current working directory.

=item *

Base64-encoded images to pass in the C<-data> field of the
L<Tk::Photo|Tk::Photo> object. This is the default form, and a couple
of unused images are supplied: see L<Tk::Wizard::Image>.

=back

=item Name:   topimagepath

=item Class:  Topimagepath

=item Switch: -topimagepath

Only required if C<-style=E<gt>'top'> (as above): the image
this filepath specifies
will be displayed in the top-right corner of the screen. Dimensions are not
restrained (yet), but only 50x50 has been tested.

Please see notes for the C<-imagepath>>.

=item Name:   nohelpbutton

=item Class:  Nohelpbutton

=item Switch: -nohelpbutton

Set to anything to disable the display of the I<Help> button.

=item Name:   resizable

=item Class:  resizable

=item Switch: -resizable

Supply a boolean value to allow resizing of the window: default
is to disable that feature to minimise display issues.

=item Switch: -tag_text

Text to supply in a 'tag line' above the wizard's control buttons.
Specify empty string to disable the display of the tag text box.

=item -image_dir

Deprecated. Supply C<-imagepath> and/or C<-topimagepath>.

=item -kill_self_after_finish

The default for the Wizard is to withdraw itself after the "finish"
(or "cancel") button is clicked.  This allows the Wizard to be reused
during the same session (the Wizard will be destroyed when its parent
MainWindow is destroyed).
If you supply a non-zero value to this option,
the Wizard will instead be destroyed after the "finish" button is clicked.

=back

Please see also L<ACTION EVENT HANDLERS>.

=head1 METHODS

=head2 new

Create a new Tk::Wizard object.
You can provide custom values for any or all of the standard widget options or widget-specific options

=cut

# The method is overridden to allow us to supply a MainWindow if one is
# not supplied by the caller. Not supplying one suits me, but Mr Rothenberg requires one.
sub new
  {
  my $inv = ref( $_[0] ) ? ref( $_[0] ) : $_[0];
  shift; # Ignore invocant
  my @args = @_;
  unless (
          (scalar(@_) % 2) # Not a simple list
          &&
          ref $args[0]  # Already got a MainWindow
         )
    {
    # Get a main window:
    unshift @args, Tk::MainWindow->new;
    push @args, "-parent" => $args[0];
    push @args, "-kill_parent_on_destroy" => 1;
    $args[0]->optionAdd( '*BorderWidth' => 1 );
    } # if
  return $inv->SUPER::new(@args);
  } # new

=head2 Populate

This method is part of the underlying Tk inheritance mechanisms.
You the programmer do not necessarily even need to know it exists;
we document it here only to satisfy Pod coverage tests.

=cut

sub Populate
  {
  my ( $self, $args ) = @_;
  warn " FFF enter Populate" if $self->{-debug};
  $self->SUPER::Populate($args);
  $self->withdraw;
  my $sFontFamily      = &_font_family();
  my $iFontSize        = &_font_size();
  my $sTagTextDefault  = 'Perl Wizard';
  # $composite->ConfigSpecs(-attribute => [where,dbName,dbClass,default]);
  $self->ConfigSpecs(
                     # -title => ['SELF','title','Title','Generic Wizard'],
                     # -title      => [ 'PASSIVE',  undef, undef, 'Wizard' ],
                     # -resizable => ['SELF','resizable','Resizable',undef],
                     -resizable => [ 'SELF', 'resizable', 'Resizable', undef ],
                     # -foreground => ['PASSIVE', 'foreground','Foreground', 'black'],
                     -parent => [ 'PASSIVE', undef, undef, undef ]
                     ,    # potentially a mainwindow
                     -command    => [ 'CALLBACK', undef, undef, undef ],
                     -background => [
                                     'METHOD', 'background', 'Background',
                                     $^O =~ /(MSWin32|cygwin)/i ? 'SystemButtonFace' : undef
                                    ],
                     -style     => [ 'PASSIVE', "style", "Style", "top" ],
                     -imagepath => [
                                    'PASSIVE',   'imagepath',
                                    'Imagepath', \$Tk::Wizard::Image::LEFT{WizModernImage}
                                   ],
                     -topimagepath => [
                                       'PASSIVE',      'topimagepath',
                                       'Topimagepath', \$Tk::Wizard::Image::TOP{WizModernSmallImage}
                                      ],
                     # event handling references
                     -nohelpbutton          => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -preNextButtonAction   => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -postNextButtonAction  => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -preBackButtonAction   => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -postBackButtonAction  => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -preHelpButtonAction   => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -helpButtonAction      => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -postHelpButtonAction  => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -preFinishButtonAction => [ 'CALLBACK', undef, undef, sub { 1 } ],
                     -finishButtonAction =>
                     [ 'CALLBACK', undef, undef, sub { $self->withdraw; 1 } ],
                     -kill_parent_on_destroy => [ 'PASSIVE', undef, undef, 0 ],
                     -kill_self_after_finish => [ 'PASSIVE', undef, undef, 0 ],
                     -debug                  => [ 'PASSIVE', undef, undef, undef ],
                     -preCloseWindowAction =>
                     [ 'CALLBACK', undef, undef, sub { $self->DIALOGUE_really_quit } ],
                     -tag_text  => [ 'PASSIVE', "tag_text",  "TagText",  $sTagTextDefault ],
                     -tag_width => [ 'PASSIVE', "tag_width", "TagWidth", 0 ],
                     -width     => [ 'SELF',    'width',     'Width',    $DEFAULT_WIDTH ],
                     -height    => [ 'SELF',    "height",    "Height",   $DEFAULT_HEIGHT ],
                     -wizardFrame => [ 'PASSIVE', undef, undef, 0 ],
                     # -width => [$self->{-style} eq 'top'? 500 : 570) unless $args->{-width};
                    );
  if ( exists $args->{-imagepath} and not -e $args->{-imagepath} ) {
    confess "Can't find file at -imagepath: " . $args->{-imagepath};
    }    # if
  if ( exists $args->{-topimagepath} and not -e $args->{-topimagepath} ) {
    confess "Can't find file at -topimagepath: " . $args->{-topimagepath};
    }    # if
  $self->{-imagepath}     = $args->{-imagepath};
  $self->{-topimagepath}  = $args->{-topimagepath};
  $self->{wizardPageList} = [];
  $self->{-debug}         = $args->{-debug} || $Tk::Wizard::DEBUG || undef;
  $self->{background_userchoice} = $args->{-background}
  || $self->ConfigSpecs->{-background}[3];
  $self->{background} = $self->{background_userchoice};
  $self->{-style} = $args->{-style} || "top";
  $self->{wizardPagePtr} = 0;
  # $self->overrideredirect(1); # Removes borders and controls
 CREATE_BUTTON_PANEL:
    {
    my $buttonPanel = $self->Frame->pack(qw/ -side bottom -fill x/);
    DEBUG_FRAME && $buttonPanel->configure(-background => 'yellow');
    # right margin:
    my $f = $buttonPanel->Frame(
                                -width => 5,
                               )->pack(-side => "right", -expand => 0);
    DEBUG_FRAME && $f->configure(-background => 'red');
    $self->Advertise( buttonPanel  => $buttonPanel );
    }    # end of CREATE_BUTTON_PANEL block
 CREATE_TAGLINE:
    {
    my $tagbox = $self->Frame(
                              -height => 12,
                             )->pack(qw/-side bottom -fill x -expand 1/);
    DEBUG_FRAME && $tagbox->configure(-background => 'magenta');
    # This is a new, simpler, accurate-width Label way of doing it:
    @asTaglinePackArgs = qw( -side right -expand 1 -fill x );
    $self->{tagtext} = $tagbox->Label(
                                      -border => 2,
                                      -foreground => 'gray50',
                                     );
    $self->_maybe_pack_tag_text;
    # This is the line that extends to the right from the tag text:
    $self->{tagline} = $tagbox->Frame(
                                      -relief => 'groove',
                                      -bd => 1,
                                      -height => 2,
                                     )->pack(@asTaglinePackArgs);
    DEBUG_FRAME && $self->{tagline}->configure(-background => 'yellow');
    $self->Advertise( tagLine => $self->{tagline} );
    $self->Advertise( tagBox  => $tagbox );
    $self->Advertise( tagText => $self->{tagtext} );
    } # end of CREATE_TAGLINE block
  # Desktops for dir select: thanks to Slaven Rezic who also suggested SHGetSpecialFolderLocation for Win32. l8r
  # There is a module for this now
  if ( $^O =~ m/win/i and -d "$ENV{USERPROFILE}/Desktop" ) {
    # use OLE;
    $self->{desktop_dir} = "$ENV{USERPROFILE}/Desktop";
    }
  elsif ( -d "$ENV{HOME}/Desktop" ) {
    $self->{desktop_dir} = "$ENV{HOME}/Desktop";
    }
  elsif ( -d "$ENV{HOME}/.gnome-desktop" ) {
    $self->{desktop_dir} = "$ENV{HOME}/.gnome-desktop";
    }
  # Font used for &blank_frame titles
  $self->fontCreate(
                    'TITLE_FONT',
                    -family => $sFontFamily,
                    -size   => $iFontSize * 1.4,
                    -weight => 'bold',
                   );
  # Font used in multiple choices for radio title
  $self->fontCreate(
                    'RADIO_BOLD',
                    -family => $sFontFamily,
                    -size   => $iFontSize,
                    -weight => 'demi',
                   );
  # Fonts used if -style=>"top"
  $self->fontCreate(
                    'TITLE_FONT_TOP',
                    -family => $sFontFamily,
                    -size   => $iFontSize * 1.4,
                    -weight => 'bold',
                   );
  $self->fontCreate(
                    'SUBTITLE_FONT',
                    -family => $sFontFamily,
                    -size   => $iFontSize * 1.2,
                   );
  # Font used in licence agreement  XXX REMOVE TO CORRECT MODULE
  $self->fontCreate(
                    'SMALL_FONT',
                    -family => $sFontFamily,
                    -size   => $iFontSize,
                   );
  # Font used in all other places
  $self->fontCreate(
                    'DEFAULT_FONT',
                    -family => $sFontFamily,
                    -size   => $iFontSize,
                   );
  $self->{defaultFont} = 'DEFAULT_FONT';
  } # Populate

sub _maybe_pack_tag_text
  {
  my $self = shift;
  # print STDERR " DDD in _maybe_p_t_t, tag_text is =", $self->{Configure}{-tag_text}, "=\n";
  return if (($self->{Configure}{-tag_text} || '') eq '');
  $self->{tagtext}->configure(-text => $self->{Configure}{-tag_text}. ' ');
  $self->{tagtext}->pack(qw( -side left -padx 0 -ipadx 2 ));
  } # _maybe_pack_tag_text

sub _pack_forget
  {
  my $self = shift;
  foreach my $o (@_)
    {
    if (Tk::Exists($o))
      {
      $o->packForget;
      } # if
    } # foreach
  } # _pack_forget

sub _repack_buttons
  {
  my $self = shift;
  my $panel = $self->Subwidget('buttonPanel');
  warn " FFF enter _repack_buttons, panel=$panel=" if $self->{-debug};
  my %hssPackArgs = (
                     -side => "right",
                     -expand => 0,
                     -pady => 10,
                     -padx => 5,
                     -ipadx => 8,
                    );
  $self->_pack_forget(@{$self->{_button_spacers_}},
                      $self->{cancelButton},
                      $self->{nextButton},
                      $self->{backButton},
                      $self->{helpButton},
                   );
  if (! $self->_on_last_page)
    {
    $self->{cancelButton} = $panel->Button(
                                           -text    => $LABELS{CANCEL},
                                           -command => [ \&_CancelButtonEventCycle, $self, $self ],
                                          )->pack(%hssPackArgs);
    # Set the cancel button a little apart from the next button:
    my $f1 = $panel->Frame(
                           -width => 8,
                          )->pack(-side => "right");
    DEBUG_FRAME && $f1->configure(-background => 'black');
    push @{$self->{_button_spacers_}}, $f1;
    warn " DDD   created cancel button" if $self->{-debug};
    $self->Advertise( cancelButton => $self->{cancelButton} );
    } # if
  $self->{nextButton} = $panel->Button(
                                       -text => $self->_on_last_page ? $LABELS{FINISH} : $LABELS{NEXT},
                                       -command => [ \&_NextButtonEventCycle, $self ],
                                      )->pack(%hssPackArgs);
  warn " DDD   created next button" if $self->{-debug};
  $self->{backButton} = $panel->Button(
                                       -text => $LABELS{BACK},
                                       -command => [ \&_BackButtonEventCycle, $self ],
                                       -state => $self->_on_first_page ? 'disabled' : 'normal',
                                      )->pack(%hssPackArgs);
  warn " DDD   created back button" if $self->{-debug};
  if ( $self->cget( -nohelpbutton ) )
    {
    $self->{helpButton} = $panel->Button(
                                         -text => $LABELS{HELP},
                                         -command => [ \&_HelpButtonEventCycle, $self ],
                                        )->pack(
                                                -side   => 'left',
                                                -anchor => 'w',
                                                -pady   => 10,
                                                -padx   => 10,
                                                -ipadx   => 8,
                                               );
    $self->Advertise( helpButton => $self->{helpButton} );
    } # if
  $self->Advertise( nextButton   => $self->{nextButton} );
  $self->Advertise( backButton   => $self->{backButton} );
  warn " FFF leave _repack_buttons\n" if $self->{-debug};
  } # _repack_buttons

# Private method: returns a font family name suitable for the operating system.
sub _font_family {
    return 'verdana'   if ( $^O =~ m!win32!i );
    return 'helvetica' if ( $^O =~ m!solaris!i );
    return 'helvetica';
}

# Private method: returns a font size suitable for the operating system.
sub _font_size {
    return 8  if ( $^O =~ m!win32!i );
    return 12 if ( $^O =~ m!solaris!i );
    return 14;
}


=head2 background

Get/set the background color for the body of the Wizard.

=cut

sub background
  {
  my $self = shift;
  my $operand = shift;
  if ( defined($operand) )
    {
    $self->{background} = $operand;
    }
  elsif (($self->{-style} ne '95')
         && ($self->_on_first_page || $self->_on_last_page))
    {
    $self->{background} = 'white';
    }
  else
    {
    $self->{background} = $self->{background_userchoice};
    }
  return $self->{background};
  } # background

=head2 addPage

  $wizard->addPage ($page_code_ref1 ... $page_code_refN)

Adds a page to the wizard. The parameters must be references to code that
evaluate to C<Tk::Frame> objects, such as those returned by the methods
C<blank_frame> and C<addDirSelectPage>.

Pages are (currently) stored and displayed in the order added.

Returns the index of the page added, which is useful as a page UID when
performing checks as the I<Next> button is pressed (see file F<test.pl>
supplied with the distribution).

See also L<METHOD blank_frame>.

=cut

sub addPage
  {
  my $self = shift;
  warn " FFF enter addPage" if $self->{-debug};
  if ( grep { ref $_ ne 'CODE' } @_ ) {
      confess "addPage requires one or more CODE references as arguments";
      }
  push @{ $self->{wizardPageList} }, @_;
  } # addPage

=head2 Show

  $wizard->Show()

This method must be called before the Wizard will be displayed,
and must precede the C<MainLoop> call.

=cut

sub Show {
    my $self = shift;
    warn " FFF enter Show" if $self->{-debug};
    return if $self->{_showing};
    if ( $^W && ($self->_last_page == 0 )) {
        warn "# Showing a Wizard that is only one page long";
    }
    $self->{wizardPagePtr} = 0;
    $self->initial_layout;
    $self->resizable( 0, 0 )
      unless $self->{Configure}{-resizable}
      and $self->{Configure}{-resizable} =~ /^(1|yes|true)$/i;
    $self->parent->withdraw;
    $self->Popup;
    $self->transient;    # forbid minimize
    $self->protocol(
        WM_DELETE_WINDOW => [ \&_CloseWindowEventCycle, $self, $self ] );
    $self->packPropagate(0);
    $self->configure( -background => $self->cget("-background") );
    $self->render_current_page;
    $self->{_showing} = 1;
    warn " FFF leave Show" if $self->{-debug};
    return 1;
}

=head2 forward

Convenience method to move the Wizard on a page by invoking the
callback for the C<nextButton>.

You can automatically move forward after C<$x> tenths of a second
by doing something like this:

  $frame->after($x,sub{$wizard->forward});

=cut

sub forward
  {
  my $self = shift;
  return $self->_NextButtonEventCycle;
  } # forward


=head2 backward

Convenience method to move the Wizard back a page by invoking the
callback for the C<backButton>.

See also L<METHOD back>.

=cut

sub backward {
    my $self = shift;
    return $self->{backButton}->invoke;
}

#
# Sub-class me!
# Called by Show().
#
sub initial_layout {
    my $self = shift;
    warn " FFF enter initial_layout" if $self->{-debug};
    return if $self->{_laid_out};
    # Wizard 98/95 style
    if (($self->cget(-style) eq '95') || $self->_on_first_page ) {
        my $im = $self->cget( -imagepath );
        if ( not ref $im ) {
            $self->Photo( "sidebanner", -file => $im );
        }
        else {
            $self->Photo( "sidebanner", -data => $$im );

            # $self->{left_object} = $self->Frame(-width=>100)->pack(qw/-side left -anchor w -expand 1 -fill both/);
        }
        $self->{left_object} =
          $self->Label( -image => "sidebanner" )
          ->pack( -side => "top", -anchor => "n" );
    }

    # Wizard 2k style - builds the left side of the wizard
    else {
        my $im = $self->cget( -topimagepath );
        if ( not ref $im ) {
            $self->Photo( "topbanner", -file => $im );
            $self->{left_object} =
              $self->Label( -image => "topbanner" )
              ->pack( -side => "top", -anchor => "e", );
        }
        else {
            $self->Photo( "topbanner", -data => $$im );
            $self->{left_object} =
              $self->Label( -image => "topbanner" )
              ->pack( -side => "top", -anchor => "e", );

            # $self->{left_object} = $self->Frame( -width => 250 )->pack( -side => "top", -anchor => "n", );
        }
    }
    $self->Advertise( imagePane => $self->{left_object} );
    $self->{_laid_out}++;
} # initial_layout

#
# Maybe sub-class me
#
sub render_current_page
  {
  my $self = shift;
  warn " FFF enter render_current_page $self->{wizardPagePtr}" if $self->{-debug};
  my %frame_pack = ( -side => "top" );
  if (
      ! $self->_on_first_page
      &&
      ! $self->_on_last_page
      &&
      ($self->{-style} ne '95')
     )
    {
    $self->{tagtext}->packForget;
    $self->_maybe_pack_tag_text;
    }
  else
    {
    $self->{tagtext}->packForget;
    }
  if ($self->_on_first_page || $self->_on_last_page)
    {
    $self->{left_object}->pack( -side => "left", -anchor => "w" );
    if ( $self->{-style} ne '95' )
      {
      $frame_pack{-expand} = 1;
      $frame_pack{-fill}   = 'both';
      }
    } # if
  elsif ( $self->cget( -style ) eq 'top' )
    {
    $self->{left_object}->packForget;
    }
  $self->_repack_buttons;
  # xxx
  $self->configure( -background => $self->cget("-background") );
  $self->{wizardFrame}->packForget
  if $self->{wizardFrame} and ref $self->{wizardFrame} ne 'CODE';
  if ( not defined $self->{wizardPageList}->[0] ) {
    Carp::croak
                                                                                                       'render_current_page called without any frames: did you add frames to the wizard?';
    }
  my $rPage = $self->{wizardPageList}->[$self->{wizardPagePtr}];
  warn " DDD in render_current_page, rPage=$rPage=" if $self->{-debug};
  if (! ref $rPage)
    {
    Carp::croak 'render_current_page called for a non-existent frame: did you add frames to the wizard?';
    } # if
  $self->{wizardFrame} = $rPage->()->pack(%frame_pack);
  if (Tk::Exists($self->{wizardFrame}))
    {
    $self->{wizardFrame}->update;
    $self->Advertise( wizardFrame => $self->{wizardFrame} );
    } # if
  $self->_resize_window;
  $self->{nextButton}->focus();
  warn " FFF leave render_current_page $self->{wizardPagePtr}" if $self->{-debug};
  } # render_current_page

sub _resize_window
  {
    my $self = shift;
    if ( ref $self->{wizardFrame} ) {
        if ( exists $self->{frame_sizes}->[ $self->{wizardPagePtr} ] ) {
            warn "Resize frame\n" if $self->{-debug};
            warn "      -width  => "
              . $self->{frame_sizes}->[ $self->{wizardPagePtr} ]->[0] . ",
        -height => " . $self->{frame_sizes}->[ $self->{wizardPagePtr} ]->[1] . "\n"
              if $self->{-debug};

            # print STDERR " DDD self=$self=\n";
            $self->configure(
                -width => $self->{frame_sizes}->[ $self->{wizardPagePtr} ]->[0],
                -height => $self->{frame_sizes}->[ $self->{wizardPagePtr} ]->[1]
            );
            $self->update;
        } # if
    } # if
    } # _resize_window


=head2 currentPage

  my $current_page = $wizard->currentPage()

This returns the index of the page currently being shown to the user.
Page are indexes start at 1, with the first page that is associated with
the wizard through the C<addPage> method. See also the L<METHOD addPage> entry.

=cut

sub currentPage
  {
  my $self = shift;
  # Throughout this module, wizardPagePtr is zero-based.  But we
  # "publish" it as one-based:
  return $self->{wizardPagePtr} + 1;
  } # currentPage

=head2 parent

  my $apps_main_window = $wizard->parent;

This returns a reference to the parent Tk widget that was used to create the wizard.

=cut

sub parent { return $_[0]->{Configure}{ -parent } || shift }

=head2 blank_frame

  my $frame = wizard>->blank_frame(
    -title    => $sTitle,
    -subtitle  => $sSub,
    -text    => $sStandfirst,
    -wait    => $iMilliseconds
  );

Returns a C<Tk::Frame> object that is a child of the Wizard control, with
some C<pack>ing parameters applied - for more details, please see C<-style>
entry elsewhere in this document.

Arguments are name/value pairs:

=over 4

=item -title =>

Printed in a big, bold font at the top of the frame

=item -subtitle =>

Subtitle/stand-first.

=item -text =>

Main body text.

=item -wait =>

Experimental, mainly for test scripts.
The amount of time in milliseconds to wait before moving forward
regardless of the user.  This actually just calls the C<forward> method (see
L<METHOD forward>).  Use of this feature will enable the back-button even if
you have disabled it.  What's more, if the page is supposed to wait for user
input, this feature will probably not give your users a chance.

WARNING: do not set -wait to too small of a number, or you will get
callbacks interrupting previous callbacks and the whole wizard will
get all out of whack.  100 is probably safe for most modern computers;
for slower machines try 300.  If you want to see the page as it flips
by, use 1000 or more.

See also: L<Tk::after>.

=back

Also:

  -width -height -background -font

=cut

#
# Sub-class me:
#  accept the args in the POD and return a Tk::Frame
#
sub blank_frame
  {
  my $self = shift;
  my $args = {@_};
  warn " FFF enter blank_frame" if $self->{-debug};
  my $wrap = $args->{-wraplength} || 375;
  $args->{-font} = $self->{defaultFont} unless $args->{-font};
  $args->{-height} ||= $DEFAULT_HEIGHT;
  $args->{-width}  ||= $DEFAULT_WIDTH;
  $self->{frame_sizes}->[ $self->{wizardPagePtr} ] = [ $args->{-width}, $args->{-height} ];
  warn "# Blank frame set width/height; $args->{-width}/$args->{-height}"
  if $self->{-debug};
  my $frame = $self->Frame(
                           -width  => $args->{-width},
                           -height => $args->{-height}
                          );
  DEBUG_FRAME && $frame->configure(-background => 'green');
  # For 'top' style pages other than first and last
  if (($self->cget( -style ) eq 'top')
      && (! $self->_on_first_page)
      && (! $self->_on_last_page)
     )
    {
    my $top_frame = $frame->Frame(
                                  -background => 'white',
                                 )->pack( -fill => 'x',
                                          -side => 'top',
                                          -anchor => 'e' );
    my $p = $top_frame->Frame( -background => 'white' );
    my $photo = $self->cget( -topimagepath );
    if ( ref $photo )
      {
      $p->Photo( "topimage", -data => $$photo );
      }
    else
      {
      $p->Photo( "topimage", -file => $photo );
      }
    $p->Label( -image => "topimage", -background => 'white' )
    ->pack( -side => "right", -anchor => "e", -padx => 5, -pady => 5 );
    $p->pack( -side => 'right', -anchor => 'n' );
    my $title_frame = $top_frame->Frame(
                                        -background => 'white',
                                       )->pack(
                                               -side   => 'left',
                                               -anchor => 'w',
                                               -expand => 1,
                                               -fill   => 'x'
                                              );
    # Is it better to call in Text::Wrap to indent, or access font
    # metrics and work out lengths and heights, or just sod it and
    # only support short lines?
    if ( $args->{-title} )
      {
      # Padding left of title: -height should come from font metrics of TITLE_FONT_TOP;
      #   but what about if the line wraps? LG: add an ellipsis at the end...
      $title_frame->Frame(qw/-background white -width 10 -height 30/
                         )->pack(qw/-fill x -anchor n -side left/);
      # The title frame content proper:
      $title_frame->Label(
                          -justify    => 'left',
                          -anchor     => 'w',
                          -wraplength => $wrap,
                          -text       => $args->{-title},
                          -font       => 'TITLE_FONT_TOP',
                          -background => "white",
                         )->pack(
                                 -side   => 'top',
                                 -expand => 1,
                                 -fill   => 'x',
                                 -pady   => 5,
                                 -padx   => 0
                                );
      } # if -title
    if ( $args->{-subtitle} )
      {
      $args->{-subtitle} =~ s/^[\n\r\f]//;
      $title_frame->Label(
                          -font       => 'SUBTITLE_FONT',
                          -justify    => 'left',
                          -anchor     => 'w',
                          -wraplength => $wrap,
                          -text => '   '. $args->{-subtitle},
                          -background => $args->{background} || "white",
                         )->pack(
                                 -side   => 'top',
                                 -expand => 0,
                                 -fill   => 'x',
                                 -padx   => 5,
                                );
      } # if -subtitle
    else
      {
      $frame->Label()
      ;    # intended so we can packForget first to $frame->children;
      }
    # This is the line below top:
    if (($self->cget(-style) eq 'top') && ! $self->_on_first_page)
      {
      $frame->Frame(
                    -width => $frame->cget( -width ) || $args->{-width},
                    -background => $frame->cget("-background"),
                    qw/ -relief groove -bd 1 -height 2/,
                   )->pack(qw/-side top -fill x/);
      } # if 'top'
    if ( $args->{-text} )
      {
      $args->{-text} =~ s/^[\n\r\f]//;
      $args->{-text} = "\n" . $args->{-text};
      my $p = $frame->Label(
                            -font       => $args->{-font},
                            -justify    => 'left',
                            -anchor     => 'w',
                            -wraplength => $wrap + 100,
                            -justify    => "left",
                            -text       => $args->{-text}
                           )->pack(
                                   -side   => 'top',
                                   -expand => 0,
                                   -fill   => 'x',
                                   -padx   => 10
                                  );
      } # if -text
    } # if 'top' style, but not first or last page
  # For wizards that are not 'top' style
  else
    {
    if ( $args->{-title} ) {
      my $p = $frame->Label(
                            -justify    => 'left',
                            -anchor     => 'w',
                            -wraplength => $wrap,
                            -text       => $args->{-title},
                            -font       => 'TITLE_FONT',
                           )->pack(
                                   -anchor => 'n',
                                   -side   => 'top',
                                   -expand => 0,
                                   -fill   => 'x'
                                  );
      }
    if ($args->{-subtitle})
      {
      $args->{-subtitle} =~ s/^[\n\r\f]//;
      my $p = $frame->Label(
                            -font       => $args->{-font},
                            -justify    => 'left',
                            -anchor     => 'w',
                            -wraplength => $wrap,
                            -text => '   '. $args->{-subtitle},
                           )->pack(
                                   -anchor => 'n',
                                   -side   => 'top',
                                   -expand => 0,
                                   -fill   => 'x'
                                  );
      }
    else {
      $frame->Label()
      ;    # intended so we can packForget first to $frame->children;
      }
    if ( $args->{-text} )
      {
      $args->{-text} =~ s/^[\n\r\f]//;
      $args->{-text} = "\n" . $args->{-text};
      my $p = $frame->Label(
                            -font       => $args->{-font},
                            -justify    => 'left',
                            -anchor     => 'w',
                            -wraplength => $wrap,
                            -justify    => "left",
                            -text       => $args->{-text},
                           )->pack(
                                   # -anchor => 'n',
                                   -side   => 'top',
                                   -expand => 0,
                                   -fill   => 'x'
                                  );
      }
    else
      {
      $frame->Label()
      ;    # intended so we can packForget first to $frame->children;
      }
    } # else
  #  my $p = $frame->Frame->pack(qw/-anchor s -side bottom -fill both -expand 1/);
  #  $p->configure(-background => $frame->cget("-background") );
  #  $p->packPropagate(0);
  # print STDERR " DDD in blank_frame(), -wait is $args->{-wait}.\n";
  $args->{-wait} ||= 0;
  if (0 < $args->{-wait})
    {
    _fix_wait(\$args->{ -wait });
    $frame->after(
                  $args->{ -wait },
                  sub {
                    $self->{nextButton}->configure( -state => 'normal' );
                    $self->{nextButton}->invoke;
                    }
                 );
    } # if
  $frame->packPropagate(0);
  return $frame->pack(qw/-side top -anchor n -fill both -expand 1/);
  } # end blank_frame


=head2 addTextFramePage

Add to the wizard a page containing a scrolling textbox, specified in
the parameter C<-boxedtext>. If this is a reference to a scalar, it is
taken to be plain text; if a plain scalar, it is taken to be the name
of a file to be opened and read.

Accepts the usual C<-title>, C<-subtitle>, and C<-text> like C<blank_frame>.

=cut

sub addTextFramePage
  {
  my $self = shift;
  # We have to make a copy of our args in order for them to get
  # "saved" in this coderef:
  my $args = {@_};
  # print STDERR " DDD addTextFramePage args are ", Dumper($args);
  return $self->addPage( sub { $self->_text_frame($args) } );
  } # addTextFramePage

sub _text_frame {
  my $self = shift;
  my $args = shift;
  # print STDERR " DDD _text_frame args are ", Dumper($args);
    local *IN;
    my $text;
    my $frame = $self->blank_frame(%$args);
    if ( $args->{-boxedtext} ) {
        if ( ref $args->{-boxedtext} eq 'SCALAR' ) {
            $text = $args->{-boxedtext};
        }
        elsif ( not ref $args->{-boxedtext} ) {
            open IN, $args->{-boxedtext}
              or croak "Could not read file: $args->{-boxedtext}; $!";
            read IN, $$text, -s IN or warn;
            close IN or warn;
        }
    }
    $$text = "" if not defined $text;

    my $padx = $self->cget( -style ) eq 'top' ? 30 : 5;
    my $t = $frame->Scrolled(
        "ROText",
        -background => ( $args->{"-background"} || 'white' ),
        -relief => "sunken",
        -borderwidth => "1",
        -font        => "SMALL_FONT",
        -setgrid     => 1,
        -scrollbars  => "osoe",
        -wrap        => "word",
    );
    $t->insert( '0.0', $$text );
    $t->configure( -state => "disabled" );
    $t->pack(qw/-expand 1 -fill both -padx 10 -pady 10/);
    $frame->Frame( -height => 10 )->pack();
    return $frame;
} # _text_frame

#
# Function (NOT a method!):       _dispatch
# Description:  Thin wrapper to dispatch event cycles as needed
# Parameters:    The _dispatch function is an internal function used to determine if the dispatch back reference
#         is undefined or if it should be dispatched.  Undefined methods are used to denote dispatchback
#         methods to bypass.  This reduces the number of method dispatches made for each handler and also
#         increased the usability of the set methods when trying to unregister event handlers.
#
sub _dispatch {
    my $handler = shift;

    # print STDERR " DDD _dispatch($handler)\n";
    if ( ref($handler) eq 'Tk::Callback' ) {
        return !$handler->Call();
    }    # if
    if ( ref($handler) eq 'CODE' ) {
        return !$handler->();
    }    # if
    return 1;
    return ( !( $handler->() ) )
      if ( ( defined $handler )
        && ( ref $handler )
        && ( ref $handler eq 'Tk::Callback' ) );
    return $handler->Call(@_) if ( ( defined $handler )
        && ( ref $handler ) );

    # Below is the original 1.9451 version:
    return ( !( $handler->Call() ) )
      if defined $handler
      and ref $handler
      and ref $handler eq 'CODE';
    return 0;
}    # _dispatch


# Returns the number of the last page (zero-based):
sub _last_page
  {
  my $self  = shift;
  my $i = scalar(@{$self->{wizardPageList}}) - 1;
  $self->{-debug} && print STDERR " DDD _last_page is $i\n";
  return $i;
  } # _last_page

# Returns true if the current page is the last page:
sub _on_last_page
  {
  my $self  = shift;
  $self->{-debug} && print STDERR " DDD in _on_last_page(), pagePtr is $self->{wizardPagePtr}\n";
  return ($self->_last_page == $self->{wizardPagePtr});
  } # _on_last_page

# Returns true if the current page is the first page:
sub _on_first_page
  {
  my $self  = shift;
  return (0 == $self->{wizardPagePtr});
  } # _on_last_page


# Increments the page pointer forward to the next logical page,
# honouring the Skip flags:
sub _page_forward {
    my $self  = shift;
    my $iPage = $self->{wizardPagePtr};

    # print STDERR " DDD _page_forward($iPage -->";
    do {
        $iPage++;
    } until ( !$self->{hiiSkip}{$iPage} || ( $self->_last_page <= $iPage ) );
    $iPage = $self->_last_page if ( $self->_last_page < $iPage );

    # print STDERR " $iPage)\n";
    $self->{wizardPagePtr} = $iPage;
}    # _page_forward

# Decrements the page pointer backward to the previous logical page,
# honouring the Skip flags:
sub _page_backward {
    my $self  = shift;
    my $iPage = $self->{wizardPagePtr};
    do {
        $iPage--;
    } until ( !$self->{hiiSkip}{$iPage} || ( $iPage <= 0 ) );
    $iPage = 0 if ( $iPage < 0 );
    $self->{wizardPagePtr} = $iPage;
}    # _page_backward

# Method:      _NextButtonEventCycle
# Description: Runs the complete view of the action handler cycle for the "Next>" button on the
#              wizard button bar. This includes dispatching the preNextButtonAction and
#              postNextButtonAction handler at the appropriate times.
#
sub _NextButtonEventCycle
  {
  my $self = shift;
  warn " FFF enter _NextButtonEventCycle\n" if $self->{-debug};
  if ( _dispatch( $self->cget( -preNextButtonAction ) ) )
    {
    warn " DDD preNextButtonAction says we should not go ahead\n" if $self->{-debug};
    return;
    } # if
  if ( $self->_on_last_page )
    {
    warn " DDD   we are on the last page\n" if $self->{-debug};
    if ( _dispatch( $self->cget( -preFinishButtonAction ) ) )
      {
      warn " DDD preFinishButtonAction says we should not go ahead\n" if $self->{-debug};
      return;
      } # if
    if ( _dispatch( $self->cget( -finishButtonAction ) ) )
      {
      warn " DDD finishButtonAction says we should not go ahead\n" if $self->{-debug};
      return;
      } # if
    $self->{really_quit}++;
    $self->_CloseWindowEventCycle();
    # Can't do anything now, we're dead
    return undef;
    } # if last page
  # Advance the wizard page pointer and then adjust the navigation buttons.
  # Redraw the frame when finished to get changes to take effect.
  $self->_page_forward;
  $self->render_current_page;
  # print STDERR " DDD this is before _dispatch postNextButtonAction\n";
  if ( _dispatch( $self->cget( -postNextButtonAction ) ) ) { return; }
  } # _NextButtonEventCycle

sub _BackButtonEventCycle {
    my $self = shift;
    return if _dispatch( $self->cget( -preBackButtonAction ) );

    # Move the wizard pointer back one position and then adjust the
    # navigation buttons to reflect any state changes. Don't fall off
    # end of page pointer
    $self->_page_backward;
    $self->render_current_page;
    if ( _dispatch( $self->cget( -postBackButtonAction ) ) ) { return; }
} # _BackButtonEventCycle

sub _HelpButtonEventCycle {
    my $self = shift;
    if ( _dispatch( $self->cget( -preHelpButtonAction ) ) )  { return; }
    if ( _dispatch( $self->cget( -helpButtonAction ) ) )     { return; }
    if ( _dispatch( $self->cget( -postHelpButtonAction ) ) ) { return; }
}

sub _CancelButtonEventCycle
  {
  my $self = shift;
  return if $self->Callback(
                            -preCancelButtonAction => $self->{-preCancelButtonAction} );
  $self->_CloseWindowEventCycle($_);
  } # _CancelButtonEventCycle

sub _CloseWindowEventCycle
  {
  my $self = shift;
  my $hGUI = shift;
  warn " FFF enter _CloseWindowEventCycle... really=[$self->{really_quit}]\n" if $self->{-debug};
  if (! $self->{really_quit})
    {
    warn "# Really?\n" if $self->{-debug};
    if (
        $self->Callback(
                        -preCloseWindowAction => $self->{-preCloseWindowAction}
                       )
       )
      {
      warn " DDD preCloseWindowAction says we should not go ahead\n" if $self->{-debug};
      return;
      } # if
    } # if
  if (Tk::Exists($hGUI))
    {
    warn "# hGUI=$hGUI= withdraw\n" if $self->{-debug};
    $hGUI->withdraw;
    } # if
  if ( $self->{Configure}{-kill_parent_on_destroy}
       && Tk::Exists( $self->parent ) )
    {
    warn "Kill parent ". $self->parent ." ". $self->{Configure}{ -parent } if $self->{-debug};
    # This should kill us, too:
    $self->parent->destroy;
    return;
    }
  warn "# Legacy withdraw\n" if $self->{-debug};
  $self->{_showing} = 0;
  if ($self->{Configure}{-kill_self_after_finish})
    {
    $self->destroy;
    }
  else
    {
    $self->withdraw;    # Legacy
    } # else
  return undef;
  } # _CloseWindowEventCycle


=head2 addDirSelectPage

  $wizard->addDirSelectPage ( -variable => \$chosen_dir )

Adds a page (C<Tk::Frame>) that contains a scrollable tree list of all
directories including, on Win32, logical drives.

Supply in C<-variable> a reference to a variable to set the initial
directory, and to have set with the chosen path.

Supply C<-nowarnings> with a value of C<1> to list only drives which are
accessible, thus avoiding C<Tk::DirTree> warnings on Win32 where removable
drives have no media.

Supply C<-nowarnings> a value other than C<1> to avoid listing drives
which are both inaccessible and - on Win32 - are
either fixed drives, network drives, or RAM drives (that is types 3, 4, and
6, according to C<Win32API::File::GetDriveType>.

You may also specify the C<-title>, C<-subtitle> and C<-text> parameters, as
in L<METHOD blank_frame>.

WARNING: The CPAN distribution Tk-Tree-4.7 does not work.  Do not
install Tk-Tree-4.7.  Just keep the Tk::Tree and Tk::DirTree that come
with Tk-804.027.

Also see L<CALLBACK callback_dirSelect>.

=cut

sub addDirSelectPage
  {
  my $self = shift;
  # We have to make a copy of our args in order for them to get
  # "saved" in this coderef:
  my $args = {@_};
  # print STDERR " DDD addDirSelectPage args are ", Dumper($args);
  $self->addPage( sub { $self->_page_dirSelect($args) } );
  } # addDirSelectPage

# PRIVATE METHOD _page_dirSelect
#
# It'd be nice to use FBox here, but it doesn't seem to support dir selection
# and DirSelect is broken and ugly
#
# As blank_frame plus:
# -variable => Reference to a variable to set.
# -nowarnings => 1 : chdir to each drive first and only list if accessible
#             => !1: as 1, plus on types 3,4 and 6.
# -directory  => start dir
sub _page_dirSelect
  {
  my $self = shift;
  my $args = shift;
  # print STDERR " DDD _page_dirSelect args are ", Dumper($args);
  if ( not $args->{-variable} ) {
    confess "You must supply a -variable parameter";
    }
  elsif ( not ref $args->{-variable} ) {
    confess "The -variable parameter must be a reference";
    }
  my $_drives = sub {
    return '/' if $^O !~ m/MSWin32/i;
    # Yuck: it does work, though. Somehow.
    eval('require Win32API::File');
    return Win32API::File::getLogicalDrives();
    };
  my ( $frame, @pl ) = $self->blank_frame(
                                          -title => $args->{-title} || "Please choose a $sdir",
                                          -subtitle => $args->{-subtitle}
                                          || "After you have made your choice, press Next to continue.",
                                          -text => $args->{-text}   || "",
                                          -wait => $args->{ -wait } || undef,
                                         );
  
  $frame->Frame( -height => 10 )->pack();
  my $entry = $frame->Entry(
                            -justify      => 'left',
                            -width        => 40,
                            -textvariable => $args->{-variable},
                           )->pack(
                                   -side   => 'top',
                                   -anchor => 'w',
                                   -fill   => "x",
                                   -padx   => 10,
                                   -pady   => 10,
                                  );
  $entry->configure( -background => $self->cget("-background") )
  if $self->cget("-background");
  
  my $dirsParent = $frame->Scrolled(
                                    "DirTree",
                                    -scrollbars       => 'osoe',
                                    -selectbackground => "navy",
                                    -selectforeground => "white",
                                    -selectmode       => 'browse',
                                    -width            => 40,
                                    -height           => 10,
                                    -browsecmd        => sub { ${ $args->{-variable} } = shift },
                                   )->pack( -fill => "both", -padx => 10, -pady => 0, -expand => 1 );
  $dirsParent->configure( -background => $self->cget("-background") )
  if $self->cget("-background");
  my $dirs = $dirsParent->Subwidget('scrolled');
  # Add a little margin at the bottom:
  $frame->Frame(-height => 5)->pack(-side => 'bottom');
  $frame->Frame()->pack(-side => 'bottom');
  my $mkdir = $frame->Button(
                             -text    => "New $sDir",
                             -command => sub
                               {
                               my $new_name = $self->prompt(
                                                            -title => "Create New $sDir",
                                                            -text  => "Please enter the name for the new $sdir"
                                                           );
                               if ($new_name) {
                                 $new_name =~ s/[\/\\]//g;
                                 $new_name = ${ $args->{-variable} } . "/$new_name";
                                 if ( !mkdir $new_name, 0777 ) {
                                   my $msg;
                                   if ( $! =~ /Invalid argument/i ) {
                                     $msg = "The $sdir name you supplied is not valid.";
                                     }
                                   elsif ( $! =~ /File Exists/i ) {
                                     $msg = "A $sdir with that name already exists.";
                                     }
                                   else {
                                     $msg = "The $sdir could not be created:\n\n\t'$!'";
                                     }
                                   $self->messageBox(
                                                     '-icon'  => 'error',
                                                     -type    => 'ok',
                                                     -title   => 'Could Not Create $sDir',
                                                     -message => $msg,
                                                    );
                                   } # if
                                 else {
                                   ${ $args->{-variable} } = $new_name;
                                   $dirs->configure( -directory => $new_name );
                                   $dirs->chdir($new_name);
                                   } # else
                                 } # if new_name
                               }, # end of -command sub
                            )->pack( -side => 'right',
                                     -anchor => 'w',
                                     -padx => 10,
                                     -ipadx => 5,
                                   );
  if ( $self->{desktop_dir} ) {    # Thanks, Slaven Rezic.
    $frame->Button(
                   -text    => "Desktop",
                   -command => sub {
                     ${ $args->{-variable} } = $self->{desktop_dir};
                     $dirs->configure( -directory => $self->{desktop_dir} );
                     $dirs->chdir( $self->{desktop_dir} );
                     },
                  )->pack( -side => 'right', -anchor => 'w', -padx => '10',
                           -ipadx => 5,
                         );
    } # if
  
  foreach my $d (&$_drives) {
    ($d) =~ /^(\w+:)/;
    if (
        $args->{-nowarnings}
        and (  $args->{-nowarnings} eq "1"
               or $^O !~ /win/i )
       )
      {
      my $cwd = Cwd::getcwd;
      $dirs->configure( -directory => $d ) if chdir $d;
      chdir $cwd;
      }
    elsif ( $args->{-nowarnings} ) {    # Fixed drive only
      my $cwd = Cwd::getcwd;
      $dirs->configure( -directory => $d )
      if Win32API::File::GetDriveType($d) == 3 and chdir $d;
      chdir $cwd;
      }
    else {
      $dirs->configure( -directory => $d );
      }
    } # foreach
  return $frame;
  } # _page_dirSelect

=head2 addFileSelectPage

  $wizard->addFileSelectPage(
                             -directory => 'C:/Windows/System32',
                             -variable => \$chosen_file,
                            );

Adds a page (C<Tk::Frame>) that contains a "Browse" button which pops up a file-select dialog box.
The selected file will be displayed in a read-only Entry widget.

Supply in C<-directory> the full path of an existing folder where the user's search shall begin.

Supply in C<-variable> a reference to a variable to have set with the chosen file name.

You may also specify the C<-title>, C<-subtitle> and C<-text> parameters, as
in L<METHOD blank_frame>.

=cut

sub addFileSelectPage
  {
  my $self = shift;
  # We have to make a copy of our args in order for them to get
  # "saved" in this coderef:
  my $args = {@_};
  # print STDERR " DDD addFileSelectPage args are ", Dumper($args);
  $self->addPage( sub { $self->_page_fileSelect($args) } );
  } # addFileSelectPage

#
# PRIVATE METHOD _page_fileSelect
#
# As blank_frame plus:
# -variable => Reference to a variable to set.
# -directory  => start dir
sub _page_fileSelect
  {
  my $self = shift;
  my $args = shift;
  # Verify arguments:
  if ( not $args->{-variable} )
    {
    confess "You must supply a -variable parameter";
    }
  elsif ( not ref $args->{-variable} )
    {
    confess "The -variable parameter must be a reference";
    }
  $args->{-directory} ||= '.';
  $args->{-title}     ||= "Please choose an existing file";
  $args->{-subtitle} ||=
  "After you have made your choice, click 'Next' to continue.";
  $args->{-text} ||= '';
  # Create the mother frame:
  my ( $frame, @pl ) = $self->blank_frame(
                                          -title    => $args->{-title},
                                          -subtitle => $args->{-subtitle},
                                          -text     => $args->{-text},
                                          -wait     => $args->{ -wait },
                                         );
  # Put some space around the embedded elements:
  $frame->Frame( -height => 10 )->pack(qw( -side left ));
  $frame->Frame( -height => 10 )->pack(qw( -side right ));
  my $entry = $frame->Entry(
                            -justify      => 'right',
                            -textvariable => $args->{-variable},
                            # For now (i.e. because we're lazy), don't
                            # let the user type in.  They must click
                            # the Browse button:
                            -state => 'readonly',
                           )->pack(
                                   -side   => 'left',
                                   -anchor => 'w',
                                   -fill   => "x",
                                   -expand => 1,
                                   -padx   => 3,
                                  );
  $entry->configure( -background => $self->cget("-background") )
  if $self->cget("-background");
  my $bBrowse = $frame->Button(
                               -text    => 'Browse...',
                               -command => sub {
                                 my $sFname = $frame->getOpenFile(
                                                                  -initialdir => $args->{-directory},
                                                                  -title      => $args->{-title},
                                                                 );
                                 ${ $args->{-variable} } = $sFname if $sFname;
                                 },
                              )->pack(qw( -side left -padx 3));
  return $frame;
  } # _page_fileSelect


=head2 addTaskListPage

Adds a page to the Wizard that will perform a series of tasks, keeping the user
informed by ticking-off a list as each task is accomplished.

Whilst the task list is being executed, both the I<Back> and I<Next> buttons
are disabled.

Parameters are as for C<blank_frame> (see L<METHOD blank_frame>), plus:

=over 4

=item -tasks

The tasks to perform, supplied as a reference to an array, where each
entry is a pair (i.e. a two-member list), the first of which is a text
string to display, the second a reference to code to execute.

=item -delay

The length of the delay, in milliseconds, after the page has been
displayed and before execution the task list is begun.
Default is 1000 milliseconds (1 second).
See L<the entry for the 'after' routine in the Tk::After manpage|Tk::After>.

=item -continue

Display the next Wizard page once the job is done: invokes the
callback of the I<Next> button at the end of the task.

=item -todo_photo

=item -doing_photo

=item -ok_photo

=item -error_photo

=item -na_photo

Optional: all C<Tk::Photo> objects, displayed as appropriate.
C<-na_photo> is displayed if the task code reference returns an undef value, otherwise:
C<-ok_photo> is displayed if the task code reference returns a true value, otherwise:
C<-error_photo> is displayed.
These have defaults taken from L<Tk::Wizard::Image|Tk::Wizard::Image>.

=item -label_frame_title

The label above the C<Tk::LabFrame> object which
contains the task list. Default label is the boring C<Performing Tasks:>.

=item -frame_args

Optional: the arguments to pass in the creation of the C<Frame> object used to contain the list.

=item -frame_pack

Optional: array-refernce to pass to the C<pack> method of the C<Frame> containing the list.

=back

=head2 TASK LIST EXAMPLE

  $wizard->addTaskListPage(
      -title => "Toy example",
      -tasks => [
         "Wait five seconds" => sub { sleep 5 },
       "Wait ten seconds!" => sub { sleep 10 },
    ],
  );

=cut

sub addTaskListPage
  {
  my $self = shift;
  # We have to make a copy of our args in order for them to get
  # "saved" in this coderef:
  my $args = {@_};
  # print STDERR " DDD addTaskListPage args are ", Dumper($args);
  $self->addPage( sub { $self->page_taskList($args) } );
  } # addTaskListPage

=head2 page_taskList

The same as C<addTaskListPage> (see L<METHOD addTaskListPage>)
but does not add the page to the Wizard.

Note that unlike C<addTaskListPage>, arguments are expected in a hash reference.

Useful for a task list that cannot be filled before the call
to C<Show()>.

Parameter C<-label_frame_title> is the label above the C<Tk::LabFrame> object which
contains the task list.  Default label is the boring C<Performing Tasks:>.

=cut

sub page_taskList
  {
  my $self = shift;
  my $args = shift;
  my @tasks;
  my @states = qw[ todo doing ok error na ];
  my $photos = {};
  foreach my $state (@states)
    {
    my $sArg = "-". $state ."_photo";
    if ( ! $args->{ $sArg } )
      {
      $photos->{$state} = $self->Photo($state,
                                       -data => $Tk::Wizard::Image::TASK_LIST{$state} );
      }
    elsif ( ! -r $args->{$sArg}
            || ! $self->Photo($state, -file => $args->{$sArg}))
      {
      warn "# Could not read $sArg from " . $args->{$sArg} if $^W;
      }
    } # foreach
  $args->{-frame_pack} = [qw/-expand 1 -fill x -padx 30 -pady 10/]
  unless $args->{-frame_pack};
  $args->{-frame_args} = [
                          -relief    => "flat",
                          -bd        => 0,
                          -label     => $args->{-label_frame_title} || "Performing Tasks: ",
                          -labelside => "acrosstop"
                         ]
  unless $args->{-frame_args};
  my $frame = $self->blank_frame(
                                 -title => $args->{-title} || "Performing Tasks",
                                 -subtitle => $args->{-subtitle}
                                 || "Please wait whilst the Wizard performs these tasks.",
                                 -text => $args->{-text}   || "",
                                 -wait => $args->{ -wait } || undef,
                                );
  if ( $#{ $args->{-tasks} } > -1 ) {
    my $task_frame =
    $frame->LabFrame( @{ $args->{-frame_args} } )
    ->pack( @{ $args->{-frame_pack} } );
    foreach ( my $i = 0 ; $i <= $#{ $args->{-tasks} } ; $i += 2 ) {
      my $icn = "-1";
      my $p =
      $task_frame->Frame(
                        )->pack( -side => 'top', -anchor => "w" );
      if ( exists $photos->{todo} ) {
        $icn = $p->Label(
                         -image      => "todo",
                         -anchor     => "w"
                        )->pack( -side => "left" );
        }
      $p->Label(
                -text       => @{ $args->{-tasks} }[$i],
                -anchor     => "w"
               )->pack( -side => "left" );
      push @tasks, [ $icn, @{ $args->{-tasks} }[ $i + 1 ] ];
      }
    } # if got any tasks
  else {
    $args->{-delay} = 1;
    }
  if ($args->{-wait})
    {
    # If we got a non-zero -wait argument, we must be part of an
    # automated test.  In any case, this page is going to auto-flip to
    # the next page soon (via a call to $widget->after).  We do NOT
    # want to start executing our tasks, only to have the Wizard flip
    # to the next page while we're still executing, because then we'll
    # be trying to update Photos that no longer exist (or worse).
    }
  else
    {
    # Do not let the user click any buttons while we're working:
    $self->{nextButton}->configure(-state => "disabled") if Tk::Exists($self->{nextButton});;
    $self->{backButton}->configure(-state => "disabled") if Tk::Exists($self->{backButton});;
    $frame->after(
                  $args->{-delay} || 1000,
                  sub
                    {
                    foreach my $task (@tasks)
                      {
                      if ( Tk::Exists($task->[0]) )
                        {
                        $task->[0]->configure( -image => "doing" );
                        $task->[0]->update;
                        } # if
                      my $result = &{ $task->[1] };
                      if ( Tk::Exists($task->[0]) )
                        {
                        $task->[0]->configure( -image => defined($result) ? $result ? 'ok' : 'error' : 'na' );
                        $task->[0]->update;
                        } # if
                      } # foreach
                    # We're all done, the user can click buttons again:
                    $self->{backButton}->configure( -state => "normal" ) if Tk::Exists($self->{backButton});
                    if (Tk::Exists($self->{nextButton}))
                      {
                      $self->{nextButton}->configure( -state => "normal" );
                      # $self->{nextButton}->invoke if $args->{ -continue };
                      } # if
                    } # sub
                 ); # after
    } # if...else
  return $frame;
  } # page_taskList


=head2 addMultipleChoicePage

Allow the user to make multiple choices among several options:
each choice sets a variable passed as reference to this method.

Accepts the usual parameters plus:

=over 4

=item -relief

For the checkbox buttons - see L<Tk::options>.

=item -choices

A reference to an array of hashes with the following fields:

=over 4

=item -title

Title of the option, will be rendered in bold

=item -subtitle

Text rendered smaller beneath the title

=item -variable

Reference to a variable that will contain the result of the choice.
Croaks if none supplied.
Your -variable will contain the default Tk::Checkbutton values of
1 for checked and 0 for unchecked.

=item -checked

Pass a true value to specify that the box should initially
appear checked.

=back

=cut

sub addMultipleChoicePage
  {
  my $self = shift;
  # We have to make a copy of our args in order for them to get
  # "saved" in this coderef:
  my $args = {@_};
  # print STDERR " DDD addMultipleChoicePage args are ", Dumper($args);
  return $self->addPage( sub { $self->_page_multiple_choice($args) } );
  } # addMultipleChoicePage

sub _page_multiple_choice
  {
  my $self = shift;
  my $args = shift;
  my $frame = $self->blank_frame(%$args);
  if (! ref($args->{-choices}) || (ref($args->{-choices}) ne 'ARRAY'))
    {
    croak "-choices should be a ref to an array!";
    } # if
  my $content =
      $frame->Frame()
      ->pack( -side => 'top', -anchor => "n", -padx => 30, -pady => 10, );

    foreach my $opt ( @{ $args->{-choices} } ) {
        croak "Option in -choices array is not a hash!"
          if not ref $opt
          or ref $opt ne 'HASH';
        croak "No -variable!"                    if not $opt->{-variable};
        croak "-variable should be a reference!" if not ref $opt->{-variable};
        my $b = $content->Checkbutton(
                                      -text     => $opt->{-title},
                                      -justify  => 'left',
                                      -relief   => $args->{-relief} || 'flat',
                                      -font     => "RADIO_BOLD",
                                      -variable => $opt->{-variable},
                                     )->pack(qw/-side top -anchor w /);
        $b->invoke if $opt->{-checked};
        $opt->{-subtitle} ||= '';
        $content->Label(
                        -text => $opt->{-subtitle},
                       )->pack(qw/-side top -anchor w -padx 25 -pady 0/);
        } # foreach
    return $frame;
    } # _page_multiple_choice

=back

=head2 setPageSkip

Mark one or more pages to be skipped at runtime.
All integer arguments are taken to be page numbers
(i.e. the number returned by any of the addPage methods)

You should never set the first page to be skipped.
You can not set the last page to be skipped.

=cut

sub setPageSkip {
    my $self = shift;
    foreach my $i (@_) {

        # The user's argument is 1-based, but our internal data structures
        # are zero-based, ergo minus 1:
        $self->{hiiSkip}{ $i - 1 } = 1;
    }    # foreach
}    # setPageSkip

=head2 setPageUnskip

Mark one or more pages not to be skipped at runtime
(i.e. reverse the effects of setPageSkip).
All integer arguments are taken to be page numbers
(i.e. the number returned by any of the addPage methods)

=cut

sub setPageUnskip {
    my $self = shift;
    foreach my $i (@_) {

        # The user's argument is 1-based, but our internal data structures
        # are zero-based, ergo minus 1:
        $self->{hiiSkip}{ $i - 1 } = 0;
    }    # foreach
}    # setPageUnskip

=head2 prompt

Equivalent to the JavaScript method of the same name: pops up
a dialogue box to get a text string, and returns it.  Arguments
are:

=over 4

=item -title =>

The title of the dialogue box.

=item -text =>

The text to display above the C<Entry> widget.

=item -value =>

The initial value of the C<Entry> box.

=item -wraplength =>

Text C<Label>'s wraplength: defaults to 275.

=item -width =>

The C<Entry> widget's width: defaults to 40.

=back

=cut

sub prompt {
  my $self = shift;
  my $args = {@_};
    my ( $d, $w );
    my $input = $self->cget( -value );
    $d = $self->DialogBox(
        -title => $args->{-title} || "Prompt",
        -buttons        => [ $LABELS{CANCEL}, $LABELS{OK} ],
        -default_button => $LABELS{OK},
    );
    if ( $args->{-text} ) {
        $w = $d->add(
            "Label",
            -font       => $self->{defaultFont},
            -text       => $args->{-text},
            -width      => 40,
            -wraplength => $args->{-wraplength} || 275,
            -justify    => 'left',
            -anchor     => 'w',
        )->pack();
    }
    $w = $d->add(
        "Entry",
        -font         => $self->{defaultFont},
        -relief       => "sunken",
        -width        => $args->{-width} || 40,
        -background   => "white",
        -justify      => 'left',
        -textvariable => \$input,
    );
    $w->pack( -padx => 2, -pady => 2 );
    $d->Show;
    return $input ? $input : undef;
} # prompt

#
# Using a -wait value for After of less than this seems to cause a weird Tk dump
# so call this whenever using a -wait
#
sub _fix_wait {
    my $wait_ref = shift;
    $$wait_ref += 200 if $$wait_ref < 250;
}

=head1 CALLBACKS

=head2 DIALOGUE_really_quit

This is the default callback for -preCloseWindowAction.
It gives the user a Yes/No dialog box; if the user clicks "Yes",
this function returns true (otherwise returns a false value).

=cut

sub DIALOGUE_really_quit
  {
  my $self = shift;
  return 0 if $self->{nextButton}->cget( -text ) eq $LABELS{FINISH};
  warn "# DIALOGUE_really_quit \n" if $self->{-debug};
  unless ( $self->{really_quit} )
    {
    warn "# Get really quit info\n" if $self->{-debug};
    my $button = $self->messageBox(
                                   '-icon'  => 'question',
                                   -type    => 'yesno',
                                   -default => 'no',
                                   -title   => 'Quit Wizard??',
                                   -message =>
                                   "The Wizard has not finished running.\n\nIf you quit now, the job will not be complete.\n\nDo you really wish to quit?"
                                  );
    $self->{really_quit} = lc $button eq 'yes' ? 1 : 0;
    warn "# ... really=[$self->{really_quit}]\n" if $self->{-debug};
    } # unless
  return !$self->{really_quit};
  } # DIALOGUE_really_quit


=head2 callback_dirSelect

A callback to check that the directory, passed as a reference in the sole
argument, exists, or can and should be created.

Will not allow the Wizard to continue unless a directory has been chosen.
If the chosen directory does not exist, Setup will ask if it should create
it. If the user affirms, it is created; otherwise the user is again asked to
chose a directory.

Returns a Boolean value.

This method relies on C<Win32API::File> on MS Win32 machines only.

=cut

sub callback_dirSelect {
  my $self = shift;
  my $var = shift;
    if ( not $$var ) {
        $self->messageBox(
            '-icon'  => 'info',
            -type    => 'ok',
            -title   => 'Form Incomplete',
            -message => "Please select a $sdir to continue."
        );
    }
    elsif ( !-d $$var ) {
        $$var =~ s|[\\]+|/|g;
        $$var =~ s|/$||g;
        my $button = $self->messageBox(
            -icon    => 'info',
            -type    => 'yesno',
            -title   => qq'$sDir does not exist',
            -message => "The $sdir you selected does not exist.\n\n"
              . "Shall I create "
              . $$var . " ?"
        );
        if ( lc $button eq 'yes' ) {
            return 1 if File::Path::mkpath($$var);
            $self->messageBox(
                -icon  => 'warning',
                -type  => 'ok',
                -title => qq'$sDir Could Not Be Created',
                -message =>
"The $sdir you entered could not be created.\n\nPlease enter a different $sdir and press Next to continue."
            );
        }
        else {
            $self->messageBox(
                -icon  => 'info',
                -type  => 'ok',
                -title => qq'$sDir Required',
                -message =>
"Please select a $sdir so that Setup can install the software on your machine.",
            );
        }
    }
    else {
        return 1;
    }
    return 0;
} # callback_dirSelect

=head1 ACTION EVENT HANDLERS

A Wizard is a series of pages that gather information and perform
tasks based upon that information. Navigated through the pages is via
I<Back> and I<Next> buttons, as well as I<Help>, I<Cancel> and
I<Finish> buttons.

In the C<Tk::Wizard> implementation, each button has associated with
it one or more action event handlers, supplied as code-references
executed before, during and/or after the button press.

The handler code should return a Boolean value, signifying whether the
remainder of the action should continue.  If a false value is
returned, execution of the event handler halts.

=over 4

=item -preNextButtonAction =>

This is a reference to a function that will be dispatched before the Next
button is processed.

=item -postNextButtonAction =>

This is a reference to a function that will be dispatched after the Next
button is processed. The function is called after the application has logically
advanced to the next page, but before the next page is drawn on screen.


=item -preBackButtonAction =>

This is a reference to a function that will be dispatched before the Previous
button is processed.

=item -postBackButtonAction =>

This is a reference to a function that will be dispatched after the Previous
button is processed.

=item -preHelpButtonAction =>

This is a reference to a function that will be dispatched before the Help
button is processed.

=item -helpButtonAction =>

This is a reference to a function that will be dispatched to handle the Help
button action.
By default there is no Help action; therefore unless you are providing this
function, you should initialize your Wizard with -nohelpbutton => 1.

=item -postHelpButtonAction =>

This is a reference to a function that will be dispatched after the Help
button is processed.

=item -preFinishButtonAction =>

This is a reference to a function that will be dispatched just before the Finish
button action.

=item -finishButtonAction =>

This is a reference to a function that will be dispatched to handle the Finish
button action.

=item -preCancelButtonAction =>

This is a reference to a function that will be dispatched before the Cancel
button is processed.  Default is to exit on user confirmation - see
L<METHOD DIALOGUE_really_quit>.

=item -preCloseWindowAction => 

This is a reference to a function that will be dispatched before the window
is issued a close command.
If this function returns a true value, the Wizard will close.
If this function returns a false value, the Wizard will stay on the current page.
Default is to exit on user confirmation - see L<DIALOGUE METHOD DIALOGUE_really_quit>.

=back

All active event handlers can be set at construction or using C<configure> -
see L<WIDGET-SPECIFIC OPTIONS> and L<METHOD configure>.

=head1 BUTTONS

  backButton nextButton helpButton cancelButton

If you must, you can access the Wizard's button through the object fields listed
above, each of which represents a C<Tk::Button> object. Yes, this is not a good
way to do it: patches always welcome ;)

This is not advised for anything other than disabling or re-enabling the display
status of the buttons, as the C<-command> switch is used by the Wizard:

  $wizard->{backButton}->configure( -state => "disabled" )

Note: the I<Finish> button is simply the C<nextButton> with the label C<$LABEL{FINISH}>.

See also L<INTERNATIONALISATION>.

=head1 INTERNATIONALISATION

The labels of the buttons can be changed (perhaps into a language other an English)
by changing the values of the package-global C<%LABELS> hash, where keys are
C<BACK>, C<NEXT>, C<CANCEL>, C<HELP>, and C<FINISH>.

The text of the callbacks can also be changed via the
C<%LABELS> hash: see the top of the source code for details.

=head1 IMPLEMENTATION NOTES

This widget is implemented using the Tk 'standard' API as far as possible,
given my almost three weeks of exposure to Tk. Please, if you have a suggestion,
or patch, send it to me directly: C<LGoddard@CPAN.org>.

The widget is a C<MainWindow> and not a C<TopLevel> window. The reasoning is that
Wizards are applications in their own right, and not usually parts of other
applications. Although at the time of writing, I had only three weeks of Tk, I believe
it should be possible
to embed a C<Tk::Wizard> into another window using C<-use> and C<-container> -- but
any info on this practice would be appreciated.

There is one outstanding bug which came about when this Wizard was translated
from an even more naive implementation to the more-standard manner. That is:
because C<Wizard> is a sub-class of C<MainWindow>, the C<-background> is inaccessible
to me. Advice and/or patches suggestions much appreciated.

=head1 THE Tk::Wizard NAMESPACE

In discussion on comp.lang.perl.tk, it was suggested by Dominique Dumont
(would you mind your address appearing here?) that the following guidelines
for the use of the C<Tk::Wizard> name-space be followed:

=over 4

=item 1

That the module C<Tk::Wizard> act as a base module, providing all the basic services and
components a Wizard might require.

=item 2

That modules beneath the base in the hierarchy provide implementations based on
aesthetics and/or architecture.

=back

=head1 NOTES ON SUB-CLASSING Tk::Wizard

If you are planning to sub-class C<Tk::Wizard> to create a different display style,
there are three routines you will need to over-ride:

=over 4

=item initial_layout

=item render_current_page

=item blank_frame

=back

This may change, please bear with me.

=head1 CAVEATS

In earlier versions of this still-alpha software, if you did not call
the C<Wizard>'s C<destroy> method, you would receive errors. This may
or may not still be an issue for you. If it is, you can "simply"
provide a callback to C<-finishButtonAction>:

  $wizard->configure(
    -finishButtonAction  => sub { $wizard->destroy; 1; },
  );

Please let me know if you need to do this.

=over 4

=item *

Bit messy when composing frames.

=item *

Task Frame LabFrame background colour doesn't set properly under 5.6.1.

=item *

20 January 2003: the directory tree part does not create directories
unless the eponymous button is clicked. Is this still an issue?

=item *

In Windows, with the system font set to > 96 DPI (via Display Properties / Settings
/ Advanced / General / Display / Font Size), the Wizard will not display pro pertly.
This seems to be a Tk feature.

=item *

Still not much of a Tk widget inheritance - any pointers welcome.

=item *

Nothing is currently done to ensure text fits into the window - it is currently up to
the client to make frames C<Scrolled>).

=back

=head1 BUGS

Please use RT (https://rt.cpan.org/Ticket/Create.html?Queue=Tk-Wizard)
to submit a bug report.

=head1 CHANGES

Please see the file F<CHANGES.txt> included with the distribution.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org) based on work Daniel T Hable.
Thanks to Martin Thurn (mthurn@cpan.org) for support and patches.

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 COPYRIGHT

Initial beta Copyright (c) Daniel T Hable, 2/2002.

Copyright (C) Lee Goddard, 11/2002 - 05/2005 ff.

Patches Copyright (C) Martin Thurn 2005.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

THIS SOFTWARE AND THE AUTHORS OF THIS SOFTWARE ARE IN NO WAY CONNECTED
TO THE MICROSOFT CORP.

THIS SOFTWARE IS NOT ENDORSED BY THE MICROSOFT CORP

MICROSOFT IS A REGISTERED TRADEMARK OF MICROSOFT CORP.

=cut

1;

__END__

