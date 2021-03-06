# Nascom

Software, utilities and documentation for the Z80-based Nascom computers.

* PolyDos - code and documentaton for this excellent Nascom operating-system
* converters - scripts for manipulating Nascom disk and binary images
* gm808_eprom_programmer - code, photos and documentation for this 2708/2716 EPROM programmer
* hw_sim - verilog simulation of the Nascom 1 video sub-system
* docs
  * Nascom 1 RAM expansion (tested)
  * Nascom 2 RAM expansion (untested)
* sdcard - Arduino-based SDcard storage. There are 2 versions:
  * A version that connects to the serial port instead of a tape recorder, and works with NAS-SYS tape commands
  * A version that connects to the PIO, with all supporting software to run PolyDos and to extract data from your old floppies
  * NEW: a PCB and a detailed user guide

## Projects in planning

At the concept stage..

* An adaptor to allow a PS/2 PC keyboard to be attached to a Nascom 1 or Nascom 2
* A new hardware design that is 100% software compatible with the Nascom 1/2 but can connect to VGA and PS/2 keyboard
* Get Nascom CP/M running on a Nascom 2 without the need for a special NASMD PROM

## Comments/improvements

* Email me or use the 'issues' button at the top on the github page.

* Fork the project and make a merge request

