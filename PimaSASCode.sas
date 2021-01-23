proc import datafile= "PimaDataset.csv" out=diabetes replace;
delimiter=',';
getnames=yes;
run;
data diabetes;
set diabetes;
if outcome=1 then outcomelabel= 'Diabetes';
else outcomelabel='NoDiabetes';
run;

proc sort;
by outcome;
run;
proc boxplot;
plot Pregnancies*outcomelabel;
plot glucose*outcomelabel;
plot bloodpressure*outcomelabel;
plot SkinThickness*outcomelabel;
plot Insulin*outcomelabel;
plot BMI*outcomelabel;
plot DiabetesPedigreeFunction*outcomelabel;
plot age*outcomelabel;
run;

proc import datafile= "PimaDataset.csv" out=diabetes replace;
delimiter=',';
getnames=yes;
run;
Title "Pima Dataset";
proc print;
run;
*/Frequency Table for Outcome = 0 or 1;
title 'Outcome Frequency Table';
proc freq ;
tables outcome;
run;
proc print;
run;

Proc univariate;
Title 'DATA EXPLORATION Histograms';
histogram pregnancies;
histogram glucose;
histogram Bloodpressure;
histogram SkinThickness;
histogram Insulin;
histogram BMI;
histogram DiabetesPedigreeFunction;
histogram Age;
run;

*/Full Model Diagnostics;
proc logistic data = diabetes;
TITLE 'Full Model Diagnostics';
model outcome(event = '1') = Pregnancies Glucose BloodPressure SkinThickness Insulin BMI DiabetesPedigreeFunction Age Glucose*BMI BloodPressure*Age/ stb corrb influence iplots;
run;

data remove_outlier_inf;
set diabetes;
if _n_ = 229 then delete;
If _n_ = 488 then delete;
if _n_ = 130 then delete;
if _n_ = 7 then delete;
if _n_ = 490 then delete;
if _n_ = 674 then delete;
run;

*/Split data into training/testing = .80/.20;
*/ samprate = 80% of obs;
*/ out = train is new dataset;
proc surveyselect data=remove_outlier_inf out=train seed=682323
samprate = .80 outall;
run;


proc freq data=train;
TITLE "Training Set Frequency";
tables selected;
run;

*/compute train_y to run model selection on training set only;
data train;
set train;
if selected then train_y = Outcome;
run;


*/Forward Method;
proc logistic data = train;
TITLE "FORWARD";
model train_y(event = '1') = Pregnancies Glucose BloodPressure SkinThickness Insulin BMI DiabetesPedigreeFunction Age 
Glucose*BMI BloodPressure*Age/ selection = forward rsquare;
run;

*/Backward Method;
proc logistic data = train;
TITLE "BACKWARD";
model train_y(event = '1') = Pregnancies Glucose BloodPressure SkinThickness Insulin BMI DiabetesPedigreeFunction Age 
Glucose*BMI BloodPressure*Age/ selection = backward rsquare;
run;

*/Stepwise Method;
proc logistic data = train;
TITLE "STEPWISE";
model train_y(event = '1') = Pregnancies Glucose BloodPressure SkinThickness Insulin BMI DiabetesPedigreeFunction Age 
Glucose*BMI BloodPressure*Age/ selection = stepwise rsquare;
run;

*/ Check Diagnostics for Final Model;
TITLE "Final Training Model";
proc logistic data = train;
model train_y(event = '1') = Pregnancies Glucose BMI DiabetesPedigreeFunction /stb corrb influence iplots;
run;

proc logistic data = train;
model train_y(event = '1') = Pregnancies Glucose BMI DiabetesPedigreeFunction/ ctable pprob = (0.1 to 0.6 by .025);
output out = pred(where=(train_y=.)) p=phat lower=lcl upper=ucl predprob=(individual);
title "Prediction Dataset";
run;

data probs;
set pred;
pred_outcome = 0;
threshold = 0.275;
if phat>threshold then pred_outcome=1;
run;

proc freq data = probs;
TITLE "Classification Matrix";
tables outcome*pred_outcome/norow nocol nopercent;
run;




* Prediction Testing for Confidence levels and Probabilities;
data new;
input Pregnancies Glucose BloodPressure SkinThickness Insulin BMI DiabetesPedigreeFunction Age;
datalines;
3 170 . . . 36 .8 .
7 120 . . . 26 1.2 .
1 99 . . . 24 .5 .
16 200 . . . 44 2.5 .
4 150 . . . 31 1.6 .
;
data scenario;
set new train;
run;

proc logistic data = scenario;
model train_y(event = '1') = Pregnancies Glucose BMI DiabetesPedigreeFunction;
output out = scenarionew(where=(train_y=.))  p=phat lower=lcl upper=ucl predprob =(individual);
title "Scenario Dataset";
run;

proc print data = scenarionew;
run;


