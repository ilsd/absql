#!/usr/local/bin/perl -w
use warnings;
use strict;
use feature ":5.10";

use Carp; use Carp::Heavy;
use Data::Dumper;
use Readonly;
use Locale::Country;
use List::MoreUtils qw( any );
 

# Benutzer-Konfiguration
Readonly our $INNLAND => q{};  # iso-code des eigenen Landes (Land wird dann beim Import nicht in das AB geschrieben)
our $DEBUG = 0;
our $LOGG = 1;

# Globale Variablen und Konstante
Readonly our $ERROR => q{ERROR};

=pod

=head1 AUFGABE DIESES SCRIPTS

Dieses Script legt in Apples Addressbook (AB) einen neuen Kontakt an.
Die Daten dazu, werden aus der SQL-Datenbank bezogen.

Die uuid des im AB neu angelegten Kontakes wird in der Datenbank in das 
Feld 'import_uuid' abgelegt.

=head2 DUBLETTEN

Derzeit werden Dubletten weder erkannt noch verhindert. Ein in der DB 
vorhandener Datensatz (= Zeile in persons) wird als neuer Konatkt in das AB
eingetragen. Er bekommt dabei eine neue UUID (das geht nicht anders, da 
Applescript nicht erlaubt, die UUID zu setzen.). Ein ev. vorhandener Eintrag
für diese Person existiert dann weiterhin parallel im AB.

=cut


use DBTools 1.2.3 qw( 
    :debug 
    :special_chars
    :ab_defaults
);
our $db = DBTools->new(db_name => 'vertrieb');  ## TODO GROSS-Schreibung


my $group_to_import = shift // die(q{Usage: ab_new_contact.pl 'Group Name' | IDnn | ALL_ROWS});

my @id_list;
if ($group_to_import =~ /ID(\d+)/) {
    @id_list = $1;
} elsif ($group_to_import =~ /^ALL_ROWS$/){
    my $rows = $db->get_rows(
        table => 'persons', 
        key_field => 'id'
    );
    @id_list = keys %$rows;
} else {
    my $rows = $db->get_rows(
        table => 'p_groups', 
        where  => {group_name => "$group_to_import" },
        key_field => 'p_id'
    );
    @id_list = keys %$rows;
}

debug(2, q{Dump of '@id_list'} . "\n" . Dumper(@id_list));

## Liste bestehender Gruppen erstellen (Cache)
our $EXISTING_GROUPS = get_group_names();  # Arrayref 

my $counter = 0;
foreach my $id (@id_list) {
    $counter++;
    print "import no $counter for id $id ... ";
    import_this_contact($id);
    say ' success';
}

sub import_this_contact {
    my $p_id = shift // die "Missing id for persons-table";

    ## GRUPPEN
    my $groups = $db->get_rows(
        table => 'p_groups',
        where => {p_id => $p_id},
    );
    debug(2, q{Dump of '$groups'} . "\n" . Dumper($groups));
    GROUP: foreach my $id (keys %$groups) {
        my $name = $groups->{"$id"}{'group_name'};
        debug(2, "Group Name: $name");
        debug(2, q{Dump of '$EXISTING_GROUPS'} . "\n" . Dumper($EXISTING_GROUPS));
        next GROUP if ( any {$name eq $_} @{$EXISTING_GROUPS});
        my $group_uuid = make_group($name);
        debug(2, "created new group $group_uuid with name $name");
    }


    ## PERSON
    my $person = $db->get_row(table => 'persons', val => $p_id);
    my $emails = $db->get_rows(
        table => 'p_email',
        where => {'p_id' => $p_id},
    );
    debug(2, q{Dump of '$emails'} . "\n" . Dumper($emails));
    my $tels = $db->get_rows(
        table => 'p_tel',
        where => {'p_id' => $p_id},
    );
    debug(2, q{Dump of '$tels'} . "\n" . Dumper($tels));
    my $adrs = $db->get_rows(
        table => 'p_adr',
        where => {'p_id' => $p_id},
    );
    debug(2, q{Dump of '$adrs'} . "\n" . Dumper($adrs));

    # Contact im AB anlegen und den Gruppen zuordnen
    my $new_uuid = make_person($person, $emails, $tels, $adrs, $groups) 
        || die "Can not make new person in AB for person id $p_id";
    debug(2, "new_uuid: $new_uuid");

    # Feld import_uuid in der DB aktualisieren
    # (damit kann der Eintrag im AB wieder gefunden werden)
    $db->update_rows(
        table => 'persons', 
        where => {id => $p_id}, 
        data  => {import_uuid => $new_uuid}) 
    || die "import of contact id $p_id failed!";
}



