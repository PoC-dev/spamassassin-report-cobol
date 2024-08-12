//HERC04MB  JOB   USER=HERC04,PASSWORD=PASS4U,MSGCLASS=A
//* Create a new, bigger file, and copy the old stuff.
//CPYDTA    EXEC  PGM=IEBGENER
//SYSIN     DD    DUMMY
//SYSPRINT  DD    SYSOUT=*
//SYSUT1    DD    DSN=HERC04.SSTATS.INPILE,DISP=(OLD,DELETE)
//SYSUT2    DD    DSN=HERC04.SSTATS.NEWPILE,DISP=(NEW,CATLG),
//          UNIT=SYSDA,VOL=SER=PUB013,
//          SPACE=(CYL,(50,32)),
//          DCB=(DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=27920)
//
//* Rename the new file to the old name.
//RNMF      EXEC  PGM=IDCAMS
//SYSPRINT  DD    SYSOUT=*
//SYSIN     DD    *
  RENAME SSTATS.NEWPILE SSTATS.INPILE
/*
