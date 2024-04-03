# Load required libraries
library(tidyverse)
library(scales)

# Read the dataset
job_data <- read_csv("https://www.dropbox.com/s/0ka14thbylxumas/data_jobs.csv?dl=1") 

# 1. top_hiring_companies, plot_1
top_hiring_companies <- job_data %>% 
  group_by(company) %>% 
  summarize(n = n()) %>% 
  slice_max(order_by = n, n = 10)
  
plot_1 <- top_hiring_companies %>% 
  ggplot(aes(x = n, y = reorder(company, n), fill = company)) +
  geom_col() +
  theme_bw() + 
  theme(legend.position = "none") +
  labs(title = "Top 10 Hiring Companies", x = "Number of Job Postings", y = "Company")

# 2. top_job_titles, plot_2
top_job_titles <- job_data %>% 
  group_by(job_simpl) %>% 
  summarize(n = n()) %>% 
  arrange(desc(n))

plot_2 <- top_job_titles %>% 
  ggplot(aes(x = n, y = reorder(job_simpl, n), fill = job_simpl)) +
  geom_col() +
  theme_bw() + 
  theme(legend.position = "none") +
  labs(title = "Jobs by Simplified Title", x = "Number of Job Postings", y = "Job Title")


# 3. skill_counts, plot_3
skill_counts <- job_data %>%
  select(ends_with("_yn")) %>%
  summarize_all(list(sum)) %>% 
  pivot_longer(
    cols = everything(),
    names_to = "skill",
    values_to = "count"
  ) 

plot_3 <- skill_counts %>% 
  ggplot(aes(x = count, y = reorder(skill, count), fill = skill)) +
  geom_col() +
  theme_bw() + 
  theme(legend.position = "none") +
  labs(title = "Skills Required", x = "Number of Job Postings", y = "Skills")
  

# 4. top_10_job_locations, plot_4
top_10_job_locations <- job_data %>% 
  group_by(location) %>% 
  summarize(n = n()) %>% 
  slice_max(order_by = n, n = 10)

plot_4 <- top_10_job_locations %>% 
  ggplot(aes(x = n, y = reorder(location, n), fill = location)) +
  geom_col() +
  theme_bw() + 
  theme(legend.position = "none") +
  labs(title = "Job Postings by Location", x = "Number of Job Postings", y = "Location")

# 5. plot_5
plot_5 <- job_data %>% 
  ggplot(aes(salary_estimate, fill = job_simpl)) +
  geom_histogram() +
  scale_x_continuous(labels = label_dollar()) +
  facet_wrap(~job_simpl) +
  theme_bw() + 
  theme(legend.position = "none") +
  labs(title = "Distribution of Salary Estimates", x = "Salary Estimate (USD)", y = "Number of Job Postings")
  

# 6. industry_salary, plot_6
industry_salary <- job_data %>% 
  filter(!is.na(company_industry)) %>% 
  group_by(company_industry) %>% 
  summarize(median_salary = median(salary_estimate), mean_salary = mean(salary_estimate)) 


plot_6 <- industry_salary %>% 
  ggplot(aes(x = median_salary, y = reorder(company_industry, median_salary), fill = company_industry)) +
  geom_col() +
  scale_x_continuous(labels = label_dollar()) +
  theme_bw() + 
  theme(legend.position = "none") +
  labs(title = "Salary Estimates by Industry", x = "Median Salary Estimate (USD)", y = "Industry")

# 7. top_locations_salary, plot_7
top_locations_salary <- job_data %>% 
  group_by(location) %>% 
  summarize(median_salary = median(salary_estimate), mean_salary = mean(salary_estimate), n = n()) %>% 
  slice_max(order_by = n, n = 10) %>% 
  arrange(location) %>% 
  select(-n)

plot_7 <- top_locations_salary %>% 
  ggplot(aes(x = median_salary, y = reorder(location, median_salary), fill = location)) +
  geom_col() +
  scale_x_continuous(labels = label_dollar()) +
  theme_bw() + 
  theme(legend.position = "none") +
  labs(title = "Salary Estimates by Location", x = "Median Salary Estimate (USD)", y = "Location")

# Naming Checks -----------------------------------------------------------------------------------------

# To help us avoid object or column name issues, I've included the following tests that will only pass 
# if you have named your objects and columns exactly correct. 

# IMPORTANT: You should not edit any of the code in this section. It should be run as a big block and you 
# should see the test results at the end.

expected_object_names <- c(
  "industry_salary",      "job_data",             "plot_1",               "plot_2",              
  "plot_3",               "plot_4",               "plot_5",               "plot_6",              
  "plot_7",               "skill_counts",         "top_10_job_locations", "top_hiring_companies",
  "top_job_titles",       "top_locations_salary"
  )

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
  message('All naming tests passed. But did you restart your session and run your WHOLE script from beginning to end with no errors??')
} else {
  message("Uh oh. Couldn't find the column(s) below:")
  found_cols %>% 
    filter(is.na(was_found)) %>% 
    select(-was_found) %>% 
    print()
}





