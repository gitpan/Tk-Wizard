package Tk::Wizard;
use vars qw/$VERSION/;
$VERSION = 1.03;	# 28/11/2002 15:36

BEGIN {
	use Carp;
	use Tk;
	use Tk::DirTree;
	require Exporter;			# Exporting Tk's MainLoop so that
	@ISA = "Exporter";			# I can just use strict and Tk::Wizard without
	@EXPORT = ("MainLoop");		# having to use Tk
}

use strict;
use base  qw(Tk::MainWindow);
Tk::Widget->Construct('WizardTest');

# See INTERNATIONALISATION
my %LABELS = (
	# Buttons
	BACK => "< Back",	NEXT => "Next >",
	FINISH => "Finish",	CANCEL => "Cancel",
	HELP => "Help", OK => "OK",
	# licence agreement
	LICENCE_ALERT_TITLE	=> "Licence Condition",
	LICENCE_OPTION_NO	=> "I do not accept the terms of the licence agreement",
	LICENCE_OPTION_YES	=> "I accept the terms the terms of the licence agreement",
	LICENCE_IGNORED		=> "You must read and agree to the licence before you can use this software.\n\nIf you do not agree to the terms of the licence, you must remove the software from your machine.",
	LICENCE_DISAGREED	=> "You must read and agree to the licence before you can use this software.\n\nAs you indicated that you do not agree to the terms of the licence, please remove the software from your machine.\n\nSetup will now exit.",
);

=head1 NAME

Tk::Wizard - GUI for step-by-step logical process

=head1 SYNOPSIS

	use Tk::Wizard;
	my $wizard = new Tk::Wizard(
		-title		=> "TitleBar Title",
		-imagepath	=> "/image/for/the/left/panel.gif",
	);
	$wizard->configure( ...add event handlers... );
	$wizard->cget( ...whatever... );
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

C<Tk> and modules of the current standard Perl Tk distribution.

On MS Win32 only: C<Win32API::File>.

And if you plan to use the method C<register_with_windows> (available on MsWin32 only),
you'll need C<Win32::TieRegistry>.

=head1 DESCRIPTION

The C<Tk::Wizard> module automates a large part of the creation of a wizard program
to collect information and then perform some complex task based upon it.

The Wizard was developed to aid software installation by end-users using ActiveState's
ActivePerl, but should function under other OS and circumstances. There package does
contain a number of routines specific to software installation: these may be removed to
a sub-class at a later date.

