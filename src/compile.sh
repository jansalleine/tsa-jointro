#!/bin/sh
OUTFILE="../jointro-tsa".prg

rm -f "$OUTFILE"

acme -v4 -f cbm -l labels.asm -o out.prg main.asm

STARTADDR=$(grep "code_start" labels.asm | cut -d$ -f2)
exomizer3 sfx 0x$STARTADDR -s "lda #\$0b sta \$d011" -x3 -o "$OUTFILE" out.prg

rm -f out.prg

if [ -z "$1" ]
then
    rm -f labels.asm
    vice -VICIIborders 0 -VICIIfilter 1 "$OUTFILE"
else
    vice -VICIIborders 2 -VICIIfilter 0 "$OUTFILE"
fi
