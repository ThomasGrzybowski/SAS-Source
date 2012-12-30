/****************************************************************************************                                                                                    *
* Program Name : TBL PT Disposition.sas                                                 *
* Project Name : Any new study.                                                         *
* Location     : \\PDCSAS\SAS-DATA\STUDIES\studyname\SAS\PROGRAMS\TFLs                  *
* Created By   : Thomas Grzybowski                                                      *
* Created On   : 28JAN2005                                                              *
*                                                                                       *
* Description  : Create Patient Disposition Summary Table, All Patients                 *
*                                                                                       *
* Modification :                                                                        *
*  By   Date        Description                                                         *
* ---- ----------- -------------------------------------------------------------------- *
*                                                                                       *
* T. Grzybowski  10AUG2005  Modified to satisfy new table shell issued by Hao Ren.      * 
*                                                                                       *
* T. Grzybowski  12SEP2005  Modified to satisfy new new table shell issued by Hao Ren.  * 
****************************************************************************************/;
options mlogic merror symbolgen;

*%setstudy(study=MKC-TI-005); 


%macro tbl_pt_dispos();

data popn;
  set derived.pop;
run;

/* count treatment groups */;
proc sql noprint;
select count (distinct trt) into: numtrt
from popn;

/* patient counts by treatment group */;
%do i = 1 %to &numtrt;
  select count (distinct pt) into: trtcnt&i from popn where trt = &i;
%end;

%let Tsumtrt = %eval(&numtrt + 1);

%let Osumtrt = %eval(&numtrt + 2);

  select count (distinct pt) into: trtcnt&Osumtrt from popn;

  select count (distinct pt) into: trtcnt&Tsumtrt from popn where trt ne 1;
quit;


/* prepare for merge with derived disposition data */;
proc sort data=popn;
  by invsite pt;
run;

proc sort data=derived.ptdispo out=ptdispo;
  by invsite pt;
run;

/* merge */;
data ptdispo;
  length trtc $2.;
  merge popn(in=in1) ptdispo(in=in2);
  by invsite pt;
  if in1;
  totpat=1;
  trtc = left(int(trt));
  trtc = "c"||trtc;
run;

* ----------------------------- *;
* Bring in the data to analyze. *;
* ----------------------------- *;

proc sort data=ptdispo out=reptdata;
    by invsite pt;
  run;

data dset1;
  set reptdata;
run;

data dset2;
  set reptdata;
  if enrolled = 0;
run;

data dset3;
  set reptdata;
  if enrolled = 1;
  if random = 1;
run;

  data dset4;
    set reptdata;
    if random=1;
  run;

  data dset5;
    set reptdata;
    if sfty_pop=1;
  run;

  data dset6;
    set reptdata;
  if t_only = 1;
  run;

  data dset7;
    set reptdata;
	if treated = 1;
  run;
 

  data dset8;
    set reptdata;
    if complete=1;
  run;

 
  /* discontinuations data set */;
  data dset9;
    set reptdata;
    if discont=1;
  run;


  data dset10;
    set dset9;
    if discresn = 1;
  run;

  data dset11;
    set dset9;
    if discresn = 2;
  run;

  data dset12;
    set dset9;
    if discresn = 3;
  run;

  data dset13;
    set dset9;
    if discresn = 4;
  run;

  data dset14;
    set dset9;
    if discresn = 5;
  run;

  data dset15;
    set dset9;
    if discresn = 6;
  run;

  data dset16;
    set dset9;
    if discresn = 7;
  run;

  data dset17;
    set dset9;
    if discresn = 8 or discresn = 999;
  run;


  data dset18;
    set reptdata;
    if itt_pop=1;
  run;

  data dset19;
    set reptdata;
    if pp_pop=1;
  run;

/* protocol violators */;
 data dset20;
    set reptdata;
    if ((vio_elig=1) or (vio_err=1) or (vio_oth=1));
 *   if ((discresn=4) or (vio_elig=1) or (vio_err=1) or (vio_oth=1));
 run;

/* reason for protocol violation */;
  data dset21;
    set reptdata;
    if vio_elig = 1;
 run;

 data dset22;
    set reptdata;
    if vio_err=1;
 run;

 data dset23;
    set reptdata;
    if vio_oth = 1;
 run;



%let numvars = 23;
%do varn=1 %to &numvars;

   %FREQSTATS(DAT=dset&varn,VAR=totpat,TRTVAR=trtc,TRTCNT_NAME=TRTCNT,
    toset=o&varn,Totalflag=F,sumtrt=&numtrt,Zeros=T);

   %FREQSTATS(DAT=dset&varn,VAR=totpat,TRTVAR=trtc,TRTCNT_NAME=TRTCNT,
    toset=ot&varn,Totalflag=OT,sumtrt=&Osumtrt,Zeros=T);

   %FREQSTATS(DAT=dset&varn,VAR=totpat,TRTVAR=trtc,TRTCNT_NAME=TRTCNT,
    toset=Tt&varn,Totalflag=TT,sumtrt=&Tsumtrt,Zeros=T);
