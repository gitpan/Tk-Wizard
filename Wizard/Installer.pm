package Tk::Wizard::Installer;
use vars qw/$VERSION/;
$VERSION = 0.01;	# LG 28 November 2002 18:31

BEGIN {
	use Carp;
	use Tk::Wizard;
	require Exporter;
	@ISA = "Tk::Wizard";
	@EXPORT = ("MainLoop");
}

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

Tk::Wizard::Installer - building-blocks for a software install wizard

=head1 DESCRIPTION

This module comprises the first moves towards a C<Tk::Wizard> extension
to automate software installation, primarily for end-users, in the manner
of I<Inno Setup>, I<Install Sheild>, etc.

=head1 DETAILS

All the methods and means of C<Tk::Wizard>, plus those below:

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
	warn "Foo";
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

=head1 SEE ALSO

L<Tk>; L<Tk::Wizard>; L<Tk::Wizard::Install::Win32>.

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

THIS SOFTWARE AND THE AUTHORS OF THIS SOFTWARE ARE IN NO WAY CONNECTED TO THE MICROSOFT CORP.
THIS SOFTWARE IS NOT ENDORSED BY THE MICROSOFT CORP
MICROSOFT IS A REGISTERED TRADEMARK OF MICROSOFT CROP.



1;