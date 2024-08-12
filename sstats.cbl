      ******************************************************************
      * PROGRAM DESCRIPTION:
      *   Reads statistics reports of Spamassassin,
      *   and calculates a summary for each month
      *   present in the input file.
      *   Report itself is written to SYSOUT.
      *
      * Example Inpile Record:
      * 1       10        20        30        40
      * +---+----+----+----+----+----+----+----+----+
      * Jan  3 05:54:00 -     5.10    2.9        3353
      * Jan  3 06:00:45      22.80    3.5       22882
      * Jan  3 06:03:29 -     0.40    3.7       97417
      * Jan  3 06:23:17 -    64.60    4.6       57721
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.   'SSTATS'.
       AUTHOR.       'Patrik Schindler, <poc@pocnet.net>'.
       INSTALLATION. 'MVS 3.8J TK4-'.
       DATE-WRITTEN. '2021-01-08'.
       DATE-COMPILED.
       REMARKS.      'NONE'.
      ******************************************************************
       ENVIRONMENT DIVISION.
      *=================================================================
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPILE-FILE  ASSIGN TO DA-S-SINPILE
                               ACCESS IS SEQUENTIAL.
      ******************************************************************
       DATA DIVISION.
      *=================================================================
       FILE SECTION.
      *-----------------------------------------------------------------
      * We should match record length of the input file.
      * Since this is coming from the card reader,
      *  we have 80 Chars per record.
       FD  INPILE-FILE
           LABEL RECORD IS STANDARD
           RECORD CONTAINS 80 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  STATISTICS-INPILE-FORMAT.
           02  MONTHNAME             PIC A(3).
           02  FILLER                PIC X.
           02  DAY-OF-MONTH          PIC X(2).
           02  FILLER                PIC X.
           02  TIMESPEC              PIC X(8).
           02  FILLER                PIC X.
           02  SCORE-TXT.
               03  SCORE-SIGN        PIC X.
                   88  VALIDITY      VALUE '-' ' '.
                   88  NUM-NEGATIVE  VALUE '-'.
               03  FILLER            PIC X.
               03  SCORE-TXT-DEC     PIC 9(5).
               03  SCORE-POINT       PIC X.
                   88  VALIDITY      VALUE '.'.
               03  SCORE-TXT-FRC     PIC 99.
               03  FILLER            PIC X.
           02  SCANTIME-TXT.
               03  SCANTIME-TXT-DEC  PIC X(4).
               03  SCANTIME-POINT    PIC X.
                   88  VALIDITY      VALUE '.'.
               03  SCANTIME-TXT-FRC  PIC 9.
               03  FILLER            PIC X.
           02  BYTES                 PIC 9(11).
           02  FILLER                PIC X(35).
      *=================================================================
       WORKING-STORAGE SECTION.
       77  EOF-IND                   PIC X          VALUE 'N'.
       77  PRV-MONTHNAME             PIC X(3)       VALUE 'NIL'.
       77  SPAMS-PER-MONTH           PIC 9(5)       VALUE ZERO.
       77  HAMS-PER-MONTH            PIC 9(5)       VALUE ZERO.
       77  MSG-PER-MONTH             PIC 9(5)       VALUE ZERO.
       77  SPAM-SCORE-SUM            PIC S9(6)V99   VALUE ZERO.
       77  HAM-SCORE-SUM             PIC S9(6)V99   VALUE ZERO.
       77  HIGHEST-SPAM-SCORE        PIC S9(3)V99   VALUE ZERO.
       77  LOWEST-HAM-SCORE          PIC S9(3)V99   VALUE ZERO.
       77  AVG-SCORE-SPAM            PIC S9(3)V99   VALUE ZERO.
       77  AVG-SCORE-HAM             PIC S9(3)V99   VALUE ZERO.
       01  SCORE                     PIC S9(3)V99   VALUE ZERO.
       01  FILLER                    REDEFINES SCORE.
           02  SCORE-DEC             PIC 9(3).
           02  SCORE-FRC             PIC S9(2).
       01  SCANTIME                  PIC 9(5)V9     VALUE ZERO.
       01  FILLER                    REDEFINES SCANTIME.
           02  SCANTIME-DEC          PIC X(4).
           02  SCANTIME-FRC          PIC S9.
       01  HEADING-1.
           02  FILLER                PIC X(32)      VALUE SPACE.
           02  FILLER                PIC X(16)
                                     VALUE 'Spam-Statistiken'.
       01  HEADING-2.
           02  FILLER                PIC X(31)      VALUE SPACE.
           02  FILLER                PIC X(22)
                                     VALUE '----- Avg. Score -----'.
           02  FILLER                PIC X(3)       VALUE SPACE.
           02  FILLER                PIC X(22)
                                     VALUE '----- Max. Score -----'.
       01  HEADING-3.
           02  FILLER                PIC X(3)       VALUE 'Mon'.
           02  FILLER                PIC X(3)       VALUE SPACE.
           02  FILLER                PIC X(5)       VALUE 'Spams'.
           02  FILLER                PIC X(4)       VALUE SPACE.
           02  FILLER                PIC X(4)       VALUE 'Hams'.
           02  FILLER                PIC X(4)       VALUE SPACE.
           02  FILLER                PIC X(6)       VALUE 'Gesamt'.
           02  FILLER                PIC X(7)       VALUE SPACE.
           02  FILLER                PIC X(4)       VALUE 'Spam'.
           02  FILLER                PIC X(9)       VALUE SPACE.
           02  FILLER                PIC X(3)       VALUE 'Ham'.
           02  FILLER                PIC X(9)       VALUE SPACE.
           02  FILLER                PIC X(4)       VALUE 'Spam'.
           02  FILLER                PIC X(9)       VALUE SPACE.
           02  FILLER                PIC X(3)       VALUE 'Ham'.
       01  OUTPUT-LINE.
           02  DATA-MONTH            PIC X(3).
           02  FILLER                PIC X(3)       VALUE SPACE.
           02  DATA-SPAMCNT          PIC Z(4)9.
           02  FILLER                PIC X(3)       VALUE SPACE.
           02  DATA-HAMCNT           PIC Z(4)9.
           02  FILLER                PIC X(5)       VALUE SPACE.
           02  DATA-MSGCNT           PIC Z(4)9.
           02  FILLER                PIC X(2)       VALUE SPACE.
           02  DATA-AVG-SPAM         PIC -ZZZZ9.99.
           02  FILLER                PIC X(3)       VALUE SPACE.
           02  DATA-AVG-HAM          PIC -ZZZZ9.99.
           02  FILLER                PIC X(4)       VALUE SPACE.
           02  DATA-MAX-SPAM         PIC -ZZZZ9.99.
           02  FILLER                PIC X(3)       VALUE SPACE.
           02  DATA-MIN-HAM          PIC -ZZZZ9.99.
      ******************************************************************
       PROCEDURE DIVISION.
       00-MAIN-ROUTINE.
           OPEN INPUT INPILE-FILE.

           DISPLAY HEADING-1.
           DISPLAY ' '.
           DISPLAY HEADING-2.
           DISPLAY HEADING-3.

           PERFORM 10-READ-AND-HANDLE-RECORD
               UNTIL EOF-IND = 'Y'.

           PERFORM 21-WRITE-STATS-LINE-AND-RESET.
           DISPLAY ' '.

           CLOSE INPILE-FILE.
           STOP RUN.
      *-----------------------------------------------------------------
       10-READ-AND-HANDLE-RECORD.
           READ INPILE-FILE
               AT END MOVE 'Y' TO EOF-IND.

           IF EOF-IND = 'N' THEN
               PERFORM 20-CHECK-RECORD.
      *-----------------------------------------------------------------
       20-CHECK-RECORD.
           IF MONTHNAME IS NOT EQUAL PRV-MONTHNAME
              AND PRV-MONTHNAME IS NOT EQUAL 'NIL' THEN
                 PERFORM 21-WRITE-STATS-LINE-AND-RESET.

           MOVE MONTHNAME TO PRV-MONTHNAME.

           IF VALIDITY OF SCORE-SIGN
              AND VALIDITY OF SCORE-POINT THEN
                 PERFORM 30-CALC-SCORE
              ELSE
                 MOVE ZERO TO SCORE.

           IF VALIDITY OF SCANTIME-POINT THEN
                 PERFORM 31-CALC-SCANTIME
              ELSE
                 MOVE ZERO TO SCANTIME.
      *-----------------------------------------------------------------
       21-WRITE-STATS-LINE-AND-RESET.
           COMPUTE AVG-SCORE-SPAM = SPAM-SCORE-SUM / SPAMS-PER-MONTH.
           COMPUTE AVG-SCORE-HAM = HAM-SCORE-SUM / HAMS-PER-MONTH.
           ADD SPAMS-PER-MONTH, HAMS-PER-MONTH GIVING MSG-PER-MONTH.

           IF MONTHNAME = 'NIL' THEN
              MOVE MONTHNAME TO DATA-MONTH
           ELSE
              MOVE PRV-MONTHNAME TO DATA-MONTH.

           MOVE SPAMS-PER-MONTH TO DATA-SPAMCNT.
           MOVE HAMS-PER-MONTH TO DATA-HAMCNT.
           MOVE MSG-PER-MONTH TO DATA-MSGCNT.
           MOVE AVG-SCORE-SPAM TO DATA-AVG-SPAM.
           MOVE AVG-SCORE-HAM TO DATA-AVG-HAM.
           MOVE HIGHEST-SPAM-SCORE TO DATA-MAX-SPAM.
           MOVE LOWEST-HAM-SCORE TO DATA-MIN-HAM.

           DISPLAY OUTPUT-LINE.

           MOVE ZERO TO SPAMS-PER-MONTH.
           MOVE ZERO TO HAMS-PER-MONTH.
           MOVE ZERO TO MSG-PER-MONTH.
           MOVE ZERO TO SPAM-SCORE-SUM.
           MOVE ZERO TO HAM-SCORE-SUM.
           MOVE ZERO TO HIGHEST-SPAM-SCORE.
           MOVE ZERO TO LOWEST-HAM-SCORE.
      *-----------------------------------------------------------------
       30-CALC-SCORE.
           MOVE SCORE-TXT-DEC TO SCORE-DEC.
           MOVE SCORE-TXT-FRC TO SCORE-FRC.

           IF NUM-NEGATIVE OF SCORE-SIGN THEN
               SUBTRACT SCORE FROM ZERO GIVING SCORE.

           IF SCORE > 4.99 THEN
               PERFORM 41-DO-SPAM-CALC
           ELSE
               PERFORM 40-DO-HAM-CALC.
      *-----------------------------------------------------------------
       31-CALC-SCANTIME.
           MOVE SCANTIME-TXT-DEC TO SCANTIME-DEC.
           MOVE SCANTIME-TXT-FRC TO SCANTIME-FRC.
      *-----------------------------------------------------------------
       40-DO-HAM-CALC.
           ADD 1 TO HAMS-PER-MONTH.
           ADD SCORE TO HAM-SCORE-SUM.
           IF SCORE < LOWEST-HAM-SCORE THEN
               MOVE SCORE TO LOWEST-HAM-SCORE.
      *-----------------------------------------------------------------
       41-DO-SPAM-CALC.
           ADD 1 TO SPAMS-PER-MONTH.
           ADD SCORE TO SPAM-SCORE-SUM.
           IF SCORE > HIGHEST-SPAM-SCORE THEN
               MOVE SCORE TO HIGHEST-SPAM-SCORE.
      *-----------------------------------------------------------------
