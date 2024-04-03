# First, some examples with metric_set():
# Remember that there are lots of performance metrics functions:
sens()
spec()
roc_auc()
rmse()
mae()
rsq()

# `metric_set()` is just a convenient way to say you want to get a bunch of those
# in a custom group to use throughout your workflow.
custom_metrics <- metric_set(sens, spec, roc_auc)

# They can then be used like this to carry those metrics into various fit operations:
wflk %>% 
  fit_resamples(resamples = folds, metrics = custom_metrics)




library(tidyverse)
library(tidymodels)
tidymodels_prefer()

setwd('~/Documents/GitHub/is-555-00-in-class-activities/15 monitoring deployed models')


# Remember these old friends? Let's read them back in:
# What does this (trained) workflow object contain?
workflow_object <- read_rds('sample_reg_wkfl.rds')

# Lots of things. Recipe stuff, trained model weights, etc.

# Like magic, a month has passed, and now we want to see how our model did:
next_months_data <-  read_csv('next_months_data.csv')



# Let's calculate predictions/scores for that new data:
# Just pass that trained workflow to the predict function to get the preds out, then
# bind with the truth colum from the new data so we can evaluate performance:
new_results <- workflow_object %>% 
  predict(new_data = next_months_data) %>% 
  bind_cols( next_months_data %>% select(sale_price))






# And now let's compare performance of that data to what we saw during training:
results_from_training <- read_csv('sample_test_results.csv')

results_from_training %>% 
  rmse(truth = sale_price, estimate = .pred)
new_results %>% 
  rmse(truth = sale_price, estimate = .pred, na_rm = T)

