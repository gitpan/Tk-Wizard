package Tk::Wizard;
use vars qw/$VERSION/;
$VERSION = 1.01;

use SelfLoader;
use Carp;
use Tk;
use Tk::Text;
use Tk::DirTree;
use Cwd;
use strict;
#no strict 'refs'; # ugh, wasn't me.

=head1 NAME

Tk::Wizard - Wizard GUI Framework

=head1 SYNOPSIS

	use Tk::Wizard;

	# Instantiate a Wizard
	my $wizard = new Tk::Wizard(
		-title => "A title",
		-imagepath => "/image/for/the/left/panel.gif",
	);

	# Create pages
	my $SPLASH       	= $wizard->addPage( sub{ page_splash ($wizard)} );
	my $COPYRIGHT_PAGE	= $wizard->addLicencePage( -filepath => "end_user_licence.txt" );
	my $GET_PREFS    	= $wizard->addPage( sub{ page_get_prefs($wizard) });
	my $user_chosen_dir;
	my $GET_DIR   		= $wizard->addDirSelectPage ( -variable => \$user_chosen_dir )
	my $INSTALL_FILES	= $wizard->addPage( sub{ page_install_files($wizard,$user_chosen_dir) });
	my $FINISH			= $wizard->addPage( sub{ page_finish($wizard) });

	$wizard->Show();
	MainLoop;

	sub page_get_prefs { my $wizard = shift;
		my $frame = $wizard->blank_frame(-title=>"The First Page",-text=>"This is page one...");
		# ....
		return $frame;
	}

	sub preNextButtonAction { my $wizard = shift;
		$_ = $wizard->currentPage;
		if (/^$SPLASH$/){
			warn "Pressed NEXT in the splash page ($SPLASH)";
			return 1;
		}
		elsif (/^$COPYRIGHT_PAGE$/){
			return $wizard->callback_licence_agreement;
		}
		elsif (/^$GET_DIR/){
			return $wizard->callback_dirSelect( \$user_chosen_dir );
		}
		# ...
	}

	__END__

=head1 DESCRIPTION

The C<Tk::Wizard> module automates a large part of the creation of a wizard program
to collect information and then perform some complex task based upon it. The wizard feel
is largly based upon the Microsoft(TM,etc) wizard style.

The Wizard was developed to aid software installation by end-users using ActiveState's
ActivePerl, but should function under under OS and circumstances. There are a number of
routines specific to software installation, which may be removed to a sub-class at a
later date.

THIS IS AN ALPHA RELEASE: ALL CONTRIBUTIONS ARE WELCOME!

=head1 ACTION EVENT HANDLERS

C<Tk::Wizard> action event handlers are code-references called at the press of a
C<Tk::Wizard> button.

The handler functions should return a Boolean value, signifying whether
the remainder of the action should continue. If a false value is returned, execution
of the event handler halts.

All active event handlers can be set at construction or using C<configure> -
see L<CONSTRUCTOR (new)> and L<METHOD configure>.

=over 4

=item -preNextButtonAction =>

This is a reference to a function that will be dispatched before the Next
button is processed.

=item -postNextButtonAction =>

This is a reference to a function that will be dispatched after the Next
button is processed.

=item -prePrevButtonAction =>

This is a reference to a function that will be dispatched before the Previous
button is processed.

=item -postPrevButtonAction =>

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

=item -preFinishButtonAction =>

This is a reference to a function that will be dispatched before the Finish
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

=head1 CONSTRUCTOR (new)

	Tk::Wizard->new( -name1=>"value1"...-nameN=>"valueN" )

Creates a new instance of the Tk::Wizard object as a C<MainWindow>, or
in the supplied C<MainWindow> (see below).

Standard paramters, appyling to the C<MainWindow>:

	-width -height -background

Non-standard parameters:

=over 4

=item -title =>

This is the title that will be displayed in the Windows title bar

=item -imagepath =>

Path to a JPEG file that will be displayed on the left-hand side of the screen.

=item -mw =>

Optionally a TK C<MainWindow> for the Wizard to occupy. If none is supplied,
one is created.

=item -style =>

If supplied and is C<top>, will put the image at the top. Could do more....

