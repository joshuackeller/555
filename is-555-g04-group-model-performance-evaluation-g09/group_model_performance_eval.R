library(tidyverse)
library(tidymodels)
tidymodels_prefer()

# Assuming you did the last case assignment correctly, your group (or at least a member of your group) should
# have your group's model materials somewhere. Namely, these ones:
# 
#   test_set_results.csv
#   trained_workflow.rds
# 
# You're going to want to copy all of those materials to this project's repository folder so that they are 
# accessible, and then use the setwd() command below to make sure you're operating from that directory.
setwd('/Users/joshuakeller/Repos/555/is-555-g04-group-model-performance-evaluation-g09/')

# 1. test_set_results, trained_workflow
trained_workflow <- read_rds('trained_workflow.rds')
test_set_results <- read_csv('test_set_results.csv')
test_set_results <- test_set_results %>% 
  mutate(.pred_class = as.factor(.pred_class), is_fraud = as.factor(is_fraud))

fraud1 <- read_csv('https://www.dropbox.com/s/8ayg09oeb5dsptq/fraud_transaction_testing.csv?dl=1')
fraud2 <- read_csv('https://www.dropbox.com/s/wu7izi9uj8w8k5i/fraud_identity_testing.csv?dl=1')


# 2. future_data

###### JOIN DATASETS
# Clean the names right from the start
fraud1_clean <- fraud1 %>% 
  janitor::clean_names()
fraud2_clean <- fraud2 %>% 
  janitor::clean_names()
# Join data together
fraud_joined <- left_join(
  fraud1_clean,
  fraud2_clean,
  by = c('transaction_id' = 'transaction_id')
)
####### CLEAN DATASETS
# Don't select the transaction_id column
fraud_no_id <- fraud_joined %>% 
  select(-transaction_id)
# Calculate the percentage of missing values for each column
missing_percentages <- tibble(
  column = names(fraud_no_id),
  missing_percent = sapply(fraud_no_id, function(col) {
    sum(is.na(col)) / length(col) * 100
  })
) %>% arrange(desc(missing_percent))
#missing_percentages %>% glimpse()
# Identify the columns with over 80% missing values
cols_to_remove <- missing_percentages$column[missing_percentages$missing_percent > 80]
# Remove the identified columns from the dataset
fraud_no_id <- fraud_no_id[, !names(fraud_no_id) %in% cols_to_remove]
#fraud_no_id %>% glimpse
# Select only the columns that we have an idea of what they are and rename columns to better understand and change billing.... to a character and is_fraud to a factor
fraud_red <- fraud_no_id %>% 
  select(is_fraud, transaction_amt, product_cd, card4, card6, addr2, r_emaildomain, p_emaildomain, id_31, device_type) %>% 
  rename(card_issuer = card4, deb_cred = card6, billing_ctry_num = addr2, operating_sys_browser = id_31) %>% 
  mutate(is_fraud = as.factor(is_fraud), billing_ctry_num = as.character(billing_ctry_num))
#mutate(billing_ctry_num = as.factor(billing_ctry_num), is_fraud = as.factor(is_fraud))
# Convert all characters to factors to fix modeling errors
#fraud_red <- fraud_red %>% mutate_if(is.character,as.factor)
#fraud_red %>% count(operating_sys_browser) %>% arrange(desc(n))
# For billing ctry code, do top 5 values + NA
fraud_red <- fraud_red %>% 
  mutate(billing_ctry_num = if_else((billing_ctry_num %in% head(unique(na.omit(billing_ctry_num[billing_ctry_num != ""])), 5) | is.na(billing_ctry_num)), as.character(billing_ctry_num), "Other")) 
# For r_emaildomain, do top 8
fraud_red <- fraud_red %>% 
  mutate(r_emaildomain = if_else((r_emaildomain %in% head(unique(na.omit(r_emaildomain[r_emaildomain != ""])), 8) | is.na(r_emaildomain)), as.character(r_emaildomain), "Other")) 
# For p_emaildomain, do top 6
fraud_red <- fraud_red %>% 
  mutate(p_emaildomain = if_else((p_emaildomain %in% head(unique(na.omit(p_emaildomain[p_emaildomain != ""])), 8) | is.na(p_emaildomain)), as.character(p_emaildomain), "Other")) 
