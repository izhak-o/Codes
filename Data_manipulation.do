* Data manipulation for descriptive analysis

clear
use "C:\Users\tanja.saxell\Documents\Patent data\Originals\Orange_book_miss_examinr.dta", clear

* numeric claims
gen temp1=subinstr(Claims, ".0", "",.) 
replace temp1=subinstr(temp1, "[", "",.) 
replace temp1=subinstr(temp1, "]", "",.) 
destring temp1, generate(claims_num) 
drop temp1

sort appl_n
by appl_no: replace appl_type = appl_type[_n-1] if appl_type[_n]==""

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA.dta", replace

* two subsets: one for NDAs, one for ANDAs: New Drug Application Type
* appl_type: New Drug Applications (NDA or innovator)  are ”N”. Abbreviated New Drug Applications (ANDA or generic) are “A”.
clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA.dta"

keep if appl_type=="N"
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_NDA_subset.dta", replace
clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA.dta"
keep if appl_type=="A"
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_subset.dta", replace
clear

* Manipulate ANDA-data: 

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_subset.dta", clear
* keep IV and III challenges + method challenges

keep if ~missing(Application_Type_Number) | ~missing(method1) | ~missing(PIII_pat_1)

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges.dta", replace


***********************************************************
* Change data the format from wide to long
*********************************************************** 

* Challenged patents
clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents.dta", clear
keep appl_no Patent__1 Patent__2 Patent_3 Patent_4 Patent_5 Patent_6 Patent_7 Patent_8 Patent_9 Patent_10
keep if ~missing(appl_no)

rename Patent__1 vari1
rename Patent__2 vari2
rename Patent_3 vari3
rename Patent_4 vari4
rename Patent_5 vari5
rename Patent_6 vari6
rename Patent_7 vari7
rename Patent_8 vari8
rename Patent_9 vari9
rename Patent_10 vari10

reshape long vari, i(appl_no) j(Patent_id)
rename vari IV_challenged_patent
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_IV.dta", replace 
clear

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents.dta", clear
keep appl_no method C22 C23
keep if ~missing(appl_no)

rename method vari1
rename C22 vari2
rename C23 vari3

reshape long vari, i(appl_no) j(Patent_id)
rename vari method_challenged_patent
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_method.dta", replace 
clear


clear

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents.dta", clear
keep appl_no method C22 C23
keep if ~missing(appl_no)

rename method vari1
rename C22 vari2
rename C23 vari3

reshape long vari, i(appl_no) j(Patent_id)
rename vari method_challenged_patent
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_method.dta", replace 
clear




use "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents.dta", clear
keep appl_no PIII_pat_1 PIII_pat_2 PIII_pat_3 PIII_pat_4
keep if ~missing(appl_no)

rename PIII_pat_1 vari1
rename PIII_pat_2 vari2
rename PIII_pat_3 vari3
rename PIII_pat_4 vari4

reshape long vari, i(appl_no) j(Patent_id)
rename vari III_challenged_patent
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_III.dta", replace 
clear

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_IV.dta", clear
merge 1:1 appl_no Patent_id using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_method.dta" 
drop _merge
merge 1:1 appl_no Patent_id using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_III.dta" 
drop _merge

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_IV_method_III.dta", replace 

* Keep at least one obs per Application_Type_Number:
drop if missing(IV_challenged_patent) & missing(method_challenged_patent) & missing(III_challenged_patent) & Patent_id>1
* Note: can be dublicate observations (the same patent for different strengths etc.)
* Remove dublicate observations

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_IV_method_III.dta", replace 
clear

* Then merge this data to variables from ANDA

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_subset.dta", clear
keep appl_no applicant approval_date ingredient
* capitalize small letters:
replace approval_date=upper(approval_date)
replace ingredient=upper(ingredient)
* remove spaces: 
replace ingredient=subinstr(ingredient," ", "",.)

* approval date: e.g. 07 -> 7
replace approval_date=subinstr(approval_date,"01,","1,",1)
replace approval_date=subinstr(approval_date,"02,","2,",1)
replace approval_date=subinstr(approval_date,"03,","3,",1)
replace approval_date=subinstr(approval_date,"04,","4,",1)
replace approval_date=subinstr(approval_date,"05,","5,",1)
replace approval_date=subinstr(approval_date,"06,","6,",1)
replace approval_date=subinstr(approval_date,"07,","7,",1)
replace approval_date=subinstr(approval_date,"08,","8,",1)
replace approval_date=subinstr(approval_date,"09,","9,",1)

replace approval_date=subinstr(approval_date,"APPROVED PRIOR TO ","",1)

gen approval_date_num=date(approval_date,"MDY")
by appl_no, sort: egen min_approval_d=min(approval_date_num)
gen min_approval_date=approval_date if approval_date_num==min_approval_d

* fill missing obs

gsort appl_no -min_approval_date
replace min_approval_date = min_approval_date[_n-1] if min_approval_date=="" & _n !=1

* test 
list if min_approval_date==""

