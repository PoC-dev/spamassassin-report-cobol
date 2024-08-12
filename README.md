This is an attempt to give an emulated mainframe some meaningful work by accumulating statistical data from syslog output of a mail server's Spamassassin log entries, and run a statistics program over the data to gather some insight.

**Note:** This project contains hard coded username *HERC04* and the accompanying password *PASS4U* in many places. This is intentionally and explained later.

## License.
This document is part of the *spamassassin-report-cobol* project, to be found on [GitHub](https://github.com/PoC-dev/spamassassin-report-cobol). Its content is subject to the [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) license, also known as *Attribution-ShareAlike 4.0 International*. The project itself is subject to the GNU Public License version 2.

## Environment preparation.
Required parts:
- Hercules as part of a Turnkey environment
- Logtail (part of the logcheck package)
- Netcat
- Perl

There are two scripts meant to run in a Linux environment.
- `sa-parse-syslog.sh` utilizes *logtail* to find new data in */var/log/mail.log* since the last run, and feeds this to *sa-parse-syslog.pl*.
- `sa-parse-syslog.pl` parses the data on *stdin* and generates a JCL job stream for feeding to the emulated card reader of Hercules, usually listening on TCP port 3505. This new data is appended to *herc04.sstats.inpile*.
- `submit` is a shell script for quickly feeding JCL files to the emulated card reader via *netcat*.

**Note:** I'm using classic SysV-init and Syslog instead of Systemd + Journalctl. Necessary modifications to *sa-parse-syslog.sh* are left as exercise to the reader.

### Hercules and the turnkey environment.
[Hercules](https://en.wikipedia.org/wiki/Hercules_(emulator)) is an emulator mimicking the classic IBM mainframe hardware. It runs on many Unix-like operating systems as well as Microsoft Windows.

IBM [MVS](https://en.wikipedia.org/wiki/MVS) is one of several historic operating systems for IBM mainframes. It eventually evolved into modern z/OS. Releases up to MVS version 3.8j — released in 1981 — were freely available and have been recovered from the original install tapes by the hobbyist community.

The turnkey environment is a readymade bundle of precompiled Hercules binaries together with a preinstalled and preconfigured MVS 3.8j. Turnkey as in "unpack, run". The most recent incarnation of the Turnkey environment is [TK5](https://www.prince-webdesign.nl/tk5). For further information, refer to the *TK5 introduction and User Manual* on the TK5 website. Obtaining and running TK5 is out of scope of this document.

**Note:** To interactively use MVS, you need a special terminal emulator, capable of interpreting and displaying the 3270 data stream. On Linux, you can install and use *c3270* (terminal) or *x3270* (for local GUI environments).

### MVS intricacies.
The heritage of MVS implies that the operation of programs favors [batch processing](https://en.wikipedia.org/wiki/Batch_processing), in contrast to interactively working with the computer in a dialog-like manner.

To tell the operating system what to do, [JCL](https://en.wikipedia.org/wiki/Job_Control_Language) statements are used. This project contains a bunch of JCL files for preparing the working environment within MVS.

**Note:** The turnkey environment historically has four users defined, *herc01* through *herc04*. The latter is a normal, non-admin user. This is why I chose to use this one. Of course, one can change the files in this project to an arbitrary user profile, which has to be created prior.

- Files are called [data sets](https://en.wikipedia.org/wiki/Data_set_(IBM_mainframe)) in MVS lingo.
- Files are [record oriented](https://en.wikipedia.org/wiki/Record-oriented_filesystem) as opposed to an more or less unstructured stream of bytes on common operating systems.
- Files need to be defined and are automatically preallocated to the defined size.
  - Extents allow limited automatic growth
- Data sets come basically in two flavors:
  - ordinary data sets are the equivalent to an ordinary file on common operating systems.
  - partitioned data sets (PDS) can be understood as an archive of files (called members) with a common record length, and were a countermeasure against wasted space due to e. g. many small text files being allocated a full disk block but rarely filling said block. Accessing data in a PDS is more "expensive" in terms of work for the computer than in a normal data set.
- Data sets to be used aren't opened "dynamically" in application programs, but they are defined in JCL and the [JCL "interpreter"](https://en.wikipedia.org/wiki/Job_Entry_Subsystem_2/3) passes the opened file descriptors to the application program being launched. Application programs merely have a "fake" name defined which is mapped to a real data set with JCL `dd` statements.

Output of program runs is traditionally directed to printers. The turnkey environment defines two printers whose output is directed to text files in the *prt* subdirectory of the turnkey directory. The printer output for most jobs ends up in *prt/prt00e.txt*. A good way on Linux to observe what's happening is to use a separate terminal window with 132 chars width, and run `tail -f prt/prt00e.txt` in there.

## MVS setup.
That being said, we're about to create three data sets:
- `herc04.sstats.inpile` is a normal, big file where statistics data is appended to
- `herc04.sstats.loadlib` is a PDS where the compiled application program ends up
- `herc04.sstats.src` is a PDS where at least COBOL source ends up

To instruct MVS what it should do, a bunch of JCL files is provided:
- `crtpile.jcl` creates the data set *herc04.sstats.inpile* with ample space
- `crtloadlib.jcl` creates the PDS *herc04.sstats.loadlib* for the compiled application `sstats`
- `crtsrcpf.jcl` creates the PDS *herc04.sstats.src* for source code and further JCLs at your leisure
- `cpysrc.jcl` copies the actual COBOL source to *herc04.sstats.src(sstats)*
- `compile.jcl` compiles the source in *herc04.sstats.src(sstats)* and puts the result into *herc04.sstats.loadlib(sstats)*

You can use the accompanying `submit` script to feed the JCLs one by one in the order given to MVS, while watching the printer output for errors. Hint: `RC=0` means success.

Further JCLs:
- `runstats.jcl` runs *herc04.sstats.loadlib(sstats)* with *herc04.sstats.inpile* as source, and prints collected statistics
- `mkbigger.jcl` is provided to allocate a new (bigger) *inpile* data set, copy over the data from the previous one, delete the old and rename the new to the old one

When done, let *sa-parse-syslog.sh* upload some data, and submit *runstats.jcl* to see a summary of the statistics data.

Finally you can run *sa-parse-syslog.sh* from cron, e. g. each hour.

## Bugs.
- This documentation possibly omits many possible pitfalls and how to recover from them.
- The described procedures have been derived from a working TK4- system and underwent no subsequent testing.
- The COBOL code is very crude, because the turnkey systems includes an ancient COBOL compiler from the late 1960's. There is no newer, free compiler available. I was not able to grok how to properly feed it signed (negative) numbers as text, so it understands it's still a number.

Feedback is well appreciated for expanding this documentation.

----

2024-08-12 poc@pocnet.net
