#!/usr/local/bin/perl -w
use warnings;
use strict;
use feature ":5.10";

use Carp; use Carp::Heavy;
use Data::Dumper;
use Readonly;
 
our $DEBUG = 0;
our $LOGG = 1;
Readonly our $ERROR => q{ERROR};

=pod

=head1 AUFGABE DIESES SCRIPTS

Dieses Script wird von einem Apple-Script (MySQL-Addressbook.applescript)
aufgerufen. Dieses übergibt die Daten eines Kontakes aus dem Addressbuch. 

Aufgabe des Scriptes ist es nun, diese Daten in die 'persons'- Tabelle
einer relationalen Datenbank abzulegen.

An Hand von Konventionen, werden dabei Entscheidungen getroffen, wie auch im Adressbuch
nicht vorhandene Felder befüllt werden. So ergibt z.B. die Übergabe von 
title='Herr', dass die Anrede mit 'Herr', das Feld Sex mit 'M' und Sprache mit 
'de' gefüllt wird.

Der Rückgabewert ist die id der angelegten Zeile.

=head2 DUBLETTEN

Das Script überprüft, ob eine UUID in der DB schon existiert. 
Wenn ja, wird für diesen Kontakt keine neue Zeile in persons angelegt.
Eventuelle Gruppen, in denen die Person Mitglied ist, werden aber in die DB
übertragen und die in der DB schon vorhandene Person dieser Gruppe zugeordnet. 

Siehe im Code
    $warning = 'UUID already exists in DB for id ' . "$p_id".

=cut


use DBTools qw( 
    :debug 
    :special_chars
    $MISSING_VALUE
);

my $data = shift;
my $group_name = shift;
debug(2, 'Daten Eingang:' . Dumper($data));
debug(1, 'Gruppenname Eingang:' . $group_name);
my @columns = split /\s*_nl_\s*/, $data;
debug(2, '@columns: ' . Dumper(@columns));
my %p_data; # data for the 'persons' table

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
        when ('abid') {
            my $p_id = $db->get_id(col => 'abid', val => $val, table => 'persons'); #  id in persons
            if ($p_id) {
                my $warning = 'UUID already exists in DB for id ' . "$p_id";
                warn  $warning . "\n";
                debug(0, $warning);

                # Pers-Gruppen-Verbindung in DB schreiben, auch wenn die Pers. schon existiert
                my $id = $db->insert_row('p_groups', {
                    p_id => $p_id,
                    group_name => $group_name}
                );
                debug(1, "inserted id $id into p_groups (p_id $p_id --> $group_name)");
                
                # keine weiteren Eintragungen = zurück zum AS
                print $ERROR;   # damit wird dem AS ein Fehler signalisiert
                exit;
            } else {
                $p_data{$key} = $val;
            }
        }
        when ('title') {
            next COLUMN if $val eq $MISSING_VALUE;
            if ($val =~ s/  ^(?:Herr|Herrn|Hr\.)\s*$ # Herr, Hr., ...
                            |
                            ^(?:Herr|Herrn|Hr\.)\s+([[:alpha:]].*)$ # 'Herr Dr.' aber nicht 'HerrFrau'
                        /$1/x
                ) {
                $p_data{'sex'} = 'M';
                $p_data{'language'} = 'de';
                $p_data{'title'} = $val; # der Rest sollte dann ein Dr. oder Mag. sein
            } elsif ($val =~ s/  (?:^(?:Frau|Fr\.)\s*)$ 
                                 |
                                 (?:^(?:Frau|Fr|Frl\.)\s+([[:alpha:]].*)$) # Frau Dr.
                                 /$1/x
                    ) {
                $p_data{'sex'} = 'F';
                $p_data{'language'} = 'de';
                $p_data{'title'} = $val; # der Rest sollte dann ein Dr. oder Mag. sein
            } elsif ($val =~ s/^Mr\.?\s*//) {
                $p_data{'sex'} = 'M';
                $p_data{'language'} = 'en';
                $p_data{'title'} = $val; # der Rest sollte dann ein Dr. oder Mag. sein
            } elsif ($val =~ s/^(?:(?:Mrs|Ms)\.?|Miss)\s*//) {
                # Miss ... used only for an unmarried woman. ... 
                # A period is not used to signify the contraction. 
                # Its counterparts are Mrs., usually used only for married women, 
                # and Ms., which may be used regardless of marital status.
                $p_data{'sex'} = 'F';
                $p_data{'language'} = 'en';
                $p_data{'title'} = $val; # der Rest sollte dann ein Dr. oder Mag. sein
            } else {
                debug(0, 'unknown title: ' . $val);
                $p_data{'title'} = $val;
            }
        }
        when ('company') {
            $p_data{$key} = 1 if $val eq 'true';
        }
        when ('creation_date') {
            debug(0, 'creation_date in AB: ' . $val);
        }
        default {
            next COLUMN if $val eq $MISSING_VALUE;
            $p_data{$key} = $val; 
        }
    }
}

debug(2, '%p_data: ' . Dumper(\%p_data));

#
# Datenbank aktualisieren
#

my $id = $db->insert_row('persons', \%p_data);
debug(0, "inserted id $id into persons ($p_data{'first_name'} $p_data{'last_name'})");
# # Pers-Gruppen-Verbindung in DB schreiben
my $group_id = $db->insert_row(
    'p_groups', 
    {
        p_id => $id,
        group_name => $group_name
    },
);
debug(1, "inserted id $group_id into p_groups (p_id $id --> $group_name)");


print $id; # zur Übergabe an AS


exit;

