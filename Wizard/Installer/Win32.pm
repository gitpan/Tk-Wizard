package Tk::Wizard::Installer::Win32;
use vars qw/$VERSION/;
$VERSION = 0.02;	# LG 28 November 2002 18:31

BEGIN {
	use Carp;
	use Tk::Wizard::Installer;
	require Exporter;
	@ISA = "Tk::Wizard::Installer";
	@EXPORT = ("MainLoop");
}

=head1 NAME

Tk::Wizard::Installer::Win32 - Win32-specific routines for Tk::Wizard::Installer

=head1 DESCRIPTION

All the methods and means of C<Tk::Wizard>, plus those below:

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
	return 1 if $Tk::platform ne 'MSWin32';
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

THIS SOFTWARE AND THE AUTHORS OF THIS SOFTWARE ARE IN NO WAY CONNECTED TO THE MICROSOFT CORP.
THIS SOFTWARE IS NOT ENDORSED BY THE MICROSOFT CORP
MICROSOFT IS A REGISTERED TRADEMARK OF MICROSOFT CROP.


