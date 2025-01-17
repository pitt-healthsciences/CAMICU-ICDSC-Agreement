/*
Zahra Aghababa  12/09/2024
Email: z_aghababa@pitt.edu

This code provides data analysis for the "Optimizing Bedside Nurse-Documented Delirium Assessments in the ICU to Predict Research Assessments".

In this project, ICDSC has been treated categorically in 2 wayas:
 - With cutoffs of 0,1-3,4-8 (Labeled V1)
 - With cutoffs of 0-3,4-8 (Labeled V2) 
*/

********************************************************************************
clear all

*Change to appropriate directory
cd "G:\Zahra\" 

*Change to appropriate filename, structured similarly to example data file
import delimited "Example_Data_Synthetic.csv"

*Log output
log using cam_icu_results_v6.log, replace

********************************************************************************
****************************STEP 1**********************************************
********************************************************************************
*Generate Intensive Care Delirium Screening Checklist (ICDSC) categorical variables
gen icdsc_cat = 0 
replace icdsc_cat = 2 if icdsc4pm >= 0 & icdsc4pm <= 3
replace icdsc_cat = 1 if icdsc4pm >3 & icdsc4pm <= 8
replace icdsc_cat = 3 if icdsc4pm == 9

* Summarize the new ICDSC Category variable by mental status today:
table1, vars(icdsc_cat cat) by(mentalstatustoday) 

* Evaluate the agreement between mental status today and the icdsc_cat variable by Kappa:
kappa mentalstatustoday icdsc_cat

*******************************************************************************
****************************STEP 2*********************************************
*******************************************************************************

*Remove patients with coma according to ICDSC or documented mental status (these patients are described descriptively only)*
drop if icdsc4pm == 9 
drop if locicdscpm == 1 | locicdscpm == 2
drop if mentalstatustoday == 3
tab cohort

*Generate icdsc category - V1 (0,1-3,4-8)
gen icdsc_cat_v1 = 0 
replace icdsc_cat_v1 = 1 if icdsc4pm == 0 
replace icdsc_cat_v1 = 2 if icdsc4pm > 0 & icdsc4pm <= 3
replace icdsc_cat_v1 = 3 if icdsc4pm >3 & icdsc4pm <= 8

*Generate icdsc category - V2 (0-3,4-8)
gen icdsc_cat_v2 = 0
replace icdsc_cat_v2 = 1 if icdsc4pm >= 0 & icdsc4pm <= 3
replace icdsc_cat_v2 =2 if icdsc4pm >3 & icdsc4pm <= 8

*Generate CAM-ICU dummy variable (=1 if delirium)
gen cam_icu_dummy = 0
replace cam_icu_dummy = 1 if mentalstatustoday == 1

local x "icdsc4pm i.icdsc_cat_v1 i.icdsc_cat_v2"
foreach var in `x' {
	logit cam_icu_dummy `var', vce(robust) or
	
	*Compute ROCs for univariate models
	predict prob, p
	
	if "`var'" == "icdsc4pm" {
		local filename "roc_univariate_icdsc4pm.png"
		local csv_filename "predicted_prob_univariate_icdsc4pm.csv"
		local graphname "roc_uni_v3"
		local titlename "Only ICDSC Score,Continuous"
		local colorname "blue"
	}
	else if "`var'" == "i.icdsc_cat_v1" {
		local filename "roc_univariate_icdsc_cat_v1.png"
		local csv_filename "predicted_prob_univariate_icdsc_cat_v1.csv"
		local graphname "roc_uni_v1"
		local titlename "Only ICDSC Score,Categorized-V1"
		local colorname "blue"
	}
	else if "`var'" == "i.icdsc_cat_v2" {
		local filename "roc_univariate_icdsc_cat_v2.png"
		local csv_filename "predicted_prob_univariate_icdsc_cat_v2.csv"
		local graphname "roc_uni_v2"
		local titlename "Only ICDSC Score,Categorized-V2"
		local colorname "blue"
	}
	export delimited prob cam_icu_dummy using "`csv_filename'",replace
	roctab cam_icu_dummy prob, graph name(`graphname',replace) recast(line) lcolor(`colorname') title("`titlename'", size(3))
	graph export "`filename'", as (png) replace
	graph close
	drop prob
}

