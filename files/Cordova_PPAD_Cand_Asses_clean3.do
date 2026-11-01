*********************************************
** PPAD Project Summer 2025 | GSR Assessment | Cordova


************************** PREP/INSPECT
** CLEAR memory & SET more off (so output doesn't pause)
** SET working directory
** LAND data & HANDLE missing data
clear
clear all 
set more off
cd "/Users/robertarturocordova/Documents/Stata/PPAD"
use "PPAD Project Data Wave 1.dta", clear
misstable summarize
misstable patterns 
describe


************************** NEW VARIABLES (I): RECODES & SHIFTS
** BUILD NUs (for recoding -1s & shifting off-by-1s)
local vars_to_copy "Hope1 HUMFL1 HUMFL2 HUMFL3_1 HUMFL6_1 HUMFL6_2 COMP_ECON COMP_GOVT"
foreach var of local vars_to_copy {
    generate `var'nu = `var'
}

** RECODES to turn -1s to .s
local recode_vars "Hope1nu HUMFL1nu HUMFL2nu HUMFL3_1nu HUMFL6_1nu HUMFL6_2nu COMP_ECONnu COMP_GOVTnu"
foreach var of local recode_vars {
    recode `var' (-1 = .)
}

** CHECK work 
local check_varsA "Hope1 Hope1nu HUMFL1 HUMFL1nu HUMFL2 HUMFL2nu"
foreach var of local check_varsA {
    tab `var'
}

local check_varsB "HUMFL3_1 HUMFL3_1nu HUMFL6_1 HUMFL6_1nu HUMFL6_2 HUMFL6_2nu"
foreach var of local check_varsB {
    tab `var'
}

codebook COMP_ECON COMP_ECONnu COMP_GOVT COMP_GOVTnu

** SHIFT off-by-1s
local shift_vars "HUMFL3_1nu HUMFL6_1nu HUMFL6_2nu COMP_ECONnu COMP_GOVTnu"
foreach var of local shift_vars {
    replace `var' = `var' - 1
}

** CHECK work 
local check_vars "HUMFL3_1 HUMFL3_1nu HUMFL6_1 HUMFL6_1nu HUMFL6_2 HUMFL6_2nu"
foreach var of local check_vars {
    tab `var'
}

codebook COMP_ECON COMP_ECONnu COMP_GOVT COMP_GOVTnu


************************** NEW VARIABLES (II): RACIAL INDICATORS
** CREATE African American and Latinx indicators
generate AA = (ppethm == 2) if !missing(ppethm)
generate LX = (ppethm == 4) if !missing(ppethm)
label variable AA "African American indicator"
label variable LX "Latinx indicator"

** CREATE age grouping variable for graphics
generate ppageBL = .
replace ppageBL = 0 if ppage >= 18 & ppage < 30
replace ppageBL = 1 if ppage >= 30 & ppage < 46  
replace ppageBL = 2 if ppage >= 46 & ppage < 60
replace ppageBL = 3 if ppage >= 60 & ppage < 100
label values ppageBL age_labels


************************** NEW VARIABLES (III): SENSITIVITY PREP
** INCORPORATE a manual weighting for functions that do not allow weights 
local rank_vars "Hope1nu HUMFL1nu HUMFL2nu HUMFL3_1nu HUMFL6_1nu HUMFL6_2nu COMP_ECONnu COMP_GOVTnu AA LX"
foreach var of local rank_vars {
    sort `var'  
	gen `var'cummwt = sum(total_wt)  
	gen `var'ttlwt = `var'cummwt[_N]  
	gen `var'rank = `var'cummwt / `var'ttlwt 
}


************************** DESCRIPTIVE STATISTICS & GRAPHICS
** ID and demographic variables
summarize Respid ppeducat ppethm ppeducat ppageBL ppgender [aweight=total_wt]

** remaining variables
summarize Hope1nu HUMFL1nu HUMFL2nu HUMFL3_1nu HUMFL6_1nu HUMFL6_2nu COMP_ECONnu COMP_GOVTnu [aweight=total_wt]

** graphics (I): BUILD external chart in google sheets
local demo_vars "ppageBL ppethm ppeducat"
foreach var of local demo_vars {
    tab `var' [aweight=total_wt]
}
* additional un-utilized graphics under graphics (II) under FOOTNOTES


************************** TESTING (I) H1 to H5
** DEFINE human flourishing variables
local flour_vars "HUMFL1nu HUMFL2nu HUMFL3_1nu HUMFL6_1nu HUMFL6_2nu"

** TEST hope - on happiness (H1a), worthwhileness (H2a), purpose (H3a), 
** worry (expenses) (H4a), & worry (basics) (H5a)
** Pearson correlation; see tables under 'Interpretation'
pwcorr Hope1nu `flour_vars' [aweight=total_wt], sig obs

** TEST power - on happiness (H1b)...worry (basics) (H5b)
** Pearson correlation (point-biserial); NOT REPORTED 
pwcorr COMP_ECONnu `flour_vars' [aweight=total_wt], sig obs

** TEST inefficiency - on happiness (H1c)...worry (basics) (H5c)
** Pearson correlation (point-biserial); NOT REPORTED 
pwcorr COMP_GOVTnu `flour_vars' [aweight=total_wt], sig obs


************************** TESTING (II): H6 & H7
** DEFINE race variables
local race_vars "AA LX"

** TEST hope on race: AA (H6a) and LX (H7a)
** Pearson correlation (point-biserial); see tables under 'Interpretation'
pwcorr Hope1nu `race_vars' [aweight=total_wt], sig obs

** TEST power on race: AA (H6b) and LX (H7b)
** Pearson correlation (phi); see tables under 'Interpretation'
pwcorr COMP_ECONnu `race_vars' [aweight=total_wt], sig obs

** TEST inefficiency on race: AA (H6c) and LX (H7c)
* Pearson correlation (phi); see tables under 'Interpretation'
pwcorr COMP_GOVTnu `race_vars' [aweight=total_wt], sig obs


************************** SENSITIVITY (I): H1 to H5 
** redoing Pearson w/ manual weights and using Spearman with manual weights
** see tables under 'Sensitivity Analysis'
local flour_rank_vars "HUMFL1nurank HUMFL2nurank HUMFL3_1nurank HUMFL6_1nurank HUMFL6_2nurank"
foreach var of local flour_rank_vars {
	pwcorr Hope1nurank `var', sig obs
    spearman Hope1nurank `var', stats(rho obs p)
}
* ranksum is not appropiate for point-biserial (as p-b assume normality)
* ktau requires another manual incorporation method

************************** SENSITIVITY (II): H6 to H7
** redoing Pearson w/ manual weights and using Spearman with manual weights
** H6a and H7a
** see tables under 'Sensitivity Analysis'
local race_rank_vars "AArank LXrank"
foreach var of local race_rank_vars {
	pwcorr Hope1nurank `var', sig obs
    spearman Hope1nurank `var', stats(rho obs p)
}
* ranksum is not appropiate for a phi coefficient (as you have no proper median)
* (ranksum also requires yet a third manual incorporation method)
* ktau requires another manual incorporation method

** redoing Pearson w/ manual weights and using Spearman with manual weights
** H6b, H6c, H7b, and H7c
** see tables under 'Sensitivity Analysis'
local power_rank_vars "COMP_ECONnurank COMP_GOVTnurank"
foreach power of local power_rank_vars {
    foreach race of local race_vars {
		pwcorr `power' `race', sig obs
		spearman `power' `race', stats(rho obs p)
    }
}


************************** FOOTNOTES
** graphics (II): SET these graphics aside for now 
/*histogram ppage, xlabel(15(10)100) xtitle("Age") ytitle("Density") title("Histogram of Age") ylabel(, angle(horizontal)) name(age, replace)
graph display age
graph export "age.png", replace

graph hbar (count) total_wt, over(ppeducat , sort(1) descending) title("Education Distribution") ytitle("Count") name(education, replace) 
graph display education
graph export "education.png", replace	

graph pie total_wt, over(ppethm) plabel(_all percent) title("Distribution of Race/Ethnicity") name(ethicity, replace)
graph display ethicity
graph export "ethicity.png", replace

histogram total_wt, xlabel(0(1)5) xtitle("Sample Weight") ytitle("Density") title("Distribution of Sample Weights") ylabel(, angle(horizontal)) name(Weight, replace)


**************** END



