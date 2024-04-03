library(tidymodels)
library(tidyverse)
# uncomment if you need to install these:
# install.packages('tidypredict')
# install.packages('yaml')
library(tidypredict)
library(yaml)

data(ames)
housing <- ames %>% janitor::clean_names()
housing %>% glimpse

set.seed(42)
housing_split <- initial_split(housing, strata = sale_price)

housing_training <- housing_split %>% training()
housing_testing <- housing_split %>% testing()

# Build feature engineering pipeline
housing_rec <- recipe(sale_price ~ .,
                      data = housing_training) %>% 
  step_corr(all_numeric_predictors(), threshold = .6) %>% 
  step_YeoJohnson(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_impute_median(all_numeric_predictors()) %>% 
  step_nzv(all_predictors())

simple_model <- boost_tree() %>% 
  set_engine('xgboost') %>% 
  set_mode('regression')

# create a reusable workflow
housing_wkfl <- workflow() %>% 
  add_model(simple_model) %>% 
  add_recipe(housing_rec)

set.seed(42)


# First, just do an overall shortcut to fit/evaluate
final_fit <- housing_wkfl %>% 
  last_fit(split = housing_split)

final_fit %>% collect_metrics()
final_fit %>% collect_predictions()



# Typical Deployment materials
trained_workflow <- extract_workflow(final_fit)
model_object <- extract_fit_parsnip(final_fit)
parsed_model <- parse_model(model_object)

tidypredict_fit(parsed_model)
write_yaml(parsed_model, "~/Desktop/model_config.yml")


library(xgboost)
# install.packages('Ckmeans.1d.dp')
xgb.importance(model=model_object$fit) %>% head()


xgb.importance(model=model_object$fit) %>% 
  xgb.ggplot.importance(top_n=6, measure=NULL, rel_to_first = F)