*Generate the dummies for each category of level of consciousness
tabulate locicdscpm, generate(category_dummy)
rename category_dummy1 locicdscpm_lev3
rename category_dummy2 locicdscpm_lev4
rename category_dummy3 locicdscpm_lev5


**********************************MODELS**********************************
*Full model - ICDSC Component and Clinical Covariates			   
*Note: For cases where mechanical ventilation status was not noted but the patient was extubated on same day of their CAM-ICU assessment, mv.status.ext assumes that the patient was extubated by the time their CAM-ICU was completed.

*Run Full model-V1_ext  (not including sedation status; Including mv.status.ext):
logit cam_icu_dummy locicdscpm_lev3 locicdscpm_lev5 i.inattentionicdscpm i.disorientationicdscpm i.hallucinationsicdscpm i.agitationhypoacticdscpm i.speechicdscpm i.sleepicdscpm i.flucicdscpm i.mvstatusext sofa_mod_imputed, vce(robust) or

*Compute ROC for the full model-V1_ext
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_full_model_v1_ext.csv",replace
roctab cam_icu_dummy prob, graph name(roc_full_v1_ext,replace) recast(line) lcolor(red) title("Full Model-V1_ext", size(3))
graph export "roc_full_model_v1_ext.png", as (png) replace
graph close
drop prob

*Create dummy variable for level of consciousness:
gen loc_dummy = 0 
replace loc_dummy = 1 if locicdscpm != 4

*Create dummy variable for agitation:
gen agitation_dummy = 0
replace agitation_dummy = 1 if agitationhypoacticdscpm != 0

*Create dummy variable for inappropriate speech:
gen speech_dummy = 0
replace speech_dummy = 1 if speechicdscpm != 0

*Create dummy variable for sleep:
gen sleep_dummy = 0
replace sleep_dummy = 1 if sleepicdscpm != 0


*Run Full model-V1_int (not including sedation status; Including mv.status.int)
logit cam_icu_dummy locicdscpm_lev3 locicdscpm_lev5 i.inattentionicdscpm i.disorientationicdscpm i.hallucinationsicdscpm i.agitationhypoacticdscpm i.speechicdscpm i.sleepicdscpm i.flucicdscpm i.mvstatusint sofa_mod_imputed, vce(robust) or

*Compute ROC for the full model-V1_int
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_full_model_v1_int.csv",replace
roctab cam_icu_dummy prob, graph name(roc_full_v1_int,replace) recast(line) lcolor(red) title("Full Model-V1_int", size(3))
graph export "roc_full_model_v1_int.png", as (png) replace
graph close
drop prob

*Full model- V2 - Using dummy variables
*Run full model-V2_ext:
logit cam_icu_dummy loc_dummy i.inattentionicdscpm i.disorientationicdscpm i.hallucinationsicdscpm agitation_dummy speech_dummy sleep_dummy i.flucicdscpm i.mvstatusext  sofa_mod_imputed,  vce(robust) or

*Compute ROC for the full model-V2_ext
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_full_model_v2_ext.csv",replace 
roctab cam_icu_dummy prob, graph name(roc_full_v2_ext,replace) recast(line) lcolor(red) title("Full Model-V2_ext", size(3))
graph export "roc_full_model_v2_ext.png", as (png) replace
graph close
drop prob

*Run full model-V2_int:
logit cam_icu_dummy loc_dummy i.inattentionicdscpm i.disorientationicdscpm i.hallucinationsicdscpm agitation_dummy speech_dummy sleep_dummy i.flucicdscpm i.mvstatusint  sofa_mod_imputed,  vce(robust) or

*Compute ROC for the full model-V2_int
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_full_model_v2_int.csv",replace 
roctab cam_icu_dummy prob, graph name(roc_full_v2_int,replace) recast(line) lcolor(red) title("Full Model-V2_int", size(3))
graph export "roc_full_model_v2_int.png", as (png) replace
graph close
drop prob

