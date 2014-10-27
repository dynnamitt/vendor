3.parts prosjekter som skal inn på Debian runtime server
========================================================

bash funksjoner for å lage .deb filer 

	 source ./buildfuncs.sh


Apache setup:

	Alias /xopus/ /usr/share/xopus4/
	<Directory /usr/share/xopus4 >
		AllowOverride None
		Order allow,deny
		allow from all
	</Directory>
	
	Alias /font-awesome/ /usr/share/Font-Awesome/
	<Directory /usr/share/Font-Awesome/ >
		AllowOverride None
		Order allow,deny
		allow from all
	</Directory>

.
