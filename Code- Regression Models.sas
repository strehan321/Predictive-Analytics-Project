/* PREPARATION OF PRODUCTION TISSUE DATA */

/* Reading Production Tissue */
LIBNAME lib 'H:\Predictive Project\factiss';

PROC IMPORT OUT=ProdTissue DATAFILE= "H:\Predictive Project\factiss\prod_tissue.xls" 
DBMS=xls REPLACE;
GETNAMES=YES;
RUN;

/*Padding Components of UPC code*/
data ProdTissue;
set ProdTissue;
SY = put(SY, z2.);
GE = put(GE, z1.);
VEND = put(VEND, z5.);
ITEM = put(ITEM, z5.);
format SY z2. GE z1. VEND z5. ITEM z5.;
run;

/* Merging Components of UPC Code */
data ProdTissue;
set ProdTissue;
length UPC2 $ 14;
UPC2=put(SY,z2.)|| put(GE,z1.) || put(VEND,z5.) || put(ITEM,z5.);
run;

/*Converting UPC2 to numeric */
data ProdTissue;
set ProdTissue;
upc_new_char = input(UPC2, 14.);
run;

/* PREPARATION OF GROCERY STORES DATA */

/* Reading Grocery Data */
data Grocery;
infile "H:\Predictive Project\factiss\factiss_groc_1114_1165" expandtabs DLM='' FIRSTOBS=2;
input IRI_KEY WEEK SY GE VEND ITEM UNITS DOLLARS F $ D PR;
run;

/*Padding Components of UPC code*/
data Grocery;
set Grocery;
SY = put(SY, z2.);
GE = put(GE, z1.);
VEND = put(VEND, z5.);
ITEM = put(ITEM, z5.);
format SY z2. GE z1. VEND z5. ITEM z5.;
run;

/* Merging Components of UPC Code */
data Grocery;
set Grocery;
length UPC $ 14;
UPC=put(SY,z2.)|| put(GE,z1.) || put(VEND,z5.) || put(ITEM,z5.);
run;

/*Converting UPC_new data type from char to numeric */
data Grocery;
set Grocery;
upc_new_char = input(upc, 14.);

/*Joining Prodtissue and Grocery*/
proc sql;
create table Grocery_Tiss as
select a.upc_new_char, a.DOLLARS, a.IRI_KEY,  a.UNITS, a.WEEK, a.F, a.D, a.PR, b.L5, b.Vol_Eq
from Grocery a
inner join
Prodtissue b
on a.upc_new_char=b.upc_new_char;
quit;

/* Scotties Data */
data Grocery_tiss_s;
set Grocery_tiss;
if L5="SCOTTIES";
run;

/* Calculating Price per sheet and Sales */
data Grocery_tiss_s;
set Grocery_tiss_s;
Price_per_Sheet=(Dollars/(Units*Vol_Eq));
Sales=(Units*Vol_Eq*100);
run;

/* Creating Promotion Dummies */
data Grocery_tiss_s;
set Grocery_tiss_s;
if F="A+" or F="A" or F="B" or F="C" then F_overall=1; else F_overall=0;
if F="A+" then F_rebate=1; else F_rebate=0;
if F="A" then F_large=1; else F_large=0;
if F="B" then F_medium=1; else F_medium=0;
if F="C" then F_small=1; else F_small=0;
if F="None" then F_none=1; else F_none=0;
if D="1" or D="2" then D_overall=1; else D_overall=0;
if D="1" then D_minor=1; else D_minor=0;
if D="2" then D_major=1; else D_major=0;
if D="0" then D_none=1; else D_none=0;
if PR="1" then PR_large=1; else PR_large=0;
if PR="0" then PR_none=1; else PR_none=0;
run; 

/* Calculating Share */
proc sql;
create table regmode_s as
select a.iri_key,a.WEEK, sales/sum(sales) as Share, sales,Price_per_sheet,
f_overall,d_overall,pr,F_rebate,F_large,F_medium,F_small,D_minor,D_major
from Grocery_Tiss_s a
group by a.iri_key,a.week;
quit;

