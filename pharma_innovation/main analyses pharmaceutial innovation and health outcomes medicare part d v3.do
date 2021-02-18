

set more off
*cd "/Users/carriebennette/Dropbox/K12 projects/Early Independence Award/Aim 2 Medicare Part D and Pharmaceutical Innovation"
cd "/Users/carriebennette/Dropbox/Papers/submitted/Aim 2 Medicare Part D and Pharmaceutical Innovation"

*use "temp data pharmaceutical innovation and health benefits medicare part D v3.dta", replace
use "master data pharmaceutical innovation and health benefits medicare part D v6.dta", replace

drop _merge
merge m:1 condition year using "master data NCI funding trends innovation.dta"

* set post year here
global year = "2008"
g post_partD = year>=$year

g prop65_post  = (post*proportion65)*100
g logincidence = log(incidence)*10

*** SENSITIVITY ANALYSIS *****
*drop if condition=="lung"

encode condition, gen(condition_n)
xtset condition_n year

* create dummy variables for year (need for 'printmodel' program)
keep if year>1993
tab year, gen(year_d)

g log_funding = log(funding_imputed)


* number of ORAL drugs, compared to before 2002 
xtpoisson count_oral post loginc prop65_post i.year if (year<=2003 | year>=$year) , fe robust irr
disp %4.1f (exp(_b[prop65_post])-1)*100 " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
disp %4.1f ((_b[prop65_post])) " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 

disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 

* restricted to conditions with at least ONE oral drug before 2002
* xtpois count_oral post count_iv loginc i.year prop65_post if inlist(condition,  "CML", "Hodgkin's lymphoma", "NHL", "breast", "colorectal", "gist", "prostate") & (year<=2003 | year>=$year), fe robust

* number of IV drugs, compared to before 2002 
xtpois count_iv post loginc prop65_post i.year if (year<=2003 | year>=$year), fe robust irr
disp %4.1f (exp(_b[prop65_post])-1)*100 " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
disp %4.3f (exp(_b[prop65_post])) " (95% CI:" %4.3f (exp(_b[prop65_post]-_se[prop65_post]*1.96)) ", " %4.3f (exp(_b[prop65_post]+_se[prop65_post]*1.96)) ") % change" 

disp %4.3f (exp(_b[prop65_post])) " (95% CI:" %4.3f (exp(_b[prop65_post]-_se[prop65_post]*1.96)) ", " %4.3f (exp(_b[prop65_post]+_se[prop65_post]*1.96)) ") % change" 

disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 

* clinical benefits
* simple before and after:
g any_oral = avg_benefits_oral_~=.
replace avg_benefits_oral2_ = 0 if avg_benefits_oral2_==.
replace avg_benefits_oral_ = 0 if avg_benefits_oral_==.
replace avg_benefits_iv = 0 if avg_benefits_iv==.

* returns to health (drop 1994 so model converges; same point estimate):
xtpois avg_benefits_oral_ prop65_post post any_oral  loginc i.year  if (year<=2003 | year>=$year) & year>1994, fe robust irr
disp %4.1f (exp(_b[prop65_post])-1)*100 " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
disp %4.3f (exp(_b[prop65_post])) " (95% CI:" %4.3f (exp(_b[prop65_post]-_se[prop65_post]*1.96)) ", " %4.3f (exp(_b[prop65_post]+_se[prop65_post]*1.96)) ") % change" 

disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 

* relative scale returns to health (drop 1994 so model converges; same point estimate):
g log_hr = log(avg_hr_oral)
xtreg log_hr  post any_oral loginc i.year prop65_post if (year<=2003 | year>=$year) & year>1994, fe robust 
disp %4.1f (exp(_b[prop65_post])-1)*100 " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 

* and including non-oral drugs before 2002 (for conditions without oral drugs approved before 2002!):
g any_oral2 = oral_cedata>0 & oral_cedata<.
replace any_oral2 = 1 if iv_cedata>0 & iv_cedata<. & year<=2003 & condition~="CML" & condition~="breast" & condition~="colorectal" & condition~="kidney" & condition~="lung" & condition~="prostate"

