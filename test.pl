use strict;
use warnings;
use Test::More 'no_plan';

use MongoDB;
use Devel::Peek;

sub build_client {
    my @args = @_;
    my $host = exists $ENV{MONGOD} ? $ENV{MONGOD} : 'localhost';

    # long query timeout may help spurious failures on heavily loaded CI machines
    return MongoDB::MongoClient->new(
        host => $host, find_master => 1, query_timeout => 60000, @args,
    );
}

my $conn = build_client();
my $coll = $conn->ns("test.test_collection");
$coll->ensure_index({"x.y" => 1}, {"name" => "foo"});

ok(1);
Dump($_);
my ($index) = grep { 1 } $coll->get_indexes;
Dump($_);
Dump($index);
ok(1);


__END__

Ways to make the problem go away:

ok(1);
my ($index) = grep { $_->{name} eq 'foo' } $coll->get_indexes;
$index = undef
ok(1);


ok(1);
{
    my ($index) = grep { $_->{name} eq 'foo' } $coll->get_indexes;
}
ok(1);


ok(1);
grep { $_->{name} eq 'foo' } $coll->get_indexes;
ok(1);


# This one is not like the others as it does not require $index be destroyed
# before the second ok().
ok(1);
my ($index) = grep { $_->{name} eq 'foo' } $coll->get_indexes;
{
    local $_ = 1;
    ok(1);
}


Interestingly localizing $_ around the grep DOES NOT solve the problem, if
$index is allowed to survive, The following DOES still exibit the problem.
my $index;
ok(1);
{
    local $_ = 1;
    ($index) = grep { $_->{name} eq 'foo' } $coll->get_indexes;
}
ok(1);
