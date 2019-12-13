# ingress-decoding-13archetypes

The 13 Archetypes challenge is a set of 13 decoding challenges, one released
each week starting on December 9, 2019. The original announcement is
[here](https://community.ingress.com/en/discussion/7505/13-archetypes-challenge).
Discussions about the challenges are
[here](https://community.ingress.com/en/categories/decoding-challenges). The
scoreboard is [here](https://ingress.com/decoding/13archetypes).

## Dreamer

Dreamer was a challenge which presented an [image](https://storage.googleapis.com/ingress-internal-event-data/13archetypes/dreamer/RECURSEDSHEEP_9b290bff-96d6-504f-becb-e9824ee71f0d.png) of two sheep in a bed with the
caption "Do Simulacra Dream of Recursed Sheep"?  The original post is
[here](https://community.ingress.com/en/discussion/7558/13-archetypes-dreamer).

### Walkthrough

A [Code 128C](https://en.wikipedia.org/wiki/Code_128) barcode is embedded into
the tartan pattern on the bed cover. The first half of the barcode is read
horizontally across the tartan. The second half is read by rotating the tartan
90 degrees. The <span style="color: green">green</span> bars as read as black
and the <span style="color: blue">blue</span> bars as white.

One approach is to visually count the bars and convert according to the Code 128C specification. Another approach is to create a scannable barcode by extracting the barcode from the image.
[ImageMagick](https://imagemagick.org/index.php) is a command-line tool that can be used to select the area of the image
containing the barcode, convert the appropriate colors to black and white,
rotate the vertical barcode, and combine the two halves side-by-side. The
following Bash function creates a scannable barcode using ImageMagick.

``` sh
extract_barcode () {
    # Extract barcode from the image file.
    IMAGE_FILE=$1
    BARCODE_FILENAME="code128"
    BARCODE_FILE="$BARCODE_FILENAME".bmp
    BARCODE_H_FILE="$BARCODE_FILENAME"_h.bmp
    BARCODE_V_FILE="$BARCODE_FILENAME"_v.bmp
    WHITE_COLOR='srgb(125,125,125)' # This is a grey color where the blue & green overlap

    # Grab a 576x8 sample from the tartan, turn the green bits black and the
    # greyish bits opaque, flip it all monochrome, invert color, and stretch it
    # to 576x576.
    convert $IMAGE_FILE \
        -crop 576x8+330+207 \
        -fill black -fuzz 25% +opaque $WHITE_COLOR \
        -monochrome \
        -negate \
        -sample 576x576\! \
        "$BARCODE_H_FILE" # 2547766575567

    # Grab a 8x576 samples from the tartan, turn the blue bits black and the
    # greyish bits opaque, and do the rest like the first half except also
    # rotate 90 clockwise.
    convert $IMAGE_FILE \
        -crop 8x576+330+207 \
        -fill black -fuzz 25% +opaque $WHITE_COLOR \
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
```

The barcode decodes into 23 two-digit numbers. You can read the Code128C
specification to decode it by hand or use barcode scanning software.
[Zxing](https://github.com/zxing/zxing) is a barcode scanning library for Java
which can also be built to use as a command-line tool. Here are the steps to
build it on Debian systems:

``` sh
apt-get update \
 && apt-get install -y git maven
 && rm -rf /var/lib/apt/lists/*
cd /opt
git clone https://github.com/zxing/zxing.git
cd /opt/zxing
mvn install -Dmaven.javadoc.skip=true
cd /opt/zxing/javase
mvn -DskipTests -Dmaven.javadoc.skip=true package assembly:single
```

Here is a Bash function to run the built Zxing and print only the raw data
extracted from the barcode:

``` sh
decode_barcode () {
    # Decode a barcode image into data
    BARCODE_FILE=$1

    # Decode barcode
    java -jar /opt/zxing/javase/target/javase-3.4.1-SNAPSHOT-jar-with-dependencies.jar $BARCODE_FILE | awk '/Raw result:/{getline; print}'
}
```

Each two-digit number corresponds to the ASCII value of a character. Here is a
Bash function to translate the numeric string into the corresponding ASCII
characters:

``` sh
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
```

The passcode is in the format `aaa#aakeyword##aa` where `a` represents one
letter, `#` represents one digit, and `keyword` represents a word of unspecified
length. Each digit is encoded as the first three letters of its name. For
example, `ZER` decodes to `0` and `ONE` decodes to `1`. Here is a function to
munge the ASCII characters into the passcode:

``` sh
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
```

Now submit that passcode!