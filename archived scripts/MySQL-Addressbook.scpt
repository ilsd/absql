FasdUAS 1.101.10   ��   ��    k             l     ��������  ��  ��        l     	���� 	 I     �������� *0 getselectedcontacts getSelectedContacts��  ��  ��  ��     
  
 l     ��������  ��  ��        l     ��  ��    L F Gibt die Daten des gerade ausgew�hlten Kontaktes im Adressbuch zur�ck     �   �   G i b t   d i e   D a t e n   d e s   g e r a d e   a u s g e w � h l t e n   K o n t a k t e s   i m   A d r e s s b u c h   z u r � c k      i         I      �������� *0 getselectedcontacts getSelectedContacts��  ��    O     @    k    ?       r    	    1    ��
�� 
az48  o      ���� $0 selectedcontacts selectedContacts      l  
 
��  ��    6 0 set thisContact to (item 1 of selectedContacts)     �     `   s e t   t h i s C o n t a c t   t o   ( i t e m   1   o f   s e l e c t e d C o n t a c t s )   ! " ! r   
  # $ # J   
 ����   $ o      ���� 0 alldata allData "  % & % X    = '�� ( ' k    8 ) )  * + * l   ��������  ��  ��   +  , - , l    �� . /��   .XR			-- collect all data of all contacts - maybe we trash this later			set contactsData to {abid:id of thisContact, title:title of thisContact, first_name:first name of thisContact, last_name:last name of thisContact, o_name:organization of thisContact, po_department:department of thisContact}			set allData to allData & {contactsData}    / � 0 0�  	 	 	 - -   c o l l e c t   a l l   d a t a   o f   a l l   c o n t a c t s   -   m a y b e   w e   t r a s h   t h i s   l a t e r  	 	 	 s e t   c o n t a c t s D a t a   t o   { a b i d : i d   o f   t h i s C o n t a c t ,   t i t l e : t i t l e   o f   t h i s C o n t a c t ,   f i r s t _ n a m e : f i r s t   n a m e   o f   t h i s C o n t a c t ,   l a s t _ n a m e : l a s t   n a m e   o f   t h i s C o n t a c t ,   o _ n a m e : o r g a n i z a t i o n   o f   t h i s C o n t a c t ,   p o _ d e p a r t m e n t : d e p a r t m e n t   o f   t h i s C o n t a c t }  	 	 	 s e t   a l l D a t a   t o   a l l D a t a   &   { c o n t a c t s D a t a }  -  1 2 1 l   ��������  ��  ��   2  3 4 3 l   �� 5 6��   5 &   copy the contacts data to MySQL    6 � 7 7 @   c o p y   t h e   c o n t a c t s   d a t a   t o   M y S Q L 4  8 9 8 r    " : ; : m      < < � = = X / U s e r s / i n g o l a n t s c h n e r / L i b r a r y / S c r i p t s / a b s q l / ; o      ���� 0 libpath LibPath 9  > ? > r   # 6 @ A @ I  # 4�� B��
�� .sysoexecTEXT���     TEXT B b   # 0 C D C b   # . E F E b   # * G H G b   # ( I J I b   # & K L K o   # $���� 0 libpath LibPath L m   $ % M M � N N   d b _ n e w _ p e r s o n . p l J 1   & '��
�� 
spac H 1   ( )��
�� 
quot F n   * - O P O 1   + -��
�� 
ID   P o   * +���� 0 thiscontact thisContact D 1   . /��
�� 
quot��   A o      ���� 0 scriptsresult ScriptsResult ?  Q R Q l  7 7�� S T��   S $  TODO: ScriptsResult verwerten    T � U U <   T O D O :   S c r i p t s R e s u l t   v e r w e r t e n R  V�� V l  7 7��������  ��  ��  ��  �� 0 thiscontact thisContact ( o    ���� $0 selectedcontacts selectedContacts &  W�� W l  > >�� X Y��   X  return allData    Y � Z Z  r e t u r n   a l l D a t a��    m      [ [�                                                                                  adrb  alis    d  Macintosh HD               ����H+    �hAddress Book.app                                                #<8Ƀ�u        ����  	                Applications    ��Ѡ      Ƀ�e      �h  *Macintosh HD:Applications:Address Book.app  "  A d d r e s s   B o o k . a p p    M a c i n t o s h   H D  Applications/Address Book.app   / ��     \ ] \ l     ��������  ��  ��   ]  ^ _ ^ l      �� ` a��   `2,

		if (exists addresses of thisContact) then			-- wir finden heraus, ob es work und/oder other Adresse gibt			set workAddressExists to false			set andereAddressExists to false			repeat with thisAddress in addresses of thisContact				if label of thisAddress = "work" or label of thisAddress = "Arbeit" then					set workAddressExists to true				end if				if label of thisAddress = "other" or label of thisAddress = "Andere" then					set andereAddressExists to true				end if			end repeat			-- wenn work, dann nehmen wir die, sonst other			if (workAddressExists) then				repeat with thisAddress in addresses of thisContact					if label of thisAddress = "work" or label of thisAddress = "Arbeit" then						set Daten to Daten & {Str:street of thisAddress}						set Daten to Daten & {PLZ:zip of thisAddress}						set Daten to Daten & {Ort:city of thisAddress}						set Daten to Daten & {LKZ:country of thisAddress}					end if				end repeat			else if (andereAddressExists) then				repeat with thisAddress in addresses of thisContact					if label of thisAddress = "other" or label of thisAddress = "Andere" then						set Daten to Daten & {Str:street of thisAddress}						set Daten to Daten & {PLZ:zip of thisAddress}						set Daten to Daten & {Ort:city of thisAddress}						set Daten to Daten & {LKZ:country of thisAddress}					end if				end repeat			end if		end if				-- Telefon ausw�hlen		if (exists phones of thisContact) then			repeat with thisTel in phones of thisContact				if label of thisTel = "work" or label of thisTel = "Arbeit" then					set Daten to Daten & {Tel:value of thisTel}					exit repeat ## Arbeits-Tel hat Priorit�t				end if				if label of thisTel = "mobile" or label of thisTel = "Mobil" then					set Daten to Daten & {Tel:value of thisTel}				end if				if label of thisTel = "other" or label of thisTel = "Andere" then					set Daten to Daten & {Tel:value of thisTel}				end if			end repeat		end if				-- Email ausw�hlen		if (exists emails of thisContact) then			repeat with thisEmail in emails of thisContact				if label of thisEmail = "work" or label of thisEmail = "Arbeit" then					set Daten to Daten & {Epost:value of thisEmail}					exit repeat ## Arbeits-Email hat Priorit�t				end if				if label of thisEmail = "mobile" or label of thisEmail = "Mobil" then					set Daten to Daten & {Epost:value of thisEmail}				end if				if label of thisEmail = "other" or label of thisEmail = "Andere" then					set Daten to Daten & {Epost:value of thisEmail}				end if			end repeat		end if	
			-- ev. fehlende Felder mit einem Leerzeichen f�llen		try			Str of Daten		on error			set Daten to Daten & {Str:space}		end try				try			PLZ of Daten		on error			set Daten to Daten & {PLZ:space}		end try				try			Ort of Daten		on error			set Daten to Daten & {Ort:space}		end try				try			LKZ of Daten		on error			set Daten to Daten & {LKZ:space}		end try				try			Tel of Daten		on error			set Daten to Daten & {Tel:space}		end try				try			Epost of Daten		on error			set Daten to Daten & {Epost:space}		end try    a � b bX  
 
 	 	 i f   ( e x i s t s   a d d r e s s e s   o f   t h i s C o n t a c t )   t h e n  	 	 	 - -   w i r   f i n d e n   h e r a u s ,   o b   e s   w o r k   u n d / o d e r   o t h e r   A d r e s s e   g i b t  	 	 	 s e t   w o r k A d d r e s s E x i s t s   t o   f a l s e  	 	 	 s e t   a n d e r e A d d r e s s E x i s t s   t o   f a l s e  	 	 	 r e p e a t   w i t h   t h i s A d d r e s s   i n   a d d r e s s e s   o f   t h i s C o n t a c t  	 	 	 	 i f   l a b e l   o f   t h i s A d d r e s s   =   " w o r k "   o r   l a b e l   o f   t h i s A d d r e s s   =   " A r b e i t "   t h e n  	 	 	 	 	 s e t   w o r k A d d r e s s E x i s t s   t o   t r u e  	 	 	 	 e n d   i f  	 	 	 	 i f   l a b e l   o f   t h i s A d d r e s s   =   " o t h e r "   o r   l a b e l   o f   t h i s A d d r e s s   =   " A n d e r e "   t h e n  	 	 	 	 	 s e t   a n d e r e A d d r e s s E x i s t s   t o   t r u e  	 	 	 	 e n d   i f  	 	 	 e n d   r e p e a t  	 	 	 - -   w e n n   w o r k ,   d a n n   n e h m e n   w i r   d i e ,   s o n s t   o t h e r  	 	 	 i f   ( w o r k A d d r e s s E x i s t s )   t h e n  	 	 	 	 r e p e a t   w i t h   t h i s A d d r e s s   i n   a d d r e s s e s   o f   t h i s C o n t a c t  	 	 	 	 	 i f   l a b e l   o f   t h i s A d d r e s s   =   " w o r k "   o r   l a b e l   o f   t h i s A d d r e s s   =   " A r b e i t "   t h e n  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { S t r : s t r e e t   o f   t h i s A d d r e s s }  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { P L Z : z i p   o f   t h i s A d d r e s s }  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { O r t : c i t y   o f   t h i s A d d r e s s }  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { L K Z : c o u n t r y   o f   t h i s A d d r e s s }  	 	 	 	 	 e n d   i f  	 	 	 	 e n d   r e p e a t  	 	 	 e l s e   i f   ( a n d e r e A d d r e s s E x i s t s )   t h e n  	 	 	 	 r e p e a t   w i t h   t h i s A d d r e s s   i n   a d d r e s s e s   o f   t h i s C o n t a c t  	 	 	 	 	 i f   l a b e l   o f   t h i s A d d r e s s   =   " o t h e r "   o r   l a b e l   o f   t h i s A d d r e s s   =   " A n d e r e "   t h e n  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { S t r : s t r e e t   o f   t h i s A d d r e s s }  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { P L Z : z i p   o f   t h i s A d d r e s s }  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { O r t : c i t y   o f   t h i s A d d r e s s }  	 	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { L K Z : c o u n t r y   o f   t h i s A d d r e s s }  	 	 	 	 	 e n d   i f  	 	 	 	 e n d   r e p e a t  	 	 	 e n d   i f  	 	 e n d   i f  	 	  	 	 - -   T e l e f o n   a u s w � h l e n  	 	 i f   ( e x i s t s   p h o n e s   o f   t h i s C o n t a c t )   t h e n  	 	 	 r e p e a t   w i t h   t h i s T e l   i n   p h o n e s   o f   t h i s C o n t a c t  	 	 	 	 i f   l a b e l   o f   t h i s T e l   =   " w o r k "   o r   l a b e l   o f   t h i s T e l   =   " A r b e i t "   t h e n  	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { T e l : v a l u e   o f   t h i s T e l }  	 	 	 	 	 e x i t   r e p e a t   # #   A r b e i t s - T e l   h a t   P r i o r i t � t  	 	 	 	 e n d   i f  	 	 	 	 i f   l a b e l   o f   t h i s T e l   =   " m o b i l e "   o r   l a b e l   o f   t h i s T e l   =   " M o b i l "   t h e n  	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { T e l : v a l u e   o f   t h i s T e l }  	 	 	 	 e n d   i f  	 	 	 	 i f   l a b e l   o f   t h i s T e l   =   " o t h e r "   o r   l a b e l   o f   t h i s T e l   =   " A n d e r e "   t h e n  	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { T e l : v a l u e   o f   t h i s T e l }  	 	 	 	 e n d   i f  	 	 	 e n d   r e p e a t  	 	 e n d   i f  	 	  	 	 - -   E m a i l   a u s w � h l e n  	 	 i f   ( e x i s t s   e m a i l s   o f   t h i s C o n t a c t )   t h e n  	 	 	 r e p e a t   w i t h   t h i s E m a i l   i n   e m a i l s   o f   t h i s C o n t a c t  	 	 	 	 i f   l a b e l   o f   t h i s E m a i l   =   " w o r k "   o r   l a b e l   o f   t h i s E m a i l   =   " A r b e i t "   t h e n  	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { E p o s t : v a l u e   o f   t h i s E m a i l }  	 	 	 	 	 e x i t   r e p e a t   # #   A r b e i t s - E m a i l   h a t   P r i o r i t � t  	 	 	 	 e n d   i f  	 	 	 	 i f   l a b e l   o f   t h i s E m a i l   =   " m o b i l e "   o r   l a b e l   o f   t h i s E m a i l   =   " M o b i l "   t h e n  	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { E p o s t : v a l u e   o f   t h i s E m a i l }  	 	 	 	 e n d   i f  	 	 	 	 i f   l a b e l   o f   t h i s E m a i l   =   " o t h e r "   o r   l a b e l   o f   t h i s E m a i l   =   " A n d e r e "   t h e n  	 	 	 	 	 s e t   D a t e n   t o   D a t e n   &   { E p o s t : v a l u e   o f   t h i s E m a i l }  	 	 	 	 e n d   i f  	 	 	 e n d   r e p e a t  	 	 e n d   i f  	 
 	 	 	 - -   e v .   f e h l e n d e   F e l d e r   m i t   e i n e m   L e e r z e i c h e n   f � l l e n  	 	 t r y  	 	 	 S t r   o f   D a t e n  	 	 o n   e r r o r  	 	 	 s e t   D a t e n   t o   D a t e n   &   { S t r : s p a c e }  	 	 e n d   t r y  	 	  	 	 t r y  	 	 	 P L Z   o f   D a t e n  	 	 o n   e r r o r  	 	 	 s e t   D a t e n   t o   D a t e n   &   { P L Z : s p a c e }  	 	 e n d   t r y  	 	  	 	 t r y  	 	 	 O r t   o f   D a t e n  	 	 o n   e r r o r  	 	 	 s e t   D a t e n   t o   D a t e n   &   { O r t : s p a c e }  	 	 e n d   t r y  	 	  	 	 t r y  	 	 	 L K Z   o f   D a t e n  	 	 o n   e r r o r  	 	 	 s e t   D a t e n   t o   D a t e n   &   { L K Z : s p a c e }  	 	 e n d   t r y  	 	  	 	 t r y  	 	 	 T e l   o f   D a t e n  	 	 o n   e r r o r  	 	 	 s e t   D a t e n   t o   D a t e n   &   { T e l : s p a c e }  	 	 e n d   t r y  	 	  	 	 t r y  	 	 	 E p o s t   o f   D a t e n  	 	 o n   e r r o r  	 	 	 s e t   D a t e n   t o   D a t e n   &   { E p o s t : s p a c e }  	 	 e n d   t r y    _  c�� c l     ��������  ��  ��  ��       �� d e f��   d ������ *0 getselectedcontacts getSelectedContacts
�� .aevtoappnull  �   � **** e �� ���� g h���� *0 getselectedcontacts getSelectedContacts��  ��   g ������������ $0 selectedcontacts selectedContacts�� 0 alldata allData�� 0 thiscontact thisContact�� 0 libpath LibPath�� 0 scriptsresult ScriptsResult h  [�������� < M��������
�� 
az48
�� 
kocl
�� 
cobj
�� .corecnte****       ****
�� 
spac
�� 
quot
�� 
ID  
�� .sysoexecTEXT���     TEXT�� A� =*�,E�OjvE�O -�[��l kh �E�O��%�%�%��,%�%j 
E�OP[OY��OPU f �� i���� j k��
�� .aevtoappnull  �   � **** i k      l l  ����  ��  ��   j   k ���� *0 getselectedcontacts getSelectedContacts�� *j+   ascr  ��ޭ