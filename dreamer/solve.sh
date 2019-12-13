#!/bin/bash
# Solves the Dreamer puzzle
# https://community.ingress.com/en/discussion/7558/13-archetypes-dreamer
set -e
IMAGE_FILE=$1 #https://storage.googleapis.com/ingress-internal-event-data/13archetypes/dreamer/RECURSEDSHEEP_9b290bff-96d6-504f-becb-e9824ee71f0d.png

identify () {
    # Get some info about the image. This isn't necessary to solve the puzzle.
    IMAGE_FILE=$1
    command identify -verbose $IMAGE_FILE
}

extract_colors () {
    # For each color, create a new image file where that color is white and all
    # other colors are black. This isn't necessary to solve the puzzle.
    IMAGE_FILE=$1

    # Get a list of unique colors
    convert $IMAGE_FILE txt:- \
    | awk '{ print $4; }' \
    | sort | uniq \
    | awk '{ print $2 }' > unique_colors.txt

    while read -r COLOR; do
        convert $IMAGE_FILE \
        -fill black \
        +opaque $COLOR \
        -monochrome \
        $COLOR.bmp
    done < unique_colors.txt
}

extract_barcode () {
    # Extract barcode from the image file.
    IMAGE_FILE=$1
    BARCODE_FILENAME="code128"
    BARCODE_FILE="$BARCODE_FILENAME".bmp
    BARCODE_H_FILE="$BARCODE_FILENAME"_h.bmp
    BARCODE_V_FILE="$BARCODE_FILENAME"_v.bmp

    # Grab a 576x8 sample from the tartan, turn the green bits black and the
    # greyish bits opaque, flip it all monochrome, invert color, and stretch it
    # to 576x576.
    convert $IMAGE_FILE \
        -crop 576x8+330+207 \
        -fill black -fuzz 25% +opaque 'srgb(125,125,125)' \
        -monochrome \
        -negate \
        -sample 576x576\! \
        "$BARCODE_H_FILE" # 2547766575567

    # Grab a 8x576 samples from the tartan, turn the blue bits black and the
    # greyish bits opaque, and do the rest like the first half except also
    # rotate 90 clockwise.
    convert $IMAGE_FILE \
        -crop 8x576+330+207 \
        -fill black -fuzz 25% +opaque 'srgb(125,125,125)' \
        -monochrome \
        -negate \
        -sample 576x576\! \
        -rotate 90 \
        "$BARCODE_V_FILE"

    # Combine the barcodes side-by-side and add a Code128-compliant border
    convert "$BARCODE_H_FILE" "$BARCODE_V_FILE" +append \
        -matte -bordercolor white -border 40 \
        "$BARCODE_FILE"
    rm -rf "$BARCODE_H_FILE" "$BARCODE_V_FILE"
    echo "$BARCODE_FILE"
}

decode_barcode () {
    # Decode a barcode image into data
    BARCODE_FILE=$1

    # Decode barcode
    java -jar zxing/javase/target/javase-3.4.1-SNAPSHOT-jar-with-dependencies.jar $BARCODE_FILE | awk '/Raw result:/{getline; print}'
}

dec2asc() {
    # Convert a decimal string to ASCII (2-digit numbers only)
    DEC_STRING=$1

    SPLITTED=$(echo $DEC_STRING | gawk '{gsub(/.{2}/,"& ")}1')
    ASCII_STRING=""
    for i in $SPLITTED; do
        c=$(printf \\$(printf '%02o' $i))
        ASCII_STRING+=$c
    done
    echo $ASCII_STRING    
}

munge () {
    # Munge a string into aaa#aakeyword##aa format
    FORMAT=(a a a d d d a a w w w w w w w d d d d d d a a)
    STRING=$1
    SPLITTED=$(echo $STRING | gawk '{gsub(/.{1}/,"& ")}1')
    IFS=', ' read -r -a arr <<< $SPLITTED
    munged=""
    for (( i=0; i<${#arr[@]}; i++)); do
        case ${FORMAT[$i]} in
            a)
                letter=${arr[$i]}
                munged+=$letter
                ;;
            d)
                printf -v numstring "%s" "${arr[@]:$i:3}"
                # translate THR to 3 and ONE to 1
                if [ $numstring == "ONE" ]; then
                    number=1
                elif [ $numstring == "THR" ]; then
                    number=3
                fi
                munged+=$number
                ((i+=2))
                ;;
            w)
                word=${string:$i:7}
                munged+=$word
                ((i+=6))
                ;;
        esac
    done
    echo $munged
}

BARCODE_FILE=$(extract_barcode "$IMAGE_FILE")
NUMBERS=$(decode_barcode "$BARCODE_FILE")
ASCII=$(dec2asc $NUMBERS)
ANSWER=$(munge "$ASCII")
echo $ANSWER