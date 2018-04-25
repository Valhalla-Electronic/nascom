# Converters

Here are PERL programs for converting NASCOM files between different formats.

* nas2cas - convert .nas format to .cas
* cas2nas - convert .cas format to .nas (also spits out a binary file)
* sy_extract - Polydos allowed creation of a symbol table in a compiled format that could be read in to the polyzap assembler. This program reads a symbol table in this compiled format and writes it out as a set of equates.


## NASCOM File formats

Files for use with NASCOM emulators are commonly of 2 file types: .nas and .cas

A .nas file is ASCII text, a hex dump in the format produced by the NAS-SYS "T" command.

In a real system, a .nas file would be loaded into memory using the NAS-SYS 1
"L" command (the "L" command was removed from NAS-SYS 3). In emulation, a .nas
file is typically loaded directly into memory under the control of the emulator.

A .cas file is binary, in the cassette tape format produced by the NAS-SYS "W"
or "G" commands or by programs that use the NAS-SYS sub-routines (e.g. NASCOM 8K
ROM BASIC).

In a real system. a .cas file represents the byte stream that would be recovered
from the cassette interface and loaded into memory under the control of the
NAS-SYS "R" command. In emulation, a .cas file is typically presented by the
emulator as a serial byte stream that is read by the emulated cassette
interface.


### .cas format

by default it is just a sequence of binary blocks. The format can be inferred
from the NAS-SYS listing.

However..

.. if it is a BASIC program it has a header which is a single letter.

BASIC will not load a program until it has found one of these headers. From
BASIC, CLOAD with no argument will read the *next* header and its data. CLOAD
with an argument will report each header in turn until it finds the right one,
and will then load.

The header has this format:

    0xd3 0xd3 0xd3 0xZZ

where ZZ is the "file-name"

When NAS-SYS is waiting for input from the keyboard, it will also accept input
from tape. Therefore, some .cas (and .nas) files also have ASCII text strings
before/after the main program data.

For example, a .cas file generated by the NAS-SYS 3 "G" command has this format:

    (CR)E0(CR)R(CR)

then data in the same format as the "W" command, then

    Ezzzz(CR)

where zzzz is the execution address of the program, as supplied to the G command.


### .nas format

Lines are in one of 2 formats:

1/ a 4-digit hex load address value followed by between 1 and 8 2-digit hex data
values. Each value is space-separated from the others. For example:

    1000 0A 0A 91 57 91 3D 53 E8
    1008 11 6A C5 12 96

2/ a 4-digit hex load address value followed by 9 2-digit hex data values. Each
value is space-separated from the others. In this case, the 9th value is the
mod-256 sum of the 10 previous bytes (the address counts as 2 bytes). For example:

    1000 0A 0A 91 57 91 3D 53 E8 15
    1008 11 6A C5 12 96 A8 14 51 0D

In both cases, the line ends with a (CR). In some cases, there are CTRL-H and
NUL (ASCII 0) characters at the end of the line before the (CR).

In principle, the two formats can be mixed in a single file. However, if they
were generated by NAS-SYS all lines in a file will be in the same format.

Some .nas files seem to have other line-ending formats, for example (CR)(LF)

If a .nas file was being loaded on a real system under the control of NAS--SYS,
it would be loaded using the "L" command. The "L" command is terminated by a "."
and therefore some .nas files end in the same way. For example:

    2938 25 CA 26 DE 27 66 27 FA
    2940 27 43 28 72
    .

An emulator that loads .nas files directly into memory should ignore the "."



### nas2cas

parse a .nas file. Generate the equivalent .cas file. By default there is no additional header
or trailer.

FUTURES/TODO:

    -g zzzz -- add ASCII header/trailer in NAS-SYS "G"enerate format, with an execution address of zzzz
    -b Z    -- add MBASIC header with file-name Z


### cas2nas

parse a .cas file. Report any header/trailer information. Generate the equivalent .nas file. By default
there is no additional header or trailer.

FUTURES/TODO:

    -t      -- add "." trailer