# For operating_sys_browser, do top 10
fraud_red <- fraud_red %>% 
  mutate(operating_sys_browser = if_else((operating_sys_browser %in% head(unique(na.omit(operating_sys_browser[operating_sys_browser != ""])), 8) | is.na(operating_sys_browser)), as.character(operating_sys_browser), "Other")) 
fraud_red <- fraud_red %>% mutate_if(is.character,as.factor)


future_data <- fraud_red

future_data

# 3. future_results
is_fraud_predictions <- trained_workflow %>% 
  predict(new_data = future_data)

probability_predictions <- trained_workflow %>% 
  predict(future_data, type = "prob") 

future_results <- future_data %>% 
  select(is_fraud) %>% 
  bind_cols(is_fraud_predictions, probability_predictions) 

# 4. performance_comparison_tibble
metric_set(roc_auc, pr_auc, precision)


performance_comparison_tibble <- bind_rows(
  test_set_results %>% roc_auc(truth = is_fraud, .pred_0) %>% mutate(type = "test_set_results"),
  test_set_results %>% pr_auc(truth = is_fraud, .pred_0) %>% mutate(type = "test_set_results"),
  test_set_results %>% precision(truth = is_fraud, .pred_class) %>% mutate(type = "test_set_results"),
  future_results %>% roc_auc(truth = is_fraud, .pred_0) %>% mutate(type = "future_results"),
  future_results %>% pr_auc(truth = is_fraud, .pred_0) %>% mutate(type = "future_results"),
  future_results %>% precision(truth = is_fraud, .pred_class) %>% mutate(type = "future_results"),
) %>% 
  pivot_wider(
    values_from = .estimate,
    names_from = type
  ) %>% 
  select(-.estimator)


# 5. performance_comparison_plot

future_roc_curve <- future_results %>%  roc_curve(truth = is_fraud, .pred_0)
test_set_roc_curve <- test_set_results %>%  roc_curve(truth = is_fraud, .pred_0)

combined_roc_curves <- bind_rows(
  mutate(future_roc_curve, type = "future_results"),
  mutate(test_set_roc_curve, type = "test_set_results")
)

performance_comparison_plot <- combined_roc_curves %>% 
  ggplot(aes(x = 1 - specificity, y = sensitivity, color = type)) +
  geom_path() +
  geom_abline(lty = 3) +
  coord_equal() +
  theme_bw() +
  labs(x = "1 - Specificity", y = "Sensitivity", title = "ROC Curve Comparison (Test Set vs Future Data)")

performance_comparison_plot %>% 
  ggsave('perf_comparison_classification.png', plot = ., 
         device = 'png', width = 14, height = 9)

performance_comparison_tibble



# Naming Checks -----------------------------------------------------------------------------------------

# To help us avoid object or column name issues, I've included the following tests that will only pass 
# if you have named your objects and columns exactly correct. 

# IMPORTANT: You should not edit any of the code in this section. It should be run as a big block and you 
# should see the test results at the end.

expected_object_names <- c("future_data", "future_results", "performance_comparison_plot",  
                           "performance_comparison_tibble", "test_set_results", "trained_workflow")

# Tests
expected_object_names_result <- sum(ls() %in% expected_object_names) == length(expected_object_names)

expected_cols <- read_csv('expected_cols.csv', show_col_types=F) 

if(!expected_object_names_result){
  error_content <- paste(expected_object_names[!expected_object_names %in% ls()], collapse = ',')
  stop(paste("Expected objects not found in the environment:",error_content))
}

in_mem <- lapply(mget(expected_object_names), colnames)

found_cols <- expected_cols %>% 
  left_join(in_mem[!unlist(lapply(in_mem,is.null))] %>%
              enframe() %>%
              unnest(value) %>%
              rename(tibble = name,
                     colname = value) %>% 
              mutate(was_found = 1),
            by = c("tibble" = "tibble", "colname"="colname"))

if(sum(is.na(found_cols$was_found)) == 0){
  message('All naming tests passed. But did you restart your session and run your WHOLE script from beginning to end??')
} else {
  message("Uh oh. Couldn't find the column(s) below:")
  found_cols %>% 
    filter(is.na(was_found)) %>% 
    select(-was_found) %>% 
    print()
}