# ========
# = Subs =
# ========

sub make_group {
    my $name = shift // die('Missing name for group');
    my @lines;
    push @lines, q<tell application "Address Book">;
    push @lines, q<   set theGroup to make new group with properties {name:"> . "$name" . q<"}> ;
    push @lines, q<   save addressbook>;
    push @lines, q<   theGroup>;       # Rückgabe der UUID
    push @lines, q<end tell>;           # Ende von tell application addressbook
    my $cmd = q{osascript -ss} . $BLANK;
    foreach (@lines) {
        $cmd .= q{-e} . $BLANK . q{'} . $_ . q{'} . $BLANK;
    }
    debug(2, $cmd);
    my $out = `$cmd`; #--> group id "D988FC9B-62FC-4ABA-9C70-E5F5821D2724:ABGroup" of application "Address Book"
    debug(2, "out of make_group: $out");
    if ($out =~ /group id "([A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}:ABGroup)" of application "Address Book"/) {
        my $uuid = $1;
        push @$EXISTING_GROUPS, "$name"; # Cache ergänzen
        debug(1, "new group: $name, $uuid");
        return $uuid;
    }
    else {
        die "invalid UUID in output >$out< when making group $name";
    }
    return;
}

sub get_group_names {
    my @lines;
    push @lines, q<tell application "Address Book">;
    push @lines, q<   name of every group> ;
    push @lines, q<end tell>;           # Ende von tell application addressbook
    my $cmd = q{osascript -ss} . $BLANK;
    foreach (@lines) {
        $cmd .= q{-e} . $BLANK . q{'} . $_ . q{'} . $BLANK;
    }
    debug(2, $cmd);
    my $out = `$cmd`; #--> group id "D988FC9B-62FC-4ABA-9C70-E5F5821D2724:ABGroup" of application "Address Book"
    debug(2, "out of get_group_names: $out");
    $out =~ s/\{|\}//g;
    $out =~ s/"//g;
    debug(2, "out of get_group_names nach Bearbeitung: $out");
    my @names = split/${COMMA}${BLANK}*/, $out; 
    return \@names;
}

