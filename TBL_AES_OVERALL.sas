/****************************************************************************************
* Program Name : TBL_AES_OVERALL.sas                                                    *
* Project Name : MKC-TI-005                                                             *
* Location     : \\Programs\TFLs                                                        *
* Created By   : Thomas Grzybowski                                                      *
* Created On   : 21DEC2004                                                              *
*                                                                                       *
* Description  : Frequency of the Adverse Events by descending count. Parts A & B.      *
*                                                                                       *
* Input        : AE (raw dataset),  POP (derived dataset)                               *
* Output       : Word documents  AETABLE.doc                                            *
*                                                                                       *
*                                                                                       *
* Modification :                                                                        *
*  By   Date        Description                                                         *
* ---- ----------- -------------------------------------------------------------------- *
* T. Grzybowski  April 12, 2005  Change name from TBL to LST.                           *
*                                                                                       *
* T. Grzybowski  April 26, 2005  Split report into A and B sub-reports.                 *
*                                                                                       *
* T. Grzybowski  April 28, 2005  Add argument to specify AE startdate - used to support *
*                                Report on Treatment-Emergent AEs.                      *
* T. Grzybowski  May 19, 2005    Rename to TBL_AES_OVERALL                              *
****************************************************************************************/;
options nofmterr mlogic symbolgen;

*%SetStudy(study=MKC-TI-005); 


%macro tbl_aes_overall(pop=, start=);

/* -------------------------------------------------- *
  Select appropriate population.
* -------------------------------------------------- */;
data popn;
 set derived.pop;
run;

%subset&pop; run;


proc sort data=popn;
  by invsite pt;
run;

proc sort data=rawdata.ae out=ae;
  by invsite pt aestdt;
run;

data preptdata(where=(aeverb ne ''));
  merge ae(in=in1) popn(in=in2);
  by invsite pt;
  if in1 and in2;
run;

data prepdata1;
  length trtcf $5.;
  length invsitet $3.;
  set preptdata;
  invsitet = compress(invsite);
  trtcf = put(trt,$trtf.);
  %ConvDateMON(aestyr, aestmo, aestdy, aestdt, aestdtn);
   drop _tmpyr _tmpdyn _tmpmon _lenyyyy;
run;


/* if start,  keep AES only since start date */;
data prepdata2;
  set prepdata1;
run;
%if &start > " " %then
%do;
data prepdata2;
  set prepdata2;
  if (aestdtn >= &start);
run;
%end;

proc sort data=prepdata2;
by trtcf inv pt aestdt aept;
run;

data prepdata3;
  set prepdata2;
  by trtcf inv pt aestdt aept;
  if first.pt then cid = 0;
  cid +1;
  cidc = left(%str(cid));
run;

proc sort data=prepdata3 out=toreport;
by trtcf inv pt cid aestdt;
run;

/* ------------------------------------------------- *
  Report Section A
* -------------------------------------------------- */;
title5 'Part A';
proc report data=toreport headline headskip nowd formchar(2)='_' spacing=1 center split='*' missing;
     column trtcf inv pt cidc aesoct aept aeverb aestdt aespdt;

    break before pt    /skip;
    break after aeverb /skip;

        define trtcf   / group order=data left  width=9 "Treatment*Group";
        define inv     / group order=data  width=5  "Inv.";
        define pt      / group order=data  width=5  "Pt.";
        define cidc     / group order=data center width = 8 " AE*Sequence*Number";
        define aesoct  / display width=20 flow "System Organ Class ";
        define aept    / display width=20 flow "Preferred Term";
        define aeverb  / group order=data width=24 flow "Adverse Event";
        define aestdt  / group order=data display width=12 "AE Start*Date";
        define aespdt  / display width=12 "Resolution*Date";
   run;

proc sort data=prepdata2 out=toreport;
by trtcf inv pt cid aept;
run;

/* -------------------------------------------------- *
  Report Section B
* -------------------------------------------------- */;
title5 'Part B';
 proc report data=toreport headline headskip nowd formchar(2)='_' spacing=2 center split='*' missing;
     column trtcf inv pt cidc aept aestdt aemdact aemdrel aedvrel;

    break before pt    /skip;
    break after aept /skip;

     define trtcf   / group order=data left  width=9 "Treatment*Group";
     define inv     / group order=data  width=4  "Inv.";
     define pt      / group order=data  width=5  "Pt.";
     define cidc    / group order=data center width = 8 " AE*Sequence*Number";
     define aept    / group order=data width=20 flow "Preferred Term";
     define aestdt  / group order=data noprint;
     define aemdact / display width=25 Flow "Action * with *Study Drug";
     define aemdrel / display width=14 "Relation-*ship to*Study Drug";
     define aedvrel / display width=14 "Relation-*ship to*Study Device";
   run;

%mend tbl_aes_overall;
