* Analysis for the data with PC (180 day patent challenge) exclusivities
clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_PC_PTA.dta", clear

* REpatentt: reissued patent, patent calculated based on the original patent: 
* http://www.genericsweb.com/Calculating_US_expiry_dates.pdf

* Mistake in data? Patent application date: Feb 26, 1894/Dec 10, 1926
drop if patentt==522982 | patentt==1712251
* Use only approved drugs in the OB
drop if _merge_OB_FDA==1 
drop if missing(appl_no)

gen patent_application_date_d=date(Patent_appl_date, "MDY")
gen patent_expire_date_d=date(patent_expire_date_text, "MDY")
format patent_expire_date_d patent_application_date_d %d
replace days_given=0 if missing(days_given)
gen patent_grant_date_d=date(Patent_grant_date, "MDY")
format patent_grant_date_d %d
gen expire2=subinstr(expire, "00:00:00", "",.)
replace expire2=subinstr(expire2, " ", "",.)
gen expire_ext=date(expire2, "YMD")
drop expire2
format expire_ext %d
gen approval_date_d=date(approval_date, "MDY")
format approval_date_d %d

keep if ~missing(patent_application_date_d) & ~missing(patent_expire_date_d) & ~missing(approval_date_d)

replace Delay_A=0 if missing(Delay_A)
replace Delay_B=0 if missing(Delay_B)
replace Delay_C=0 if missing(Delay_C)
replace Delay_Non=0 if missing(Delay_Non)
replace Delay_Overlapping=0 if missing(Delay_Overlapping)
replace Applicant_delay=0 if missing(Applicant_delay)
replace Total_PTA=0 if missing(Total_PTA)


* expire: patent extension file
* sometimes patent expire_date_text includes patent extensions, sometimes not

* Patent extensiosn
gen expire_extend=expire_ext+days_given
replace expire_extend=patent_expire_date_d if missing(expire_extend)
format expire_extend %d

* length from the extension file

gen length=expire_extend-patent_application_date_d 
* Length in months because #days/year varies
gen length_mo=(year(expire_extend)-year(patent_application_date_d))*12+month(expire_extend)-month(patent_application_date_d)
gen length_y=length_mo/12
gen length_y_sq=length_y*length_y

* Patent term (max length): standard length+PTA+PTE
* Compute patent term from application date
* Standard term: takes into account leap years!

gen temp1=mdy(month(patent_application_date_d),day(patent_application_date_d), year(patent_application_date_d)+20)
gen temp2=mdy(month(patent_grant_date_d),day(patent_grant_date_d), year(patent_grant_date_d)+17)
format temp1 temp2 %d
gen max_temp=max(temp1,temp2)
format max_temp %d
gen term_expiry=temp1
replace term_expiry=max_temp if patent_application_date_d<date("Jun 8, 1995", "MDY")  
replace term_expiry=term_expiry+days_given+Total_PTA
format term_expiry %d
gen term=term_expiry-patent_application_date_d
gen term_mo=(year(term_expiry)-year(patent_application_date_d))*12+month(term_expiry)-month(patent_application_date_d)
gen term_y=term_mo/12

drop temp1 temp2 max_temp

* Term in years 

corr term_y length_y
corr term_y length_y if length_y>=20
* 0.9113

bysort patentt: gen first_o_p=1 if _n==1
replace first_o_p=0 if missing(first_o_p)

sum term_y length_y

set scheme s2color

* Patent length vs. max length

twoway (histogram term_y if first_o_p==1, color(green)) ///
        (histogram length_y if first_o_p==1,  ///
         fcolor(none) lcolor(black)), graphregion(color(white)) bgcolor(white) legend(order(1 "Maximum length" 2 "Length in Orange Book"))

graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Length_vs_term.pdf", replace
		 
* Effective patent life (max) 

gen effective_life=(year(term_expiry)-year(approval_date_d))*12+month(term_expiry)-month(approval_date_d)
gen effective_life_y=effective_life/12
hist effective_life_y if first_o_p==1, title("") xtitle("Maximum effective life (years)") graphregion(color(white)) bgcolor(white)  

graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Effective_life.pdf", replace

gen effective_ext=(days_given+Total_PTA)/(term_expiry-approval_date_d)
sum effective_ext
hist effective_ext if first_o_p==1, title("") xtitle("Extensions/maximum effective life (years)") graphregion(color(white)) bgcolor(white)  
hist effective_ext if first_o_p==1 & days_given+Total_PTA>0, title("") xtitle("Extensions/maximum effective life, PTA+PTE>0") graphregion(color(white)) bgcolor(white)  
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Extension_rel_effectivelife.pdf", replace


* Average application time by(grant_year)

