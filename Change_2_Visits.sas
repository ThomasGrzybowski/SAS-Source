/****************************************************************************************
* Macro Name :  Change_2_visits.sas                                                     *
* Project Name : MKC-TI-005.                                                            *
* Location     : \\PDCSAS\SAS-DATA\STUDIES\studyname\SAS\PROGRAMS\macros                *
* Created By   : Thomas Grzybowski                                                      *
* Created On   : 19-Aug-2005                                                            *
*                                                                                       *
* Description  : Calc difference between two visits: create dataset with difference in  *
*               variable specifed by "&outvar".  "Visit" is the "where" variable and    *
*               "Study", "invsite", "pt" are the key variables.                         *
*                                                                                       *
* Modification :                                                                        *
*  By   Date        Description                                                         *
* ---- ----------- -------------------------------------------------------------------- *
*
****************************************************************************************/;
options nofmterr symbolgen merror mlogic;


%macro change_2_visits(indata=, indatb=, outdat=, invar=, outvar=, visita=, visitb=);

%if &indatb < " " %then %let indatb = &indata; 
%if &outvar < " " %then %let outvar = &invar; 


/* merge visits so as to get diff */;
proc sql noprint;

  create table _tab&visita as
  select distinct
    study,
    invsite, 
    pt,
  trtc,
    &invar  
  from &indata where visit = &visita;

  create table _tab&visitb as
  select distinct
    study,
    invsite, 
    pt,
	trtc,
    &invar  
  from &indatb where visit = &visitb;

  create table _merged_visits as
    select distinct
        _tab&visita..study,
        _tab&visita..invsite, 
        _tab&visita..pt,
		_tab&visita..trtc,
        _tab&visita..&invar as _nvalue&visita,
        _tab&visitb..&invar as _nvalue&visitb
    from _tab&visita left join _tab&visitb
    on   _tab&visita..study   = _tab&visitb..study
    and  _tab&visita..invsite = _tab&visitb..invsite 
    and  _tab&visita..pt      = _tab&visitb..pt
	and _tab&visita..trtc     = _tab&visitb..trtc;

    quit;

    /* get diff */;
    data &outdat;
      set _merged_visits;
        &outvar = _nvalue&visitb - _nvalue&visita;
  	    if &outvar ne .;
    run;

%mend change_2_visits;