=item -nohelpbutton =>

Set to anything to disable the display of the help buton.

=item Action Event Handlers:

See L<ACTION EVENT HANDLERS> for details.

=back

All paramters can be set after construction using C<configure> - see
L<METHOD configure>.

As the C<Tk::Wizard> object also controls the I<Next> and I<Previous>
buttons, you can set the configuration - use the C<cancelButtonRef> and
C<prevButtonRef> object fields:

	$wizard->{prevButtonRef}->configure( -state => "disabled" )

The B<default font> is created by the constructor as 8pt Verdana,
named C<DEFAULT_FONT> and placed in the object's C<defaultFont> field.
All references to the default font in the Wizard call this routine, so
changing the default is easy.

Privately, C<licence_agree> flags whether the end-user licence agreement
has been accepted.

=cut

sub new($) {
   my $invocant = shift;
   my $class = ref( $invocant) || $invocant;
   my $self = {};
   $self = { # required for GUI operation
		# configuration parameters
		-title             => "Generic Wizard",

		# event handling references
		-preNextButtonAction    => undef,
		-postNextButtonAction    => undef,

		-prePrevButtonAction     => undef,
		-postPrevButtonAction    => undef,

		-preHelpButtonAction     => undef,
		-helpButtonAction        => undef,
		-postHelpButtonAction    => undef,

		-preFinishButtonAction   => undef,
		-finishButtonAction      => undef,
		-postFinishButtonAction  => undef,

		-preCancelButtonAction 	=> sub { &DIALOGUE_really_quit($self) },
		-preCloseWindowAction	=> sub { &DIALOGUE_really_quit($self), },

		# wizard page control list and pointer
		wizardPageList          => [],
		wizardPagePtr           => 0,

		# internally used to track the wizard page being shown
		wizardFrame         => 0,
	};
	my $args = {@_};
	foreach (keys %$args){
		$self->{$_} = $args->{$_}
	}
	unless ($self->{wizwin}){
		$self->{wizwin} = delete ($self->{mw})
		|| MainWindow->new(
			-background=>$self->{-background}||'white',
			-width=>$self->{-width}||600,
			-height=>$self->{-height}||500,
		);
	}
	bless $self, $class;
	# Font used for &blank_frame titles
	$self->{wizwin}->fontCreate(qw/TITLE_FONT -family verdana -size 12 -weight bold/); #
	# Font used in licence agreement
	$self->{wizwin}->fontCreate(qw/SMALL_FONT -family verdana -size 8 /); #
	# Font used in all other places
	$self->{wizwin}->fontCreate(qw/DEFAULT_FONT -family verdana -size 8 /); #
	$self->{defaultFont} = 'DEFAULT_FONT';
	return $self;
} # end of sub new


=head1 METHODS

=head2 METHOD configure

Allows the configuration of all object properties.
=cut

sub configure {
	my $self = shift;
	my %newHandlers = ( @_ );
	foreach( keys %newHandlers) {
		$self->{$_} = $newHandlers{$_};
	}
}


=head2 METHOD addPage

	$wizard->addPage ($page_code_ref)

This method is used to add a Wizard page to the wizard. The $page parameter must be a Tk::Frame object.
The pages are stored and will be displayed in the order that they were added to the Wizard control.

=cut

sub addPage { my ($self, @pages) = (shift,@_);
	push @{$self->{wizardPageList}}, @pages;
}


=head2 METHOD Show

	C<wizard>->Show()

This method must be dispatched before the Wizard will be displayed, and must
preced the C<MainLoop> call.

=cut

