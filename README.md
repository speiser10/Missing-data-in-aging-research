# Missing-data-in-aging-research

This data simulation accompanies the paper Missing data in aging research.  The purpose of this simulation is to demonstrate how three different imputation methods (mean, regression imputation, and random forest) operate under the three different missing data mechanisms (MCAR, MAR, and MNAR).

Age, sex, and BMI were generated to model the outcome gait speed.  BMI was simulated to be normally distributed with a mean of 27 and standard deviation of 6.  Gait speed was simulated to be negatively associated with age, female sex, and BMI.  30% of BMI values were deleted under each missing data mechanism.  To simulate MCAR, 30% of BMI values were randomly deleted.  Missingness in BMI is not related to any other variables, observed or unobserved.  To simulate MAR, the probability that BMI was missing depended on sex – if sex was female the probability of BMI missing was set to 0.6, and if sex was male the probability was set to 0.05.  This situation is MAR because missingness depends only on an observed variable.  To simulate MNAR, the probability that BMI was missing depended on the value of BMI itself; all values above the 70th percentile were set to missing.  Data is therefore MNAR because missingness depends on the unobserved BMI values.  

Mean, regression imputation, and the machine learning method random forest were used to impute BMI.  From each iteration, the true mean and standard deviation of BMI and the mean and standard deviation of BMI after imputation were recorded.  For imputed observations, the absolute difference from the true value was recorded.  MSE was then calculated.  To make comparisons, these measures were averaged across the 100 simulations.  Before the results of the simulation are shown, below is an example from one data set of possible missing data visualizations. 

The plot below is a tool to visualize which variables have missing values and where in the data set these values are.  Each column is a variable in the data set, and each row is an observation.  In this dataset, there are 100 observations and 4 variables.  Red indicates an integer (sex = 0/male or sex = 1/female) and blue indicates a numeric value.  Grey indicates a missing value.  BMI is the only variable with missing values, and about 30% of the values are grey/missing.  This plot is created with the function vis_dat() from the “visdat” package.
vis_dat(data)

<img width="750" height="750" alt="Visualize missing data" src="https://github.com/user-attachments/assets/0add3250-806a-437c-918f-cd05f32e7d56" />

The “naniar” package in R offers multiple ways to visualize missing data.  In combination with ggplot2, the naniar package can be used to make an overlapping density plot that shows the distribution of the outcome among missing and non-missing predictors values.  The as_shadow() function creates a shadow matrix, which is a matrix composed of binary missing indicators for each variable in the data set.  The missing indicator for BMI is used to create an overlapping density plot of gait speed using the following code:

data %>%
  as_shadow() %>%
  bind_shadow() %>%
  ggplot(aes(
    x = gs,
    fill = BMI_NA
  )) +
  geom_density(alpha = 0.5)

In the histograms below, the distribution of gait speed among non-missing BMI values is in pink and among missing BMI values is in blue.  When data is MCAR, the distributions are largely overlapping.  However, in the MAR and MNAR plots, gait speed is lower among missing BMI values; the distribution is shifted to the left.  This intuitively makes sense for both missing mechanisms.  Under MAR, BMI is more likely to be missing for females, who have lower gait speed.  Under MNAR, values in the highest 30th percentile of BMI are missing, and higher BMI is associated with lower gait speed.

<img width="750" height="750" alt="Hist MCAR" src="https://github.com/user-attachments/assets/91e3c9d9-1538-4d16-b325-d01f710e1d24" />
<img width="750" height="750" alt="Hist MAR" src="https://github.com/user-attachments/assets/5110b6aa-fc28-45ea-bd14-3f52b32150c9" />
<img width="750" height="750" alt="Hist MNAR" src="https://github.com/user-attachments/assets/e28334ee-5326-4540-9414-33af87b5086b" />

The shadow matrix can also be used to visualize imputed values.  The scatterplots below show the relationship between BMI and gait speed, with colors used to differentiate points where BMI was imputed.  BMI is on the x-axis, while gait speed is on the y-axis.  Points with imputed BMI are in blue.

Code for mean imputation (run under different missing mechanisms):
mean_BMI <- mean(data$BMI, na.rm = TRUE)
scatter = data %>%
  bind_shadow() %>%
  as.data.frame() %>%
  mutate(
    BMI = case_when(is.na(BMI) ~ mean_BMI, TRUE ~ BMI)
  ) %>%
  ggplot(aes(
    x = BMI,
    y = gs,
    colour = BMI_NA
  )) +
  geom_point() +
  ylab("Gait speed") +
  xlim(0, 50) + ylim(0, 1.8)

