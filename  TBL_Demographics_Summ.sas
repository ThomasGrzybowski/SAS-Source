/****************************************************************************************
* Program Name : TBL_Demographics_Summ.sas                                              *
* Project Name : MKC-TI-005.                                                            *
* Location     : \\PDCSAS\SAS-DATA\STUDIES\studyname\SAS\PROGRAMS\TFLs                  *
* Created By   : Thomas Grzybowski                                                      *
* Created On   : 23-Nov-2004                                                            *
*                                                                                       *
* Description  : Create Demographic Summary Statistics Table.                           *
*                                                                                       *
* Modification :                                                                        *
*  By   Date        Description                                                         *
* ---- ----------- -------------------------------------------------------------------- *
*                                                                                       *
* TG    15-DEC-2004  Modified to run from Run_TFL_Tables_Master.sas                     *
*                                                                                       *
* TG    03-MAR-2005  Simplified and modified to handle various populations.             *
*                                                                                       *
* TG    11-AUG-2005   Modified to conform with table definition in new SAP.          *
*                                                                                       *
* TG    13SEP2005  Modified to satisfy new new table shell issued by Hao Ren.           * 
*                                                                                       *
****************************************************************************************/;
options nofmterr symbolgen mlogic;

*%setstudy(study=MKC-TI-005);


/*** this macro is used in the main pgrm to transpose data in row order for the report ***/;
/*   also does some formatting, combining N and percent into a single char variable      */;

%macro postprocess(fromset=, toset=, dvar=);

/* format percent column */;
data &fromset;
set &fromset;
format pctntc $8.;
format count_pctc $13.;
  pctnt = perc + 0.0000001;
  pctntc = '(' || put(pctnt,5.1) || ')';
  count_pctc = put(count,3.) ||' '|| pctntc;
run;

proc sort data=&fromset out=&toset;
by &dvar; run;

%mend postprocess;



/*** Main macro calculates summary stats and produces a tabular report ***/;
%macro tbl_demographics_summ(pop=(varx=SFTY_POP,relx=eq,valx=1); );

ODS listing close;

/* read-in demog, translate height to meters from cm */;
data demog;
  set derived.addemog;
  dmhtm=dmht/100;
run;

/* read-in population, create character variable for treatment group */;
data pop;
  set derived.pop;
  length trtc $2.;
  trtc = "c"||put(trt,1.);
run;

%subset&pop;

proc sql noprint;
/* count treatment groups */;
select count (distinct trt) into: numtrt from pop;

create table pop_1 as
select distinct
  demog.STUDY,
  demog.PT,
  demog.INV,
  demog.dmage,
  demog.dmsex,
  demog.dmrace,
  demog.adhba1cn,
  demog.consdtxt,
  demog.consdtn,
  pop.trtc
  from demog, pop
where pop.pt = demog.pt;

%do i = 1 %to &numtrt;
select count (distinct pt) into: ptcnt&i from pop_1 where trtc = "c&i";
%end;
%let Osumtrt = %eval(&numtrt + 2);
select count (distinct pt) into: ptcnt&Osumtrt from pop_1;

/* get only pts who are not in treatment group 1 */;
create table poptt as
select distinct *
  from pop_1
where trtc ne "c1";

%let Tsumtrt = %eval(&numtrt + 1);
select count (distinct pt) into: ptcnt&Tsumtrt from poptt where trtc ne "c1";


/**************************************
/***    Catagorical Variables       ***
/**************************************/;

/*** call sub for count and pct patients by gender sex ***/;
%freqstats
  (dat=pop_1,toset=cat1,var=dmsex,trtvar=trtc,trtcnt_name=ptcnt,Totalflag=F,sumtrt=&numtrt);

%postprocess(fromset=cat1, toset=cat1, dvar=dmsex); run;

proc transpose data=cat1 out=tcat1;
by dmsex;
id trtc;
var count_pctc;
run;

/* now call sub for totals */;
%freqstats(dat=pop_1,toset=cat1Ot,var=dmsex,trtvar=trtc,trtcnt_name=ptcnt,Totalflag=OT,sumtrt=&Osumtrt);
run;

%freqstats(dat=pop_1,toset=cat1tt,var=dmsex,trtvar=trtc,trtcnt_name=ptcnt,Totalflag=TT,sumtrt=&Tsumtrt);
run;

