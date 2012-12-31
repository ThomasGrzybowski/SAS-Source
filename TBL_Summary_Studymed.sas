/****************************************************************************************
* Program Name : TBL_Summary_Studymed.sas                                               *
* Project Name : MKC-TI-005.                                                            *
* Location     : \\PDCSAS\SAS-DATA\STUDIES\studyname\SAS\PROGRAMS\TFLs                  *
* Created By   : Thomas Grzybowski                                                      *
* Created On   : 1-APR-2005                                                             *
*                                                                                       *
* Description  : Create Summary Statistics Table of exposure to study medication.       *
*                                                                                       *
* Modification :                                                                        *
*  By   Date        Description                                                         *
* ---- ----------- -------------------------------------------------------------------- *
*                                                                                       *
* T. Grzybowski  1-June-2005   Use fdosdtn and ldosdtn as found in pop(derived) dataset.*
*                                                                                       *
* T. Grzybowski  1-Sept-2005   Modified to conform with new SAP, ie. add range, median  *
*                              and modify table column headers.                         *
*                                                                                       *
* T.Grzybowski   29SEP2005   Modified to satisfy new new table shell issued by Hao Ren, * 
*                            adding "Treatment Total" and Overall Total.                *
*                                                                                       *
****************************************************************************************/;
options nofmterr symbolgen merror mlogic;

*%setstudy(study=MKC-TI-005);

%macro Contstats(dat=, var=, trtvar=, LABL=, SUFF=, BYGRP1= );

   PROC SORT DATA=&DAT;
     BY &TRTVAR &BYGRP1;
   RUN;

   /* stats against variable VAR using proc means */;
   PROC MEANS DATA=&DAT NOPRINT;
     BY &TRTVAR &BYGRP1;
     VAR &VAR;
   OUTPUT OUT=OUTMEAN&SUFF
           MEAN=Mean&SUFF
  	   MEDIAN =Med&SUFF
           MIN =Min&SUFF
           MAX =MAX&SUFF
           N   =NUM&SUFF
           STD =STD&SUFF  /autolabel; run;

  data outmean&SUFF;
    length range $11.;
    set outmean&SUFF;
	range = put(min&suffx,4.)||','||put(max&suffx,4.);
	drop min&suffx max&suffx;
  run;

%mend Contstats;


%macro postprocess(indat=, outdata=, Suffx= );

/* transpose each row (of each i treatment + 1 for total) to create a column */;
%do i = 1 %to &osumtrt;

  proc sql noprint;
  create table row&i as
  select 
       mean&Suffx format 5.2,
       num&Suffx,
       med&Suffx,
       std&Suffx format 5.2,
	   range
  from OUTMEAN&Suffx
  where trtc = "c&i";

  proc transpose data=row&i out=c&i;
  var   mean&Suffx
        num&Suffx
        med&Suffx
        std&Suffx
  	    range;
  run;
%end;

/** coelesce columns into all as a single table */;
proc sql;
create table all_&suffx as
select * from c1;

%do i = 2 %to &Osumtrt;
  alter table all_&suffx
  add col&i char(20), subpop num;
  update all_&suffx set col&i=(select col1 from C&i where all_&suffx.._name_ = C&i.._name_);
  update all_&suffx set subpop=&suffx;
%end;
%mend postprocess;



/*** Main macro calculates summary stats and produces a tabular report ***/;

%macro tbl_summary_studymed();

/* read-in population */;
data pop;
  set derived.pop;
  length trtc $2.;
  trtc = "c"||put(trt,$1.);
run;

/* count treatment groups  */;
proc sql noprint;
select count (distinct trt) into: numtrt from pop;

%let tsumtrt = %eval(&numtrt+1);
%let osumtrt = %eval(&numtrt+2);

/* count pts per treatment group in the defined population */;
%do i = 1 %to &numtrt;
  select count (distinct pt) into: ptcnt&i from pop where trtc = "c&i";
%end;

/* total pts in the population */;
select count (distinct pt) into: ptcnt&Osumtrt from pop;

/* "treatment total" pts in the population */;
select count (distinct pt) into: ptcnt&Tsumtrt from pop where trtc > "c1";
quit;


/*** loop through specified populations ***/;
%macro innerloop(pop=, suffx= );

data pop&suffx;
  set pop;
  length trtc $2.;
  trtc = "c"||put(trt,$1.);
run;

%subset&pop;

proc sql noprint;
create table last_first_&suffx as
  select 
    study, 
    invsite, 
    pt, 
    trtc, 
    fdosdtn,
    ldosdtn
