#!/bin/sh
gpasm -p 16F690 main.asm && pk2cmd -PPIC16F690 -Fmain.hex -M
