/****************************************************************************************
*                                                                                       *
* Program Name : TBL_PT_Disposition_Listing.sas                                         *
* Project Name : Any new study.                                                         *
* Location     : \\PDCSAS\SAS-DATA\STUDIES\studyname\SAS\PROGRAMS\TFLs                  *
* Created By   : Thomas Grzybowski                                                      *
* Created On   : 11JAN2005                                                              *
*                                                                                       *
* Description  : Create Patient disposition table by patient.                           *
*                                                                                       *
* Input        : pop (derived), ptdispos (derived)                                      *
* Output       : Report                                                                 *
*                                                                                       *
* Macro        : TDispo                                                                 *
* Parameters   : (M:Mandatory  O:Optional)                                              *
*    STUDY<M>  : Name of study.                                                         *
*    INLIB<M>  : Name of library where analysis dataset is stored.                      *
*   INDATA<M>  : Name of analysis dataset.                                              *
*    INPOP<M>  : Name of population derived dataset.                                    *
*  STDYVAR<O>  : Name of study identifier variable.                                     *
*                Default is stdyvar=blank, study identifier not included in listing.    *
*                If stdyvar= is non-blank, study identifier included in listing.        *
*   TRTVAR<O>  : Name of treatment group variable.                                      *
*                Default is trtvar=blank, treatment group not included in listing.      *
*                If trtvar= is non-blank, treatment group included in listing.          *
*                                                                                       *
* Modification :                                                                        *
*  By   Date        Description                                                         *
* ---- ----------- -------------------------------------------------------------------- *
*                                                                                       *
* Thomas Grzybowski 18JAN2005  Modify for MKC-TI-005.                                   *
*                                                                                       *
****************************************************************************************/;
options merror mlogic symbolgen;

*%setstudy(study=MKC-TI-005);

* ------------------------------------------------ *;
* Macro to produce Patient Disposition Listing.    *;
* ------------------------------------------------ *;
%macro tbl_pt_disposl(pop=);

* --------------------------------- *;
* Select the appropriate population *;
* --------------------------------- *;
  proc sort data=derived.pop out=popn;
    by invsite pt;
  run;

  %subset&pop;

  proc sort data=derived.ptdispo out=reptdata;
    by invsite pt;
  run;

  data reptdata;
    merge reptdata(in=in1) popn(in=in2);
    by invsite pt;
    if in2;
  run;

  proc sort data=reptdata;
    by study trt invsite pt;
  run;


  * ------------------------------------ *;
  * Create Report                        *;
  * Patient Disposition Listing          *;
  * ------------------------------------ *;
  data toreport;
    set reptdata;
    * Calculate Number of Days from first study dose;
    fdosdtn=mealdate5;
    daysfrm=(ldosdtn-fdosdtn)+1;
    daysfrmc=compress(daysfrm);
    if daysfrmc='.' then daysfrmc='';

    if pe_subgp=1 then pe_gpa=1;
       else pe_gpa=0;
    if pe_subgp=2 then pe_gpb=1;
       else pe_gpb=0;
  run;


  proc report data=toreport
              headline headskip nowd formchar(2)='_' spacing=3 center split='*' missing;

    column trt invsite pt sfty_pop itt_pop pe_pop recruit enrolled treated discont complete daysfrmc;

        break after trt /skip;
    break after pt / skip;

    define  trt       / group order=data width=9 flow left 'Treatment*Group' format=trtf.;
    define  invsite   / group order=data width=5 left ' Inv.* Site';
    define  pt        / group order=data format=$8.      width=5 left 'Pat*No.';
    define  sfty_pop  / display format=yesno.  width=7 center 'Safety';
    define  itt_pop   / display format=yesno.  width=8 center 'Intent*to*Treat';
    define  pe_pop    / display format=yesno.  width=8 left 'Primary*Efficacy';
    define  recruit   / display format=yesno.  width=9 left 'Recruited';
    define  enrolled  / display format=yesno.  width=8 left 'Enrolled';
    define  treated   / display format=yesno.  width=7 left 'Treated';
    define  discont   / display format=yesno.  width=8 left "Discont-*inued";
    define  complete  / display format=yesno.  width=9 left 'Completed';
    define daysfrmc   / display                width=9 left 'Days on*Study';
  run;

%mend tbl_pt_disposl;