For mean imputation, all missing values are imputed with the mean of the non-missing BMI values.  Therefore, points with imputed BMI form a vertical line at the estimated mean.  Comparing across missing mechanisms, mean BMI appears biased for MNAR; at about 25 compared to 27, the mean is underestimated.  The variability of BMI is also underestimated, as BMI has less spread.  

<img width="750" height="750" alt="Scatter MCAR mean" src="https://github.com/user-attachments/assets/031dad0a-8286-48d5-95bd-4b29c6c387fd" />
<img width="750" height="750" alt="Scatter MAR mean" src="https://github.com/user-attachments/assets/021f607f-52c1-4091-bf92-8a22238c336e" />
<img width="750" height="750" alt="Scatter MNAR mean" src="https://github.com/user-attachments/assets/629fba27-a25c-436d-bd1a-9b1cf4b9ab85" />

Code for regression imputation (run under different missing mechanisms):
formulas <- make.formulas(data)
scatter = data %>%
  bind_shadow() %>%
  as.data.frame() %>%
  mice(
    method = "norm.nob",
    formulas = formulas,
    m = 1, maxit = 1
  ) %>%
  complete() %>%
  ggplot(aes(
    x = BMI,
    y = gs,
    colour = BMI_NA
  )) +
  geom_point() +
  ylab("Gait speed") +
  xlim(0, 50) + ylim(0, 1.8)

Code for missForest (run under different missing mechanisms):
data_shadow <- data %>%
  bind_shadow() %>%
  as.data.frame() %>%
  select(BMI_NA)
data_full <- missForest(data, maxiter = 10, ntree = 100, verbose = FALSE)
data_full <- data_full$ximp
data <- cbind.data.frame(data_full, data_shadow)
scatter = data %>%
  ggplot(aes(
    x = BMI,
    y = gs,
    colour = BMI_NA
  )) +
  geom_point() +
  ylab("Gait speed") +
  xlim(0, 50) + ylim(0, 1.8)

Regression imputation and missForest plots show similar patterns.  When data is MNAR, both imputation methods underestimate variability.  None of the imputed BMI values are larger than the observed BMI values; we know the true values were all larger than the observed values due to how MNAR was simulated, which shows the inadequacy of the imputation methods.  A similar phenomenon is seen with MAR for missForest, whereas regression imputation imputes a larger range of BMI values.  missForest underestimates variability more than regression imputation, which has a larger spread of values.  This is especially apparent in the MCAR and MAR plots.  

<img width="750" height="750" alt="Scatter MCAR reg" src="https://github.com/user-attachments/assets/1b27f4ad-0ef3-4179-baab-100691c489c5" />
<img width="750" height="750" alt="Scatter MCAR missForest" src="https://github.com/user-attachments/assets/bb81cf01-2cf9-462c-b5c9-8b063e619cb4" />
<img width="750" height="750" alt="Scatter MNAR reg" src="https://github.com/user-attachments/assets/7999e926-262b-4ef0-898c-97401c0a0033" />
<img width="750" height="750" alt="Scatter MNAR missForest" src="https://github.com/user-attachments/assets/174b8d8e-a6f4-4824-9c25-25a877334690" />
<img width="750" height="750" alt="Scatter MAR reg" src="https://github.com/user-attachments/assets/ebd1bfc7-f87b-4b3b-b89f-c97f4e8af2a1" />
<img width="750" height="750" alt="Scatter MAR missForest" src="https://github.com/user-attachments/assets/382049ba-11f4-4520-b4f2-c72858735088" />

The results of the simulation are shown below.  
Under MCAR and MAR, all three imputation methods had an unbiased mean BMI.  Mean imputation and missForest underestimated variability, while regression imputation preserved the variability of BMI.  Mean imputation and missForest had lower mean squared error estimates than regression imputation, which is expected because regression imputation introduces prediction error to preserve variability.
Under MNAR, all three methods resulted in a biased mean estimate.  All three methods also underestimated variability, with mean imputation and missForest underestimating more than regression imputation.  MSE is higher for MNAR than MCAR or MAR, but missForest has the lowest MSE.

<img width="702" height="238" alt="Table" src="https://github.com/user-attachments/assets/85cca2f0-971a-4c84-a222-79cacdaee186" />


All of the code from this tutorial is posted to GitHub.  This tutorial demonstrates how to visualize missing data and shows how biased mean and variability estimates depend on both the missing mechanism and the imputation method.  