The wizard feel is largly based upon the Microsoft(TM,etc) wizard style: the default is
simillar to that found in Microsoft Windows 95; a more Windows 2000-like feel is also
supported (see the C<-style> entry in L<WIDGET-SPECIFIC OPTIONS>.

B<THIS IS AN ALPHA RELEASE: ALL CONTRIBUTIONS ARE WELCOME!>

=head1 STANDARD OPTIONS

    -title -background -width -height

See the Tk::options manpage for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:   style

=item Class:  ""

=item Switch: -style

Sets the display style of the Wizard.

The default C<95> value creates a traditional, Windows 95-style wizard,
with every page being C<SystemButtonFace> coloured, with a large image on the
left (C<-imagepath>, below).

A value of C<top>, the Wizard will be more of a Windows 2000-like affair,
with the initial page being a white-backgrounded version of the traditional style,
and subsequent pages being C<SystemButtonFace> coloured, with a white
strip at the top holding a title and subtitle, and a smaller image (C<-topimagepath>,
below>.

=item Name:   imagepath

=item Class:  ""

=item Switch: -imagepath

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

=item Name:   topimagepath

=item Class:  ""

=item Switch: -topimagepath

Only required if C<-style=>'top'> (as above): the image this filepath specifies
will be displayed in the top-right corner of the screen. Dimensions are not
restrained (yet), but only 50px x 50px has been tested.

Please see notes the C<-imagepath> entry, above.

=item Name:   nohelpbutton

=item Class:  ""

=item Switch: nohelpbutton

Set to anything to disable the display of the I<Help> buton.

=back

Please see also L<ACTION EVENT HANDLERS>.

=cut

sub Populate {
    my ($cw, $args) = @_;
	# the delete above ensures that new() does not try
	# and do  $cw->configure(-flag => xxx);

    $cw->SUPER::Populate($args);

#	$w = $cw->Component(...);

#	$cw->Delegates(...);

    $cw->ConfigSpecs(
# ?		-title			=> ['SELF','title','Title','Generic Wizard'],
		-command    	=> ['CALLBACK', undef, undef, undef ],
#		-foreground 	=> ['PASSIVE', 'foreground','Foreground', 'black'],
		-background 	=> ['METHOD', 'background','Background', $^O eq 'MSWin32'? 'SystemButtonFace':'gray'],
		-style			=> ['PASSIVE',"style","Style","95"],
		-imagepath		=> ['PASSIVE','topimagepath', 'Imagepath', undef],
		-topimagepath	=> ['PASSIVE','topimagepath', 'Topimagepath', undef],
		# event handling references
		-preNextButtonAction    => ['PASSIVE',undef,undef,undef],
		-postNextButtonAction   => ['PASSIVE',undef,undef,undef],
		-preBackButtonAction    => ['PASSIVE',undef,undef,undef],
		-postBackButtonAction   => ['PASSIVE',undef,undef,undef],
		-preHelpButtonAction    => ['PASSIVE',undef,undef,undef],
		-helpButtonAction       => ['PASSIVE',undef,undef,undef],
		-postHelpButtonAction   => ['PASSIVE',undef,undef,undef],
		-finishButtonAction     => ['PASSIVE',undef,undef,undef],
		-preCancelButtonAction 	=> ['CALLBACK',undef, undef, sub { &DIALOGUE_really_quit($cw) }],
		-preCloseWindowAction	=> ['CALLBACK',undef, undef, sub { &DIALOGUE_really_quit($cw) }],
		# wizard page control list and pointer
	);

	$cw->{wizardPageList}	= [];
	$cw->{wizardPagePtr}	= 0;
	$cw->{wizardFrame}		= 0;
	$cw->{-imagepath}		= ""	|| $args->{-imagepath};
	$cw->{-topimagepath}	= "" 	|| $args->{-topimagepath};
	$cw->{-style}			= "95"	|| $args->{-style};
	$cw->{background_userchoice} = $args->{-background} || $cw->ConfigSpecs->{-background}[3];
	$cw->{background} = $cw->{background_userchoice};
	$args->{-title}  = "Generic Wizard" unless $args->{-title};
	$args->{-style} = $cw->{-style} unless $args->{-style};	# yuck
	$args->{-width } = ($args->{-style} eq 'top'? 500 : 570) unless $args->{-width};
	$args->{-height} = 370 unless $args->{-height};

	my $buttonPanel = $cw->Frame();
	$cw->{nextButton} = $buttonPanel->Button( -text => $LABELS{NEXT},
		-command => [ \&NextButtonEventCycle, $cw ],
		-width => 10
	)->pack( -side => "right", -expand => 0,-pady=>10);
	$cw->{backButton} = $buttonPanel->Button( -text => $LABELS{BACK},
		-command => [ \&BackButtonEventCycle, $cw ],
		-width => 10,
		-state => "disabled"
	)->pack( -side => "right", -expand => 0,-pady=>10);
	$cw->{cancelButton} = $buttonPanel->Button( -text => $LABELS{CANCEL},
		-command => [ \&CancelButtonEventCycle, $cw, $cw],
		-width => 10
	) ->pack( -side => "right", -expand => 0,-pady=>10);
	unless ($cw->cget(-nohelpbutton)){
		$cw->{helpButton} = $buttonPanel->Button( -text => $LABELS{HELP},
			-command => [ \&HelpButtonEventCycle, $cw ],
			-width => 10,
		)->pack( -side => 'left', -anchor => 'w',-pady=>10);
	}
	$buttonPanel->pack(qw/ -side bottom -fill x/);

	# Line above buttons
	$cw->Frame(
		-width => $cw->cget(-width)||500,
		-background=>$cw->cget(-background),
		qw/ -relief groove -bd 1 -height 2/,
	)->pack(qw/-side bottom -fill x/);

	# Font used for &blank_frame titles
	$cw->fontCreate(qw/TITLE_FONT -family verdana -size 12 -weight bold/);
	# Fonts used if -style=>"top"
	$cw->fontCreate(qw/TITLE_FONT_TOP -family verdana -size 8 -weight bold/);
	$cw->fontCreate(qw/SUBTITLE_FONT  -family verdana -size 8 /);
	# Font used in licence agreement
	$cw->fontCreate(qw/SMALL_FONT -family verdana -size 8 /);
	# Font used in all other places
	$cw->fontCreate(qw/DEFAULT_FONT -family verdana -size 8 /);
	$cw->{defaultFont} = 'DEFAULT_FONT';

	# setup the MainWindow to match the criteria for a wizard widget
	$cw->resizable( 0, 0);        # forbid resize
	$cw->withdraw;                # position in screen center
	$cw->Popup;
	$cw->transient;               # forbid minimize
	$cw->protocol( WM_DELETE_WINDOW => [ \&CloseWindowEventCycle, $cw, $cw]);
	$cw->packPropagate(0);
	$cw->configure(-background=>$cw->cget(-background));
}


sub background { my ($self,$operand)=(shift,shift);
	if (defined $operand){
#		warn "set bg to $operand";
		$self->{background} = $operand;
		return $operand;
	}
	elsif ($self->{wizardPagePtr}==0 or $self->{wizardPagePtr}==$#{$self->{wizardPageList}}){
#		warn "pages are such ($self->{wizardPagePtr}) that bg is set to white from $self->{background}";
		$self->{background} = 'white';
		return 'white';
	} else {
		$self->{background} = $self->{background_userchoice};
		return $self->{background};
	}
}

=head2 METHOD addPage

	$wizard->addPage ($page_code_ref1 ... $page_code_refN)

Adds a page to the wizard. The parameters must be references to code that
evaluate to C<Tk::Frame> objects, such as those returned by the methods C<blank_frame>,
C<addLicencePage> and C<addDirSelectPage>.

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
	if ($^W and $self->cget(-style) eq 'top' and not $self->cget(-topimagepath)){
		warn "Wizard has -style=>top but not -topimagepath is defined";
	}
	if ($^W and $#{$self->{wizardPageList}}==0){
		warn "Showing a Wizard that is only one page long";
	}

	# Wizard 98/95 style
	if ($self->cget(-style) eq '95' or $self->{wizardPagePtr}==0){
		if ($self->cget(-imagepath)){
			$self->Photo( "sidebanner",  -file => $self->cget(-imagepath));
			$self->{left_object} = $self->Label( -image => "sidebanner")->pack( -side => "left", -anchor => "w");
		} else {
			$self->{left_object} = $self->Frame(-width=>100)->pack(qw/-side left -anchor w -expand 1 -fill both/);
		}
	}

	# Wizard 2k style - builds the left side of the wizard
	else {
		if ($self->cget(-topimagepath)){
			$self->Photo( "sidebanner", -file => $self->cget(-topimagepath));
			$self->{left_object} = $self->Label( -image => "sidebanner")->pack( -side => "top", -anchor => "e", );
		} else {
			$self->{left_object} = $self->Frame( -width => 250 )->pack( -side => "top", -anchor => "n", -padx=>5, -pady=>2);
		}
	}

	# This populates the wizard page panel on the side of the screen.
	$self->{wizardFrame} =
	$self->{wizardPageList}->[$self->{wizardPagePtr}]->()->pack(qw/-side top -expand 0 -padx 20 -pady 2/);

	$self->redrawWizardPage;
} # end of sub Show



sub redrawWizardPage { my $self = shift;
	if (($self->cget(-style) eq 'top' and $self->{wizardPagePtr} == 0)
		or $self->{wizardPagePtr} == $#{$self->{wizardPageList}}
	){
		$self->{left_object}->pack( -side => "left", -anchor => "w");
	} elsif ($self->cget(-style) eq 'top'){
		$self->{left_object}->packForget;
	}
	$self->configure("-background"=>$self->cget("-background"));
	$self->{wizardFrame}->packForget;
	$self->{wizardFrame} = $self->{wizardPageList}->[$self->{wizardPagePtr}]->();
}



=head2 METHOD currentPage

	my $current_page = $wizard->currentPage()

This returns the index of the page currently being shown to the user.
Page are indexes start at 1, with the first page that is associated with
the wizard through the C<addPage> method.

See L<METHOD addPage>.

=cut

sub currentPage { my $self = shift;
	return ($self->{wizardPagePtr} + 1);
}

=head2 METHOD parent

	my $apps_main_window = $wizard->parent;

This returns a reference to the parent Tk widget that was used to create the wizard.
Returns a reference to the Wizard's C<MainWindow>.

=cut

sub parent { return shift }


=head2 METHOD blank_frame

	my $frame = C<wizard>->blank_frame(-title=>$title,-subtitle=>$sub,-text=>$standfirst);

Returns a C<Tk::Frame> object that is a child of the Wizard control, with some C<pack>ing
parameters applied - for more details, please see C<-style> entry elsewhere in this document.

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
		$main_bg = $self->cget("-background"); # was white
		$main_wi = $args->{-width} || 300;
	}
	# For 'top' style, main body is user choice (undef  by default)
	elsif ($self->cget(-style) eq 'top' and $self->{wizardPagePtr}>0){
		$main_bg = $self->cget("-background");# undef;
		$main_wi = $args->{-width} || 600
	}
	# For other styles (95 default), main body is userdefined or plain
	else {
		$main_bg = $args->{background} || $self->cget("-background");
		$main_wi = $args->{-width} || 300;
	}
	my $frame = $self->parent->Frame(
		-width=>$main_wi, -height=>$args->{-height}||300,
	);

	$frame->configure(-background => $main_bg) if $main_bg;

	$args->{-font} = $self->{defaultFont} unless $args->{-font};
	my $wrap = $args->{-wraplength} || 375;

	# For 'top' style pages other than first and last
	if (($self->cget(-style) eq 'top' and $self->{wizardPagePtr}>0)
	and $self->{wizardPagePtr} != $#{$self->{wizardPageList}}
	){
		my $top_frame = $frame->Frame(-background=>'white')->pack(-fill=>'x',-side=>'top',-anchor=>'e');
 		$_ = $top_frame->Frame(-background=>'white');
		$_->Photo( "topimage", -file => $self->cget(-topimagepath));
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
			)->pack(-anchor=>'n',-side=>'top',-expand=>1,-fill=>'x');
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
			)->pack(-anchor=>'n',-side=>'top',-expand=>'1',-fill=>'x');
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
			)->pack(-anchor=>'n',-side=>'top',-expand=>'1',-fill=>'x');
			$_->configure(-background=>$main_bg) if $main_bg;
		} else {
			$frame->Label(); # intended so we can packForget first to $frame->children;
		}
	}
	$frame->pack(qw/-side top -fill x -expand 1 -anchor n/);
