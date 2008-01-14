use Test::More;

my $VERSION = do { my @r = ( q$Revision: 1.2 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

eval "use Test::Pod::Coverage 1.00";

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;

all_pod_coverage_ok(
	also_private => [qr/^(DEBUG|ERROR|TRACE|WARN|INFO|FATAL)$/],
);

__END__