/* Calculating Weighted Price , features and Displays */
data regmode_s;
set regmode_s;	
wt_price=Share*Price_per_sheet;
wt_f=Share*f_overall;
wt_f_rebate=share*f_rebate;
wt_f_large=share*f_large;
wt_f_medium=share*f_medium;
wt_f_small=share*f_small;
wt_d=Share*d_overall;
wt_d_minor=share*d_minor;
wt_d_major=share*d_major;
wt_pr=Share*pr;
run;

/* Creation of Panel Data */
proc sql;
create table panel_s as
select a.iri_key,a.WEEK, sum(a.Sales) as T_Sales,
sum(wt_price) as w_price ,sum(wt_f) as w_f,sum(wt_d) as w_d,sum(wt_pr)as w_pr,sum(wt_f_rebate) as w_f_rebate,
sum(wt_f_large) as w_f_large, sum(wt_f_medium) as w_f_medium,sum(wt_f_small) as w_f_small,
sum(wt_d_minor) as w_d_minor,sum(wt_d_major) as w_d_major
from regmode_s a
group by a.iri_key,a.week;
quit;

/* Kleenex to calculate cross price elasticity */
data Grocery_tiss_K;
set Grocery_tiss;
if L5="KLEENEX";
run;

/* Creating Promotion Dummies */
data Grocery_tiss_K;
set Grocery_tiss_K;
if F="A+" or F="A" or F="B" or F="C" then F_overall=1; else F_overall=0;
if F="A+" then F_rebate=1; else F_rebate=0;
if F="A" then F_large=1; else F_large=0;
if F="B" then F_medium=1; else F_medium=0;
if F="C" then F_small=1; else F_small=0;
if F="None" then F_none=1; else F_none=0;
if D="1" or D="2" then D_overall=1; else D_overall=0;
if D="1" then D_minor=1; else D_minor=0;
if D="2" then D_major=1; else D_major=0;
if D="0" then D_none=1; else D_none=0;
if PR="1" then PR_large=1; else PR_large=0;
if PR="0" then PR_none=1; else PR_none=0;
run;

/* Calculating Price per sheet and Sales */
data Grocery_tiss_K;
set Grocery_tiss_K;
Price_per_Sheet=(Dollars/(Units*Vol_Eq));
Sales=(Units*Vol_Eq*100);
run;

/* Calculating Share */
proc sql;
create table regmode_k as
select a.iri_key,a.WEEK, sales/sum(sales) as Share, sales,Price_per_sheet,f_overall,d_overall,
pr,F_rebate,F_large,F_medium,F_small,D_minor,D_major
from Grocery_Tiss_k a
group by a.iri_key,a.week;
quit;

/* Calculating Weighted Price , features and Displays */
data regmode_K;
set regmode_K;	
wt_price=Share*Price_per_sheet;
wt_f=Share*f_overall;
wt_f_rebate=share*f_rebate;
wt_f_large=share*f_large;
wt_f_medium=share*f_medium;
wt_f_small=share*f_small;
wt_d=Share*d_overall;
wt_d_minor=share*d_minor;
wt_d_major=share*d_major;
wt_pr=Share*pr;
run;

/* Creation of Panel Data */
proc sql;
create table panel_k as
select a.iri_key,a.WEEK, sum(a.Sales) as T_Sales,
sum(wt_price) as w_price ,sum(wt_f) as w_f,sum(wt_d) as w_d,sum(wt_pr)as w_pr,sum(wt_f_rebate) as w_f_rebate,
sum(wt_f_large) as w_f_large,sum(wt_f_medium) as w_f_medium,sum(wt_f_small) as w_f_small,
sum(wt_d_minor) as w_d_minor,sum(wt_d_major) as w_d_major
from regmode_k a
group by a.iri_key,a.week;
quit;