sub Show { my $self = shift;
	# builds the buttons on the bottom of thw wizard
	my $buttonPanel = $self->{wizwin}->Frame();
	$self->{nextButtonRef} = $buttonPanel->Button( -text => "Next >",
		-command => [ \&NextButtonEventCycle, $self ],
		-width => 10
	)->pack( -side => "right", -expand => 0,-pady=>10);
	$self->{prevButtonRef} = $buttonPanel->Button( -text => "< Back",
		-command => [ \&PrevButtonEventCycle, $self ],
		-width => 10,
		-state => "disabled"
	)->pack( -side => "right", -expand => 0,-pady=>10);
	$buttonPanel->Button( -text => "Cancel",
		-command => [ \&CancelButtonEventCycle, $self, $self->{wizwin}],
		-width => 10
	) ->pack( -side => "right", -expand => 0,-pady=>10);
	unless ($self->{-nohelpbutton}){
		$buttonPanel->Button( -text => "Help",
			-command => [ \&HelpButtonEventCycle, $self ],
			-width => 10,
		)->pack( -side => 'left', -anchor => 'w',-pady=>10);
	}
	$buttonPanel->pack( -side => "bottom", -fill => 'x', );

	my $line = $self->{wizwin}->Frame(qw/-relief ridge -bd 1 -height 2 -background white/);
	$line->pack(qw/-side bottom -fill x -expand yes/);

	unless ($self->{-style} eq 'top'){
		# builds the image on the left side of the wizard
		if ($self->{-imagepath}){
			die "Can't find imagepath file $self->{-imagepath}" if !-r $self->{-imagepath};
			# -format => "gif" not needed?
			$self->{wizwin}->Photo( "sidebanner",  -file => $self->{-imagepath});
			$self->{wizwin}->Label( -image => "sidebanner")->pack( -side => "left", -anchor => "w");
		} else {
			$self->{wizwin}->Frame(
				-background => $self->{-background}||'white',-width => 100
			)->pack(
				-side => "left", -anchor => "w",-expand=>'both',-fill=>'both'
			);
		}
		# This populates the wizard page panel on the side of the screen.
		$self->{wizardFrame} =
		$self->{wizardPageList}->[$self->{wizardPagePtr}]->()->pack(
			-side=>"top", -expand=>0, -padx=>20, -pady=>2
		);
	}
	else {
		# Builds the left side of the wizard
		if ($self->{-imagepath}){
			$self->{wizwin}->Photo( "sidebanner", -file => $self->{-imagepath});
			$self->{wizwin}->Label( -image => "sidebanner")->pack( -side => "top", -anchor => "n", -padx=>5, -pady=>2);
		} else {
			$self->{wizwin}->Frame( -width => 250 )->pack( -side => "top", -anchor => "n", -padx=>5, -pady=>2);
		}

		# This populates the wizard page panel on the side of the screen.
		$self->{wizardFrame} =
		   $self->{wizardPageList}->[($self->{wizardPagePtr})]->()->pack( -side => "bottom", -expand => 0, -padx=>5, -pady=>2);
	}

	# setup the containing window to match the criteria for a wizard widget
	$self->{wizwin}->configure( -title => $self->{-title});
	$self->{wizwin}->resizable( 0, 0);        # forbid resize
	$self->{wizwin}->withdraw;                # position in screen center
	$self->{wizwin}->Popup;
	$self->{wizwin}->transient;               # forbid minimize
	$self->{wizwin}->protocol( WM_DELETE_WINDOW => [ \&CloseWindowEventCycle, $self, $self->{wizwin}]);
} # end of sub Show


=head2 METHOD currentPage

	my $current_page = $wizard->currentPage()

This returns the index of the page that is currently shown. Pages are indexed starting at 1 with the
first page that is associated with the wizard through the addWizardPage method.

=cut

sub currentPage {
   my($self) = @_;
   return ($self->{wizardPagePtr} + 1);
}

=head2 METHOD parent

	my $parent_window = C<wizard>->parent

This returns areference to the parent Tk widget that was used to create the wizard and all of the controls.
By default, returns a reference to the main window.

Defined at construction - see L<CONSTRUCTOR (new)>..

=cut

sub parent {
   my ($self) = @_;
   return $self->{wizwin};
}

=head2 METHOD blank_frame

	my ($frame,@packing) = C<wizard>->blank_frame(-title=>$title,-text=>$standfirst);

Returns a C<Tk::Frame> object that is a child of the Wizard control.
Some padding parameters are applied to the frame by the wizard control;

Arguments are name/value pairs:

=over 4

=item -title =>

Printed in a big, bold font at the top of the frame as a title

=item -text =>

Printed under the title in standard font.

=back

Also:

	-width -height -background -font

=cut