#	$_ = $frame->Frame(-background=>"yellow")->pack(qw/-expand 1 -fill both/);
	return $frame;
} # end blank_frame


=head2 METHOD addLicencePage

	$wizard->addLicencePage ( -filepath => $path_to_licence_text )

Adds a page (C<Tk::Frame>) that contains a scroll texxt box of a licence text file
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

Adds a page (C<Tk::Frame>) that contains a scrollable texxt box of all directories
including, on Win32, logical drives.

Supply in C<-variable> a reference to a variable to set the initial directory,
and to have set with the chosen path.

Supply C<-nowarnings> to list only drives which are accessible, thus avoiding C<Tk::DirTree>
warnings on Win32 where removable drives have no media.

You may also specify the C<-title>, C<-subtitle> and C<-text> paramters, as in L<METHOD blank_frame>.

See L<CALLBACK callback_dirSelect>.

=cut

sub addDirSelectPage { my ($self,$args) = (shift,{@_});
	$self->addPage( sub { $self->page_dirSelect($args)  } );
}


#
# Method:       dispatch
# Description:  Thin wrapper to dispatch event cycles as needed
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
# Description: Runs the complete view of the action handler cycle for the "Next>" button on the
#              wizard button bar. This includes dispatching the preNextButtonAction and
#              postNextButtonAction handler at the apporprate times.
#
sub NextButtonEventCycle { my $self = shift;
	if( dispatch( $self->cget(-preNextButtonAction) )) { return;}
	# advance the wizard page pointer and then adjust the navigation buttons.
	# readraw the frame when finished to get changes to take effect.
	$self->{wizardPagePtr}++;
	$self->{wizardPagePtr} = $#{$self->{wizardPageList}} if( $self->{wizardPagePtr} >= $#{ $self->{wizardPageList}});
	$self->{backButton}->configure( -state => "normal");
	if( $self->{nextButton}->cget( -text) eq $LABELS{FINISH}) {
		if( dispatch( $self->cget(-finishButtonAction))) { return; }
		$self->CloseWindowEventCycle();
	}
	$self->{nextButton}->configure( -text => $LABELS{FINISH}) if( $self->{wizardPagePtr} == $#{ $self->{wizardPageList}});
	$self->redrawWizardPage;
	if( dispatch( $self->cget(-postNextButtonAction))) { return; }
}

sub BackButtonEventCycle { my $self=shift;
	return if dispatch( $self->cget(-preBackButtonAction));
	# move the wizard pointer back one position and then adjust the navigation buttons
	# to reflect any state changes. Don't fall off end of page pointer
	$self->{wizardPagePtr}--;
	$self->{wizardPagePtr} = 0 if( $self->{wizardPagePtr} < 0);
	$self->{nextButton}->configure( -text => $LABELS{NEXT});
	$self->{backButton}->configure( -state => "disabled") if( $self->{wizardPagePtr} == 0);
	$self->redrawWizardPage;
	if( dispatch( $self->cget(-postBackButtonAction))) { return; }
}

sub HelpButtonEventCycle { my $self = shift;
	if (dispatch( $self->cget(-preHelpButtonAction))) { return; }
	if (dispatch( $self->cget(-helpButtonAction))) { return; }
	if (dispatch( $self->cget(-postHelpButtonAction))) { return; }
}


sub CancelButtonEventCycle { my ($self, $args) = (shift, @_);
	return if $self->Callback( -preCancelButtonAction => $self->{-preCancelButtonAction} );
	$self->CloseWindowEventCycle( $args);
}


sub CloseWindowEventCycle { my ($self, $hGUI) = (shift,@_);
	return if $self->Callback( -preCloseWindowAction => $self->{-preCloseWindowAction} );
	$self->destroy;
#	return if dispatch( $self->cget(-preCloseWindowAction));
#	$hGUI->destroy;
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
	my $padx = $self->cget(-style) eq 'top'? 30 : 5;
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
		-background=>$self->cget("-background"),
	)->pack(-padx=>$padx, -anchor=>'w',);
	$frame->Radiobutton(
		-font => $self->{defaultFont},
		-text     => $LABELS{LICENCE_OPTION_NO},
		-variable => \${$self->{licence_agree}},
		-relief   => 'flat',
		-value    => 0,
		-underline => 5,
		-anchor	=> 'w',
		-background=>$self->cget("-background"),
    )->pack(-padx=>$padx, -anchor=>'w',);
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
# As blank_frame plus:
# -variable => Reference to a variable to set.
# -nowarnings => chdir to each drive first and only list if accessible
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
	$entry->configure(-background=>$self->cget("-background")) if $self->cget("-background");
	my $dirs	= $frame->Scrolled ( "DirTree",
		-scrollbars => 'osoe',
		-selectbackground => "navy", -selectforeground => "white",-selectmode =>'browse',
		-width=>40, height=>10,
		-browsecmd => sub { ${$args->{-variable}}=shift },
	)->pack(-fill=>"x",-padx=>10, -pady=>0,);
	$dirs->configure(-background=>$self->cget("-background")) if $self->cget("-background");
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
		}, # end of -command sub
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
		if ($args->{-nowarnings}){
			$dirs->configure(-directory=>$_) if chdir  $_
		} else {
			$dirs->configure(-directory=>$_)
		}
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