************************Sensitivity Analysis************************
*Sensitivity Analysis 1 - ICDSC Components only - V1:
logit cam_icu_dummy locicdscpm_lev3 locicdscpm_lev5 i.inattentionicdscpm i.disorientationicdscpm i.hallucinationsicdscpm i.agitationhypoacticdscpm i.speechicdscpm i.sleepicdscpm i.flucicdscpm,  vce(robust) 

*Compute ROC for the ICDSC Components only - V1
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_sa1_v1.csv",replace
roctab cam_icu_dummy prob, graph name(roc_comp_v1) recast(line) lcolor(green) title("ICDSC Component only-V1", size(3))
graph export "roc_icdsc_component_only_v1.png", as (png) replace
graph close
drop prob

*Sensitivity Analysis 1 - ICDSC Components only - V2:
logit cam_icu_dummy loc_dummy i.inattentionicdscpm i.disorientationicdscpm i.hallucinationsicdscpm agitation_dummy speech_dummy sleep_dummy i.flucicdscpm,  vce(robust) or

*Compute ROC for the ICDSC Component only - V2
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_sa1_v2.csv",replace
roctab cam_icu_dummy prob, graph name(roc_comp_v2) recast(line) lcolor(green) title("ICDSC Component only-V2", size(3))
graph export "roc_icdsc_component_only_v2.png", as (png) replace
graph close
drop prob

*Sensitivity Analysis 2 - Continuous ICDSC Score + Covariates - V1-ext:
logit cam_icu_dummy icdsc4pm i.mvstatusext sofa_mod_imputed, vce(robust) or

*Compute ROC for Continuous ICDSC Score + Covariates
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_sa2_v1.csv",replace
roctab cam_icu_dummy prob, graph name(roc_cov_v1) recast(line) lcolor(green) title("ICDSC Count ICDSC score &covariates-V2", size(3))
graph export "roc_icdsc_score_and_covariates_only_v1.png", as (png) replace
graph close
drop prob

*Sensitivity Analysis 2 - Continuous ICDSC Score + Covariates - V1-int:
logit cam_icu_dummy icdsc4pm i.mvstatusint sofa_mod_imputed, vce(robust) or

*Sensitivity Analysis 2 - Category ICDSC Score (V1) + Covariates - V2-ext:
logit cam_icu_dummy i.icdsc_cat_v1 i.mvstatusext sofa_mod_imputed, vce(robust) or

*Compute ROC for Category ICDSC Score (V1) + Covariates
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_sa2_v2.csv",replace
roctab cam_icu_dummy prob, graph name(roc_cat_v2) recast(line) lcolor(green) title("ICDSC Cat ICDSC score &covariates-V2", size(3))
graph export "roc_icdsc_cat_and_covariates_only_v2.png", as (png) replace
graph close
drop prob

*Sensitivity Analysis 2 - Category ICDSC Score (V1) + Covariates - V2-int:
logit cam_icu_dummy i.icdsc_cat_v1 i.mvstatusint sofa_mod_imputed, vce(robust) or

*Sensitivity Analysis 2 - Category ICDSC Score (V2) + Covariates - V3-ext:
logit cam_icu_dummy i.icdsc_cat_v2 i.mvstatusext sofa_mod_imputed, vce(robust) or

*Compute ROC for Category ICDSC Score (V2) + Covariates
predict prob, p
export delimited prob cam_icu_dummy using "predict_prob_sa2_v2.csv",replace
roctab cam_icu_dummy prob, graph name(roc_cat_v3) recast(line) lcolor(green) title("ICDSC Cat ICDSC score &covariates-V3", size(3))
graph export "roc_icdsc_cat_and_covariates_only_v3.png", as (png) replace
graph close
drop prob

*Sensitivity Analysis 2 - Category ICDSC Score (V2) + Covariates - V3-int:
logit cam_icu_dummy i.icdsc_cat_v2 i.mvstatusint sofa_mod_imputed, vce(robust) or

log close