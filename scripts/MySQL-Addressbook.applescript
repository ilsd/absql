#!/usr/bin/osascript

-- AUFAGBE: Ausgewählte Kontakte in die DB kopieren

-- Verwendung:
-- 1. Kontakte auswählen
-- 2. Script starten (Apfel-R in textMate z.B.)
-- 3. Logfile kontrollieren
tell application "System Events"
    set gruppenName to text returned of (¬
        display dialog "Gruppen-Name" ¬
            default answer "unbekannt" ¬
            buttons {"OK"} ¬
            default button 1¬
        ) ¬
        as string
end tell

-- Anzahl ausgewählter Kontakte ermitteln
tell application "Address Book"
    set selectedContacts to selection
    set numberOfContacts to number of selectedContacts
end tell

-- Auswahl überprüfen
tell application "System Events"
    set answer to the button returned of (¬
        display dialog "Anzahl Kontakte die in die Gruppe " & gruppenName & ¬
            " exportiert werden: " & numberOfContacts ¬
            buttons {"OK weiter ...", "Abbrechen"} ¬
            default button 2¬
        )
    if (answer = "Abbrechen") then
        exit
    end if
end tell

exportSelectedContacts(gruppenName)

-- Gibt die Daten des gerade ausgewählten Kontaktes im Adressbuch zurück
on exportSelectedContacts(gruppenName)
    
    -- Vars
    set LibPath to "/Users/ingolantschner/Library/Scripts/absql/scripts/"
    set contactCounter to 0
    
    tell application "Address Book"
        
        set selectedContacts to selection
        repeat with thisContact in selectedContacts
            
            -- collect all data of all contacts - maybe we trash this later
            set hashSep to "=>"
            set lineSep to " _nl_ "
            -- the data is collected in form of a perl-hash:
            -- key => value
            -- key should be the same string as the column-name in the MySQL DB

            -- creation-date umformatieren
            set datum to creation date of thisContact
            set Tag to day of datum as number
        	set Monat to month of datum as number
        	set Jahr to year of datum as number

        	-- führende Null für Tag und Monat ergänzen
        	if Monat < 10 then
        		set Monat to "0" & Monat
        	end if
        	if Tag < 10 then
        		set Tag to "0" & Tag
        	end if
        	set DatumISO to Jahr & "-" & Monat & "-" & Tag
        	
            
            set contactsData to ¬
                "ab_creation_date" & hashSep & DatumISO                    & lineSep & ¬
                "abid"          & hashSep & id of thisContact           & lineSep & ¬
                "title"         & hashSep & title of thisContact        & lineSep & ¬
                "first_name"    & hashSep & first name of thisContact   & lineSep & ¬
                "last_name"     & hashSep & last name of thisContact    & lineSep & ¬
                "middle_name"   & hashSep & middle name of thisContact  & lineSep & ¬
                "o_name"        & hashSep & organization of thisContact & lineSep & ¬
                "company"       & hashSep & company of thisContact      & lineSep & ¬
                "department"    & hashSep & department of thisContact   & lineSep & ¬
                "job_title"     & hashSep & job title of thisContact    & lineSep & ¬
                "nickname"      & hashSep & nickname of thisContact     & lineSep & ¬
                "suffix"        & hashSep & suffix of thisContact       & lineSep
            
            
            -- note aufbereiten (Gänsefüßchen entfernen)
            if (exists note of thisContact) then
                set sourceText to note of thisContact
                set ASTID to AppleScript's text item delimiters
                set AppleScript's text item delimiters to  "\"" 
                set sourceText to text items of sourceText
                set AppleScript's text item delimiters to "''"
                set sourceText to "" & sourceText
                set AppleScript's text item delimiters to ASTID
                set contactsData to contactsData ¬
                    & "note" & hashSep & sourceText & lineSep
            end if
            
            -- copy the contacts data to MySQL
            set idPerson to do shell script LibPath & "db_new_person.pl"¬
                & space & quote & contactsData & quote & space & quote & gruppenName & quote
                
            if ( idPerson ≠ "ERROR") then 
                set contactCounter to contactCounter + 1
                
                -- -- Gruppen-Personen-Verbindung eintragen
                -- set groupId to do shell script LibPath & "db_add_to_group.pl"¬
                --     & space & quote & idPerson & quote ¬
                --     & space & quote & gruppenName & quote
            
                -- Telefon 
                if (exists phones of thisContact) then
                    repeat with thisTel in phones of thisContact
                        set telData to¬
                            "tel" & hashSep & value of thisTel & lineSep & ¬
                            "label" & hashSep & label of thisTel & lineSep & ¬
                            "uuid" & hashSep & id of thisTel & lineSep & ¬
                            "p_id" & hashSep & idPerson & lineSep
                        set idTel to do shell script LibPath & "db_new_tel.pl"¬
                            & space & quote & telData & quote
                    end repeat
                end if
                
                -- Emails 
                if (exists emails of thisContact) then
                    repeat with thisEmail in emails of thisContact
                        set emailData to¬
                            "email" & hashSep & value of thisEmail & lineSep & ¬
                            "label" & hashSep & label of thisEmail & lineSep & ¬
                            "uuid" & hashSep & id of thisEmail & lineSep & ¬
                            "p_id" & hashSep & idPerson & lineSep
                        set idEmail to do shell script LibPath & "db_new_email.pl"¬
                            & space & quote & emailData & quote
                    end repeat
                end if
                
                -- Adressen
                if (exists addresses of thisContact) then
                    repeat with thisAdr in addresses of thisContact
                        set adrData to¬
                            "str" & hashSep & street of thisAdr & lineSep & ¬
                            "zip" & hashSep & zip of thisAdr & lineSep & ¬
                            "country" & hashSep & country of thisAdr & lineSep & ¬
                            "place" & hashSep & city of thisAdr & lineSep & ¬
                            "label" & hashSep & label of thisAdr & lineSep & ¬
                            "uuid" & hashSep & id of thisAdr & lineSep & ¬
                            "p_id" & hashSep & idPerson & lineSep
                        set idAdr to do shell script LibPath & "db_new_adr.pl"¬
                            & space & quote & adrData & quote
                    end repeat
                end if
            -- else 
            --     set idPgroups to do shell script LibPath & "db_connect.pl"¬
            --                     & space & quote & contactsData & quote
            end if # end of if (Person ...)
        end repeat
    end tell
    "Anzahl Kontakte hinzugefügt: " &  contactCounter
end getSelectedContacts

on ISOdate(datum)
	if datum = "heute" or datum = "today" or datum = "now" then
		-- gibt den *heutigen* Tag im ISO-Format zurück (yyyy-mm-dd)
		set Tag to day of (current date) as number
		set Monat to month of (current date) as number
		set Jahr to year of (current date) as number
	else
		set Tag to day of datum as number
		set Monat to month of datum as number
		set Jahr to year of datum as number
	end if
	
	-- führende Null für Tag und Monat ergänzen
	if Monat < 10 then
		set Monat to "0" & Monat
	end if
	if Tag < 10 then
		set Tag to "0" & Tag
	end if
	
	set DatumISO to Jahr & "-" & Monat & "-" & Tag
	return DatumISO as text
end ISOdate
