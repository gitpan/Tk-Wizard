package Tk::Wizard::Installer::Win32;
use vars qw/$VERSION/;
$VERSION = 0.021;	# 03 December 2002, 12:17 CET

BEGIN {
	use Carp;
	use Tk::Wizard::Installer;
	require Exporter;
	@ISA = "Tk::Wizard::Installer";
	@EXPORT = ("MainLoop");
}

use Win32::TieRegistry( Delimiter=>"/", ArrayValues=>0 );

=head1 NAME

Tk::Wizard::Installer::Win32 - Win32-specific routines for Tk::Wizard::Installer

=head1 DESCRIPTION

All the methods and means of C<Tk::Wizard>, plus the below, which are thought
to be specific to the Microsoft Windows platform.

=head1 DEPENDENCIES

	Tk::Wizard
	Tk::Wizard::Installer
	Win32::TieRegistry

=head1 METHODS

=head2 METHOD register_with_windows

Registers an application with Windows so that it can be "uninstalled"
using the I<Add/Remove Programs> dialogue.

An entry is created in the Windows' registry pointing to the
uninstall script path. See C<UninstallString>, below.

Returns C<undef> on failure, C<1> on success. Does nothing on non-MSWin32 platforms

Aguments are:

=over 4

=item uninstall_key_name

The name of the registery sub-key to be used. This is transparent to the
end-user, but should be unique for all applications.

=item UninstallString

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

=item QuiteUninstallString

As C<UninstallString> above, but for ... quiet uninstalls.

=item app_path

Please see the entry for C<UninstallString>, above.

=item DisplayName

=item DisplayVersion

=item Size

The strings displayed in the application list of the Add/Remove dialogue.

=item ModifyPath

=item NoRepair NoModify NoRemove

=item EstimatedSize InstallSorce InstallDate InstallLocation

=item AthorizedCDFPrefix Language ProductID

Unknown

=item Comments

=item RegOwner

=item RegCompnay

=item Contact

=item HelpTelephone

=item Publisher

=item URLUpdateInfo

=item URLInfoAbout

=item HelpLink

These are all displayed when the Support Information link
is clicked in the Add/Remove Programs dialogue. The last
should be full URIs.

=back

The routine will also try to add any other paramters to the
registry tree in the current location: YMMV.

=cut

sub register_with_windows { my ($self,$args) = (shift,{@_});
	return 1 if $Tk::platform ne 'MSWin32';
	unless ($args->{DisplayName} and $args->{UninstallString}
		and ($args->{uninstall_key_name} or $args->{app_path})
	){
		die __PACKAGE__."::register_with_windows requires an argument of name/value pairs which must include the keys 'UninstallString', 'uninstall_key_name' and 'DisplayName'";
	}

	if (not $args->{UninstallString} and not $args->{app_path}){
		die __PACKAGE__."::register_with_windows requires either argument 'app_path' or 'UninstallString' be set.";
	}
	if ($args->{app_path}){
		$args->{app_path} = "perl -e '$args->{app_path} -u'";
	}
	my $uninst_key_ref =
	$Registry->{'LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/'} ->
		CreateKey( $args->{uninstall_key_name} );
	die "Perl Win32::TieRegistry error" if !$uninst_key_ref;

	foreach (keys %$args){
		next if $_ =~ /^(app_path|uninstall_key_name)$/g;
		$uninst_key_ref->{"/$_"} = $args->{$_};
	}
	return $!? undef : 1;
}


1;
__END__


=head1 CHANGES

Please see the file F<CHANGES.txt> included with the distribution.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org).

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI; windows; win32; registry.

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 ff.

Distributed under the same terms as Perl itself.
