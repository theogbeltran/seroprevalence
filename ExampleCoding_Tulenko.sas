*Name: Theo Beltran
	Program: Seroprevalence_Recoding.sas
    Date: 19Nov2020
	Description: Seroprevalence Recoding for Samantha Tulenko
*****************************************************************************/
OPTIONS MERGENOBY=warn NODATE NONUMBER FORMCHAR="|----|+|---+=|-/\<>*";
FOOTNOTE "Seroprevalence_Recoding.sas run at %SYSFUNC(DATETIME(), DATETIME.) by Theo Beltran";
/******************************* begin program ******************************/

/*************************WRITE LIBNAME STATEMENT************************/

LIBNAME SEROP1 "\\Mac\Home\Desktop";
/************************************************************************/


/******************************SET UP DATA*******************************/

*RUN THIS FIRST TO BE SURE NOT OVER-WRITING ORIGINAL DATASET;
*Steps to import: Import dataset, CSV file, Choose file, then setting to SEROP1.WEEK; 

proc import datafile = '\\Mac\Home\Desktop\weekly.csv'
 out = serop1.week
 dbms = CSV;
run;
*RUNNING DATASET;

PROC CONTENTS DATA = serop1.week;
RUN;

*Create Variable assessing duplicate tests for same person (MRN)
Indication of multiple tests would have both of those tests =1
The amount N=1 divided by 2 is how many duplicate tests there are
However, you would have to look in the dataset to see if the same test for one person is done more than twice;
proc sort data=serop1.week;
by PAT_MRN_ID TEST_CATEGORY;
run;

DATA serop1.test;
SET serop1.week;
by PAT_MRN_ID TEST_CATEGORY;
DuplicateRubella=  ^(first.PAT_MRN_ID and last.PAT_MRN_ID) and TEST_CATEGORY='RUBELLA'; 
DuplicateSyphilis=  ^(first.PAT_MRN_ID and last.PAT_MRN_ID) and TEST_CATEGORY='SYPHILIS'; 
run;

proc print data=serop1.test (obs=10);
run;


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

proc sort data=serop1.test;
BY ACCESSION_NUMBER;
run;

Data serop1.weekly;
	Merge serop1.wide serop1.test;
	by ACCESSION_NUMBER;
PROC print data= serop1.weekly;
run;

*Merging Indexed Dataset (Import Indext dataset first);

proc import datafile = '\\Mac\Home\Desktop\Index.csv'
 out = serop1.index
 dbms = CSV;
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
PROC print data= serop1.merge;
run;

*Merging ELISA output (import ELISA datset first);

proc import datafile = '\\Mac\Home\Desktop\Elisa.csv'
 out = serop1.elisa
 dbms = CSV;
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

*Final dataset check;
PROC print data= serop1.merge3;
run;
