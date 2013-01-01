/****************************************************************************************
*                                                                                       *
* Program Name : TBL_CMEDS_Summary.sas                                                  *
* Project Name : MKC-TI-005.                                                            *
* Location     : \\PDCSAS\SAS-DATA\STUDIES\MKC-TI-005\SAS\PROGRAMS\TFLs                 *
* Created By   : Thomas Grzybowski                                                      *
* Created On   : 28MAR2005                                                              *
*                                                                                       *
* Description  : Create table showing medicine treatments since Visit 3.                *
*                Treatment is determined by medication category of use.                 *
* Modification :                                                                        *
*  By   Date        Description                                                         *
* ---- ----------- -------------------------------------------------------------------- *
*                                                                                       *
*                                                                                       *
****************************************************************************************/;

*%setstudy(study=MKC-TI-005);


/*** Calculate summary stats and produces a tabular report for Conmed History ***/;
%macro tbl_cmeds_summ(pop=);

/* read-in population, create character variable for treatment group */;
data pop;
  set derived.pop;
  length trtc $2.;
  trtc = "c"||put(trt,$1.); 
run;

%subset&pop; run;


/* count treatment groups */;
proc sql noprint;
select count (distinct trt) into: numtrt 
 from pop;

%let sumtrt = %eval(&numtrt + 1);
%put &sumtrt;

/* count subjects per treatment */;
select count (distinct pt) into: ptcnt&sumtrt from pop;
%do i = 1 %to &numtrt;
select count (distinct pt) into: ptcnt&i from pop where trt = &i;
%end;

/*** get medication history from conmeds ***/;
proc sql noprint;
create table conmed as
select distinct * 
  from derived.conmed
run;
quit; 

/* merge/join by population */;
proc sql noprint;
create table diab_t as
select distinct *  
from conmed, pop
where pop.pt = conmed.pt;

/* keep only those medical Rx beginning since Visit 3 */;
/* using mealdate3 from pop */;
create table dia3 as
select distinct
    study,
    inv,
    pt, 
    cmpnt,
    category,
    trtc
    from diab_t
where cmstdtn > mealdate3;  



/***    Now count treatment subset totals and calc percentages.   ***/;

/* total pts taking a medication by medication and category of use */; 
create table dia_4 as
select 
    cmpnt, 
    category, 
    trtc,
    count(pt) as medcount
from dia3 
group by cmpnt, category, trtc;

/* treatment totals */;
create table dia_sum as
select 
    cmpnt, 
    category, 
    count(pt) as medcount
from dia3 
group by cmpnt, category;

/* category totals */;
create table dia_cat as
select 
    category, 
    trtc,
    count(pt) as medcount
from dia3 
group by category,trtc;

/* category sum across all treatments */;
create table dia_cat_sum as
select 
    category, 
    count(pt) as medcount
from dia3 
group by category;
quit;

data dia_cat_sum;
set dia_cat_sum;
  trtc = "c&sumtrt";
  run;

proc append base=dia_cat data=dia_cat_sum; run;

data dia_cat;
length cmpnt $200.;
  set dia_cat;
    cmpnt = " ";
run;

data dia_sum;
  length trtc $2.;
  set dia_sum;
  trtc = "c&sumtrt";
run;

proc append base=dia_4 data=dia_sum; run;
proc append base=dia_4 data=dia_cat; run;

/* Calculate and format percents */;
/* bring counts back into dataset */;
data dia_5;
  set dia_4;
  %do i = 1 %to &sumtrt;
    trtcnt&i = int(symget("ptcnt&i"));
  %end;
run;

data dia_6;
    set dia_5;
      %do i=1 %to &sumtrt;
        if trtc="c&i" then do;
            _pctnt  = (medcount/trtcnt&i) * 100;
            _pctnt  = _pctnt + 0.0000001;
            pctntc = compress( '(' || put(_pctnt,5.1) || '%)' );
        end;
      %end;
     drop %do j = 1 %to &sumtrt; trtcnt&j %end;;
     run;

/* base table */;
proc sql noprint;
create table all_sum as
select distinct
    cmpnt, category
from dia_6;

/* counts and pct by treatment */;
%do i = 1 %to &sumtrt;
create table all_&i as
select distinct
    cmpnt,
    category,
    medcount as medcnt,
    pctntc
from dia_6
where trtc = "c&i";
%end;


/* Denormalize by-treatment results using sumtrt as the base table */;
/* i.e. bring all cols back together as rows in a single table.    */;
%do i = 1 %to &sumtrt;

alter table all_sum add medcnt&i num;

alter table all_sum add pctntc&i char;

update all_sum set medcnt&i = 
(select medcnt from all_&i where all_sum.cmpnt = all_&i..cmpnt 
                             and all_sum.category = all_&i..category);

update all_sum set pctntc&i = 
(select pctntc from all_&i where all_sum.cmpnt = all_&i..cmpnt 
                             and all_sum.category = all_&i..category);
%end;
quit;


/*** final formatting ***/;
/* concatonate N and pct into one column to save space */;
data toreport;
  set all_sum;
  if Category < "1" then Category = " UNCODED";
  %do i = 1 %to &sumtrt;
    length colc&i $12.;
    colc&i = %str(left(compress(put(0.0, 8.0) ))) || " (0.0%)" ;
    call symput("TRTLAB&i",put(&i,$trtf.));
    if medcnt&i > 0 then colc&i = %str(left(compress(put(medcnt&i,8.0))) || " " || left(pctntc&i));
  %end;
run;

proc sort data=toreport out=toreport;
  by category cmpnt;


/*** The Report ***/;
proc report data=toreport nowd split='*' missing headline formchar (2)='_' spacing=1 headskip;

    column category cmpnt %do i=1 %to &sumtrt; (colc&i) %end; ;

    break after category / skip suppress;

    define category  / group  width=25 'Category of Use' left flow;
    define cmpnt     / display  width=17 'Medication Name' left flow;

     %do i=1 %to &sumtrt;
       define colc&i / display width=13 center " &&trtlab&i*  [N=%str(%cmpres(&&ptcnt&i))]  "; 
     %end;
run;

%mend tbl_cmeds_summ;


