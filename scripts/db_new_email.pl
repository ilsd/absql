#!/usr/local/bin/perl -w
use warnings;
use strict;
use feature ":5.10";

use Carp; use Carp::Heavy;
use Data::Dumper;

our $DEBUG = 0;
our $LOGG = 0;

=pod

=head1 AUFGABE DIESES SCRIPTS

Dieses Script wird von einem Apple-Script aufgerufen. Dieses übergibt die Daten
eines Kontakes aus dem Addressbuch. 

Aufgabe des Scriptes ist es nun, diese Daten in die 'p_email'- Tabelle
einer relationalen Datenbank abzulegen.

Der Rückgabewert ist die id der angelegten Zeile.

=cut


use DBTools qw( 
    :debug 
    :special_chars
    $MISSING_VALUE
);

my $data = shift;
debug(2, 'Daten Eingang:' . Dumper($data));
my @columns = split /\s*_nl_\s*/, $data;
debug(2, '@columns: ' . Dumper(@columns));
my %data; # data for the 'p_tel' table

my $db = DBTools->new(db_name => 'vertrieb');

#
# Hashkey aufbauen
#

COLUMN: foreach my $col (@columns) {
    debug(2, $col);
    my ($key, $val) = split /\s*=>\s*/, $col;
    if (not defined $key or not defined $val) { die 'key or value undefined'};
    debug(2, 'key/value: ' . "$key => $val" );
    
    # Arbeitet alle Felder eines Datensatzes (Kontaktes) ab und füllt 
    # entsprechend die Felder in den Tabellen der DB aus. 
    given ($key) {
        # when ('email') {
        #     next COLUMN if $val eq $MISSING_VALUE;
        #     ...
        # }
        
        # p_id und label werden von der default-Regel erfasst
        default {
            next COLUMN if $val eq $MISSING_VALUE;
            $data{$key} = $val; 
        }
    }
}

debug(2, '%data: ' . Dumper(\%data));

#
# Datenbank aktualisieren
#

my $id = $db->insert_row('p_email', \%data);
debug(1, "inserted id $id into p_email ($data{'email'} for p_id $data{'p_id'})");
print $id;
exit;

