#!/usr/local/bin/perl -w
use warnings;
use strict;
use feature ":5.10";

our $DEBUG = 0;
our $LOGG = 0;
use DBTools qw ( :debug );
use Data::Dumper;


# Blöde Leerzeichen am Ende entfernen


my $db = DBTools->new(db_name => 'vertrieb');

my $rows = $db->get_rows(table => 'persons');
debug(2, q{Dump of '$rows'} . "\n" . Dumper($rows));

foreach my $id (keys %{$rows}) {
    
    if (defined $rows->{$id}{'title'}) {
        my $title = $rows->{$id}{'title'};
        if ($title =~ /\s+$/ ) {
            say "$rows->{$id}{'last_name'}: >$title<";
            $title =~ s/(.*?)\s+$/$1/;
            say "$rows->{$id}{'last_name'}: >$title<";
            $db->update_rows(table => 'persons', where => {id => $id }, data => {title => $title} );
        }
    }
}