sub blank_frame { my ($self,$args) = (shift,{@_});
	my $frame = $self->parent->Frame(
		-width=>$args->{-width}||290,
		-height=>$args->{-height}||300,
		-background=>$args->{background}||"white",
	);
	$args->{-font} = $self->{defaultFont} unless $args->{-font};
	my $wrap = 350 || $args->{-width}-20;
	if ($args->{-title}){
		$frame->Label(
			-font => $args->{-font},
			-justify => 'left',
			-anchor=> 'w',
			-wraplength=>$wrap, -text=>$args->{-title}, -font=>'TITLE_FONT',
			-background=>$args->{background}||"white",
		)->pack(-side=>'top',-expand=>'1',-fill=>'x');
		$frame->Frame->pack(-fill => 'both');
	}
	if ($args->{-text}){
		$args->{-text} =~ s/^[\n\r\f]//;
		$args->{-text} = "\n".$args->{-text};
		$_ = $frame->Frame;
		$_->Label(
			-font => $args->{-font},
			-justify => 'left',
			-anchor=> 'w',
			-wraplength=>$wrap, qw/-justify left/, -text => $args->{-text},
			-background=>$args->{background}||"white",
		)->pack(-side=>'top',-expand=>'1',-fill=>'x');
		$_->pack(-side=>'top',-expand=>'1',-fill=>'x',-padx=>10);
	}
	$frame -> pack;
	return ($frame, qw/-side top -pady 2 -padx 2 -anchor w/);
}


=head2 METHOD addLicencePage

	$wizard->addLicencePage ( -filepath => $path_to_licence_text )

Adds a page that contains a scroll texxt box of a licence text file
specifed in the C<-filepath> argument. Presents the user with two
options, accept and continue, or not accept and quit. The user
I<cannot> progress until the 'agree' option has been chosen.

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
C<-title> and C<-text> paramters, as in L<METHOD blank_frame>.

See L<CALLBACK callback_dirSelect>.

=cut

sub addDirSelectPage { my ($self,$args) = (shift,{@_});
	$self->addPage( sub { $self->page_dirSelect($args)  } );
}




######################################################################################################
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
######################################################################################################
sub dispatch { my $handler = shift;
   return (!($handler->())) if defined $handler;
   return 0;
} # end of sub dispatch