gen p_appl_year=substr(Patent_appl_date, -4, 4)
destring p_appl_year, replace
replace p_appl_year=1990 if p_appl_year<=1990
label var p_appl_year "Patent application year"
gen Time=((year(patent_grant_date_d)-year(patent_application_date_d))*12+month(patent_grant_date_d)-month(patent_application_date_d))/12
label var Time "Patent application time, years"

set scheme s2color
twoway fpfitci Time p_appl_year if first_o_p==1, title("Patent application time (years)") xtitle("Patent application year") xlabel(minmax) graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Applicationtime_year.pdf", replace

hist Time if first_o_p==1, title("") xtitle("Patent application time (years)") graphregion(color(white)) bgcolor(white)  
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Applicationtime.pdf", replace

* max_expiration_d: term+patent_application_date, note: term is calculated always from 
* patent applicate date!
gen comp_time=((year(term_expiry)-year(Chall_approval_date_min))*12+month(term_expiry)-month(Chall_approval_date_min))/12
hist comp_time if first_o_p==1, title("") xtitle("Patent term expiry-first PIV challenge (years)") graphregion(color(white)) bgcolor(white)  
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Expiry_challange.pdf", replace
	
gen term_sq=term*term
gen length_sq_years=length_y*length_y
gen examiner=ex_surname+" "+ex_name

* Average number of claims per examiner, each patent is counted only once
sort patentt

****************************************
* IV:s
* Average number of claims per examiner, each patent is counted only once
* NEXT: Compute these for different time periods (utilize over-time variation)
* CONTINUE HERE!

bysort patent_no examiner: gen first_o=1 if _n==1
replace first_o=0 if missing(first_o)
* a sum of claims per examiner
gen claims_temp=claims_num*first_o
bysort examiner: egen count_claims_per_examnr=sum(claims_temp)
* Excluding the claims of a patent
gen claims_count_excl=count_claims_per_examnr-claims_num
bysort examiner: egen sum_patents_per_examnr=sum(first_o)

gen ave_claims_excl=claims_count_excl/(sum_patents_per_examnr-1)

gen application_time=patent_grant_date_d-patent_application_date_d

gen at_temp=application_time*first_o
bysort examiner: egen count_at_per_examnr=sum(at_temp)
* Excluding the application time of a patent
gen at_ex_excl=count_at_per_examnr-application_time

gen ave_at_excl=at_ex_excl/(sum_patents_per_examnr-1)

********************************************************
* gen drop_ind2=0
* replace drop_ind2=1 if Challenged_active_ingredient==1 & IV_challenged_indicator==0


gen After_may_29_2000=0
replace After_may_29_2000=1 if patent_application_date_d>=date("May 29, 2000", "MDY")

gen inter=ave_at_excl*After_may_29_2000
reg term ave_at_excl After_may_29_2000 if first_o==1 

* Original utility and plant patents issuing from applications filed on or after May 29, 2000 will be eligible for patent term adjustment if issuance of the patent is delayed due to one or more of the listed administrative delays.  
reg claims_num ave_claims_excl if first_o==1
reg application_time ave_at_excl if first_o==1

reg term After_may_29_2000 ave_at_excl inter if first_o==1 & 
reg term After_may_29_2000 ave_at_excl inter if first_o==1
reg length_y After_may_29_2000 ave_at_excl inter if first_o==1

gen iter_at_after292000=application_time*After_may_29_2000

reg length_y After_may_29_2000 application_time iter_at_after292000 if first_o==1 

gen PC=0
replace PC=1 if PC_applicant~=""

gen appr_date=date(approval_date, "MDY")
gen approval_year=substr(approval_date, -4,.)
destring approval_year, replace


* PC: merged by ingredient dfroute strength

format patent_expire_date_d %d

gen diff1=(patent_expire_date_d-IV_approval_date_min)
bysort patentt: gen first_o_ps=1 if _n==1

gen diff2=floor(diff1/365)

hist diff1 if first_o_p==1, title("patent expire date - IV appr. date") xtitle("Nbr of days")
hist diff2 if first_o_ps==1, title("patent expire date - IV appr. date") xtitle("Nbr of years")
hist length if first_o_ps==1, title("patent length") xtitle("Nbr of days")
hist length_y if first_o_ps==1, title("patent length") xtitle("Nbr of years")

encode ingredient, gen(ingred_fe)
xtset ingred_fe
xtreg PC claims_num length length_sq dfroute, fe robust

ivregress 2sls IV_challenged_indicator length length_sq approval_year (claims_num=ave_claims_excl) if drop_ind2==0 & drop_ind2==0, cluster(ingredient)

* applicant has any new molecular entities/active ingredients within the group of an active ingredient

