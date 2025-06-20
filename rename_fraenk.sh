#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
fraenk_dir="$script_dir/fraenk"

if [ ! -d "$fraenk_dir" ]; then
    echo "Fehler: Der Ordner 'fraenk' existiert nicht im aktuellen Verzeichnis."
    exit 1
fi

cd "$fraenk_dir" || exit 1

for file in *.pdf; do
    if [ -f "$file" ]; then
        if [[ $file =~ ^[0-9]{4}-[0-9]{2}\.pdf$ ]]; then
            new_name="fraenk_$file"
            mv "$file" "$script_dir/$new_name"
            echo "Datei umbenannt und verschoben: $file -> $script_dir/$new_name"
        else
            echo "Datei entspricht nicht dem Muster: $file"
        fi
    fi
done

curl -H "Authorization: Token PAPERLESSNGXAPITOKEN" \
    -F document=@/$script_dir/${new_name%}.pdf \
    -F correspondent=7 \
    -F document_type=1 \
    -F tags=1 \
    http://PAPERLESSNGXIPADDRESS:8000/api/documents/post_document/

if [ ! "$(ls -A *.pdf 2>/dev/null)" ]; then
    echo "Keine .pdf Dateien im fraenk-Ordner gefunden."
fi
