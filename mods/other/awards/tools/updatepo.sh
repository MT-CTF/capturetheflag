#! /bin/bash

# To create a new translation:
#   msginit --locale=ll_CC -o locale/ll_CC.po -i locale/template.pot

cd "$(dirname "${BASH_SOURCE[0]}")/..";

# Extract translatable strings.
xgettext --from-code=UTF-8 \
		--keyword=S \
		--keyword=NS:1,2 \
		--keyword=N_ \
		--add-comments='Translators:' \
		--add-location=file \
		-o locale/template.pot \
		$(find . -name '*.lua')

# Update translations.
find locale -name '*.po' | while read -r file; do
	echo $file
	msgmerge --update $file locale/template.pot;
done
