# Automatically caches settings in the code
# (turns calls to ctf.setting into constants)

echo Creating build directory $1
rm -fr $1
mkdir $1

echo Copying files
rsync -av --exclude=".*" . $1 > /tmp/0

# Read CSV files
echo Replacing settings...
INPUT=settings_cache.csv
OLDIFS=$IFS
IFS="   "
[ ! -f $INPUT ] &while read sName sValue
do
        # Trim sName
        sName="$(echo -e "${sName}" | sed -e 's/[[:space:]]*$//')"

        # Replace in all files
        grep -rl "ctf.setting($sName)" $1 | xargs sed -i "s/ctf.setting($sName)/$sValue/g"

        # Print message
        echo "Replacing ctf.setting($sName) with $sValue"
done < $INPUT
IFS=$OLDIFS

echo Done