label variable min_approval_date "Min approval date by appl_no, only ANDAs"

drop approval_date approval_date_num min_approval_d

sort appl_no applicant min_approval_date ingredient
by appl_no applicant min_approval_date ingredient: gen dup=1 if _n>1
drop if dup==1
drop dup

* id
gen yksi=1
by appl_no ingredient, sort: gen id=sum(yksi)
drop yksi

reshape wide applicant, i(appl_no min_approval_date ingredient) j(id)

* Note: there can be many active ingredients per application

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\ANDA_modified.dta", replace 

merge m:m appl_no using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_ANDA_challenges_IV_method_III.dta"
* drop if master only (i.e. keep only challenges)
drop if _merge==1 

label data "This data includes IV, III and method challenges and information on FDA applications and approvals"
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Challenges_final.dta", replace 


* Now this data can be merged to the NDA data by any of the patent numbers or by active ingredient
* Let's first clean NDA data: 

clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_NDA_subset.dta", clear

drop Patent__1 Patent__2 Patent_3 Patent_4 Patent_5 Patent_6 Patent_7 Patent_8 Application_Type_Number Communication_Final_Date Patent_9 Patent_10 Date_of_ANDA_applicaiton method1 method2 method3 PIII_pat_1 PIII_pat_2 PIII_pat_4 patent1_float patent2_float patent3_float patent4_float patent5_float patent6_float patent7_float patent8_float patent9_float patent10_float method1_float method2_float method3_float PIII_p1_float PIII_p2_float PIII_p3_float PIII_pat_3 PIII_p4_float
* Keep if some patent info is available
keep if ~missing(patentt) | ~missing(patent) 

replace approval_date=upper(approval_date)
replace ingredient=upper(ingredient)
* remove spaces: 
replace ingredient=subinstr(ingredient," ", "",.)

* approval date: e.g. 07 -> 7
replace approval_date=subinstr(approval_date,"01,","1,",1)
replace approval_date=subinstr(approval_date,"02,","2,",1)
replace approval_date=subinstr(approval_date,"03,","3,",1)
replace approval_date=subinstr(approval_date,"04,","4,",1)
replace approval_date=subinstr(approval_date,"05,","5,",1)
replace approval_date=subinstr(approval_date,"06,","6,",1)
replace approval_date=subinstr(approval_date,"07,","7,",1)
replace approval_date=subinstr(approval_date,"08,","8,",1)
replace approval_date=subinstr(approval_date,"09,","9,",1)

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_NDA_subset_cleaned.dta", replace
clear

* Imitation measure 1: imitation vs. no imitation (1/0) per patent
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Challenges_final.dta", clear 
gen IV_challenged_indicator=1
keep IV_challenged_patent IV_challenged_indicator min_approval_date
rename IV_challenged_patent patentt, replace

by patentt, sort: egen IV_approval_date_min=min(date(min_approval_date,"MDY"))
format IV_approval_date_min %d
drop min_approval_date

by patentt, sort: gen first_o=1 if _n==1
drop if missing(first_o)
drop if missing(patentt)
drop first_o

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_per_patent.dta", replace
clear

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Challenges_final.dta", clear 
gen method_challenged_indicator=1
keep method_challenged_patent method_challenged_indicator min_approval_date
rename method_challenged_patent patentt, replace

by patentt, sort: egen method_approval_date_min=min(date(min_approval_date,"MDY"))
format method_approval_date_min %d
drop min_approval_date

by patentt, sort: gen first_o=1 if _n==1
drop if missing(first_o)
drop if missing(patentt)
drop first_o

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Method_chall_per_patent.dta", replace
clear

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Challenges_final.dta", clear 
gen III_challenged_indicator=1
keep III_challenged_patent III_challenged_indicator min_approval_date
rename III_challenged_patent patentt, replace

by patentt, sort: egen III_approval_date_min=min(date(min_approval_date,"MDY"))
format III_approval_date_min %d
drop min_approval_date


by patentt, sort: gen first_o=1 if _n==1
drop if missing(first_o)
drop if missing(patentt)
drop first_o

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\III_chall_per_patent.dta", replace
clear

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Challenges_final.dta", clear 
gen Challenged_active_ingredient=1
label var Challenged_active_ingredient "Active ingredient is challenged"
keep ingredient Challenged_active_ingredient min_approval_date

by ingredient, sort: egen Chall_approval_date_min=min(date(min_approval_date,"MDY"))
format Chall_approval_date_min %d
drop min_approval_date

by ingredient, sort: gen first_o=1 if _n==1
drop if missing(first_o)
drop first_o

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_per_active_ingredient.dta", replace

***

clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_NDA_subset_cleaned.dta", clear
drop _merge
merge m:1 patentt using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_per_patent.dta"
replace IV_challenged_indicator=0 if missing(IV_challenged_indicator) 

drop _merge
merge m:1 patentt using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Method_chall_per_patent.dta"
replace method_challenged_indicator=0 if missing(method_challenged_indicator) 