%postprocess(fromset=cat1Ot, toset=cat1Ot, dvar=dmsex); run;

%postprocess(fromset=cat1tt, toset=cat1tt, dvar=dmsex); run;


/* join treatment total column to base table */;
proc sql noprint;
create table all_1tt as
select 
  cat1tt.var,
  cat1tt.dmsex,
  %do i = 1 %to &numtrt; c&i format $13., %end;
  cat1tt.count_pctc as c&tsumtrt
from  tcat1, cat1tt where tcat1.dmsex = cat1tt.dmsex;

/* join overall total column */;
create table all_1ot as
select 
  all_1tt.var,
  all_1tt.dmsex,
  %do i = 1 %to &tsumtrt; c&i format $13., %end;
  cat1ot.count_pctc as c&osumtrt
from  all_1tt, cat1ot where all_1tt.dmsex = cat1ot.dmsex;

/* additional variable-specific tweaks for the report */;
data all_1;
  length statdesc $15.;
  length var1 $10.;
  length statno $3.;
set all_1ot;
  pagegrp = 1;
  var1 = "Gender";
  statno = "0";
  statdesc = put(dmsex,$sex2v7.);
  %do i = 1 %to &Osumtrt;
    call symput("TRTLAB&I",put("c&i",$trtcf.));
  %end;
  drop dmsex var;
run;

/*** call sub for count and pct patients by race ***/;

%freqstats(dat=pop_1,toset=cat2,var=dmrace,trtvar=trtc,trtcnt_name=ptcnt,Totalflag=F,sumtrt=&numtrt);

%postprocess(fromset=cat2, toset=cat2, dvar=dmrace); run;

proc transpose data=cat2 out=tcat2;
by dmrace;
id trtc;
var count_pctc;
run;

/* now call sub for totals */;
%FREQSTATS(DAT=pop_1,toset=cat2ot,VAR=dmrace,TRTVAR=trtc,TRTCNT_NAME=ptcnt,Totalflag=OT,sumtrt=&Osumtrt,Zeros=T);

%freqstats(dat=pop_1,toset=cat2tt,var=dmrace,trtvar=trtc,trtcnt_name=ptcnt,Totalflag=TT,sumtrt=&Tsumtrt,zeros=T);
run;

%postprocess(fromset=cat2tt, toset=cat2tt, dvar=dmrace); run;

%postprocess(fromset=cat2ot, toset=cat2ot, dvar=dmrace); run;

/* join treatment-totals column to base table */;
proc sql noprint;
create table all_2tt as
select 
cat2tt.var,
cat2tt.dmrace,
%do i = 1 %to &numtrt; c&i format $13., %end;
cat2tt.count_pctc as c&tsumtrt
from  tcat2, cat2tt
where tcat2.dmrace = cat2tt.dmrace;

/* join overall total column */;
create table all_2ot as
select 
  all_2tt.var,
  all_2tt.dmrace,
  %do i = 1 %to &tsumtrt; c&i format $13., %end;
  cat2ot.count_pctc as c&osumtrt
from  all_2tt, cat2ot
where all_2tt.dmrace = cat2ot.dmrace;

/* additional processing for the report */;
data all_2;
  length statdesc $15.;
  length statno $3.;
  length var1 $10.;
set all_2ot;
  pagegrp = 2;
  var1 = "Race";
  statno = "0";
  statdesc = put(dmrace,$15.);
  %do i = 1 %to &numtrt;
     if compress(c&i) < '0' then c&i = '  0 (0.0)';
  %end;
  drop dmrace var;
run;

proc append base=all_1 data=all_2; run;


/**************************************
/***    Continuous Variables        ***
/**************************************/;
%let suffx=3;
%cont_stats(dat=poptt,var=dmage,trtvar=trtc,LABL=dmage,SUFF=&suffx,bygrp1=study,bygrp2=,totflag=Y,trtsum=&Tsumtrt);

/* treatment total stats */;
proc sql noprint;
create table row&tsumtrt as
select  mean&Suffx format 5.1,
        min&Suffx,
    	max&Suffx,
        num&Suffx,
        med&Suffx,
        std&Suffx format 5.2
  from OUTMEAN&Suffx
  where trtc = "c&tsumtrt";

