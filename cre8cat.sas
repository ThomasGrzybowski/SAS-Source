*----------------------------------------------------------------------;
*-- Name: cre8cat.sas;
*-- Creates an empty sas catalog using proc build in batch mode;
*-- July 24, 2000;
*-- Written by: Arthur Asghar;
*-- Submitted with permission from Arthur Asghar Jan, 1, 2013
*----------------------------------------------------------------------;
%macro cre8cat/des="Creates sas catalog";
  %let lr_cat=&sysparm;
  %let lr=%scan(&lr_cat,1,'.');
  %let cat=%scan(&lr_cat,2,'.');
  %put ............................ Libref=&lr;
  %put ............................ Catname=&cat;
  %if %sysfunc(libref(&lr)) %then %do;
    %put .................................... &lr does not exist;
    x "print '\tlibref entered by you  does not exist'";
    %goto finish;
  %end;
  %if %sysfunc(cexist(&sysparm)) %then %do;
    %put Catalog :&sysparm: already exists .;
    x "print '\tCatalog already exists.'";
  %end;
  %else %do;
    proc build c=&sysparm batch;
    run;
    quit;
    %put .................. Catalog :&sysparm: created.;
    x "print '\tCatalog created'";
    %put .................. sysinfo from proc build is:&sysinfo:;
  %end;
  %finish:
%mend;
*----------------------------------------------------------------------;
*-- run the macro;
%cre8cat