drop _merge
merge m:1 patentt using "C:\Users\tanja.saxell\Documents\Patent data\Merged\III_chall_per_patent.dta"
replace III_challenged_indicator=0 if missing(III_challenged_indicator) 

drop _merge
merge m:1 ingredient using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_per_active_ingredient.dta"
replace Challenged_active_ingredient=0 if missing(Challenged_active_ingredient) 



* continue here:

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_merged_analysis.dta", replace

***********************************************************

* Challenges thru exclusivity type

clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA.dta"
* 180 day exclusivity for the PIV challenge
keep if exclusivity_code=="PC" 
keep applicant approval_date dfroute ingredient strength trade_name 

by ingredient strength dfroute, sort: egen PC_approval_date=min(date(approval_date,"MDY"))
format PC_approval_date %d
drop approval_date

replace dfroute=strupper(dfroute)
replace ingredient=strupper(ingredient)
replace strength=strupper(strength)

replace dfroute=subinstr(dfroute," ", "",.)
replace ingredient=subinstr(ingredient," ", "",.)
replace strength=subinstr(strength," ", "",.)

rename applicant PC_applicant
rename trade_name PC_trade_name

bysort ingredient strength dfroute: gen first_o=1 if _n==1
keep if first_o==1
drop first_o

save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_PC_subset.dta", replace
clear

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_merged_analysis.dta", clear

replace dfroute=strupper(dfroute)
replace ingredient=strupper(ingredient)
replace strength=strupper(strength)

replace dfroute=subinstr(dfroute," ", "",.)
replace ingredient=subinstr(ingredient," ", "",.)
replace strength=subinstr(strength," ", "",.)

* from using                         12  (_merge==2)

drop _merge
merge m:1 ingredient strength dfroute using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Orange_book_drugs_FDA_PC_subset.dta"
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_merged_analysis_PC.dta", replace


* Merge drugs@FDA (collapsed) and Orange book: 

clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_merged_analysis_PC.dta", clear
sort appl_no product_no
rename _merge _merge_PC
merge m:1 appl_no product_no using "C:\Users\tanja.saxell\Documents\Patent data\Originals\drugsFDA_collapsed.dta"
drop if _merge==2

/*    
   Result                           # of obs.
    -----------------------------------------
    not matched                        50,270
        from master                    50,115  (_merge==1)
        from using                        155  (_merge==2)

    matched                            33,835  (_merge==3)
    -----------------------------------------

*/

* Drop if in using only

rename _merge _merge_OB_FDA
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_merged_analysis_PC.dta", replace

use "C:\Users\tanja.saxell\Documents\Patent data\Originals\Copy of PTA_total.dta", clear
gen Type_num=0
replace Type_num=1 if Delays=="Total"
drop Delays
reshape wide Days, i(Patent_no) j(Type_num)
rename Days0 Applicant_delay
rename Days1 Total_PTA

save "C:\Users\tanja.saxell\Documents\Patent data\Originals\PTA_total.dta", replace


clear 
use "C:\Users\tanja.saxell\Documents\Patent data\Originals\PTA_final.dta", clear

destring Days, replace
gen Type_num=0 
replace Type_num=1 if Delays=="B"
replace Type_num=2 if Delays=="C"
replace Type_num=3 if Delays=="Non"
replace Type_num=4 if Delays=="Overlapping"

drop Delays
drop if Patent_no==""
reshape wide Days, i(Patent_no) j(Type_num)
rename Days0 Delay_A
rename Days1 Delay_B
rename Days2 Delay_C
rename Days3 Delay_Non
rename Days4 Delay_Overlapping

merge 1:1 Patent_no using "C:\Users\tanja.saxell\Documents\Patent data\Originals\PTA_total.dta"
replace Applicant_delay=0 if missing(Applicant_delay)
label var Applicant_delay "Applicant delay, only if Delay_Non>0"
replace Total_PTA=0 if missing(Total_PTA)
drop _merge

save "C:\Users\tanja.saxell\Documents\Patent data\Originals\PTA_merged.dta", replace
use "C:\Users\tanja.saxell\Documents\Patent data\Originals\PTA_merged.dta", clear

rename Patent_no patent_no
merge 1:m patent_no using "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_merged_analysis_PC.dta"
rename _merge _merge_PTA
drop Col1

rename ingredient ingredient_original
gen ingredient=regexs(0) if regexm(ingredient_original, "[a-zA-Z]+")
replace ingredient=ingredient+", COMBINATIONS" if ingredient~=ingredient_original

merge m:1 ingredient using "C:\Users\tanja.saxell\Documents\Patent data\ther_sub.dta"
drop if _merge==2
drop _merge

* No combinations, ATC3
rename ingredient ingredient_comb
gen ingredient=regexs(0) if regexm(ingredient_original, "[a-zA-Z]+")

merge m:1 ingredient using "C:\Users\tanja.saxell\Documents\Patent data\ther_sub_atc3.dta"
drop if _merge==2
drop _merge


save "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_PC_PTA.dta", replace