xtpois avg_benefits_oral2 any_oral2  loginc i.year post prop65_post if (year<=2003 | year>=$year) & year>1994, fe robust 
disp %4.1f (exp(_b[prop65_post])-1)*100 " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 
	
* and negative binomial
xtnbreg avg_benefits_oral2 any_oral2  loginc i.year post prop65_post if (year<=2003 | year>=$year) & year<2016, fe  
disp %4.1f (exp(_b[prop65_post])-1)*100 " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 

	* explore negative binomial
	xtnbreg avg_benefits_oral2 any_oral2 count_iv loginc i.year  post prop65_post if (year<=2003 | year>=$year) & year<2016, fe  
	disp %4.1f (exp(_b[prop65_post])-1)*100 " (95% CI:" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
	disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 

* IV rugs
g any_iv = iv_cedata>0 & iv_cedata<.
xtpois avg_benefits_iv  any_iv loginc i.year  post prop65_post if (year<=2003 | year>=$year) , fe robust irr 
disp %4.1f (exp(_b[prop65_post])-1)*100 " (" %3.1f (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 ", " %3.1f (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 ") % change" 
disp %4.3f (exp(_b[prop65_post])) " (95% CI:" %4.3f (exp(_b[prop65_post]-_se[prop65_post]*1.96)) ", " %4.3f (exp(_b[prop65_post]+_se[prop65_post]*1.96)) ") % change" 

disp %4.1f ((_b[logincidence])) " (95% CI:" %3.1f ((_b[logincidence]-_se[logincidence]*1.96)) ", " %3.1f ((_b[logincidence]+_se[logincidence]*1.96)) ") % change" 


* AND NOW LET'S LOOK AT EFFECT OVER TIME: 
use "master data pharmaceutical innovation and health benefits medicare part D v3b.dta", replace
keep if year>1993

g any_oral = avg_benefits_oral_~=.
replace avg_benefits_oral2_ = 0 if avg_benefits_oral2_==.
replace avg_benefits_oral_ = 0 if avg_benefits_oral_==.
replace avg_benefits_iv = 0 if avg_benefits_iv==.
g any_oral2 = oral_cedata>0 & oral_cedata<.
replace any_oral2 = 1 if iv_cedata>0 & iv_cedata<. & year<=2003 & condition~="CML" & condition~="breast" & condition~="colorectal" & condition~="kidney" & condition~="lung" & condition~="prostate"
g any_iv = iv_cedata>0 & iv_cedata<.
* set post year here
global year = "2008"
g post_partD = year>=$year

g prop65_post  = (post*proportion65)*100
g logincidence = log(incidence)

*** SENSITIVITY ANALYSIS *****
*drop if condition=="lung"

encode condition, gen(condition_n)
xtset condition_n year

* create dummy variables for year (need for 'printmodel' program)
tab year, gen(year_d)


replace post = year>=2000
replace prop65_post = post*proportion65*100
g beta = .
g beta_lb = .
g beta_ub = .
g index = _n

xtpois count_oral post loginc i.year count_iv prop65_post if (year<1999 | inlist(year, 1999, 2000, 2001, 2002)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 1
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 1 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 1

xtpois count_oral post loginc i.year count_iv prop65_post if (year<1999 | inlist(year, 2003, 2004, 2005, 2006, 2007)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 2
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 2
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 2

xtpois count_oral post loginc i.year count_iv  prop65_post if (year<1999 | inlist(year,  2008, 2008, 2009, 2010, 2011, 2012)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 3
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 3
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 3

xtpois count_oral post  loginc i.year count_iv prop65_post if (year<1999 | inlist(year, 2013, 2014, 2015, 2016)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 4
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 4
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 4

twoway rspike beta_lb beta_ub index if beta_ub<30, graphregion(color(white)) lcolor(gray) || scatter beta index if beta<50, mcolor(navy) legend(off) msymbol(diamond) aspectratio(2) ///
	xlabel(1 "1999-01" 2 "2003-07" 3  "2008-12" 4 "2013-16" , angle(40)) xtitle("") ylabel( -10 "-10%" 0 "0%" 10 "10%" 20 "20%" 24 " ") ytitle("Percent change in # FDA approvals" " ")
          

xtpois count_iv post loginc i.year count_oral prop65_post if (year<1999 | inlist(year, 1999, 2000, 2001, 2002)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 1
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 1 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 1

xtpois count_iv post loginc i.year count_oral prop65_post if (year<1999 | inlist(year,  2004, 2005, 2006, 2007)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 2
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 2
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 2

xtpois count_iv post loginc i.year count_oral prop65_post if (year<1999 | inlist(year, 2008, 2009, 2010, 2011, 2012)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 3
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 3
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 3

xtpois count_iv post loginc i.year count_oral prop65_post if (year<1999 | inlist(year, 2013, 2014, 2015, 2016 )) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 4
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 4
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 4

twoway rspike beta_lb beta_ub index in 1/4 if beta_lb>-20 & beta_ub<20, graphregion(color(white)) lcolor(gray) || scatter beta index in 1/4, mcolor(cranberry) legend(off) msymbol(diamond) aspectratio(2) ///
	xlabel(1 "1999-02" 2 "2002-07" 3  "2008-12" 4 "2013-16"  , angle(40)) xtitle("") ylabel( -10 "-10%" 0 "0%" 10 "10%" 20 "20%" 24 " ") ytitle("Percent change in # FDA approvals" " ")


* DON'T ADJUST FOR NUMBER OF AGENTS APPROVED in health benefits models!

xtpois avg_benefits_oral2  any_oral2  year post loginc  prop65_post if (year<1999 | inlist(year, 1999, 2000, 2001)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 1
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 1 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 1

xtpois avg_benefits_oral2  any_oral2  year post loginc  prop65_post if (year<1999 | inlist(year, 2003, 2004, 2005, 2006)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 2
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 2 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 2

xtpois avg_benefits_oral2  any_oral2  year post loginc prop65_post if (year<1999 | inlist(year, 2007, 2008, 2009, 2010, 2011, 2012)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 2
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 2
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 2

xtpois avg_benefits_oral2  any_oral2 year post loginc  prop65_post if (year<1999 | inlist(year,  2013, 2014, 2015, 2016)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 3
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 3 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 3

twoway rspike beta_lb beta_ub index in 1/3, graphregion(color(white)) lcolor(gray) || scatter beta index in 1/3, mcolor(navy) legend(off) msymbol(diamond) aspectratio(2) ///
	xlabel(1 "1999-01" 2  "2007-12" 3 "2013-16", angle(40)) xtitle("") ylabel(-20 "-20%" 0 "0%" 20 "20%") ytitle("Percent change in survival benefits" " ")

	* IV
xtpois avg_benefits_iv  any_iv year post loginc  prop65_post if (year<1999| inlist(year,  2000, 2001, 1999)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 1
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 1 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 1

xtpois avg_benefits_iv  any_iv year post loginc  prop65_post if (year<1999 | inlist(year, 2004, 2005,2006, 2007 )) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 2
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 2 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 2

xtpois avg_benefits_iv  any_iv year  post loginc  prop65_post if (year<1999 | inlist(year, 2007,  2008, 2009, 2010, 2011)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 2
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 2 
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 2

xtpois avg_benefits_iv  any_iv year  post loginc  prop65_post if (year<1999 | inlist(year, 2012,  2013, 2014, 2015, 2016)) , fe robust
replace beta = -(1-exp(_b[prop65_post]))*100 in 3
replace beta_lb = (exp(_b[prop65_post]-_se[prop65_post]*1.96)-1)*100 in 3
replace beta_ub = (exp(_b[prop65_post]+_se[prop65_post]*1.96)-1)*100 in 3

twoway rspike beta_lb beta_ub index in 1/3, graphregion(color(white)) lcolor(gray) || scatter beta index in 1/3, mcolor(cranberry) legend(off) msymbol(diamond) aspectratio(2) ///
	xlabel(1 "1999-01" 2  "2007-12" 3 "2013-16", angle(40)) xtitle("") ylabel(-20 "-20%" 0 "0%" 20 "20%") ytitle("Percent change in survival benefits" " ")