/*** call sub to generate descriptive statistics for continuous variables, output one dataset per treatment group ***/;
%cont_stats(dat=pop_1,var=dmage,trtvar=trtc,LABL=dmage,SUFF=&suffx,bygrp1=study,bygrp2=,totflag=Y,trtsum=&Osumtrt);

/*** transpose each row (of each i treatment + 1 for total) to create a column ***/;
/* base stats */;
%do i = 1 %to &numtrt;
proc sql noprint;
create table row&i as
select  mean&Suffx format 5.1,
        min&Suffx,
    	max&Suffx,
        num&Suffx,
        med&Suffx,
        std&Suffx format 5.2
  from OUTMEAN&Suffx
  where trtc = "c&i";
%end;

/* overall stats */;
create table row&Osumtrt as
select  mean&Suffx format 5.1,
        min&Suffx,
    	max&Suffx,
        num&Suffx,
        med&Suffx,
        std&Suffx format 5.2
  from OUTMEAN&Suffx
  where trtc = "c&Osumtrt";


%do i = 1 %to &Osumtrt;
  data row&i;
    length range $11.;
    set row&i;
	range = put(min&suffx,4.)||','||put(max&suffx,4.);
	drop min&suffx max&suffx;
  run;

  proc transpose data=row&i out=c&i;
  var   mean&Suffx
        num&Suffx
        med&Suffx
        std&Suffx
		range; run;

  %if &i > 1 %then 
  %do;
    data c&i;
	length col&i $13.;
    set c&i;
      col&i = col1;
      drop col1;
    run;
  %end;

  /* coelesce columns into all as a single table */;
  proc sql noprint;
  create table all_c&suffx as
  select * from C&i;
%end;


/* add-on totals columns */;
%do i = 1 %to &Osumtrt;
  alter table all_c&suffx
  add col&i char(13);
  update all_c&suffx set col&i=(select col&i from C&i where all_c&suffx.._name_ = C&i.._name_);
%end;
quit;

/* text for statistic description */;
data all_d&suffx;
  set all_c&suffx;
  length var1 $10.;
  length statno $3.;
  length statdesc $15;
  var1 = "Age (yrs)";  
  shortname = upcase(substr(_name_,1,3));
  statno    = put(shortname,$sn.);
  statdesc  = put(shortname,$sndesc.);
  pagegrp = &suffx;
  drop _label_ _name_ shortname;
run;


/*** HBA1C data analysis  ***/;
%let suffx=4;
%cont_stats(dat=poptt,var=adhba1cn,trtvar=trtc,LABL=hba1c,SUFF=&suffx,bygrp1=study,bygrp2=,totflag=Y,trtsum=&Tsumtrt);

/* treatment total stats */;
proc sql noprint;
create table row&tsumtrt as
select  mean&Suffx format 5.1,
        min&Suffx,
    	max&Suffx,
        num&Suffx,
        med&Suffx,
        std&Suffx format 5.2
  from OUTMEAN&Suffx
  where trtc = "c&tsumtrt";

/*** call sub to generate descriptive statistics for continuous variables, output one dataset per treatment group ***/;
%cont_stats(dat=pop_1,var=adhba1cn,trtvar=trtc,LABL=hba1c,SUFF=&suffx,bygrp1=study,bygrp2=,totflag=Y,trtsum=&Osumtrt);

/*** transpose each row (of each i treatment + 1 for total) to create a column ***/;
/* base stats */;
%do i = 1 %to &numtrt;
proc sql noprint;
create table row&i as
select  mean&Suffx format 5.1,
        min&Suffx,
    	max&Suffx,
        num&Suffx,
        med&Suffx,
        std&Suffx format 5.2
  from OUTMEAN&Suffx
  where trtc = "c&i";
%end;

/* overall stats */;
create table row&Osumtrt as
select  mean&Suffx format 5.1,
        min&Suffx,
    	max&Suffx,
        num&Suffx,
        med&Suffx,
        std&Suffx format 5.2
  from OUTMEAN&Suffx
  where trtc = "c&Osumtrt";


