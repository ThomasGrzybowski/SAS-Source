/**********************************************************************************************
* Macro        : FREQSTATS                                                                    *
* Description  : Derived from FRQSTATS. Calculates summary statistics for categorical variables*
*                The following summary statistics are calculated: N and Percent               *
*                Summary statistics can be calculated by any named Group plus two more BY     *
*                  variables.                                                                 *
*                e.g. If TRTVAR=TRT and BYGRP1=Visit and BYGRP2=Parameter are specified,      *
*                    summary stats are calculated by Treatment Group, Visit and Parameter.    *
*                                                                                             *
* Parameters   :                                                                              *
*        DAT   : Name of analysis dataset.                                                    *
*        VAR   : Description of analysis variable.                                            *
*     TRTVAR   : Name of treatment group variable. If trtvar= is specified, summary           *
*                 Default is trtvar=blank, treatment group not included.                      *
*                 If trtvar= is specified, summary stats are calculated by Treatment Group.   *
*     BYGRP1   : Name of first variable to calculate summary statistics by.  (e.g. Visit)     *
*                 Default is bygrp1=blank, no BY group 1.                                     *
*     BYGRP2   : Name of second variable to calculate summary statistics by. (e.g. Parameter) *
*                 Default is bygrp2=blank, no BY group 2.                                     *
*     ORDVAR   : Controls the order the categories appear in the summary statistics table.    *
*TRTCNT_NAME   : Name of percent denominator provided by calling program.                     *
*      TOSET   : Name to use for output dataset.                                              *
*                                                                                             *
*                                                                                             *
* Modification :                                                                              *
*  By   Date        Description                                                               *
* ---- ----------- -------------------------------------------------------------------------- *
*  TG   25FEB2005  Change denominator name for Percent calculations from global var TRTCNT to *
*                  parameter TRTCNT_NAME for treatment group counts held in dataset variables.*                                                   
*                                                                                             *
*  TG   28FEB2005  Create only one output data set, containing VAR, TRTVAR and calculated     *
*                  freq and percent.  Note that we do formatting somewhere else.              *
*                                                                                             *
*  TG   2MAR2005   Add Totalflag to flag for analysis of totals (one grand treatmenent group).*
*                                                                                             *
*  TG   29MAR2005  Add treatment parameter sumtrt so as not to depend upon global variable.   *
*                                                                                             *
*  TG   10MAY2005  Add parameter desc as a text description put into output variable var.     *
*                                                                                             *
*  TG   09AUG2005  Make BY into macro var BY_ so that it can disappear if not needed.         *
*                                                                                             *
*  TG   08SEP2005  Create new totals options, TT treatment total and OT overall total         *
*                                                                                             *
*  TG   09SEP2005  Create dummy output table with zeros if flag set.  Table will continue to  *
*                  exist with zeros if there are no records for analysis.                     *
*                                                                                             *
*  TG   14SEP2005  Remove dependency on ORDVAR.                                               *
*                                                                                             *
* ------------------------------------------------------------------------------------------- */;

%MACRO FREQSTATS(DAT=,VAR=,TRTVAR=trt,ORDVAR=,BYGRP1=,BYGRP2=,TRTCNT_NAME=trtc,Totalflag=F,toset=O1,Sumtrt=,Desc=' ',Zeros=F);

  %let BY_ =;
  %let Star_ =;

  %if &ORDVAR > ' ' %then %let Star_ = * ;

  %if &BYGRP1 > ' ' %then 
  %do;
    %let BY_ = BY;
    PROC SORT DATA=&DAT;
     &BY_ &BYGRP1 &BYGRP2; RUN;
  %end;

  /* create optional dummy table */;
  %if &zeros = T %then 
  %do;
    proc sql noprint;
  	create table &toset
    (&trtvar char(2), count num, perc num);
  	insert into &toset  
  	  %do i = 1 %to  &numtrt;
    	set &trtvar = "c&i", count = 0, perc = 0.0
  	  %end; 
;
  %end;


  %if &Totalflag=TT %then
  %do; 
  /* for treatment totals */;
	 PROC SQL NOPRINT;
	 CREATE TABLE _TMP&DAT AS
	 SELECT * FROM &DAT 
	 WHERE &TRTVAR > "c1";

	 %if &sqlobs > 0 %then
	 %do;
       PROC FREQ DATA=_TMP&DAT NOPRINT;
       &BY_ &BYGRP1 &BYGRP2;
       TABLES &VAR/OUT=&toset;
       RUN;

       DATA &toset;
         length var $200.;
         SET &toset;
         PERC=(COUNT/&&&TRTCNT_NAME&Tsumtrt)*100;
         &trtvar = "c&Tsumtrt";
         var = symget('desc');
        RUN;
	 %end;
	 %else %if &zeros = T %then 
     %do;
  	    proc sql noprint;
  	    create table &toset
        (&trtvar char(2), count num, perc num);
  	    insert into &toset  
    	  set &trtvar = "c&i", count = 0, perc = 0.0;
     %end;
  %end;


  %if &Totalflag=OT %then
  %do;
  /* for overall totals */;
	 PROC SQL NOPRINT;
	 CREATE TABLE _TMP&DAT AS
	 SELECT * FROM &DAT;

	 %if &sqlobs > 0 %then
	 %do;
       PROC FREQ DATA=&DAT NOPRINT;
       &BY_ &BYGRP1 &BYGRP2;
       TABLES &VAR/OUT=&toset;
       RUN;

       DATA &toset;
       length var $200.;
       SET &toset;
         PERC=(COUNT/&&&TRTCNT_NAME&Osumtrt)*100;
         &trtvar = "c&Osumtrt";
         var = symget('desc');
       RUN;
	 %end;
	   %else %if &zeros = T %then 
     %do;
	   %let i = %eval(&i + 1);
  	   proc sql noprint;
  	   create table &toset
       (&trtvar char(2), count num, perc num);
  	   insert into &toset  
       set &trtvar = "c&i", count = 0, perc = 0.0;
    %end;
  %end;


  %if &TRTVAR > ' ' %then %let BY_ = BY;

  %if &Totalflag=F %then
  %do;
  	 PROC SQL NOPRINT;
	 CREATE TABLE _TMP&DAT AS
	 SELECT * FROM &DAT;

	 %if &sqlobs > 0 %then
	 %do;
       PROC SORT DATA=&DAT;
       &BY_ &TRTVAR &BYGRP1 &BYGRP2;
       RUN;

       %if (&ordvar > " " ) %then 
       %do;
        PROC FREQ DATA=&DAT NOPRINT;
        &BY_ &TRTVAR &BYGRP1 &BYGRP2;
        TABLES &VAR&Star_&ORDVAR/OUT=&toset;
        RUN;
       %end;

       %if (&ordvar < "1" ) %then 
       %do;
        PROC FREQ DATA=&DAT NOPRINT;
        &BY_ &TRTVAR &BYGRP1 &BYGRP2;
        TABLES &VAR/OUT=&toset;
        RUN;
       %end;
	 %end;

       DATA &toset;
       length var $200.;
       SET &toset; 
       %DO i = 1 %TO &NUMTRT;
         IF &TRTVAR="c&i" THEN PERC=(COUNT/&&&TRTCNT_NAME&i)*100;
       %END;
       var = symget('desc');
       RUN;
    %end;
  quit;
%MEND FREQSTATS;