/* Joining Scotties and Kleenex*/

proc sql;
create table panel as
select a.w_price as S_price,b.w_price as K_price,  a.iri_key,a.week,a.T_sales,
a.w_f,a.w_d,a.w_pr,a.w_f_rebate,a.w_f_large,a.W_f_medium,a.w_f_small,a.w_d_minor,a.w_d_major
from panel_s a
inner join
panel_k b
on a.iri_key=b.iri_key and a.week=b.week;
quit;

/* Creating Interaction Terms */
data panel;
set panel;
F_D=w_d*w_f;
F_PR=w_f*w_pr;
pr_d=w_pr*w_d;
run;

/*Creating Non Linear Terms */
data panel;
set panel;
Fsq=w_f*w_f;
Dsq=w_d*w_d;
Prsq=w_pr*w_pr;
pricesq=S_price*S_price;
run;

/* Creating Seasonal Dummies */
data panel;
set panel;
if 1114<=week<=1130 then S1=1; else S1=0;
if 1131<=week<=1148 then S2=1; else S2=0;
if 1149<=week<=1165 then S3=1; else S3=0;
run;

/* Creating Seasonal Interactions */
data panel;
set panel;
S1_pr=S1*w_pr;
S2_pr=S2*w_pr;
S3_pr=S3*w_pr;
S1_d=S1*w_d;
S2_d=S2*w_d;
S3_d=S3*w_d;
S1_f=S1*w_f;
S2_f=S2*w_f;
S3_f=S3*w_f;
run;

/* Time Series*/
proc SQL;
create TABLE Time_Series As
SELECT Week, SUM(T_Sales) AS Sales
FROM Panel
group by Week;
quit;

/* Sales Plot of Scotties */
proc sgplot data=Time_Series;
series y= Sales x=week/ markers;
run;

/* Base Model */
proc panel data = panel;
id iri_key week;
model "Random-One" T_sales=s_price w_pr w_d w_f/ ranone;
run;

/* FE Base Model */
proc panel data = panel;
id iri_key week;
model "Fixed-two" T_sales=S_price w_pr w_d w_f/ fixone;
run;

/* Base Model with Season Effect (PR) not significant */
proc panel data = panel;
id iri_key week;
model "Fixed-One" T_sales=S_price w_pr w_d w_f S1_pr S2_pr S1 S2 / fixone;
run;

/* Base Model with Season Effect (F)*/
proc panel data = panel;
id iri_key week;
model "Fixed-One" T_sales=S_price w_pr w_d w_f S1_f S2_f S1 S2 / fixone;
run;

/* Base Model with Season Effect (D) rsq =.55*/ 
proc panel data = panel;
id iri_key week;
model "Fixed-One" T_sales=S_price w_pr w_d w_f S1_d S2_d S1 S2 / fixone;
run;

/* Base Model with Season Effect(Overall) removed pr */
proc panel data = panel;
id iri_key week;
model "Fixed-One" T_sales=S_price w_pr w_d w_f S1_d S2_d S1_f S2_f S1 S2 / fixedone;
run;

/* Model with all effects */
proc panel data = panel;
id iri_key week;
model "Fixed-One" T_sales=S_price w_pr w_d w_f S1_d S2_d S1_f S2_f S1 S2 F_D S1_pr S2_pr/ fixone;
run;

/* Final Model(Random Effects) */
proc panel data = panel;
id iri_key week;
model "Random-One" T_sales=s_price k_price  S1 S2 w_d w_f w_pr S1_d s2_d s1_f s2_f f_d s1_pr s2_pr/ ranone;
run;

/* Final Model(Fixed Effects) */
proc panel data = panel;
id iri_key week;
model "Fixed-One" T_sales=s_price k_price  S1 S2 w_d w_f w_pr S1_d s2_d s1_f s2_f f_d s1_pr s2_pr/ fixone;
run;

proc means data =panel;
var T_sales s_price k_price;
run;