%do i = 1 %to &Osumtrt;
  data row&i;
    length range $11.;
    set row&i;
	range = put(min&suffx,4.1)||','||put(max&suffx,4.1);
	drop min&suffx max&suffx;
  run;

  proc transpose data=row&i out=c&i;
  var   mean&Suffx
        num&Suffx
        med&Suffx
        std&Suffx
		range; run;

  %if &i > 1 %then 
  %do;
    data c&i;
	length col&i $13.;
    set c&i;
      col&i = col1;
      drop col1;
    run;
  %end;

  /* coelesce columns into all as a single table */;
  proc sql noprint;
  create table all_c&suffx as
  select * from C&i;
%end;


/* add-on totals columns */;
%do i = 1 %to &Osumtrt;
  alter table all_c&suffx
  add col&i char(13);
  update all_c&suffx set col&i=(select col&i from C&i where all_c&suffx.._name_ = C&i.._name_);
%end;
quit;

/* text for statistic description */;
data all_d&suffx;
  set all_c&suffx;
  length var1 $10.;
  length statno $3.;
  length statdesc $15;
  var1 = "HbA1c (%)";  
  shortname = upcase(substr(_name_,1,3));
  statno    = put(shortname,$sn.);
  statdesc  = put(shortname,$sndesc.);
  pagegrp = &suffx;
  drop _label_ _name_ shortname;
run;


/*** study specific from this point on ***/;
/* stack continuous vars */;
proc append base = all_d3 data = all_d4 FORCE; run;

/* format and force left */;
data all_f;
%do i = 1 %to &numtrt;
  length c&i $13.;
%end;
set all_d3;
%do i = 1 %to &Osumtrt;
  c&i = %str(left(col&i));
  if statno = 5.3 then c&i = "["||compress(c&i)||"]";
%end;
drop %do j=1 %to &Osumtrt; col&j %end; ;
run;

/* study specific select only those statistics which are wanted in the report */;
proc sql;
 create table all_s as
   select * from all_f where statno in ('1', '2', '3.1', '4', '5.3')
   order by statno; quit;

/* cont and cat vars all together now */;
proc append base = all_1  data = all_s FORCE; run;

proc sort data = all_1;
by pagegrp var1 statno; run;

/* final format */;
data toreport;
%do i = 1 %to &Osumtrt;
  length colcf&i $16.;
%end;
set all_1;
%do i = 1 %to &Osumtrt;
    lenny = length(compress(c&i));
	point= indexc(c&i,'.');
	if lenny = 1 then colcf&i = %str("  "||c&i);
	if lenny = 2 then colcf&i = %str(" "||c&i);
	if lenny > 2 then colcf&i = left(c&i);
	if point = 3 then colcf&i = %str(" "||c&i);
	if point = 2 then colcf&i = %str("  "||c&i);
	if point = 1 then colcf&i = %str("   "||c&i);
	if point > 3 then colcf&i = %str("  "||c&i);

	if (statno <'1') and (length(compress(c&i)) > 9) then colcf&i = %str(c&i);
	if (statno <'1') and (length(compress(c&i)) = 9) then colcf&i = %str(""||c&i);
	if (statno <'1') and (length(compress(c&i)) = 8)  then colcf&i = %str(" "||c&i);
	if (statno <'1') and (length(compress(c&i)) < 8)  then colcf&i = %str(" "||c&i);
%end;
run;


/*** The Report ***/;
ODS listing; run;

proc report data=toreport nowd split='*' missing headline formchar (2)='_' spacing=1 headskip;

  column pagegrp (var1 statno statdesc %do i=1 %to &Osumtrt; (colcf&i) %end; );

     break before var1 / skip;

     define pagegrp   / group order=data noprint;
     define var1      / group width=11 order=internal "Parameter" left flow;
     define statno    / group order=data noprint;
     define statdesc  / display width=13 'Category/*Statistic' left flow;
     %do i=1 %to &numtrt;
       define colcf&i / display width=14 left "  &&trtlab&i*   [N=%str(%cmpres(&&ptcnt&i))]";
     %end;
	 define colcf&tsumtrt / display width=14 left "Treatment*Total[1]*  [N=%str(%cmpres(&&ptcnt&tsumtrt))]";
     define colcf&osumtrt / display width=14 left "Overall *Total[1]*  [N=%str(%cmpres(&&ptcnt&osumtrt))]";

run;

%mend tbl_demographics_summ;

