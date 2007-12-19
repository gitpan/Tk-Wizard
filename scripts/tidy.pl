our $VERSION = 0.1;
use strict;
use warnings;
use Perl::Tidy ();
use File::Find ();
use FindBin qw/$Bin/;
use File::Copy ();

File::Find::find( \&tidy, $Bin . '/..' );
exit(0);

sub tidy {
    return unless $File::Find::name =~ /\.(pl|t|pm)$/i;
    return if $File::Find::name =~ m{/inc/}g;

    warn "# " . $File::Find::name . "\n";

    my $args;
    my $new_name = $File::Find::name . '.tdy';
    my $old_name = $File::Find::name . '.old';

    Perl::Tidy::perltidy(
        source      => $File::Find::name,
        destination => $new_name,
        stderr      => $args->{stderr},
        perltidyrc  => $Bin . '/perltidyrc',
    );

    die "ERROR: ", $args->{stderr} if $args->{stderr};
    die "ERROR: Did not create " . $new_name . "\n" unless -e $new_name;

    # Copy orig to temp in case we mess up
    File::Copy::move( $File::Find::name, $old_name )
      or die "Could not back-up orig: $!";
    File::Copy::move( $new_name, $File::Find::name )
      or die "Could not move new to orig: $!";
    unlink($old_name) or die "Could not remove temp copy of orig: $!";
}
