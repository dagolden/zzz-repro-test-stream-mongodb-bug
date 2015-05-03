use strict;
use warnings;
use Test::More 'no_plan';

use MongoDB;
use Devel::Peek;
use Try::Tiny;
use Safe::Isa;

sub our_get_indexes {
    my ($self) = @_;

    # try command style for 2.8+
    my ( $ok, @indexes ) = try {
        my $command = Tie::IxHash->new( listIndexes => $self->name, cursor => {} );
        # don't actually run command, fake response
        my $res = {
            "cursor" => {
                "id"         => 0,
                "ns"         => 'test.$cmd.listIndexes.test_collection',
                "firstBatch" => [
                    {
                        "v"    => 1,
                        "key"  => { "_id" => 1 },
                        "name" => "_id_",
                        "ns"   => "test.test_collection"
                    },
                    {
                        "v"    => 1,
                        "key"  => { "x.y" => 1 },
                        "name" => "foo",
                        "ns"   => "test.test_collection"
                    }
                ]
            },
            "ok" => 1
          };
        my @list;
        # XXX RC0 - RC2 give collections result; RC3+ give cursor result
        if ( $res->{indexes} ) {
            @list = @{$res->{indexes}};
        }
        else {
            my $cursor  = MongoDB::Cursor->new(
                started_iterating => 1,                 # we have the first batch
                _client           => $self->_database->_client,
                _master           => $self->_database->_client,    # fake this because we're already iterating
                _ns               => $res->{cursor}{ns},
                _agg_first_batch => $res->{cursor}{firstBatch},
                _agg_batch_size  => scalar @{ $res->{cursor}{firstBatch} }, # for has_next
                _query           => $command,
            );
            $cursor->_init( $res->{cursor}{id} );
            @list = $cursor->all;
        }
        return 1, @list;
    }
    catch {
        die $_;
    };

    return @indexes;
}

my $conn = MongoDB::MongoClient->new(
    host          => (exists $ENV{MONGOD} ? $ENV{MONGOD} : 'localhost'),
    find_master   => 1,
    query_timeout => 60000
);
my $coll = $conn->ns("test.test_collection");

ok(1);
Dump($_);
my ($index) = our_get_indexes($coll);
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
