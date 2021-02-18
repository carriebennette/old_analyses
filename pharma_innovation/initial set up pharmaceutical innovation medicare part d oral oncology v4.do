set more off
cd "/Users/carriebennette/Dropbox/K12 projects/Early Independence Award/Aim 2 Medicare Part D and Pharmaceutical Innovation"

use "incidence data trends (SEER) v3.dta", clear
g year2 = year*year
g gist = 1

foreach v in hodgkins pancreas gastric gist liver breast bladder colorectal all aml cll cml nhl basal childhoodleukemia kidney lung melanoma myeloma ovarian prostate thyroid cervical neuroblastoma {
	regress `v' year year2
	predict temp 
	replace `v' = temp if year>2012 
	drop temp
	rename `v' incidence_`v'
}

* incomplete data for NET
regress pNET year year2
predict temp 
replace pNET = temp if year>2009
rename pNET incidence_pNET 
drop temp

regress cns year year2
predict temp 
replace cns = temp if year>2009
rename cns incidence_cns 
drop temp

regress sarcoma year year2
predict temp 
replace sarcoma = temp if year>2009
rename sarcoma incidence_sarcoma
drop temp

reshape long incidence_, i(year) j(condition) string
rename incidence_ incidence

replace condition = "child" if condition=="childhoodleukemia"
replace condition = "CML" if condition=="cml"
replace condition = "CLL" if condition=="cll"
replace condition = "NHL" if condition=="nhl"
replace condition = "AML" if condition=="aml"
replace condition = "ALL" if condition=="all"
replace condition = "Hodgkin's lymphoma" if condition=="hodgkins"

tempfile incidence
save `incidence'

use "/Users/carriebennette/Dropbox/K12 projects/Early Independence Award/drugabacus data.dta", clear
keep genericname cemonths clinical rarity original unitprice
keep if cemonths!=.
rename genericname drugname
replace drugname = "imatinib" if strpos(drugname, "imatinib")>0

destring unitprice, ignore("$" ",") replace
replace original = strlower(original)
replace original = "CLL" if original=="leukemia cll"
replace original = "CML" if original=="leukemia cml"
replace original = "ALL" if original=="leukemia all" | original=="all"
replace original = "ALL" if original=="leukemia aml" | original=="aml"

replace original = "NHL" if original=="lymphoma" & (drugname=="ibritumomab" | drugname=="tositumomab")
replace original = "gastric" if original=="stomach"

rename original indicationcategory
g first = 1

replace drugname="bendamustine" if drugname=="bendamustine hydrochloride"
tempfile temp
save `temp'

use "/Users/carriebennette/Dropbox/K12 projects/Early Independence Award/Aim 2 Medicare Part D and Pharmaceutical Innovation/list of FDA approvals v9.dta", clear
g fdadaten = date(fdadate, "MDY", 2016)
g year = year(fdadaten)

replace drugname = "imatinib" if strpos(drugname, "imatinib")>0

replace indicationc = "pNET" if indication=="pancreatic neuroendocrine tumors (pNET)" | indication=="metastatic gastroenteropancreatic neuroendocrine tumors (GEP-NETs)" | indication=="progressive neuroendocrine tumors of pancreatic origin (PNET)"
replace indicationc="sarcoma" if indication=="advanced soft tissue sarcoma" | indication=="unresectable or metastatic liposarcoma or leiomyosarcoma "

* some drugs are for symptom management
drop if drugname=="denosumab" | drugname=="triptorelin pamoate"
drop if drugname=="methoxsalen" 

replace drugname = strtrim(drugname)
replace indicationcat = "breast" if indicationc=="Breast"
replace indicationcat = "lung" if indicationc=="Lung"
replace indicationcat = "head" if indicationc=="head and neck"

* manually change one indication (for merge with DrugAbacus data; will combine with 'lung' later)
*replace indicationcat = "mesothelioma" if indicationcat=="lung" & drugname=="pemetrexed" & year==2004

replace indicationcat = "ALL" if drugname=="cytarabine liposomal" & indicationc=="childhood leukemia"
*replace indicationcat = "ALL" if indicationc=="childhood leukemia" & (drugname~="imatinib mesylate" | drugname=="clofarabine")
*replace indicationcat = "CML" if indicationc=="childhood leukemia" & drugname=="imatinib mesylate"

