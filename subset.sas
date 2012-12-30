/****************************************************************
 *  FILENAME: SUBSET.SAS
 *  AUTHOR:   T. Grzybowski 
 *
 *  PURPOSE:  To subset a data set by a single variable VARX.
 *            If no INDAT data set is specified, the SYSLAST 
 *            data set is used as INDAT.  If no OUTDAT data set 
 *            is specified the INDAT data set is used.
 *            The default RELX comparison operator is EQ.
 *            
 *  ASSUME:   VARX, and VALX are assigned.
 *
 ****************************************************************
 *  Modifications:
 ****************************************************************/;
/* options mlogic symbolgen;*/;

%macro subset(varx=,relx=eq,valx=,indat=,outdat=);

    %if &indat  < ' ' %then %let indat  = &syslast; 

    %if &outdat < ' ' %then %do;

        %let outdat = &indat; 
        %let posn = %index(&indat,.); 
        %if (&posn > 0) %then %let outdat = %substr(&indat,(%eval(&posn + 1)));

    %end;    

    proc sql;
    create  table        &outdat as
    select  *     from   &indat
                  where  &varx &relx &valx ;
%mend subset; 
