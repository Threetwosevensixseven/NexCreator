# NexCreator
Fork of NexCreator, a big file format for the ZX Spectrum Next.

[NexCreator](https://gitlab.com/thesmog358/tbblue/blob/master/src/c/NexCreator.c) is (C) 2018 Jim Bagley.

* Added a test program which can load all 224 of the ZX Spectrum Next 8K MMU RAM banks, and print a value to verify the contents are as expected.

![Test program](https://github.com/Threetwosevensixseven/NexCreator/raw/master/images/test-program.png)

* Added the optional ability to exclude one or more of the eight 128K banks from the input SNA file. This allows you to avoid overwriting BASIC or NextZXOS system variables, but still include some code, the PC and the SP from the input SNA file.

* Added the optional ability to specify the PC and SP without including an input SNA file. This also facilitates creating BASIC- and NextZXOS-friendly .nex files.

![Example Files](https://github.com/Threetwosevensixseven/NexCreator/raw/master/images/example-files.png)

* Changed the way that 2MB RAM .nex files are specified. Instead of counting the banks, a .nex file is 2MB if any of the 16K banks bank numbers are larger than 47.