* no idea why, but for some reason imatinib is showing up as two different drugs...

g oral = inlist(oral, "oral", "Tablets")
g iv = inlist(oraliv, "Injection", "Intravenous", "intrathecal", "intravenous", "intramuscular", "subcutaneous")

bysort drugname indicationc (fdadaten): g first = _n==1

* one drug approved prior to 1995 - fix manunally:
replace first = 0 if drugname=="tamoxifen"

merge m:1 drugname indicationcategory first using `temp'

* pemetrexed is repeated (x2)
drop if indicationcat=="mesothelioma"
replace cemonths = 3 if indicationcat== "lung" & drugname=="pemetrexed" & year==2004

****** MANUAL UPDATES: EFFICACY DATA FROM https://www.aeaweb.org/articles.php?doi=10.1257/jep.29.1.139 ******
*** NOTE TO SELF: rituximab estimates in AEA paper are wrong??? (udpated below)

replace cemonths = 2.7 if drugname=="docetaxel" & year==1996
replace cemonths = 2.7 if drugname=="irinotecan" & year==1996
replace cemonths = 2.3 if drugname=="topotecan" & year==1996
replace cemonths = 2.9 if drugname=="anastrozole" & year==1995
replace cemonths = 3 if drugname=="capecitabine" & year==1998 & indicationc=="breast"
replace cemonths = 3.7 if drugname=="exemestane" & year==1999 & indicationc=="breast"
replace cemonths = 3 if drugname=="everolimus" & year==2012 & indicationc=="breast"

	* PFS survival for exemestane...
replace cemonths = 2.32 if drugname=="letrozole" & year==1997 & indicationc=="breast"
replace cemonths = 6.36 if drugname=="alemtuzumab" & year==2001 & indicationc=="CLL"
replace cemonths = 1.1 if drugname=="rituximab" & year==2010 & indicationc=="CLL"
replace cemonths = 2.7 if drugname=="trastuzumab" & year==1998 & indicationc=="breast"

* notes to self: 
	* no applicable data (single arm studies) for cladribine (so exclude 1993!), pegaspargase, vincristine, omacetaxine, busulfan, bevacizumab (cns), bendamustine (NHL), cytarabine, lenalidomide (NHL), ibrutinib (NHL), osimertinib (lung)
	* only surrogate endpoint (no survival): bexarotene (tumor response), pembrolizumab (lung), porfimer sodium, belinostat, romidepsin, pralatrexate, bevacizumab (breast), plerixafor (NHL), degarelix (prostate), topotecan (lung), ponatinib (CML), bosutinib (CML), talimogene (melanoma)
	* no data (weird label); doxorubicin (ovarian)
	* nab-paclitaxel for lung was non-inferiority trial...?
	* ruxolitinib has not reached median survival yet (myeloma), nor has ibrutinib (CLL)
	* treatments for ALL dont' include median survival...mercaptopurine, 
	* if drug~="pegaspargase" & drug~="pembrolizumab" & drug~="belinostat" & drug~="vincristine" & drug~="omacetaxine" & drug~="busulfan" & drug~="bendamustine" & drug~="cytarabine" & drug~="plerixafor" & drug~="degarelix" & drug~="topotecan" & drug~="doxorubicin" & drug!="porfimer sodium" & drug~="belinostat" & drug~="romidepsin" & drug~="pralatrexate" 
	* accelerated approval: idelalisib (CLL & NHL), pembrolizumab (lung), daratumumab (myeloma)
	
***** MANUAL UPDATES: EFFICACY DATA FROM MY REVIEW (FDA Labels) ******* 
replace cemonths = 1.8 if drugname=="trifluridine/tipiracil" & year==2015
replace cemonths = 5 if drugname=="cobimetinib" & year==2015
replace cemonths = 5.9 if drugname=="ixazomib" & year==2015
replace cemonths = 2.8 if drugname=="nivolumab" & year==2015 & indicationc=="lung" & first==1
replace cemonths = 1.4 if drugname=="gemcitabine" & year==1996 & indicationc=="lung"
replace cemonths = 1.6 if drugname=="ramucirumab" & year==2015 & indicationc=="colorectal"
replace cemonths = 1.4 if drugname=="ramucirumab" & year==2014 & indicationc=="lung"
replace cemonths = 1.6 if drugname=="necitumumab" & year==2015 & indicationc=="lung"
replace cemonths = 3.3 if drugname=="bevacizumab" & year==2014 & indicationc=="ovarian"
replace cemonths = 2.5 if drugname=="temozolomide" & year==1999 & indicationc=="cns"
replace cemonths = 0.42 if drugname=="denileukin" & year==1999 & indicationc=="NHL"
replace cemonths = 1.6 if drugname=="vinorelbine" & year==1994 & indicationc=="lung"
	* denileukin was kind of a weird one
replace cemonths = 4 if drugname=="epirubicin" & year==1999 & indicationc=="breast"
	* epirubicin is somewhat of an estimate reading of KM curve!
replace cemonths = 5 if drugname=="sorafenib" & year==2013 & indicationc=="thyroid"
replace cemonths = 4.5 if drugname=="elotuzumab" & year==2015 & indicationc=="myeloma"
replace cemonths = 0.9 if drugname=="capecitabine" & year==2001 & indicationc=="colorectal"
replace cemonths = 0.4 if drugname=="toremifene" & year==1997 & indicationc=="breast"
replace cemonths = 4.8 if drugname=="bevacizumab" & year==2009 & indicationc=="kidney"
replace cemonths = 0 if drugname=="bevacizumab" & year==2008 & indicationc=="breast"
* paclitaxel (breast - 1994) has not reached median survival 
	replace cemonths = 3.4 if drugname=="paclitaxel" & indicationc=="breast" & year==1994
	* http://www.cancernetwork.com/articles/paclitaxel-improves-survival-metastatic-breast-cancer
	
replace cemonths = 2.7 if drugname=="docetaxel" & year==1999 & indicationc=="lung"
	* for docetaxel (lung) I took average of two trial results (5.3 and 0.1 improvement in PFS)
replace cemonths = 10.5 if drugname=="lenalidomide" & year==2006 & indicationc=="myeloma"
replace cemonths = 9.3 if drugname=="peginterferon alfa-2b" & indicationc=="melanoma" & year==2011
	* for peginterferon alfa-2b effect was recurrence free survival... 
replace cemonths = 8.7 if drugname=="carfilzomib" & indicationc=="myeloma" & year==2012
replace cemonths = 2.4 if drugname=="dabrafenib" & indicationc=="melanoma" & year==2013
replace cemonths = 6.4 if drugname=="trametinib and dabrafenib" & indicationc=="melanoma" & year==2014
replace cemonths = 3.7 if drugname=="bicalutamide"
replace cemonths = 4.9 if drugname=="cabozantinib" & indicationc=="kidney" & year==2016 
*replace cemonths = 52.44 if drugname=="dinutuximab" & indicationc=="neuroblastoma" & year==2015
replace cemonths = 13.7 if drugname=="thalidomide" & indicationc=="myeloma" & year==2006
		* based on improvement in 3-year event-free survival: http://www.ncbi.nlm.nih.gov/pubmed/16873668

replace cemonths = 40 if drugname=="tretinoin"
		*based on improvement in 1-year event-free survival: http://www.nature.com/leu/journal/v14/n8/full/2401859a.html#fig1

replace cemonths = 31.5 if drugname=="imatinib" & indicationc=="gist" & year==2002
replace cemonths = 3.9 if drugname=="regorafenib" & indicationc=="gist" & year==2013
	* http://www.medscape.com/viewarticle/779854
	
replace cemonths = 18.1 if drugname=="sunitinib" & indicationc=="gist" & year==2006
	* http://www.accessdata.fda.gov/spl/data/6560ebd9-1955-4857-86c1-69a483075b96/6560ebd9-1955-4857-86c1-69a483075b96.xml#section-13.1

replace cemonths = 2.8 if drugname=="sorafenib" & indicationc=="liver" & year==2007
	* http://www.accessdata.fda.gov/spl/data/c614a52e-7ba4-4adb-b11c-d34bc7165dd6/c614a52e-7ba4-4adb-b11c-d34bc7165dd6.xml#section-13

	* FDA LABEL UPDATES
replace cemonths = 2.5 if drugname=="trastuzumab" & indicationc=="gastric" & year==2010
replace cemonths = 6 if drugname=="everolimus" & indicationc=="pNET" & year==2011
replace cemonths = 4.8 if drugname=="sunitinib" & indicationc=="pNET" & year==2011
replace cemonths = 7.2 if drugname=="eribulin"
replace cemonths = 11.9 if drugname=="obinutuzumab" & indicationc=="NHL" & year==2016
replace cemonths = 1.9 if drugname=="irinotecan" & indicationc=="pancreas" & year==2014
replace cemonths = 4.2 if drugname=="pembrolizumab" & indicationc=="lung" & year==2015
replace cemonths = 2 if drugname=="bevacizumab" & indicationc=="lung" & year==2006
replace cemonths = 19.7 if drugname=="cetuximab" & indicationc=="head" & year==2006
replace cemonths = 0.6 if drugname=="docetaxel" & indicationc=="gastric" & year==2006
replace cemonths = 3.1 if drugname=="docetaxel" & indicationc=="head" & year==2006
replace cemonths = 2.4 if drugname=="docetaxel" & indicationc=="prostate" & year==2004
replace cemonths = 2.8 if drugname=="doxorubicin" & indicationc=="myeloma" & year==2007
replace cemonths = 0.7 if drugname=="doxorubicin" & indicationc=="ovarian" & year==1995
replace cemonths = 2.3 if drugname=="gemcitabine" & indicationc=="breast" & year==2004
replace cemonths = 2.8 if drugname=="gemcitabine" & indicationc=="ovarian" & year==2006
replace cemonths = 1.9 if drugname=="irinotecan" & indicationc=="pancreas" & year==2015
replace cemonths = 1.8 if drugname=="nab-paclitaxel" & indicationc=="pancreas" & year==2013
replace cemonths = 0.3 if drugname=="topotecan" & indicationc=="lung" & year==1998
replace cemonths = 2.7 if drugname=="trabectedin" & indicationc=="other" & year==2015
replace cemonths = 1 if drugname=="rituximab" & year==1997
	* above is corrected estimate from AEA paper. 

replace cemonths = 3 if drugname=="pazopanib" & year==2012 & indicationc=="sarcoma"
replace cemonths = 9.1 if drugname=="lenvatinib" & year==2016 & indicationc=="kidney"

* some more fixes:
replace cemonths = 3.4 if drugname=="letrozole" & year==2001 & indicationc=="breast" 
replace cemonths = 0 if drugname=="crizotinib" & year==2011 & indicationc=="lung" 
replace cemonths = 4.9 if drugname=="palbociclib" & year==2016 & indicationc=="breast" & cemonths==.
replace cemonths = 5.2 if drugname=="lapatinib" & year==2010 & indicationc=="breast" & cemonths==.
replace cemonths = 3.5 if drugname=="gefitinib" & year==2015 & indicationc=="lung" & cemonths==.
replace cemonths = 3.4 if drugname=="erlotinib" & year==2004 & indicationc=="lung" 
replace cemonths = 1 if drugname=="erlotinib" & year==2010 & indicationc=="lung" & cemonths==.
replace cemonths = 5.2 if drugname=="abiraterone acetate" & year==2011 & indicationc=="prostate"
replace cemonths = 4.6 if drugname=="abiraterone acetate" & year==2012 & indicationc=="prostate"
replace cemonths = 0 if drugname=="nilotinib" & year==2010 & indicationc=="CML"
replace cemonths = 0 if drugname=="dasatinib" & year==2010 & indicationc=="CML"

*could be higher! http://www.medscape.com/viewarticle/836729
replace cemonths = 5.4 if drugname=="lanreotide" & indicationc=="pNET" & year==2014

* fix one indication category
replace indicationc = "NHL" if indication=="Waldenstrom’s macroglobulinemia"

* drug used for chemoprevention and two other indications that aren't cancer:
drop if indicationc=="chemoprevention (other)"
drop if indication=="pediatric and adult patients with atypical hemolytic uremic syndrome (aHUS)"
drop if drugname=="siltuximab"

* NOW DROP A COUPLE WEIRD ONES!
drop if indicationc=="other" | indicationc=="NET"

* SENSITIVITY ANALYSIS
*drop if drugname=="imatinib" 

drop first
bysort drugname indicationc (fdadaten): g first=_n==1
keep if first==1

g year_condition = .
foreach v in AML ALL NET pNET basal bladder cervical cns gastric gist liver head hodgkins neuroblastoma sarcoma ovarian pancreas breast lung NHL CML CLL child colorectal kidney myeloma prostate melanoma thyroid {
	g count_oral_`v'=.
	g count_iv_`v'=.
	g avg_benefits_oral_`v'=.
	g avg_benefits_oral2_`v'=.
	g avg_benefits_iv_`v'=.
	
	g oral_cedata_`v'=.
	g iv_cedata_`v'=.
	
	forvalues x=1993/2016{
		qui count if indicationcat=="`v'" & year==`x' & oral==1  & cemonths~=.
		qui replace count_oral_`v' = r(N) if year==`x' & oral==1  

		qui count if indicationcat=="`v'" & year==`x' & iv==1  & cemonths~=.
		qui replace count_iv_`v' = r(N) if year==`x'  & iv==1  

		qui sum cemonths if indicationcat=="`v'" & year==`x' & oral==1  
		qui replace avg_benefits_oral_`v' = r(mean) if year==`x' & oral==1 
		qui replace avg_benefits_oral2_`v' = r(mean) if year==`x' & oral==1 

		qui sum cemonths if indicationcat=="`v'" & year==`x' 
		qui replace avg_benefits_oral2_`v' = r(mean) if year==`x' & year<=2002 &  (avg_benefits_oral2_`v'==. | avg_benefits_oral2_`v'==0) & indicationcat~="CML" & indicationcat~="breast" & indicationcat~="colorectal" & indicationcat~="kidney" & indicationcat~="lung" & indicationcat~="prostate"
	
		*qui sum cemonths if indicationcat=="`v'" & year==`x' 
		*qui replace avg_benefits_oral2_`v' = r(mean) if avg_benefits_oral2_`v'==. & year==`x' & year<=2002 

		qui sum cemonths if indicationcat=="`v'" & year==`x' & iv==1 
		qui replace avg_benefits_iv_`v' = r(mean) if year==`x' & iv==1 

		qui sum cemonths if indicationcat=="`v'" & year==`x' & oral==1 
		qui replace oral_cedata_`v' = r(N) if year==`x' & oral==1 

		qui sum cemonths if indicationcat=="`v'" & year==`x' & iv==1 
		qui replace iv_cedata_`v' = r(N) if year==`x' & iv==1 
	}	
			
}

