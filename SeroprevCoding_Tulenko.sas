*Name: Theo Beltran
	Program: Seroprevalence_Recoding.sas
    Date: 13Dec2020
	Description: Seroprevalence Recoding for Samantha Tulenko
*****************************************************************************/
OPTIONS MERGENOBY=warn NODATE NONUMBER FORMCHAR="|----|+|---+=|-/\<>*";
FOOTNOTE "Seroprevalence_Recoding.sas run at %SYSFUNC(DATETIME(), DATETIME.) by Theo Beltran";
/******************************* begin program ******************************/

/*************************WRITE LIBNAME STATEMENT************************/

LIBNAME SEROP1 "\\Mac\Home\Downloads";
/************************************************************************/


/******************************SET UP DATA*******************************/

*RUN THIS FIRST TO BE SURE NOT OVER-WRITING ORIGINAL DATASET;
*Steps to import: Import dataset, CSV file, Choose file, then setting to SEROP1.WEEK; 

proc import datafile = 'Insert File Path here'
 out = serop1.week
 dbms = xlsx;
run;

*RUNNING DATASET;

PROC CONTENTS DATA = serop1.week;
RUN;

*Removing identifiying data;
DATA serop1.week(DROP = PAT_FIRST_NAME PAT_LAST_NAME); 
SET serop1.week;
RUN;

*Long to Wide Format(regarding multiple tests from same Ascencion Number);
proc sort data=serop1.week;
by ACCESSION_NUMBER;
run;
proc transpose data=serop1.week out=serop1.wide prefix=TEST_CATEGORY;
  by ACCESSION_NUMBER;
  id TEST_CATEGORY;
  var TEST_CATEGORY;
run;

*Check to see if correct format;
proc print data=serop1.wide (obs=10);
run;

*Creating Rubella Variable;

DATA serop1.wide;
SET serop1.wide;
	IF TEST_CATEGORYRUBELLA = 'RUBELLA' THEN rubella = 1;
	else rubella =0;
run;

*Check rubella variable;
PROC FREQ DATA = serop1.wide;
tables rubella;
RUN;

*Creating Syphilis Variable;

DATA serop1.wide;
SET serop1.wide;
	IF TEST_CATEGORYSYPHILIS = 'SYPHILIS' THEN syphilis = 1;
	else syphilis =0;
run;
*Check syphilis variable;
PROC FREQ DATA = serop1.wide;
tables syphilis;
RUN;

proc print data=serop1.wide (obs=10);
run;

*****************************************************
MERGING DATASETS;

*Merging the two datasets created for duplicates and wide format;
Proc sort data=serop1.wide;
BY ACCESSION_NUMBER;
run;

proc sort data=serop1.week;
BY ACCESSION_NUMBER;
run;

Data serop1.weekly;
	Merge serop1.wide serop1.week;
	by ACCESSION_NUMBER;

*Check to see if correct format;
PROC print data= serop1.weekly;
run;

*Merging Indexed Dataset (Import Indext dataset first);

proc import datafile = '\\Insert File Path Name Here.xlsx'
 out = serop1.index
 dbms = excel;
run;

PROC CONTENTS DATA = serop1.index;
RUN;

*Rename accession number to merge to First dataset (serop1.weekly);
Data serop1.index;
set serop1.index;
RENAME accession_number_ml= ACCESSION_NUMBER;
RENAME desilva_lab_id= ID;
run;

proc sort data=serop1.index;
BY ACCESSION_NUMBER;
run;

Data serop1.merge;
	Merge serop1.weekly serop1.index;
	by ACCESSION_NUMBER;
run;

*Check to see if correct format;
PROC print data= serop1.merge;
run;

*Merging ELISA output (import ELISA datset first);

proc import datafile = '\\Insert File Name Here\All Processed Data 20201203.xlsx'
 out = serop1.elisa
 dbms = excel;
run;

PROC CONTENTS DATA = serop1.elisa;
RUN;

proc sort data=serop1.elisa;
BY ID;
run;
proc sort data=serop1.merge;
BY ID;
run;

*Merging all 3 datasets together;
Data serop1.merge3;
	Merge serop1.merge serop1.elisa;
	by ID;


*Dropping multiple ascension numbers;

proc sort data=serop1.merge3;
BY ACCESSION_NUMBER;
run;

DATA serop1.merge3nodup;
SET serop1.merge3;
by ACCESSION_NUMBER;
if ^(last.ACCESSION_NUMBER) then delete; 
run;

*Check to see if it looks right;

PROC print data= serop1.merge3nodup (obs=10);
run;

*Create Table assessing duplicate tests for same person (MRN);
proc freq data=serop1.merge3nodup;
table PAT_MRN_ID*rubella;
run;
proc freq data=serop1.merge3nodup;
table PAT_MRN_ID*syphilis;
run;


*Counts duplicates for syphilis;

proc sql;
 create table pDupChk as
 select unique PAT_MRN_ID, syphilis, count(*) as count
 from serop1.merge3nodup
 group by PAT_MRN_ID, syphilis
  having count>1;
title 'After Removing Total Dups - Other Non-Exact Dups';
 proc print data=pDupChk noobs;
 run;


*Counts duplicates for rubella;

 proc sql;
 create table pDupChk as
 select unique PAT_MRN_ID, rubella, count(*) as count
 from serop1.merge3nodup
 group by PAT_MRN_ID, rubella
  having count>1;
title 'After Removing Total Dups - Other Non-Exact Dups';
 proc print data=pDupChk noobs;
 run;

*Final dataset check;
proc print data=serop1.merge3nodup;
run;