######################################################################################################
#
# Method:      NextButtonEventCycle
#
# Description: Runs the complete view of the action handler cycle for the "Next>" button on the
#              wizard button bar. This includes dispatching the preNextButtonAction and
#              postNextButtonAction handler at the apporprate times.
#
######################################################################################################
sub NextButtonEventCycle { my $self = shift;
	if( dispatch( $self->{-preNextButtonAction})) { return;}

	# advance the wizard page pointer and then adjust the navigation buttons.
	# readraw the frame when finished to get changes to take effect.
	$self->{wizardPagePtr}++;
	$self->{wizardPagePtr} = $#{$self->{wizardPageList}} if( $self->{wizardPagePtr} >= $#{ $self->{wizardPageList}});

	if( $self->{nextButtonRef}->cget( -text) eq "Finish") {
		if( dispatch( $self->{-finishButtonAction})) { return; }
		$self->CloseWindowEventCycle();
	}
	$self->{prevButtonRef}->configure( -state => "normal");
	$self->{nextButtonRef}->configure( -text => "Finish") if( $self->{wizardPagePtr} == $#{ $self->{wizardPageList}});
	$self->redrawWizardPage;

	if( dispatch( $self->{-postNextButtonAction})) { return; }
} # end of sub NextButtonEventCycle



######################################################################################################
#
# Method:      PrevButtonEventCycle
#
# Description: Runs the complete view of the action handler cycle for the "<Previous" button on the
#              wizard button bar. This includes dispatching the prePrevButtonAction and
#              postPrevButtonAction handler at the apporprate times.
#
# Parameters:    None
#
######################################################################################################
sub PrevButtonEventCycle { my $self=shift;
	return if dispatch( $self->{-prePrevButtonAction});

	# move the wizard pointer back one position and then adjust the navigation buttons
	# to reflect any state changes. Don't fall off end of page pointer
	$self->{wizardPagePtr}--;
	$self->{wizardPagePtr} = 0 if( $self->{wizardPagePtr} < 0);

	$self->{nextButtonRef}->configure( -text => "Next >");
	$self->{prevButtonRef}->configure( -state => "disabled") if( $self->{wizardPagePtr} == 0);
	$self->redrawWizardPage;

	if( dispatch( $self->{-postPrevButtonAction})) { return; }
} # end of sub PrevButtonEventCycle


######################################################################################################
#
# Method:      HelpButtonEventCycle
#
# Description: This generates all of the events required when the Help button is clicked. This runs
#              through the pre event handler, the event handler and then the post event handler. If
#              no event handlers are defined, the method does nothing.
#
# Parameters:    None
#
######################################################################################################
sub HelpButtonEventCycle { my $self = shift;
	if (dispatch( $self->{-preHelpButtonAction})) { return; }
	if (dispatch( $self->{-helpButtonAction})) { return; }
	if (dispatch( $self->{-postHelpButtonAction})) { return; }
} # end of sub HelpButtonEventCycle


######################################################################################################
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
######################################################################################################
sub CancelButtonEventCycle { my ($self, $hGUI) = (shift, @_);
  return if dispatch( $self->{-preCancelButtonAction});
  $self->CloseWindowEventCycle( $hGUI);
}


######################################################################################################
#
# Method:      CloseWindowEventCycle
#
# Description: This generates all of the necessary events required for a good Wizard control when
#              the Window is about to be closed. This involves dispatching the preCloseWindowAction handler
#              and then destroying the reference to the Window control.
#
# Parameters:    None
#
######################################################################################################
sub CloseWindowEventCycle { my ($self, $hGUI) = (shift,@_);
	return if dispatch( $self->{-preCloseWindowAction});
	$hGUI->destroy;
}


######################################################################################################
#
# Method:      redrawWizardPage
#
# Description: Update the wizard page panel by unpacking the existing controls and then repacking.
#              This allows updates to the page pointer to become visible.
#
# Parameters:  None
#
######################################################################################################
sub redrawWizardPage { my $self = shift;
	$self->{wizardFrame}->packForget;
	$self->{wizardFrame} = $self->{wizardPageList}->[$self->{wizardPagePtr}]->()->pack( -side => "top");
}



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
	$self->{licence_agree} = undef;
	open IN,$licence_file or die "No licence: $licence_file; $!";
	read IN,$text,-s IN;
	close IN;
	my ($frame,@pl) = $self->blank_frame(
		-title=>"End-user Licence Agreement",
		-text=>"\nPlease read the following Licence Agreement. Use the scrollbar to read to the end of the agreement.\n\n"
	);
	my $t = $frame->Scrolled(
		qw/Text -relief sunken -borderwidth 2 -font SMALL_FONT -width 10 -setgrid true
		-height 9 -scrollbars e -wrap word/
	);
	$t->insert('0.0', $text);
	$t->configure(-state => "disabled");
	$t->pack(qw/-expand yes -fill both -padx 10 /);
	$frame->Radiobutton(
            -background => "white",
            -font => $self->{defaultFont},
            -text     => "I accept the terms the terms of the licence agreement",
            -variable => \${$self->{licence_agree}},
            -relief   => 'flat',
            -value    => 1,
            -underline => '2',
        )->pack(@pl);
	$frame->Radiobutton(
            -background => "white",
            -font => $self->{defaultFont},
            -text     => "I do not accept the terms of the licence agreement",
            -variable => \${$self->{licence_agree}},
            -relief   => 'flat',
            -value    => 0,
            -underline => 5,
        )->pack(@pl);

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
		my $button = $self->parent->messageBox('-icon' => 'info', -type => 'ok',				-title => 'Licence Condition',-message => "You must read and agree to the licence before you can use this software.\n\nIf you do not agree to the terms of the licence, you must remove the software from your machine.");
		return 0;
	}
	elsif (not ${$self->{licence_agree}}){
		my $button = $self->parent->messageBox('-icon' => 'warning', -type => 'ok',				-title => 'Licence Condition',-message => "You must read and agree to the licence before you can use this software.\n\nAs you indicated that you do not agree to the terms of the licence, please remove the software from your machine.");
		$button = $self->parent->messageBox('-icon' => 'info', -type => 'ok',				-title => 'Setup Cancelled',-message => "Setup will now exit.");
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
		-text  => $args->{-text}  || "Please select a directory",
	);
	my $entry	= $frame->Entry(
		-background => "white",
		-justify => 'left',
		-width=>40,
		-textvariable=>$args->{-variable},
	)->pack(-side=>'top',-anchor=>'w',-fill=>"x", -padx=>10, -pady=>10,);
	my $dirs	= $frame->Scrolled ( "DirTree",
		-scrollbars => 'osoe',
		-background => $self->{-background}||"white",
		-selectbackground => "navy", -selectforeground => "white",
		-selectmode =>'browse',
		-width=>40, height=>10,
		-browsecmd => sub {${$args->{-variable}}=shift},
	)->pack(-fill=>"x",-padx=>10, -pady=>0,);

	my $bottom	= $frame->Frame(
		-height=>20, -background=>$self->{-background}||'white'
	);
	my $mkdir = $bottom->Button(
		-text => "New Directory",
		-command => sub {
			my $new_name = $self->prompt(-title=>'Create New Directory',-text=>"Please enter the name for the new directory");
			$new_name =~ s/[\/\\]//g;
			$new_name = ${$args->{-variable}} ."/$new_name";
			if (! mkdir $new_name,0777){
				$self->parent->messageBox(
					'-icon' => 'error', -type => 'ok',-title => 'Could Not Create Directory',
					-message => "The directory could not be created:\n$new_name\n\n'$!'"
				);
			} else {
				${$args->{-variable}} = $new_name;
				$dirs->configure(-directory => $new_name);
				warn $dirs->chdir($new_name);
			}
		},
	)->pack( -side => 'right', -anchor => 's', );

	$bottom->pack(-fill=>"x",-padx=>10, -pady=>0, -side => 'bottom', -anchor => 'w',);

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