from pop&suffx
where fdosdtn > 0;

/* get days between first dose date and last dose date, make copy to use for total */;
data last_first_&suffx;
  set last_first_&suffx;
  dffsd = (ldosdtn - fdosdtn) + 1;
  *if dffsd < 0 then dffsd = 0;
run;

/* create overall totals data */;
data dup&suffx;
  set last_first_&suffx;
  trtc="c&Osumtrt";
run; 

/* create treatment-totals data */;
data trt&suffx;
  set last_first_&suffx;
  if trtc > "c1";
  trtc="c&Tsumtrt";
run; 

proc append base=last_first_&suffx data=trt&suffx; run;
proc append base=last_first_&suffx data=dup&suffx; run;

proc sort data = last_first_&suffx;
by study trtc dffsd; run;

/*** call sub to generate descriptive statistics */;
%contstats(dat=last_first_&suffx, var=dffsd, trtvar=trtc, LABL=A1, SUFF=&suffx, bygrp1=study);
%postprocess(indat=OUTMEAN&suffx, outdata=all&suffx, suffx=&suffx);

%mend innerloop;


/*  drive loop through populations */;
%innerloop(pop=(varx=SFTY_POP,relx=eq,valx=1),suffx=1);
%innerloop(pop=(varx=ITT_POP,relx=eq,valx=1),suffx=2);
%innerloop(pop=(varx=PP_POP,relx=eq,valx=1), suffx=3);


/* append results for report */;
proc append base=all_1 data=all_2; 
proc append base=all_1 data=all_3; 

/* format text for report */;
data allp;
  set all_1;
  length statno $3.;
  length var1 $10.;
  length statdesc $15;
  var1      = upcase(substr(_label_,1,9));
  shortname = upcase(substr(_name_,1,3));
  statno    = put(shortname,$sn.);
  statdesc  = put(shortname,$sndesc.);
  drop _label_ _name_ ;
run;

/* format to char and force left */;
data allpp;
%do i = 1 %to &osumtrt;
  length colc&i $16.;
%end;
set allp;
 %do i = 1 %to &osumtrt;
  colc&i = %str(col&i);
  colc&i = left(compress(colc&i));
%end;
run;

/** Center decimal in col space */;
data toreport;
length visitdesc $20;
%do i = 1 %to &osumtrt;
  length colcf&i $15.;
%end;
set allpp;
%do i = 1 %to &osumtrt;
    point=indexc(colc&i,'.');

    if length(colc&i) = 1 then colcf&i = %str("  "||colc&i);
    if length(colc&i) = 2 then colcf&i = %str(" "||colc&i);
    if length(colc&i) = 3 then colcf&i = left(colc&i);
    if length(colc&i) > 3 then colcf&i = left(colc&i);
    if point = 4 then colcf&i = colc&i;

    if point = 3 then colcf&i = %str(" "||colc&i);
    if point = 2 then colcf&i = %str("  "||colc&i); 
    if point = 1 then colcf&i = %str("   "||colc&i);
	if shortname = "RAN" then colcf&i = %str('['||trim(colc&i)||']');
%end;
if subpop = 1 then visitdesc = "Safety";
if subpop = 2 then visitdesc = "Intention-to-Treat";
if subpop = 3 then visitdesc = "Per Protocol";
visit = 1;
run;

/* for col headings */;
data _null_;
 %do i = 1 %to &osumtrt;
    call symput("TRTLAB&i", put(&i,$trtf.));
 %end;
run;

proc sort data=toreport;
by subpop visitdesc statno; run;


/*** The Report ***/;
ODS listing; run;

proc report data=toreport nowd split='*' missing headline formchar (2)='_' spacing=2 headskip;

  column subpop visitdesc statno statdesc (%do i=1 %to &osumtrt; (colcf&i) %end;);

     break before subpop /skip;

     define subpop    / order noprint;
     define visitdesc / order width=20 'Population' left;
     define statno    / order noprint;
     define statdesc  / display width=14 'Statistic' left flow;
     %do i=1 %to &numtrt;
define colcf&i /display width=11 left " &&trtlab&i*  [N=%str(%cmpres(&&ptcnt&i))] ";
     %end;
define colcf&tsumtrt /display width=11 left "Treatment*Total[2]*  [N=%str(%cmpres(&&ptcnt&tsumtrt))] ";
define colcf&osumtrt /display width=11 left " Overall* Total[2]*  [N=%str(%cmpres(&&ptcnt&osumtrt))] ";

run;
ODS listing close;

%mend tbl_summary_studymed;