sub make_person {
    my $data = shift // die(q{Missing data for person.});
    my $emails = shift;
    my $tels = shift;
    my $adrs = shift;
    my $groups = shift;
    
    # make shure, we always have the original uuid with the person
    die ( 'missing abid' ) if not defined $data->{'abid'};
    
    # clean the 'note'
    if (defined $data->{'note'}) {
        $data->{'note'} =~ s/\n/$BLANK\/\/$BLANK/g;
        $data->{'note'} =~ s/"/''/g;
        $data->{'note'} =~ s/'/$BLANK/g;
    }
    
    # construct the title
    my $title;
    if (defined $data->{'sex'} and defined $data->{'language'} ) {
        if ($data->{'sex'} eq 'M' and $data->{'language'} eq 'de') {
            $title = 'Herr';
        } elsif ($data->{'sex'} eq 'F' and $data->{'language'} eq 'de') {
            $title = 'Frau';
        } elsif ($data->{'sex'} eq 'M' and $data->{'language'} eq 'en') {
            $title = 'Mr.';
        } elsif ($data->{'sex'} eq 'F' and $data->{'language'} eq 'en') {
            $title = 'Mrs.';
        };
    }
    
    # set the 'company'-flag to 'true' or 'false'
    my $company = $FALSE;
    if( defined $data->{'company'} ) {
        $company = $data->{'company'} ? $TRUE : $FALSE;
    } 
    
    if (defined $data->{'title'}) {
        $title .= $BLANK . $data->{'title'}
    }
    
    ## Construct the Applescript
    my @lines;
    push @lines, q<tell application "Address Book">;
    push @lines, q<   set thePerson to make new person with properties {> 
        . q<first name:">       . ($data->{'first_name'}    // $EMPTY)   
        . q<", last name:">     . ($data->{'last_name'}     // $EMPTY)  
        . q<", organization:">  . ($data->{'o_name'}        // $EMPTY)
        . q<", company:">       . "$company"
        . q<", job title:">     . ($data->{'job_title'}     // $EMPTY)   
        . q<", title:">         . ($title                   // $EMPTY)   
        . q<", middle name:">   . ($data->{'middle_name'}   // $EMPTY)   
        . q<", nickname:">   . ($data->{'nickname'}   // $EMPTY)   
        . q<", suffix:">   . ($data->{'suffix'}   // $EMPTY)   
        . q<", note:">   . ($data->{'note'} // $EMPTY)    
        . q<", department:">   . ($data->{'department'}   // $EMPTY)   
        . q<"}>
    ; # end of push
    push @lines, q<   save addressbook>;
    
    # abid (originale UUID) als related Name mitgeben
    push @lines, q<make new related name at end of related names of thePerson with properties > 
        . q<{label:"> . 'abid' 
        . q<", value:"> . "$data->{'abid'}" 
        . q<"}>;
    
    
    # Emails
    foreach my $id (keys %$emails) {
        my $email = $emails->{"$id"}{'email'};
        my $label = $emails->{"$id"}{'label'} // $DEFAULT_LABEL;
        push @lines, q<make new email at end of emails of thePerson with properties > 
            . q<{label:"> . "$label" 
            . q<", value:"> . "$email" 
            . q<"}>;
    }
    push @lines, q<   save addressbook>;
    
    # Phones
    foreach my $id (keys %$tels) {
        my $tel;
        if (defined $tels->{"$id"}{'number'}) {
            $tel = q{+} . $tels->{"$id"}{'country_code'} 
                 . q{-} . $tels->{"$id"}{'area_code'}
                 . q{-} . $tels->{"$id"}{'number'}
                 . (defined $tels->{"$id"}{'ext'} ? q{-} . $tels->{"$id"}{'ext'} : $EMPTY) ;
        } else {
            $tel = $tels->{"$id"}{'full_no'};
        }
         
        my $label = $tels->{"$id"}{'label'} // $DEFAULT_LABEL;
        push @lines, q<make new phone at end of phones of thePerson with properties > 
            . q<{label:"> . "$label" 
            . q<", value:"> . "$tel" 
            . q<"}>;
    }
    push @lines, q<   save addressbook>;
    
    # Addresses
    foreach my $id (keys %$adrs) {
        my $str   = $adrs->{"$id"}{'str'} // $EMPTY;
        my $city   = $adrs->{"$id"}{'place'} // $EMPTY;
        my $zip   = $adrs->{"$id"}{'zip'} // $EMPTY;
        my $country;
        given ($adrs->{"$id"}{'iso'}) {
          when( undef )   { $country = ($adrs->{"$id"}{'country'} // $EMPTY) }
          when( $INNLAND ){ $country = $EMPTY } # Name wird unterdrückt gemäß Adressierungsrichtlinien Post
          when ( 'de'  )  {  $country = 'Deutschland' }
          when ( 'ch'  )  {  $country = 'Schweiz' }
          when ( 'us'  )  {  $country = 'USA' }
          when ( 'nl'  )  {  $country = 'Niederlande' }
          when ( 'it'  )  {  $country = 'Italien' }
          when ( 'fr'  )  {  $country = 'Frankreich' }
          default  { $country = code2country( $adrs->{"$id"}{'iso'} ); }  # engl. Name laut ISO/UNO
        }
        my $label = $adrs->{"$id"}{'label'} // $DEFAULT_LABEL;
        push @lines, q<make new address at end of addresses of thePerson with properties > 
            . q<{label:"> . "$label" 
            . q<", street:"> . "$str" 
            . q<", city:"> . "$city" 
            . q<", zip:"> . "$zip" 
            . q<", country:"> . "$country" 
            . q<"}>;
    }
    push @lines, q<   save addressbook>;
    
    # Den Gruppen zuordnen
    foreach my $id (keys %$groups) {
        my $group_name = $groups->{"$id"}{'group_name'};
        push @lines, q<   add thePerson to group "> . $group_name . q<">;
    }
    push @lines, q<   save addressbook>;
    
    # Abschluss tell-Block
    push @lines, q<   thePerson>;       # Rückgabe der Personen UUID
    push @lines, q<end tell>;           # Ende von tell application addressbook
    my $cmd = q{osascript -ss} . $BLANK;
    foreach (@lines) {
        $cmd .= q{-e} . $BLANK . q{'} . $_ . q{'} . $BLANK;
    }
    debug(2, $cmd);
    my $out = `$cmd`; # person id "A77BA325-F65B-4CEC-AD2D-F2644C5FD8E2:ABPerson" of application "Address Book"
    if ($out =~ /person id "([A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}:ABPerson)" of application "Address Book"/) {
        my $uuid = $1;
        debug(1, "new person: " . ($data->{'first_name'} // $EMPTY) . $BLANK . ($data->{'last_name'} // $EMPTY) . $BLANK . ($data->{'o_name'} // $EMPTY) . ", $uuid");
        return $uuid;
    }
    else {
        die "invalid UUID in output >$out<";
    }
    return;
}
__END__


