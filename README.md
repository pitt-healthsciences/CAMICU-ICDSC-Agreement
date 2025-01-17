# CAMICU-ICDSC-Agreement
Optimizing Bedside Nurse-Documented Delirium Assessments in the ICU to Predict Research Assessments

Project Overview
This project analyzes data for the study titled 'Optimizing Bedside Nurse-Documented Delirium Assessments in the ICU to Predict Research Assessments'. The analysis focuses on the relationship between bedside nurse-documented delirium assessments and their ability to predict research-grade assessments, with a particular emphasis on the Intensive Care Delirium Screening Checklist (ICDSC) and CAM-ICU data.

Prerequisites - Before running this code, ensure the following:
1. Software: Stata 14 or later.
2. Input Data: The dataset 'mock_data.csv' is created.

Steps in the Analysis
1. Data Preparation
Import the data, logging is set up in the code to capture the results.
2. Step 1: Generate ICDSC Categories
Generate the ICDSC category variable based on the ICU delirium. 
3.  Univariate Logistic Regression
Perform univariate logistic regression for selected variables and generate ROC curves.
4. Outputs
The following outputs are generated:
  1. Log File
  2. ROC Curve Images
  3. Predicted Probabilities CSV Files
5. Models
Perform multinomial logistic regression for all the models and conduct sensitivity analysis to ensure robustness


