package Tk::Wizard;
use vars qw/$VERSION/;
$VERSION = 1.0211;	# 27 November 2002, 17:19 CET
#
# Please read the copyright notice and licence at the end of this file.
#
use strict;
use Carp;
use Cwd;
use Tk;
use Tk::DirTree;

=head1 NAME

Tk::Wizard - Wizard framework for installers & more

=head1 SYNOPSIS

	use Tk::Wizard;
	# Instantiate a Wizard
	my $wizard = new Tk::Wizard(
		-title		=> "TitleBar Title",
		-imagepath	=> "/image/for/the/left/panel.gif",
	);
	$wizard->configure( ...add event handlers... );
	$wizard->addPage(
		... code-ref to anything returning a Tk::Frame ...
	);
	$wizard->addPage( sub {
		return $wizard->blank_frame(
			-title	=> "Page Title",
			-text	=> "Stand-first text.",
		);
	});
	$wizard->Show;
	MainLoop;
	__END__

To avoid 50 lines of SYNOPSIS, please see the file F<test.pl> included
with the distribution.

=head1 DEPENDENCIES

	Tk and modules of the current standard Perl Tk distribution.

On MS Win32 only:

	Win32API::File

And if you plan to use the method C<register_with_windows> on MsWin32,
you'll need Win32::TieRegistry.

=head1 DESCRIPTION

The C<Tk::Wizard> module automates a large part of the creation of a wizard program
to collect information and then perform some complex task based upon it.

The Wizard was developed to aid software installation by end-users using ActiveState's
ActivePerl, but should function under other OS and circumstances. There package does
contain a number of routines specific to software installation: these may be removed to
a sub-class at a later date.