sub DIALOGUE_really_quit { my $wizard = shift;
	my $button = $wizard->parent->messageBox('-icon' => 'question', -type => 'yesno',
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
		-buttons => ["Cancel","OK"],-default_button=>'OK',
	);
	if ($args->{-text}){
		$w = $d->add("Label",
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
	return $input;
}



=head2 LEGACY METHOD wpFrame

	my $frame = C<wizard>->wpFrame;

Returns a C<Tk::Frame> object that is a child of the Wizard control. It should be
used when creating wizard pages since some padding parameters are applied to it by
the wizard control.

=cut

sub wpFrame { my $self = shift;
   my $frame = $self->{wizwin}->Frame( -width => 290, -height => 400);
   $frame->packPropagate( 0 );
   return $frame;
}



1;
__END__

=head1 CAVEATS / BUGS

=over 4

=item *

Nothing is currently done to ensure text fits into the window - it is currently up to
the client to make frames C<Scrolled>), as I'm having problems making C<&blank_frame>
produce them.

=item *

Dimenions are not yet fixed - more of my novice Tk problems!

=item *

When The I<New Directory> button in the C<addDirSelectPage> method is used
to create a new directory, the C<DirTree> object does not open the branch.
How can it?

=item *

If a Wizard is one page long, the C<FINISH> button will not appear as expected.

=cut

=head1 CHANGES

=head2 VERSION 1.01

=over 4

=item *

Made the supply of a C<MainWindow> to the constructor optional, and
changed the supply method from a reference to part of the passed name/value list.

=item *

Changed C<filename> field to C<-imagepath> for readability.

=item *

Made all arguments begin with C<-> to fit in with Tk "switches".

=item *

Added method C<blank_frame> that can take title and standfirst text.

=item *

Added a bit of space between the Wizard body and the button footer.

=item *

Added default font and background.

=item *

Added licence agreement bits.

=back

=head2 VERSION 1.0

Initial version by Daniel T Hable, found with Google, at
L<http://perlmonks.thepen.com/139336.html|http://perlmonks.thepen.com/139336.html>.

=head1 AUTHOR

Daniel T Hable,

Lee Goddard (lgoddard@cpan.org).

=head1 COPYRIGHT

Copyright (c) 2002 Daniel T. Hable.

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
