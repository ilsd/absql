#!/usr/local/bin/perl -w
use warnings;
use strict;
use feature ":5.10";

use Carp; use Carp::Heavy;
use Data::Dumper;

our $DEBUG = 0;
our $LOGG = 2;

=pod

=head1 AUFGABE DIESES SCRIPTS

Dieses Script wird von einem Apple-Script aufgerufen. Dieses übergibt die Daten
eines Kontakes aus dem Addressbuch. 

Aufgabe des Scriptes ist es nun, diese Daten in die 'p_tel'- Tabelle
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
        when ('tel') {
            next COLUMN if $val eq $MISSING_VALUE;
            if ($val =~ m{
                \+
                (\d{1,4})   # country code
                -
                (\d{1,10})  # area-code
                -
                ([\d\s]{3,20})    # tel
                (?:   -
                    ([\d\s]{1,6})
                )?              # optional with extension
                }x) {
                    $data{'country_code'}   = $1;
                    $data{'area_code'}      = $2;
                    $data{'number'}         = $3;
                    $data{'ext'}            = $4;
                    
                    # Leerzeichen entfernen, da Datentyp INTEGER
                    $data{'number'} =~ s/\s+//g;
                    $data{'ext'}    =~ s/\s+//g;                    
                    
            }; # end of if
            $data{'full_no'} = $val;
        }
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

my $id = $db->insert_row('p_tel', \%data);
debug(1, "inserted id $id into p_tel ($data{'full_no'} for p_id $data{'p_id'})");
print $id;
exit;