# Returns true if to continue
# By default, may be called by close window or pressing cancel
sub DIALOGUE_really_quit { my $self = shift;
	return 0 if $self->{nextButton}->cget(-text) eq $LABELS{FINISH};
	unless ($self->{really_quit}){
		my $button = $self->parent->messageBox('-icon' => 'question', -type => 'yesno',
		-default => 'no', -title => 'Quit Setup?',
		-message => "Setup has not finished installing.\n\nIf you quit now, you will not be able to run the software.\n\nDo you really wish to quit?");
		$self->{really_quit} = $button eq 'yes'? 1:0;
	}
	return !$self->{really_quit};
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
	my $input = $self->cget(-value);
	$args->{-parent} = $self->parent if not $args->{-parent};
	$d = $args->{-parent}->DialogBox(-title => $args->{-title}||"Prompt",
		-buttons => [$LABELS{CANCEL},$LABELS{OK}],-default_button=>$LABELS{OK},
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
see L<WIDGET-SPECIFIC OPTIONS> and L<METHOD configure>.

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

Still not much of a Tk widget inheritance - any pointers welcome.

=item *

Nothing is currently done to ensure text fits into the window - it is currently up to
the client to make frames C<Scrolled>), as I'm having problems making C<&blank_frame>
produce them.

=back

=head1 CHANGES

Please see the file F<CHANGES.txt> included with the distribution.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org) based on work Daniel T Hable.

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 COPYRIGHT

Copyright (c) Daniel T Hable, 2/2002.

Modifications Copyright (C) Lee Goddard, 11/2002 ff.

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
