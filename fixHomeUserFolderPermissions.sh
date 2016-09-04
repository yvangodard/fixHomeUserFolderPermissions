#!/bin/bash

# Variables initialisation
version="fixHomeUserFolderPermissions v0.1 - 2016, Yvan Godard [godardyvan@gmail.com]"
SystemOS=$(sw_vers -productVersion | awk -F "." '{print $0}')
SystemOSMajor=$(sw_vers -productVersion | awk -F "." '{print $1}')
SystemOSMinor=$(sw_vers -productVersion | awk -F "." '{print $2}')
SystemOSPoint=$(sw_vers -productVersion | awk -F "." '{print $3}')
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
listUsers=$(mktemp /tmp/${scriptName}_listUsers.XXXXX)
githubRemoteScript="https://raw.githubusercontent.com/yvangodard/fixHomeUserFolderPermissions/master/fixHomeUserFolderPermissions.sh"

# Exécutable seulement par root
if [ `whoami` != 'root' ]; then
	echo "Ce script doit être utilisé par le compte root. Utilisez 'sudo'."
	exit 1
fi

echo ""
echo "****************************** `date` ******************************"
echo "${scriptName} démarré..."
echo "sur Mac OSX version ${SystemOS}"
echo ""

# Check URL
function checkUrl() {
  command -p curl -Lsf "$1" >/dev/null
  echo "$?"
}

# Changement du séparateur par défaut et mise à jour auto
OLDIFS=$IFS
IFS=$'\n'
# Auto-update script
if [[ $(checkUrl ${githubRemoteScript}) -eq 0 ]] && [[ $(md5 -q "$0") != $(curl -Lsf ${githubRemoteScript} | md5 -q) ]]; then
	[[ -e "$0".old ]] && rm "$0".old
	mv "$0" "$0".old
	curl -Lsf ${githubRemoteScript} >> "$0"
	echo "Une mise à jour de ${0} est disponible."
	echo "Nous la téléchargeons depuis GitHub."
	if [ $? -eq 0 ]; then
		echo "Mise à jour réussie, nous relançons le script."
		chmod +x "$0"
		exec ${0} "$@"
		exit $0
	else
		echo "Un problème a été rencontré pour mettre à jour ${0}."
		echo "Nous poursuivons avec l'ancienne version du script."
	fi
	echo ""
fi
IFS=$OLDIFS

ls -A1 /Users/ | grep -v Guest | grep -v ".localized" > ${listUsers}

if [[ ${SystemOSMajor} -eq 10 && ${SystemOSMinor} -ge 11 ]] || [[ ${SystemOSMajor} -gt 10 ]]; then
	for currentUser in $(cat ${listUsers}) ; do
		echo "Traitement de l'utilisateur '${currentUser}' ..."
		if [[ ${currentUser} == "Shared" ]]; then
	        chmod -R 777 /Users/${currentUser}
	    else
	    	# userID=$(dscl . -read /Users/${currentUser} UniqueID | awk '{print $2}')
			userID=$(/usr/bin/id -u ${currentUser})
			# Reset the users Home Folder permissions.
			/usr/sbin/diskutil resetUserPermissions / ${userID}
		fi
		echo ""
	done
elif [[ ${SystemOSMajor} -eq 10 && ${SystemOSMinor} -le 10 ]]; then
	for currentUser in $(cat ${listUsers}) ; do
		echo "Traitement de l'utilisateur '${currentUser}' ..."
		if [[ ${currentUser} == "Shared" ]]; then
	        chmod -R 777 /Users/${currentUser}
	    else
	    	# Suppression des ACL
	    	chmod -R -N /Users/${currentUser}
	    	chflags -R nouchg,nouappnd ~ $TMPDIR..
	    	# Correction du propriétaire
	    	chown -R ${currentUser}:staff /Users/${currentUser}
	    	# Droits par défaut
	    	chmod -R 700 /Users/${currentUser}
	    	# Droit d'accès au dossier
	        chmod 755 /Users/${currentUser}
	        chmod -R 755 /Users/${currentUser}/Public/
	        chmod -R 733 /Users/${currentUser}/Public/Drop\ Box/
	        chmod -R 755 /Users/${currentUser}/Sites/
	        chmod -R 644 /Users/${currentUser}/Sites/*
	        chmod -R 755 /Users/${currentUser}/Sites/images/
	    fi
	    echo ""
	done
fi

[ -e ${listUsers} ] && rm ${listUsers}
echo "Fin du processus."
exit 0