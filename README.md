# NexCreator
Fork of [NexCreator](https://gitlab.com/thesmog358/tbblue/blob/master/src/c/NexCreator.c), a big file format for the [ZX Spectrum Next](https://www.specnext.com/about/).

NexCreator is © 2018 Jim Bagley.

## Download

Download a 32-bit Windows version of this fork [here](https://github.com/Threetwosevensixseven/NexCreator/raw/master/vs/Debug/NexCreator.exe).

## Additions

* Added a test program which can load all 224 of the ZX Spectrum Next 8K MMU RAM banks, and print a value to verify the contents are as expected.

![Test program](https://github.com/Threetwosevensixseven/NexCreator/raw/master/images/test-program.png)

* Added the optional ability to exclude one or more of the eight 128K banks from the input SNA file. This allows you to avoid overwriting BASIC or NextZXOS system variables, but still include some code, the PC and the SP from the input SNA file.

* Added the optional ability to specify the PC and SP without including an input SNA file. This also facilitates creating BASIC- and NextZXOS-friendly .nex files.

![Example Files](https://github.com/Threetwosevensixseven/NexCreator/raw/master/images/example-files.png)

* Changed the way that 2MB RAM .nex files are specified. Instead of counting the banks, a .nex file is 2MB if any of the 16K banks bank numbers are larger than 47.

* Added the optional ability to specify 8KB files and 8KB bank numbers with the !MMU token, instead of 16KB files and 16KB bank numbers.

![8KB Bank Example](https://github.com/Threetwosevensixseven/NexCreator/raw/master/images/example-8k-banks.png)

* Added the optional ability to specify a 16K bank to get paged in at $C000 before jumping to the PC. This can be specified with the !BANK token or with the third argument of the !PCSP token. This bank defaults to 0 (16K page 0) if not specified.

  This allows the contents of your NEX file to completely avoid overwriting any of the 128K banks, in particular the BASIC sysvars in page 5 and NextZXOS working data in pages 7 and 8. [NextZXOS API calls](https://gitlab.com/thesmog358/tbblue/blob/master/docs/nextzxos/NextZXOS_API.pdf) can now be safely made from your BASIC or machine code program. 

![BASIC-Friendly Example](https://github.com/Threetwosevensixseven/NexCreator/raw/master/images/example-basic-friendly.png)

* Modified .nexload dot command to print error messages in the top screen, and raise a custom BASIC error.  

* .nexload gives a custom BASIC nexload update error when it encounters .nex files newer than it can handle.  

* .nexload gives a custom BASIC core update error when it encounters .nex files requiring core version newer than the current core.

## Acknowledgements
### NexCreator
NexCreator is © 2018 Jim Bagley.

Jim's original version can be found [here](https://gitlab.com/thesmog358/tbblue/raw/master/tools/dev/NexCreator/NexCreator.exe?inline=false), with the source code [here](https://gitlab.com/thesmog358/tbblue/blob/master/src/c/NexCreator.c).

The NextZXOS .nexload dot command to load these files can be found [here](https://gitlab.com/thesmog358/tbblue/raw/master/dot/NEXLOAD?inline=false), with the source code [here](https://gitlab.com/thesmog358/tbblue/blob/master/src/asm/nexload/nexload.asm).

### FZX
The test program includes a derivation of the [FZX font driver](https://spectrumcomputing.co.uk/index.php?cat=96&id=28171).

FZX font driver - Copyright (c) 2013 Einar Saukas  
FZX font format - Copyright (c) 2013 Andrew Owen  

FZX is a royalty-free compact font file format designed primarily for storing bitmap fonts for 8 bit computers, primarily the Sinclair ZX Spectrum, although also adopting it for other platforms is welcome and encouraged!

FZX has the following features:

* proportional spacing
* characters can be up to 16 pixels in width
* characters can be up to 192 pixels in height
* up to 224 characters per font (code 32 to 255)

You can freely use the FZX driver code in your programs (even for commercial releases), or adapt this code according to your needs. In particular, porting this code to other platforms is permitted and encouraged.

The only requirement is that you must clearly indicate in your documentation that you have either used this code or created a derivative work based on it.

The FZX font format is an open standard. You can freely use it to design and distribute new fonts, or use it inside any programs (even commercial releases). The only requirement is that this standard should be strictly followed, without making irregular changes that could potentially cause incompatibilities between fonts and programs on different platforms.