%end;


%do varn=1 %to &numvars;

    proc sql noprint;
    create table oa&varn as
    select trtc, count, perc
    from o&varn;

    create table Tt&varn as
    select trtc, count, perc
    from Tt&varn;

    create table OT&varn as
    select trtc, count, perc
    from ot&varn;

	proc append base=oa&varn data=Tt&varn; run;
    proc append base=oa&varn data=Ot&varn; run;

    data of&varn;
    format pctntc $8.;
    set oa&varn;
      varn = int(&varn);
      if perc < 0.0000001 then perc = 0;
      pctnt = perc + 0.0000001;
      pctntc = '(' || put(pctnt,5.1) || ')';
      count_pctc = right(compress(put(count,8.))) ||' '|| pctntc;
      keep trtc count_pctc varn;
    run;

   proc append base=of_all data=of&varn; run;

 %end;


  proc transpose data=of_all out=alldat;
    by varn;
    id trtc;
    var count_pctc;
    run;


/* Final formatting for report    */;
/* study specific from here on    */;
/* Fill in blank cells with zeros */;
DATA ALLto;
length par $74.;
retain skipper;
SET alldat;
  %do j = 1 %to &numtrt;
    if varn > 3 then do;
    c&j = trim(left(c&j));
    if compress(c&j) <= "" then c&j = "  0 (  0.0)";
	end;
	if varn < 4 then  c&j = " ";
  %end;
  %do j = &Tsumtrt %to &Osumtrt;
    c&j = trim(left(c&j));
    if compress(c&j) <= "" then c&j = "  0 (  0.0)";
  %end;

  statno=0;
  if varn = 1 then par = 'Screened';
  if varn = 2 then par = '  Screen Failure';
  if varn = 3 then par = '  Randomized [1]';
  if varn = 4 then skipper=0;
  if varn = 4 then par = 'Randomized';
  if varn = 5 then skipper=1;
  if varn = 5 then par = 'Safety Population';
  if varn = 6 then par = "  Technosphere-only Treated";
  if varn = 7 then par = "  Double-Blinded Treated";
  if varn = 8 then skipper=2;
  if varn = 8 then par = "Completed";
  if varn = 9 then skipper=3;
  if varn = 9 then par = "Prematurely Discontinued";

  if varn = 10 then skipper=4;
  if varn = 10 then par = '  One Episode of Severe Hypoglycemia';
  if varn = 11 then par= '  Laboratory Abnormality';
  if varn = 12 then par= '  Adverse Event';
  if varn = 13 then par= '  Protocol Violation';
  if varn = 14 then par= '  Patient Withdrew Consent';
  if varn = 15 then par= '  Patient Died';
  if varn = 16 then par= '  Physician Decision';
  if varn = 17 then par= '  Other';

  if varn = 18 then skipper=5;
  if varn = 18 then par= 'Intention-to-Treat Population';
  if varn = 19 then skipper=6;
  if varn = 19 then par= 'Per Protocol Population';
  if varn = 20 then skipper=7;
  if varn = 20 then par= 'Protocol Violators';
  if varn = 21 then skipper=8;
  if varn = 21 then par= '  Not Met Eligibility Criteria';
  if varn = 22 then par= '  Treatment Assignment Error';
  if varn = 23 then par= '  Other';

  drop _name_;
RUN;


/***  The Report ***/;
/* for treatment col headings */;
data _null_;
 %do i = 1 %to &Osumtrt;
    call symput("TRTLAB&i", put("&i",$trtf.));
 %end;
run;

proc sort data = allto out=toreport;
by varn skipper par;


proc report data=toreport nowd split='*' missing headline formchar (2)='_' spacing=1;

    column skipper varn par (%do i=1 %to &Osumtrt; (c&i) %end;);

    define skipper / group noprint;
    define varn    / group noprint;

    break after skipper / skip;

    define par  / group width=38 "  Population" left flow;

    %do i=1 %to &numtrt;
    define c&i / display width=11 right "&&trtlab&i  *  [N=%str(%cmpres(&&trtcnt&i))]* __*n    (%)";
    %end;
    define c&tsumtrt / display width=11 right "Treatment*Total[2] *[N=%str(%cmpres(&&trtcnt&tsumtrt))] * __*n    (%)";
    define c&Osumtrt / display width=11 right "Overall*Total[2]*  [N=%str(%cmpres(&&trtcnt&osumtrt))]* __*n    (%)";

    compute before skipper;
	  desc = "                                   ";
	  if skipper = 4  or skipper = 8 then 
      do; 
		line  @6  desc $37.;
	    if skipper = 4 then desc = "Primary Reason for Discontinuation:";
	    if skipper = 8 then desc = "Primary Reason, Protocol Violation:";
	  end;
	endcomp;

run;

%mend tbl_pt_dispos;
