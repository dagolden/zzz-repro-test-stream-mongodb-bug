use strict;
use warnings;
use Test::More 'no_plan';

use MongoDB;

my @testdbs;

sub build_client {
    my @args = @_;
    my $host = exists $ENV{MONGOD} ? $ENV{MONGOD} : 'localhost';

    # long query timeout may help spurious failures on heavily loaded CI machines
    return MongoDB::MongoClient->new(
        host => $host, find_master => 1, query_timeout => 60000, @args,
    );
}

sub get_test_db {
    my $conn = shift;
    my $testdb = 'testdb' . int(rand(2**31));
    my $db = $conn->get_database($testdb) or die "Can't get database\n";
    push(@testdbs, $db);
    return  $db;
}

BEGIN {
    eval {
        my $conn = build_client();
        my $testdb = get_test_db($conn);
        eval { $conn->get_database("admin")->_try_run_command({ serverStatus => 1 }) }
            or die "Database has auth enabled\n";
    };

    if ( $@ ) {
        (my $err = $@) =~ s/\n//g;
        if ( $err =~ /couldn't connect/ ) {
            $err = "no mongod on " . ($ENV{MONGOD} || "localhost:27017");
            $err .= ' and $ENV{MONGOD} not set' unless $ENV{MONGOD};
        }
        plan skip_all => "$err";
    }
};

END {
    for my $db (@testdbs) {
        $db->drop;
    }
}

my $conn = build_client();
my $testdb = get_test_db($conn);
$testdb->drop;
my $dbname = $testdb->name;
my $coll = $conn->ns("$dbname.test_collection");
$coll->ensure_index({"x.y" => 1}, {"name" => "foo"});

ok(1);
my ($index) = grep { $_->{name} eq 'foo' } $coll->get_indexes;
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