The wizard feel is largly based upon the Microsoft(TM,etc) wizard style: the default is
simillar to that found in Microsoft Windows 95; a more Windows 2000-like feel is also
supported (see the C<-style> entry in L<CONSTRUCTOR (new)>.


B<THIS IS A BETA RELEASE: ALL CONTRIBUTIONS ARE WELCOME!>

=cut

# See INTERNATIONALISATION
my %LABELS = (
	# Buttons
	BACK => "< Back",	NEXT => "Next >",
	FINISH => "Finish",	CANCEL => "Cancel",
	HELP => "Help",
	# licence agreement
	LICENCE_ALERT_TITLE	=> "Licence Condition",
	LICENCE_OPTION_NO	=> "I do not accept the terms of the licence agreement",
	LICENCE_OPTION_YES	=> "I accept the terms the terms of the licence agreement",
	LICENCE_IGNORED		=> "You must read and agree to the licence before you can use this software.\n\nIf you do not agree to the terms of the licence, you must remove the software from your machine.",
	LICENCE_DISAGREED	=> "You must read and agree to the licence before you can use this software.\n\nAs you indicated that you do not agree to the terms of the licence, please remove the software from your machine.\n\nSetup will now exit.",
);


=head1 CONSTRUCTOR (new)

	Tk::Wizard->new( -name1=>"value1"...-nameN=>"valueN" )

Creates a new instance of the Tk::Wizard object as a C<MainWindow>, or
in the supplied C<MainWindow> (see below).

=head2 STANDARD OPTIONS

The following standard paramters apply to the whole of the Wizard:

	-width -height -background -wraplength

=head2 WIZARD-SPECIFIC OPTIONS

=over 4

=item -title =>

This is the title that will be displayed in the main window's title bar

=item -style =>

Default is no value, which creates a traditional, Windows 95-style wizard,
with every page being C<SystemButtonFace> coloured, with a large image on the
left (C<-imagepath>, below).

If C<-style=>'top'>, the Wizard will be more of a Windows 2000-like affair,
with the initial page being a white-backgrounded version of the traditional style,
and subsequent pages being C<SystemButtonFace> coloured, with a white
strip at the top holding a title and subtitle, and a smaller image (C<-topimagepath>,
below>.

=item -imagepath =>

Path to an image file that will be displayed on the left-hand side of the screen.
Dimensions are not been restrained (yet).

Notes:

=over 4

=item *

This is a C<Tk::Photo> object without the format being specified - this has been
tested only on GIF and JPEG.

=item *

No checking is done, but paths ought to be absolute, as no effort is made to
maintain or restore any initial current working directory.

=item *

The supplied images F<setup_blue.gif> and F<setup_blue_top.gif> are used by default.
If you supply others you will probably have to set the Wizard's C<-width> and
C<-height> properties, as there is (currently) no image-sized checking performed.

=back

=item -topimagepath =>

Only required if C<-style=>'top'> (as above): the image this filepath specifies
will be displayed in the top-right corner of the screen. Dimensions are not
restrained (yet), but only 50px x 50px has been tested.

Please see notes the C<-imagepath> entry, above.

=item -mw =>

Optionally a TK C<MainWindow> for the Wizard to occupy. If none is supplied,
one is created. If you supply a <MainWindow>, you'll currently probably need to
specify new C<-width> and C<-height> attributes for the Wizard.

=item -nohelpbutton =>

Set to anything to disable the display of the help buton.

=item Action Event Handlers:

Please see L<ACTION EVENT HANDLERS> for details.

=back

All paramters can be set after construction using C<configure> - see
L<METHOD configure>.

The B<default font> is created by the constructor as 8pt Verdana,
named C<DEFAULT_FONT> and placed in the object's C<defaultFont> field.
All references to the default font in the Wizard call this routine, so
changing the default is easy.

Privately, C<licence_agree> flags whether the end-user licence agreement
has been accepted.

=cut

sub new($) { my ($invocant,$args) = (shift,{@_});
   my $class = ref( $invocant) || $invocant;
   my $self = {};
   $self = { # required for GUI operation
		# configuration parameters
		-title					=> "Generic Wizard",
		-style					=> "95",
		# event handling references
		-preNextButtonAction    => undef,
		-postNextButtonAction   => undef,
		-preBackButtonAction    => undef,
		-postBackButtonAction   => undef,
		-preHelpButtonAction    => undef,
		-helpButtonAction       => undef,
		-postHelpButtonAction   => undef,
		-finishButtonAction     => undef,
		-preCancelButtonAction 	=> sub { &DIALOGUE_really_quit($self) },
		-preCloseWindowAction	=> sub { &DIALOGUE_really_quit($self), },
		# wizard page control list and pointer
		wizardPageList          => [],
		wizardPagePtr           => 0,
		# private: current frame
		wizardFrame         	=> 0,
	};
	foreach (keys %$args){
		$self->{$_} = $args->{$_}
	}
	unless ($self->{wizwin}){
		$self->{wizwin} = delete ($self->{mw})
		|| MainWindow->new(
			-width  => $self->{-width}  || ($self->{-style} eq 'top'? 500 : 570),
			-height => $self->{-height} || 370,
		);
	}
	bless $self, $class;
	# Font used for &blank_frame titles
	$self->{wizwin}->fontCreate(qw/TITLE_FONT -family verdana -size 12 -weight bold/);
	# Fonts used if -style=>"top"
	$self->{wizwin}->fontCreate(qw/TITLE_FONT_TOP -family verdana -size 8 -weight bold/);
	$self->{wizwin}->fontCreate(qw/SUBTITLE_FONT  -family verdana -size 8 /);
	# Font used in licence agreement
	$self->{wizwin}->fontCreate(qw/SMALL_FONT -family verdana -size 8 /);
	# Font used in all other places
	$self->{wizwin}->fontCreate(qw/DEFAULT_FONT -family verdana -size 8 /);
	$self->{defaultFont} = 'DEFAULT_FONT';
	# See sub Show for more....
	return $self;
} # end of sub new


=head1 METHODS

=head2 METHOD configure

Allows the configuration of all object properties.
=cut

sub configure { my $self = shift;
	my %newHandlers = ( @_ );
	foreach( keys %newHandlers) { $self->{$_} = $newHandlers{$_} }
}


=head2 METHOD addPage

	$wizard->addPage ($page_code_ref1 ... $page_code_refN)

Adds a Wizard page to the wizard. The parameters must be C<Tk::Frame> objects,
such as those returned by the methods C<blank_frame>, C<addLicencePage> and C<addDirSelectPage>.

Pages are (currently) stored and displayed in the order added.

Returns the index of the page added, which is useful as a page UID when peforming
checks as the I<Next> button is pressed (see file F<test.pl> supplied with the distribution).

See also L<METHOD blank_frame>, L<METHOD addLicencePage> and L<METHOD addDirSelectPage>.

=cut

sub addPage { my ($self, @pages) = (shift,@_);
	push @{$self->{wizardPageList}}, @pages;
}


=head2 METHOD Show

	C<wizard>->Show()

This method must be dispatched before the Wizard will be displayed,
and must preced the C<MainLoop> call.

=cut

sub Show { my $self = shift;
	# builds the buttons on the bottom of thw wizard
	if ($^W and $self->{-style} eq 'top' and not $self->{-topimagepath}){
		warn "Wizard has -style=>top but not -topimagepath is defined";
	}
	if ($^W and $#{$self->{wizardPageList}}==0){
		warn "Showing a Wizard that is only one page long";
	}
	my $buttonPanel = $self->{wizwin}->Frame();
	$self->{nextButton} = $buttonPanel->Button( -text => $LABELS{NEXT},
		-command => [ \&NextButtonEventCycle, $self ],
		-width => 10
	)->pack( -side => "right", -expand => 0,-pady=>10);
	$self->{backButton} = $buttonPanel->Button( -text => $LABELS{BACK},
		-command => [ \&BackButtonEventCycle, $self ],
		-width => 10,
		-state => "disabled"
	)->pack( -side => "right", -expand => 0,-pady=>10);
	$self->{cancelButton} = $buttonPanel->Button( -text => $LABELS{CANCEL},
		-command => [ \&CancelButtonEventCycle, $self, $self->{wizwin}],
		-width => 10
	) ->pack( -side => "right", -expand => 0,-pady=>10);
	unless ($self->{-nohelpbutton}){
		$self->{helpButton} = $buttonPanel->Button( -text => $LABELS{HELP},
			-command => [ \&HelpButtonEventCycle, $self ],
			-width => 10,
		)->pack( -side => 'left', -anchor => 'w',-pady=>10);
	}
	$buttonPanel->pack( -side => "bottom", -fill => 'x', );

	my $line = $self->{wizwin}->Frame(
		-width => $self->{-width}||500,
		qw/ -relief groove -bd 1 -height 2 -background SystemButtonFace/
	);
	$line->pack(qw/-side bottom -fill x/);

	#
	# Wizard 98/95 style
	#
	if ($self->{-style} eq '95' or $self->{wizardPagePtr}==0){
		if ($self->{-imagepath}){
			$self->{wizwin}->Photo( "sidebanner",  -file => $self->{-imagepath});
			$self->{left_object} = $self->{wizwin}->Label( -image => "sidebanner")->pack( -side => "left", -anchor => "w");
		} else {
			$self->{left_object} = $self->{wizwin}->Frame(
				-width => 100
			)->pack(
				-side => "left", -anchor => "w",-expand=>1,-fill=>'both'
			);
		}

		# Seems graceless but:
		if ($self->{-style} eq 'top' and $self->{wizardPagePtr}==0){
			$self->{wizwin}->configure(-background=>'white')
		} elsif ($self->{-background}) {
			$self->{wizwin}->configure(-background=>$self->{-background})
		}
		# This populates the wizard page panel on the side of the screen.
		$self->{wizardFrame} =
		$self->{wizardPageList}->[$self->{wizardPagePtr}]->()->pack(
			-side=>"top", -expand=>0, -padx=>20, -pady=>2
		);
	}

	#
	# Wizard 2k style - builds the left side of the wizard
	#
	else {
		if ($self->{-topimagepath}){
			$self->{wizwin}->Photo( "sidebanner", -file => $self->{-topimagepath});
			$self->{left_object} = $self->{wizwin}->Label( -image => "sidebanner")->pack( -side => "top", -anchor => "e", );
		} else {
			$self->{left_object} = $self->{wizwin}->Frame( -width => 250 )->pack( -side => "top", -anchor => "n", -padx=>5, -pady=>2);
		}

		# This populates the wizard page panel on the side of the screen.
		$self->{wizardFrame} =
			$self->{wizardPageList}->[($self->{wizardPagePtr})]->()->pack(
			   -side => "bottom", -expand => 0, -padx=>5, -pady=>2
			);
	}

	#
	# setup the containing window to match the criteria for a wizard widget
	#
	$self->{wizwin}->configure( -title => $self->{-title});
	$self->{wizwin}->resizable( 0, 0);        # forbid resize
	$self->{wizwin}->withdraw;                # position in screen center
	$self->{wizwin}->Popup;
	$self->{wizwin}->transient;               # forbid minimize
	$self->{wizwin}->protocol( WM_DELETE_WINDOW => [ \&CloseWindowEventCycle, $self, $self->{wizwin}]);
	$self->{wizwin}->packPropagate(0);
	$self->{wizwin}->configure(-background=>'white');
} # end of sub Show


=head2 METHOD currentPage

	my $current_page = $wizard->currentPage()

This returns the index of the page currently being shown to the user.
Page are indexes start at 1, with the first page that is associated with
the wizard through the C<addPage> method.

See L<METHOD addPage>.

=cut

sub currentPage {
   my($self) = @_;
   return ($self->{wizardPagePtr} + 1);
}

=head2 METHOD parent

	my $main_window = $wizard->parent

This returns a reference to the parent Tk widget that was used to create the wizard.
Returns a reference to the Wizard's C<MainWindow>, as defined at construction or
supplied by the user before the C<Show> method was called - see L<CONSTRUCTOR (new)>..

=cut

sub parent {
   my ($self) = @_;
   return $self->{wizwin};
}

=head2 METHOD blank_frame

	my ($frame,@packing) = C<wizard>->blank_frame(-title=>$title,-text=>$standfirst);

Returns a C<Tk::Frame> object that is a child of the Wizard control, with some C<pack>ing
parameters applied - for more details, please see C<-style> section in L<CONSTRUCTOR (new)>.

Arguments are name/value pairs:

=over 4

=item -title =>

Printed in a big, bold font at the top of the frame as a title

=item =subtitle =>

Subtitle/standfirst.

=item -text =>

Main body text.

=back

Also:

	-width -height -background -font

See also L<METHOD addLicencePage> and L<METHOD addDirSelectPage>.

=cut

sub blank_frame { my ($self,$args) = (shift,{@_});
	my ($main_bg,$main_wi);
	# First and last pages are white
	if ($self->{wizardPagePtr}==0
		or $self->{wizardPagePtr} == $#{$self->{wizardPageList}}
	){
		$main_bg = "white";
		$main_wi = $args->{-width} || 300;
	}
	# For 'top' style, main body is plain
	elsif ($self->{-style} eq 'top' and $self->{wizardPagePtr}>0){
		$main_bg = undef;
		$main_wi = $args->{-width} || 600
	}
	# For other styles (95 default), main body is userdefined or plain
	else {
		$main_bg = $args->{background} || undef;
		$main_wi = $args->{-width} || 300;
	}
	my $frame = $self->parent->Frame(
		-width=>$main_wi, -height=>$args->{-height}||300,
	);

	$frame->configure(-background => $main_bg) if $main_bg;

	$args->{-font} = $self->{defaultFont} unless $args->{-font};
	my $wrap = $args->{-wraplength} || 375;

	# For 'top' style pages other than first and last
	if (($self->{-style} eq 'top' and $self->{wizardPagePtr}>0)
	and $self->{wizardPagePtr} != $#{$self->{wizardPageList}}
	){
		my $top_frame = $frame->Frame(-background=>'white')->pack(-fill=>'x',-side=>'top',-anchor=>'e');
 		$_ = $top_frame->Frame(-background=>'white');
		$_->Photo( "topimage", -file => $self->{-topimagepath});
		$_->Label( -image => "topimage")->pack( -side=>"right", -anchor=>"e", -padx=>5,-pady=>5);
		$_->pack(-side=>'right',-anchor=>'n');
		my $title_frame = $top_frame->Frame(-background=>'white')->pack(
			-side=>'left',-anchor=>'w',-expand=>1,-fill=>'x'
		);
		#
		# Is it better to call in Text::Wrap to indent, or
		# access font metrics and work out lengths and heights, or
		# just sod it and only support short lines?
		#
		if ($args->{-title}){
			# Indent left of title: -height should come from font metrics of TITLE_FONT_TOP;
			# 	and what about if the line wraps?
			$title_frame->Frame(qw/-background white -width 30 -height 30/)->pack(qw/-anchor n -side left/);
			$title_frame->Label(
				-justify => 'left', -anchor=> 'w', -wraplength=>$wrap,
				-text=> $args->{-title},
				-font=>'TITLE_FONT_TOP', -background=>"white",
			)->pack(-side=>'top',-expand=>'1',-fill=>'x',-pady=>5,-padx=>5);
		}
		if ($args->{-subtitle}){
			# Indent the subtitle - see note above
			$title_frame->Frame(qw/-background white -width 20 -height 12/)->pack(qw/-anchor w -side left/);
			$args->{-subtitle} =~ s/^[\n\r\f]//;
			$args->{-subtitle} = $args->{-subtitle};
			$title_frame->Label(
				-font => 'SUBTITLE_FONT',
				-justify => 'left',
				-anchor=> 'w',
				-wraplength=>$wrap, qw/-justify left/, -text => $args->{-subtitle},
				-background=>$args->{background}||"white",
			)->pack(-side=>'top',-expand=>'1',-fill=>'x',-padx=>5,);
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
		if ($args->{-text}){
			$args->{-text} =~ s/^[\n\r\f]//;
			$args->{-text} = "\n".$args->{-text};
			$_ = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',  -anchor=> 'n',
				-wraplength => $wrap + 100,
				-justify => "left", -text => $args->{-text}
			)->pack(-side=>'top',-expand=>'1',-fill=>'x',-padx=>10);
			$_->configure(-background => $main_bg) if $main_bg ;
		}
	}

	else {
		if ($args->{-title}){
			$_ = $frame->Label(
				-justify => 'left', -anchor=> 'w',
				-wraplength=>$wrap, -text=>$args->{-title}, -font=>'TITLE_FONT',
			)->pack(-side=>'top',-expand=>1,-fill=>'x');
			$_->configure(-background=>$main_bg) if $main_bg;
		}
		if ($args->{-subtitle}){
			$args->{-subtitle} =~ s/^[\n\r\f]//;
			$args->{-subtitle} = "\n".$args->{-subtitle};
			$_ = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',
				-anchor=> 'w',
				-wraplength=>$wrap, qw/-justify left/, -text => $args->{-subtitle},
			)->pack(-side=>'top',-expand=>'1',-fill=>'x');
			$_->configure(-background=>$main_bg) if $main_bg;
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
		if ($args->{-text}){
			$args->{-text} =~ s/^[\n\r\f]//;
			$args->{-text} = "\n".$args->{-text};
			$_ = $frame->Label(
				-font => $args->{-font},
				-justify => 'left',
				-anchor=> 'w',
				-wraplength=>$wrap, qw/-justify left/, -text => $args->{-text},
			)->pack(-side=>'top',-expand=>'1',-fill=>'x');
			$_->configure(-background=>$main_bg) if $main_bg;
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
	}

	return $frame->pack(qw/-side top -fill x -padx 0/);
} # end blank_frame


=head2 METHOD addLicencePage

	$wizard->addLicencePage ( -filepath => $path_to_licence_text )

Adds a page that contains a scroll texxt box of a licence text file
specifed in the C<-filepath> argument. Presents the user with two
options, accept and continue, or not accept and quit. The user
I<cannot> progress until the 'agree' option has been chosen. The
choice is entered into the object field C<licence_agree>, which you
can test as the I<Next> button is pressed, either using your own
function or with the Wizard's C<callback_licence_agreement> function.

You could supply the GNU Artistic Licence....

See L<CALLBACK callback_licence_agreement> and L<METHOD page_licence_agreement>.

=cut

sub addLicencePage { my ($self,$args) = (shift, {@_});
	die "No -filepath argument present" if not $args->{-filepath};
	$self->addPage( sub { $self->page_licence_agreement($args->{-filepath} )  } );
}


=head2 METHOD addDirSelectPage

	$wizard->addDirSelectPage ( -variable => \$chosen_dir )

Adds a page that contains a scroll texxt box of all directories
including, on Win32, logical drives.  You can also specify the
C<-title>, C<-subtitle> and C<-text> paramters, as in L<METHOD blank_frame>.

See L<CALLBACK callback_dirSelect>.

=cut

sub addDirSelectPage { my ($self,$args) = (shift,{@_});
	$self->addPage( sub { $self->page_dirSelect($args)  } );
}





#
# Method:       dispatch
#
# Description:  Thin wrapper to dispatch event cycles as needed
#
# Parameters:    The dispatch function is an internal function used to determine if the dispatch back reference
#         is undefined or if it should be dispatched. Undefined methods are used to denote dispatchback
#         methods to bypass. This reduces the number of method dispatchs made for each handler and also
#         increased the usability of the set methods above when trying to unregister event handlers.
#

sub dispatch { my $handler = shift;
   return (!($handler->())) if defined $handler;
   return 0;
} # end of sub dispatch



#
# Method:      NextButtonEventCycle
#
# Description: Runs the complete view of the action handler cycle for the "Next>" button on the
#              wizard button bar. This includes dispatching the preNextButtonAction and
#              postNextButtonAction handler at the apporprate times.
#

sub NextButtonEventCycle { my $self = shift;
	if( dispatch( $self->{-preNextButtonAction})) { return;}

	# advance the wizard page pointer and then adjust the navigation buttons.
	# readraw the frame when finished to get changes to take effect.
	$self->{wizardPagePtr}++;
	$self->{wizardPagePtr} = $#{$self->{wizardPageList}} if( $self->{wizardPagePtr} >= $#{ $self->{wizardPageList}});

	$self->{backButton}->configure( -state => "normal");
	if( $self->{nextButton}->cget( -text) eq $LABELS{FINISH}) {
		if( dispatch( $self->{-finishButtonAction})) { return; }
		$self->CloseWindowEventCycle();
	}
	$self->{nextButton}->configure( -text => $LABELS{FINISH}) if( $self->{wizardPagePtr} == $#{ $self->{wizardPageList}});
	$self->redrawWizardPage;

	if( dispatch( $self->{-postNextButtonAction})) { return; }
} # end of sub NextButtonEventCycle




#
# Method:      BackButtonEventCycle
#
# Description: Runs the complete view of the action handler cycle for the "<Previous" button on the
#              wizard button bar. This includes dispatching the preBackButtonAction and
#              postBackButtonAction handler at the apporprate times.
#
# Parameters:    None
#

sub BackButtonEventCycle { my $self=shift;
	return if dispatch( $self->{-preBackButtonAction});

	# move the wizard pointer back one position and then adjust the navigation buttons
	# to reflect any state changes. Don't fall off end of page pointer
	$self->{wizardPagePtr}--;
	$self->{wizardPagePtr} = 0 if( $self->{wizardPagePtr} < 0);

	$self->{nextButton}->configure( -text => $LABELS{NEXT});
	$self->{backButton}->configure( -state => "disabled") if( $self->{wizardPagePtr} == 0);
	$self->redrawWizardPage;

	if( dispatch( $self->{-postBackButtonAction})) { return; }
} # end of sub BackButtonEventCycle



#
# Method:      HelpButtonEventCycle
#
# Description: This generates all of the events required when the Help button is clicked. This runs
#              through the pre event handler, the event handler and then the post event handler. If
#              no event handlers are defined, the method does nothing.
#
# Parameters:    None
#

sub HelpButtonEventCycle { my $self = shift;
	if (dispatch( $self->{-preHelpButtonAction})) { return; }
	if (dispatch( $self->{-helpButtonAction})) { return; }
	if (dispatch( $self->{-postHelpButtonAction})) { return; }
} # end of sub HelpButtonEventCycle



#
# Method:      CancelButtonEventCycle
#
# Description: This generates all of the necessary events reqruied for a good Wizard control when
#              the cancel button is clicked. This involves dispatching the preCancelButtonAction handler
#              and then activating the CloseWindowEventCycle to run through the process of closing
#              the window.
#
# Parameters:    None
#
sub CancelButtonEventCycle { my ($self, $hGUI) = (shift, @_);
  return if dispatch( $self->{-preCancelButtonAction});
  $self->CloseWindowEventCycle( $hGUI);
}


#
# Method:      CloseWindowEventCycle
#
# Description: This generates all of the necessary events required for a good Wizard control when
#              the Window is about to be closed. This involves dispatching the preCloseWindowAction handler
#              and then destroying the reference to the Window control.
#
sub CloseWindowEventCycle { my ($self, $hGUI) = (shift,@_);
	return if dispatch( $self->{-preCloseWindowAction});
	$hGUI->destroy;
}


#
# Method:      redrawWizardPage
#
# Description: Update the wizard page panel by unpacking the existing controls and then repacking.
#              This allows updates to the page pointer to become visible.
#
sub redrawWizardPage { my $self = shift;
	# For 'top' style: change page format after page 1
	if (($self->{-style} eq 'top' and $self->{wizardPagePtr} == 0)
		or $self->{wizardPagePtr} == $#{$self->{wizardPageList}}
	){
		$self->{left_object}->pack( -side => "left", -anchor => "w");
	} elsif ($self->{-style} eq 'top'){
		$self->{left_object}->packForget;
	}
	if ($self->{wizardPagePtr}==0 or $self->{wizardPagePtr}==$#{$self->{wizardPageList}}){
		$self->{wizwin}->configure(-background=>$self->{-background}||"white");
	} else {
		$self->{wizwin}->configure(-background=>$self->{-background}||"SystemButtonFace");
	}
	$self->{wizardFrame}->packForget;
	$self->{wizardFrame} = $self->{wizardPageList}->[$self->{wizardPagePtr}]->();
	if ($self->{-style} ne 'top'  and $self->{wizardPagePtr} > 0){
		$self->{wizardFrame}->pack( -side=>"top", -expand=>0, -padx=>10, -pady=>2 );
	} else {
		$self->{wizardFrame}->pack( -side => "top");
	}
}


#
# PRIVATE METHOD page_licence_agreement
#
#	my $COPYRIGHT_PAGE = $wizard->addPage( sub{ Tk::Wizard::page_licence_agreement ($wizard,$LICENCE_FILE)} );
#
# Accepts a C<TK::Wizard> object and the path to a text file
# containing the licence.
#
# Returns a C<Tk::Wizard> page entitled "End-user Licence Agreement",
# a scroll-box of the licence text, and an "Agree" and "Disagree"
# option. If the user agrees, the caller's package's global (yuck)
# C<$LICENCE_AGREE> is set to a Boolean true value.
#
# If the licence file cannot be read, this routine will call C<die $!>.
#
# See also L<CALLBACK callback_licence_agreement>.
#
sub page_licence_agreement { my ($self,$licence_file) = (shift,shift);
	local *IN;
	my $text;
	my $padx = $self->{-style} eq 'top'? 30 : 5;
	$self->{licence_agree} = undef;
	open IN,$licence_file or croak "Could not read licence: $licence_file; $!";
	read IN,$text,-s IN;
	close IN;
	my ($frame,@pl) = $self->blank_frame(
		-title	 =>"End-user Licence Agreement",
		-subtitle=>"Please read the following licence agreement carefully.",
		-text	 =>"\n"
	);
	my $t = $frame->Scrolled(
		qw/Text -relief sunken -borderwidth 2 -font SMALL_FONT -width 10 -setgrid true
		-height 9 -scrollbars e -wrap word/
	);
	$t->insert('0.0', $text);
	$t->configure(-state => "disabled");
	$t->pack(qw/-expand 1 -fill both -padx 10 /);
	$frame->Frame(-height=>10)->pack();
	$_ = $frame->Radiobutton(
		-font => $self->{defaultFont},
		-text     => $LABELS{LICENCE_OPTION_YES},
		-variable => \${$self->{licence_agree}},
		-relief   => 'flat',
		-value    => 1,
		-underline => '2',
		-anchor	=> 'w',
	)->pack(-padx=>$padx, -anchor=>'w',);
	$_->configure(-background=>$self->{-background}) if $self->{-background};
	$frame->Radiobutton(
		-font => $self->{defaultFont},
		-text     => $LABELS{LICENCE_OPTION_NO},
		-variable => \${$self->{licence_agree}},
		-relief   => 'flat',
		-value    => 0,
		-underline => 5,
		-anchor	=> 'w',
    )->pack(-padx=>$padx, -anchor=>'w',);
	$_->configure(-background=>$self->{-background}) if $self->{-background};
	return $frame;
}

=head2 CALLBACK callback_licence_agreement

Intended to be used with an action-event handler like C<-preNextButtonAction>,
this routine check that the object field C<licence_agree>
is a Boolean true value. If that operand is not set, it warns
the user to read the licence; if that operand is set to a
Boolean false value, a message box says goodbye and quits the
program.

=cut

sub callback_licence_agreement { my $self = shift;
	if (not defined ${$self->{licence_agree}}){
		my $button = $self->parent->messageBox('-icon'=>'info',-type=>'ok',
		-title => $LABELS{LICENCE_ALERT_TITLE},
		-message => $LABELS{LICENCE_IGNORED});
		return 0;
	}
	elsif (not ${$self->{licence_agree}}){
		my $button = $self->parent->messageBox('-icon'=>'warning', -type=>'ok',-title=>$LABELS{LICENCE_ALERT_TITLE},
		-message => $LABELS{LICENCE_DISAGREED});
		exit;
	}
	return 1;
}

#
# PRIVATE METHOD page_dirSelect
#
# -title    => Page title.
# -text     => Standfirst text.
# -variable => Reference to a variable to set.
#
sub page_dirSelect { my ($self,$args) = (shift,shift);
	my ($frame,@pl) = $self->blank_frame(
		-title => $args->{-title} || "Please choose a directory",
		-subtitle => $args->{-text}  || "After you have made your choice, press Next to continue.",
	);
	$frame->Frame(-height=>10)->pack();
	my $entry	= $frame->Entry(
		-justify		=> 'left',
		-width			=> 40,
		-textvariable	=>$args->{-variable},
	)->pack(-side=>'top',-anchor=>'w',-fill=>"x", -padx=>10, -pady=>10,);
	$entry->configure(-background=>$self->{-background}) if $self->{-background};
	my $dirs	= $frame->Scrolled ( "DirTree",
		-scrollbars => 'osoe',
		-selectbackground => "navy", -selectforeground => "white",-selectmode =>'browse',
		-width=>40, height=>10,
		-browsecmd => sub { ${$args->{-variable}}=shift },
	)->pack(-fill=>"x",-padx=>10, -pady=>0,);
	$dirs->configure(-background=>$self->{-background}) if $self->{-background};
	$frame->Frame(-height=>10)->pack();

	my $mkdir = $frame->Button( -text => "New Directory",
		-command => sub {
			my $new_name = $self->prompt(-title=>'Create New Directory',-text=>"Please enter the name for the new directory");
			if ($new_name){
				$new_name =~ s/[\/\\]//g;
				$new_name = ${$args->{-variable}} ."/$new_name";
				if (! mkdir $new_name,0777){
					if ($! =~ /Invalid argument/i){
						$_ = "The directory name you supplied is not valid.";
					} elsif ($! =~ /File Exists/i){
						$_ = "A directory with that name already exists.";
					} else {
						$_ = "The directory could not be created:\n\n\t'$!'"
					}
					$self->parent->messageBox(
						'-icon' => 'error', -type => 'ok',-title => 'Could Not Create Directory',
						-message => $_,
					);
				} else {
					${$args->{-variable}} = $new_name;
					$dirs->configure(-directory => $new_name);
					$dirs->chdir($new_name);
				}
			}
		},
	)->pack( -side => 'right', -anchor => 'w', -padx=>'10', );

	$frame->Button( -text => "Desktop",
		command => sub {
			${$args->{-variable}} = "$ENV{USERPROFILE}/Desktop";
			$dirs->configure(-directory => "$ENV{USERPROFILE}/Desktop");
			$dirs->chdir("$ENV{USERPROFILE}/Desktop");
		},
	)->pack( -side => 'right', -anchor => 'w', -padx=>'10', );

	foreach (&_drives){
		($_) = /^(\w+:)/;
		$dirs->configure(-directory=>$_);
	}
	return $frame;
}

=head2 CALLBACK callback_dirSelect

A callback to check that the directory, passed as a reference in the sole
argument, exists, and can and should be created.

Will not allow the Wizard to continue unless a directory has been chosen.
If the chosen directory does not exist, Setup will ask if it should create
it. If the user affirms, it is created; otherwise the user is again asked to
chose a directory.

Returns a Boolean value.

This method relies on C<Win32API::File> on MS Win32 machines only.

=cut

sub callback_dirSelect { my ($self,$var) = (shift,shift);
	if (not $$var){
		$self->parent->messageBox(
			'-icon' => 'info', -type => 'ok',-title => 'Form Incomplete',
			-message => "Please select a directory to continue."
		);
	}
	elsif (!-d $$var){
		$$var =~ s|[\\]+|/|g;
		$$var =~ s|/$||g;
		my $button = $self->parent->messageBox(
			-icon => 'info', -type => 'yesno',
			-title => 'Directory does not exist',
			-message => "The directory you selected does not exist.\n\n"."Shall I create ".$$var." ?"
		);
		if ($button eq 'yes'){
			eval ('use File::Path');
			return 1 if File::Path::mkpath $$var;
			$self->parent->messageBox(
				-icon => 'warning', -type => 'ok',
				-title => 'Directory Could Not Be Created',
				-message => "The directory you entered could not be created.\n\nPlease enter a different directory and press Next to continue."
			);
		} else {
			$self->parent->messageBox(
				-icon => 'info', -type => 'ok',
				-title => 'Directory Required',
				-message => "Please select a directory so that Setup can install the software on your machine.",
			);
		}
	} else {
		return 1;
	}
	return 0;
}

sub _drives {
	return '/' if $^O ne 'MSWin32';
	eval('require Win32API::File');
	return Win32API::File::getLogicalDrives();
}


=head2 DIALOGUE METHOD DIALOGUE_really_quit

The default routine called when the user clicks I<Cancel> or attempts
to close the window (C<-preCancelButtonAction> and C<-preCloseWindowAction>).
Justs asks 'Are you sure?' Calls C<exit> if they are.

=cut

sub DIALOGUE_really_quit { my $self = shift;
	return 0 if $self->{nextButton}->cget(-text) eq $LABELS{FINISH};
	my $button = $self->parent->messageBox('-icon' => 'question', -type => 'yesno',
	-default => 'no', -title => 'Quit Setup?',
	-message => "Setup has not finished installing.\n\nIf you quit now, you will not be able to run the software.\n\nDo you really wish to quit?");
	exit if $button eq 'yes';
	return 0;
}


=head2 DIALOGUE METHOD prompt

Equivalent to the JavaScript method of the same name: pops up
a dialogue box to get a text string, and returns it.  Arguemnts
are:

=over 4

=item -parent =>

C<Tk> object that is our parent window. Default's to our C<parent> field.

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

sub prompt { my ($self,$args) = (shift,{@_});
	eval ('use Tk::DialogBox');
	my ($d, $w);
	my $input = $self->{-value};
	$args->{-parent} = $self->parent if not $args->{-parent};
	$d = $args->{-parent}->DialogBox(-title => $args->{-title}||"Prompt",
		-buttons => [$LABELS{CANCEL},"OK"],-default_button=>'OK',
	);
	if ($args->{-text}){
		$w = $d->add("Label",
			-font => $self->{defaultFont},
			-text => $args->{-text},
			-width=>40, -wraplength => $args->{-wraplength}||275,
			-justify => 'left', -anchor=>'w',
		)->pack();
	}
	$w = $d->add("Entry",
		-font => $self->{defaultFont}, -relief=>"sunken",
		-width => $args->{-width}||40,
		-background => "white",
		-justify => 'left',
		-textvariable => \$input,
	);
	$w->pack(-padx=>2,-pady=>2);
	$d->Show;
	return $input? $input : undef;
}




=head2 METHOD register_with_windows

Registers an application with Windows so that it can be Uninstalled
using the I<Add/Remove Programs> dialogue.

An entry is created in the Windows' registry pointing to the
uninstall script path. See C<uninstall_string>, below.

Returns C<undef> on failure, C<1> on success.

Aguments are:

=over 4

=item display_name =>

The string displayed in bold in the Add/Remove Programs dialogue.

=item display_version =>

Optional: the version number displayed in the Add/Remove Programs dialogue.

=item uninstall_key_name

The name of the registery sub-key to be used.

=item uninstall_string

The command-line to execute to uninstall the script.

According to L<Microsoft|http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dnwue/html/ch11d.asp>:

	You must supply complete names for both the DisplayName and UninstallString
	values for your uninstall program to appear in the Add/Remove Programs
	utility. The path you supply to Uninstall-String must be the complete
	command line used to carry out your uninstall program. The command line you
	supply should carry out the uninstall program directly rather than from a
	batch file or subprocess.

The default value is:

	perl -e '$args->{app_path} -u'

This default assumes you have set the argument C<app_path>, and that it
checks and reacts to the the command line switch C<-u>:

	package MyInstaller;
	use strict;
	use Tk::Wizard;
	if ($ARGV[0] =~ /^-*u$/i){
		# ... Have been passed the uninstall switch: uninstall myself now ...
	}
	# ...

Or something like that.

=back

B<Note:> this method uses C<eval> to require C<Win32::TieRegistry>.

This method returns C<1> and does nothing on non-MSWin32 platforms.

=cut

sub register_with_windows { my ($self,$args) = (shift,{@_});
	return 1 if $^O ne 'MSWin32';
	unless ($args->{display_name} and $args->{uninstall_string}
		and ($args->{uninstall_key_name} or $args->{app_path})
	){
		die __PACKAGE__."::register_with_windows requires an argument of name/value pairs which must include the keys 'uninstall_string', 'uninstall_key_name' and 'display_name'";
	}

	if (not $args->{uninstall_string} and not $args->{app_path}){
		die __PACKAGE__."::register_with_windows requires either argument 'app_path' or 'uninstall_string' be set.";
	}
	if ($args->{app_path}){
		$args->{app_path} = "perl -e '$args->{app_path} -u'";
	}
	my $Registry;
	eval('use Win32::TieRegistry( Delimiter=>"/", ArrayValues=>0 );');
	my $uninst_key_ref =
	$Registry->{'LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/'} ->
		CreateKey( $args->{uninstall_key_name} );
	die "Perl Win32::TieRegistry error" if !$uninst_key_ref;
	$uninst_key_ref->{"/DisplayName"} = $args->{display_name};
	if ($args->{display_version}){
		$uninst_key_ref->{"/DisplayVersion"} = $args->{display_version};  # $VERSION;
	}
	$uninst_key_ref->{"/UninstallString"} = $args->{uninstall_string};
	return $!? undef : 1;
}


1;
__END__

=head1 ACTION EVENT HANDLERS

A Wizard is a series of pages that gather information and perform tasks based upon
that information. Navigated through the pages is via I<Back> and I<Next> buttons,
as well as I<Help>, I<Cancel> and I<Finish> buttons.

In the C<Tk::Wizard> implimentation, each button has associated with it one or more
action event handlers, supplied as code-references executed before, during and/or
after the button press.

The handler code should return a Boolean value, signifying whether the remainder of
the action should continue. If a false value is returned, execution of the event
handler halts.

=over 4

=item -preNextButtonAction =>

This is a reference to a function that will be dispatched before the Next
button is processed.

=item -postNextButtonAction =>

This is a reference to a function that will be dispatched after the Next
button is processed.

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

=item -postHelpButtonAction =>

This is a reference to a function that will be dispatched after the Help
button is processed.

=item -finishButtonAction =>

This is a reference to a funciton that will be dispatched to handle the Finish
button action.

=item -postFinishButtonAction =>

This is a reference to a function that will be dispatched after the Finish
button is processed.

=item -preCancelButtonAction =>

This is a reference to a function that will be dispatched before the Cancel
button is processed.  Default is to exit on user confirmation - see
L<METHOD DIALOGUE_really_quit>.

=item -preCloseWindowAction =>

This is a reference to a funciton that will be dispatched before the window
is issued a close command. Default is to exit on user confirmation - see
L<DIALOGUE METHOD DIALOGUE_really_quit>.

=back

All active event handlers can be set at construction or using C<configure> -
see L<CONSTRUCTOR (new)> and L<METHOD configure>.

=head1 BUTTONS

	backButton nextButton helpButton cancelButton

If you must, you can access the Wizard's button through the object fields listed
above, each of which represents a C<Tk::BUtton> object.

This is not advised for anything other than disabling or re-enabling the display
status of the buttons, as the C<-command> switch is used by the Wizard:

	$wizard->{backButton}->configure( -state => "disabled" )

Note: the I<Finish> button is simply the C<nextButton> with the label C<$LABEL{FINISH}>.

See also L<INTERNATIONALISATION>.

=head1 INTERNATIONALISATION

The labels of the buttons can be changed (perhaps into a language other an English)
by changing the values of the package-global C<%LABELS> hash, where keys are
C<BACK>, C<NEXT>, C<CANCEL>, C<HELP>, and C<FINISH>.

The text of the licence agreement page and callbacks can also be changed via the
C<%LABELS> hash: see the top of the source code for details.

=head1 CAVEATS / BUGS / TODO

=over 4

=item *

In Windows, with the system font set to > 96 dpi (via Display Properties / Settings
/ Advanced / General / Display / Font Size), the Wizard will not display propertly.
This seems to be a Tk feature.

=item *

Not much of a Tk widget inheritance - any pointers welcome.

=item *

Nothing is currently done to ensure text fits into the window - it is currently up to
the client to make frames C<Scrolled>), as I'm having problems making C<&blank_frame>
produce them.

=item *

When The I<New Directory> button in the C<addDirSelectPage> method is used
to create a new directory, the C<DirTree> object does open the branch.
but does not show it as selected - how can it?

=cut

=head1 CHANGES

=head2 VERSION 1.021

=over 4

=item *

More minor display tweeks.

=item *

Added internationalisation of button labels.

=back

=head2 VERSION 1.02

=over 4

=item *

All known display issues fixed.

=item *

Warnings about stupid things if run undef C<-w>.

=item *

Directory selection method cleaned, fixed and extended.

=item *

C<-style=>top> implimented.

=item *

Windows "uninstall" feature: thanks to James Tillman and Paul Barker for info.

=cut

=head2 VERSION 1.01

=over 4

=item *

Added method C<blank_frame> that can take title and standfirst text.

=item *

Added licence agreement bits.

=item *

Modified spacing, added default font and background;
changed C<filename> field to C<-imagepath> for readability;
made all arguments begin with C<-> to fit in with Tk "switches";
made the supply of a C<MainWindow> to the constructor optional, and
changed the supply method from a reference to part of the passed name/value list.

=back

=head2 VERSION 1.0

Initial version by Daniel T Hable, found with Google, at
L<http://perlmonks.thepen.com/139336.html|http://perlmonks.thepen.com/139336.html>.

=head1 AUTHOR

Daniel T Hable,

Lee Goddard (lgoddard@cpan.org).

=head1 KEYWORDS

Wizard; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 COPYRIGHT

Copyright (c) 2002 Daniel T Hable.

Modifications Copyright (C) Lee Goddard, 2002.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of
the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
