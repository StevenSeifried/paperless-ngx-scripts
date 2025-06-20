#!/bin/bash
set -e
check_filename() {
    local filename="$1"
    [[ $filename =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}_[0-9]+\.jpg\.png$ ]]
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
lidl_dir="$script_dir/Lidl"

if [ ! -d "$lidl_dir" ]; then
    echo "Fehler: Der Ordner 'Lidl' existiert nicht im aktuellen Verzeichnis."
    exit 1
fi

cd "$lidl_dir" || exit 1

for file in *.png; do
    if [ -f "$file" ]; then
        if check_filename "$file"; then
            date_part="${file:0:10}"
            new_name="Lidl_Koenigsbrunn_${date_part}.png"
            mv "$file" "$script_dir/$new_name"
            echo "Datei umbenannt und verschoben: $file -> $script_dir/$new_name"
            
            curl -X 'POST' \
              'http://STIRLINGPDFIPADDRESS:8080/api/v1/convert/img/pdf' \
              -H 'accept: */*' \
              -H 'Content-Type: multipart/form-data' \
              -F "fileInput=@$script_dir/$new_name;type=image/png" \
              -F 'fitOption=fitDocumentToImage' \
              -F 'colorType=color' \
              -F 'autoRotate=false' \
              -o "$script_dir/${new_name%.png}.pdf"
            
            echo "Datei zu PDF konvertiert: $script_dir/${new_name%.png}.pdf"
            
            curl -H "Authorization: Token PAPERLESSNGXAPITOKEN" \
            -F document=@/$script_dir/${new_name%.png}.pdf \
               -F correspondent=2 \
               -F document_type=3 \
               -F tags=3 \
                http://PAPERLESSNGXIPADDRESS:8000/api/documents/post_document/

            rm "$script_dir/$new_name"
            echo "Ursprüngliche PNG-Datei gelöscht: $script_dir/$new_name"
        else
            echo "Datei entspricht nicht dem Muster: $file"
        fi
    fi
done

if [ ! "$(ls -A *.png 2>/dev/null)" ]; then
    echo "Keine .png Dateien im Lidl-Ordner gefunden."
fi
