library(tidyverse)
library(naniar)
library(visdat)

n_runs <- 100
n <- 100
p_mcar <- 0.30
set.seed(1234)

age <- rnorm(n, mean = 65, sd = 10)
sex <- rbinom(n, size = 1, prob = 0.50)
BMI <- rnorm(n, mean = 27, sd = 6)
error <- rnorm(n, mean = 0, sd = 0.25)
gs <- 2.75 - 0.015 * age - 0.3 * sex - 0.02 * BMI + error
gs <- ifelse(gs < 0, 0, gs)

miss_ind <- rbinom(n, size = 1, prob = p_mcar)
BMI_miss <- ifelse(miss_ind == 1, NA_real_, BMI)

data <- cbind.data.frame(age, sex, BMI_miss, gs) %>% rename(
  BMI = BMI_miss
)

# shows which variables have missing values and
# where in the data set they are
vis_dat(data)

# histogram that shows distribution of outcome
# among missing and non-missing x values
hist = data %>%
  as_shadow() %>%
  bind_shadow() %>%
  ggplot(aes(
    x = gs,
    fill = BMI_NA
  )) +
  geom_density(alpha = 0.5) +
  ggtitle("MCAR"); hist

# visualizing imputations
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
  xlim(0, 50) + ylim(0, 1.8) + 
  ggtitle("MCAR Mean Imputation"); scatter