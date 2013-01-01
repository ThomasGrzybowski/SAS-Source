/*******************************************************************************
*  Program : ConvDateMON.sas                                                   *
*  Location: \SAS\PROGRAMS\Macros                                              *
*  Author  : T. Grzybowski                                                     *
*  Creation Date: Feb. 15, 2005                                                *
*                                                                              *
*  Purpose: Convert given date text fields into Text and Numeric values.       *
*                                                                              *
*  Input  : Date to convert, given three text variables: YYYY,MON,DD.          *
*  Output : Text date format = mm/dd/yyyy                                      *
*           Numeric date (SAS date) format                                     *
*                                                                              *
*                                                                              *
*  Parameters:                                                                 *
*      dtYYYY   : The year of the date to convert.                             *
*      dtMON  : The three-character month to convert.                        *
*      dtDD     : The two-character day of the month to convert.               *
*      newtext: Text Variable name for the new character date to be created.   *
*      newnum : Numeric variable name for the new numeric date to be created.  *
*                                                                              *
*                                                                              *
********************************************************************************
*  Modifications:                                                              *
*  By    Date      Description                                                 *
* ---- ----------- ----------------------------------------------------------- *
* TGrzybowski  27-APR-2005  Change lower boundary test for _tmpdyn monthday    *
*                           from "00" to "0".                                  *
*                                                                              *
* TGrzybowski  27-APR-2005  Pass dtDD (day) through as two chars for text date *
*                           for report purposes.                               *
*                                                                              *
* TGrzybowski  12-Jul-2005  Fix bug created with last change which used 01 for *
*                           numeric days all the time.                         * 
* AMoore       03-Aug-2005  Changed format of date text variable "newtext" as  *
*                           as per  trial statistician Hao Ren.                * 
*                           the date format will follow date9.                 *
********************************************************************************/;

%macro ConvDateMON(dtYYYY, dtMON, dtDD, newtext, newnum);

/* Don't do anything if the year is not complete */;
/* Assign '01' values for use by MDY SASdate if there is no real date for MON or dy. */;
/* Use number of days in month as a test */;

_tmpyr = "    ";
_tmpyr = compress(&dtYYYY);
_lenyyyy=length(_tmpyr);

if (_lenyyyy = 4) and ( _tmpyr < '9999') then 
do;
  _tmpmon = '  ';
  if  &dtMON =  'JAN' then do;
	_tmpmon = '01';
	_tmpdyn = "31";
  end;
  if  &dtMON =  'FEB' then do;
	_tmpmon = '02';
	_tmpdyn = "29";
  end;
  if  &dtMON =  'MAR' then do;
	_tmpmon = '03';
	_tmpdyn = "31";
  end;
  if  &dtMON =  'APR' then do;
	_tmpmon = '04';
	_tmpdyn = "30";
  end;
  if  &dtMON =  'MAY' then do;
	_tmpmon = '05';
	_tmpdyn = "31";
  end;
  if  &dtMON =  'JUN' then  do;
	_tmpmon = '06';
	_tmpdyn = "30";
  end;
  if  &dtMON =  'JUL' then  do;
	_tmpmon = '07';
	_tmpdyn = "31";
  end;
  if  &dtMON =  'AUG' then  do;
	_tmpmon = '08';
	_tmpdyn = "31";
  end;
  if  &dtMON =  'SEP' then  do;
	_tmpmon = '09';
	_tmpdyn = "30";
  end;
  if  &dtMON =  'OCT' then  do;
	_tmpmon = '10';
	_tmpdyn = "31";
  end;
  if  &dtMON =  'NOV' then  do;
	_tmpmon = '11';
	_tmpdyn = "30";
  end;
  if  &dtMON =  'DEC' then  do;
	_tmpmon = '12';
	_tmpdyn = "31";
  end;

  &newtext = compress(&dtDD||&dtMON||_tmpyr);
  
  if &dtDD > _tmpdyn then _tmpdyn = '01';
  if &dtDD < _tmpdyn then _tmpdyn = &dtDD;
  if &dtDD < '01'    then _tmpdyn = '01';
  if _tmpyr > "0000" then &newnum = MDY(_tmpmon, _tmpdyn, _tmpyr);
end;

%mend ConvDateMON;