collapse (mean) count_oral_* count_iv_* avg_benefits_* oral_cedata_* iv_cedata_* , by(year)
reshape long count_oral_ oral_cedata_ iv_cedata_ count_iv_ avg_benefits_oral_  avg_benefits_oral2_ avg_benefits_iv_ , i(year) j(condition) string

** MERGE INCIDENCE DATA **
merge 1:1 year condition using `incidence'	

g proportion65 = .69 if condition=="lung"
replace propor = .61 if condition=="myeloma"
replace prop = .59 if condition=="colorectal"
replace prop = .42 if condition=="breast"
replace prop = .55 if condition=="NHL"
replace prop = .57 if condition=="prostate"
replace prop = .68 if condition=="CLL"
replace prop = .49 if condition=="CML"
replace prop = .727 if condition=="bladder"
replace prop = .456 if condition=="melanoma"
replace prop = .196 if condition=="thyroid"
replace prop = .112 if condition=="ALL"
replace prop = .637 if condition=="liver"
replace prop = .454 if condition=="ovarian"
replace prop = .196 if condition=="cervical"
replace prop = .664 if condition=="pancreas"
replace prop = .483 if condition=="kidney"
replace prop = .551 if condition=="AML"
replace prop = .361 if condition=="cns"
replace prop = .690 if condition=="gastric"
replace prop = 0.23 if condition=="sarcoma"
replace prop = 0.43 if condition=="head"

*need better estimate for basal, gist, NET (but doens't affect results)
replace prop = 0.60 if condition=="basal"
replace prop = 0.40 if condition=="gist"
replace prop = 0.35 if condition=="pNET"
replace prop = 0.178 if condition=="hodgkins"

*drop if  year<1994 

save "master data pharmaceutical innovation and health benefits medicare part D v4.dta", replace
