use strict;
use warnings;

use Test::More;
use lib "./lib";
use ExtUtils::testlib;

my $VERSION = do { my @r = ( q$Revision: 1.3 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };


eval "use Test::Pod::Coverage 1.00";

if ( $@ ){
	plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
}

else {
	TODO: {
		local $TODO = "Must read the pod coverage API";
		all_pod_coverage_ok(
			also_private => [ qr/^[A-Z_]+$/ ], # all-caps Log4Perl/l4p-stubs functions as privates
		);
	}
}


__END__
