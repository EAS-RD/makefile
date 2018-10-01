#!/bin/sh
if [ "" = "$1" ]; then
  echo "Syntax :"
  echo "${0} <project_name>"
  exit 1
fi

# Executes shell command (second argument), controls return value,
# and displays message on error. This message corresponds to the
# first argument.
cmdControl () {
    if [ "$2" != "" ]; then
        echo "-> ${2}"
        eval "${2}"
        if [ "$?" != "0" ]; then
            case "$1" in
                "D") echo "Decompress error !"
                     exit 1
                     ;;
                "C") echo "Create error !"
                     exit 2
                     ;;
                "R") echo "Rename error !"
                     exit 3
                     ;;
            esac
        fi
    fi
}
# Decompress files
cmdControl "D" "tar -xzf makonvert.tar.gz"
rm makonvert.tar.gz

# Creates the necessary files
cmdControl "R" "mv org.eclipse.cdt.core.prefs .settings/org.eclipse.cdt.core.prefs"
cmdControl "C" "echo \"1\" > rev-number.txt"
cmdControl "C" "echo \"1.0.0\" > vers-number.txt"

# Adapts the files to the project
cmdControl "R" "mv template.doxyfile ${1}.doxyfile"
find . -type f -exec sed -i "s/xTemplatex/${1}/g" '{}' +

rm makonvert.sh