gen temp1=0
replace temp1=1 if Chemical_Type==1
bysort applicant ingredient: egen nme_applicant=max(temp1)
drop temp1

gen temp1=0
replace temp1=1 if Chemical_Type==2
bysort applicant ingredient: egen nai_applicant=max(temp1)
drop temp1

gen tablet=strpos(dfroute,"TABLET")
replace tablet=1 if tablet>0
gen capsule=strpos(dfroute,"CAPSULE")
replace capsule=1 if capsule>0
gen injectable=strpos(dfroute,"INJECTABLE")
replace injectable=1 if injectable>0

* Nbr of patents per application:

bysort appl_no patentt: gen temp1=1 if _n==1
bysort appl_no: egen patents_per_appl=sum(temp1)
drop temp1

gen term_yr=term/365
gen term_yr_sq=term_yr*term_yr
gen term_sq=term*term
gen RE_t=substr(patent_no,1,2)
gen RE=0
replace RE=1 if RE_t=="RE"
drop RE_t

gen temp1=0
replace temp1=1 if Chemical_Type==1
bysort applicant ingredient: egen nme_applicant=max(temp1)
drop temp1

gen temp1=0
replace temp1=1 if Chemical_Type==2
bysort applicant ingredient: egen nai_applicant=max(temp1)
drop temp1

gen tablet=strpos(dfroute,"TABLET")
replace tablet=1 if tablet>0
gen capsule=strpos(dfroute,"CAPSULE")
replace capsule=1 if capsule>0
gen injectable=strpos(dfroute,"INJECTABLE")
replace injectable=1 if injectable>0

gen claims_sq=claims_num*claims_num

reg IV_challenged_indicator term_yr term_yr_sq nme_applicant nai_applicant patents_per_appl tablet capsule injectable approval_year claims_num if drop_ind2==0 & RE==0
reg IV_challenged_indicator term_yr term_yr_sq nme_applicant nai_applicant patents_per_appl tablet capsule injectable approval_year claims_num if drop_ind2==0

ivregress 2sls IV_challenged_indicator term_yr term_yr_sq nme_applicant nai_applicant patents_per_appl tablet capsule injectable approval_year (claims_num=ave_claims_excl) if drop_ind2==0 & RE==0, first

gen After_may_29_2000=0
replace After_may_29_2000=1 if patent_application_date_d>=date("May 29, 2000", "MDY")

gen ave_at_excl_sq=ave_at_excl*ave_at_excl
gen inter_ave_at_sq=ave_at_excl_sq*After_may_29_2000

ivregress 2sls IV_challenged_indicator After_may_29_2000 claims_num nme_applicant nai_applicant patents_per_appl tablet capsule injectable approval_year (term_yr=ave_at_excl inter) if drop_ind2==0 & RE==0, first

ivreg2 IV_challenged_indicator nme_applicant nai_applicant patents_per_appl tablet capsule injectable After_may_29_2000 (term_yr term_yr_sq claims_num=ave_at_excl ave_at_excl_sq inter inter_ave_at_sq ave_claims_excl) if drop_ind2==0 & RE==0, gmm2s robust first

* Utility and plant patents issuing on applications filed on or after June 8, 1995, but before May 29, 2000, are eligible for the patent term extension provisions of former 35 U.S.C. 154(b) and 37 CFR 1.701. 

gen drop_time=0
replace drop_time=1 if patent_application_d>=date("Jun 8, 1995", "MDY") & patent_application_d<date("May 29, 2000", "MDY")

reg IV_challenged_indicator term_yr term_yr_sq nme_applicant nai_applicant patents_per_appl tablet capsule injectable approval_year claims_num if drop_ind2==0 & drop_time==0 


ivregress 2sls IV_challenged_indicator length approval_year (claims_num=ave_claims_excl) if drop_ind2==0 & drop_ind2==0
ivregress 2sls IV_challenged_indicator approval_year claims_num (length=ave_at_excl) if drop_ind2==0 & drop_ind2==0


ivregress 2sls IV_challenged_indicator nme_applicant nai_applicant patents_per_appl tablet capsule injectable After_may_29_2000 claims_num (length_y=ave_at_excl inter) if drop_ind2==0 & drop_ind2==0, first

gen ave_at_excl_sq=ave_at_excl*ave_at_excl
gen inter_ave_at_sq=ave_at_excl_sq*After_may_29_2000

ivreg2 IV_challenged_indicator nme_applicant nai_applicant patents_per_appl tablet capsule injectable After_may_29_2000 (length_y length_y_sq claims_num=ave_at_excl ave_at_excl_sq inter inter_ave_at_sq ave_claims_excl) if drop_ind2==0 & drop_ind2==0, gmm2s robust first

