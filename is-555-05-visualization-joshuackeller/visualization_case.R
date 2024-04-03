# Intro / Setup -----------------------------------------------------------------------------------------

library(tidyverse)
cars <- read_csv('https://www.dropbox.com/s/piimbmlxxn2d1f5/cars.csv?dl=1')


#1 data_1, plot_1
data_1 <- cars %>%
  filter(cylinders %in% c(4, 6, 8)) %>% 
  # arrange(cylinders) %>% # this was the only way I was able to get the chart to order right, but it screws up how data_1 is supposed to look so I left it out
  mutate(cylinders_c = parse_factor(as.character(cylinders))) %>% 
  select(make, model, mpg_hwy, cylinders_c)

# Note: Try to change order to 4,6,8
plot_1 <- data_1 %>% 
  ggplot(mapping = aes(x = mpg_hwy, color = cylinders_c, fill = cylinders_c)) +
  geom_histogram(alpha = .5, position = 'dodge', bins = 15) +
  labs(x = "Highway MPG", y ="Count", title = "Highway MPG by Cylinders") +
  theme_bw()


#2 data_2, plot_2
data_2 <- cars %>% 
  filter(year %in% c(1985, 1995, 2010)) %>% 
  mutate(era = if_else(year == 1985, "80s", if_else(year == 1995, "90s", "2000s"))) %>% 
  select(make, model, mpg_city, era)

plot_2 <- data_2 %>% 
  ggplot(mapping = aes(x = mpg_city, fill = era)) +
  geom_density(alpha = 0.5) +
  geom_vline(xintercept = 30, color="green") +
  labs(x = "City MPG", y = "Density", title = "Density of City MPG for the 80s, 90s, and 2000s") +
  theme_bw()

#3 data_3, plot_3

data_3 <- cars %>% 
  filter(class %in% c('Compact Cars', 'Subcompact Cars', 'Standard Pickup Trucks', 'Midsize Cars')) %>% 
  select(make, class)

plot_3 <- data_3 %>% 
  ggplot(mapping = aes(x = make, fill = class)) +
  geom_bar() +
  labs(x = "Make", y = "Count", title = "Count of Makes and Top 4 Classes") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))


#4 data_4, plot_4

data_4 <- cars %>% 
  filter(make %in% c('Chevrolet', 'Porsche', 'Mercedes-Benz', 'Toyota')) %>% 
  select(make, mpg_hwy)

plot_4 <- data_4 %>% 
  ggplot(mapping = aes(x = make, y = mpg_hwy, fill = make)) +
  geom_violin() +
  annotate("text", x = 1.25, y = 105, label = "SparkEV, MPG=109") +
  labs(x = "Make", y = "Highway MPG", title = "Distribution of Highway MPG for 4 Makes") +
  theme_bw()

#5 data_5, plot_5

data_5 <- cars %>% 
  filter(year >= 2008, drive %in% c("4-Wheel or All-Wheel Drive", "Front-Wheel Drive", "Rear-Wheel Drive")) 

plot_5 <- data_5 %>% 
  ggplot(mapping = aes(x = cylinders, y = mpg_city, color = drive)) +
  geom_point(alpha = 0.3, size = 4, position = "jitter") +
  scale_x_continuous(limits = c(1,13), breaks = c(2,4,6,8,10,12)) +
  labs(x = "Cylinders", y = "City MPG", title = "City MPG by Cylinders and Drive Type") +
  theme_bw()


#6 data_6, plot_6

data_6 <- cars %>% 
  filter(drive != "Part-time 4-Wheel Drive") %>% 
  select(eng_size, mpg_city, drive)

plot_6 <- data_6 %>% 
  ggplot(mapping = aes(x = eng_size, y = mpg_city)) +
  geom_point() +
  geom_smooth() +
  facet_wrap(~drive, scales = "free") +
  theme_bw()

#7 data_7, plot_7

data_7 <- cars %>% 
  mutate(fuel_group = if_else(fuel == "Regular", "Regular Unleaded", "Other")) %>% 
  filter(make %in% c('Chevrolet', 'Ford', 'Dodge', 'Toyota')) %>% 
  group_by(make, year, fuel_group) %>% 
  summarize(city = mean(mpg_city, na.rm = T), hwy = mean(mpg_hwy, na.rm = T)) %>% 
  pivot_longer(
    cols = c(city, hwy),
    names_to = "mpg_type",
    values_to = "mpg"
  )

plot_7 <- data_7 %>% 
  ggplot(mapping = aes(x = year, y = mpg, color = mpg_type)) +
  geom_line(size = 1) +
  facet_grid(fuel_group~make) +
  labs(x = "Year", y = "Avg MPG", title = "MPG over time across makes and fuel type") +
  theme_bw() 
  
  

# Finalize, Commit, Push --------------------------------------------------------------------------------

# BEFORE YOU COMMIT AND PUSH YOUR SUBMISSION
#
# Please carefully follow the (new) instructions at the end of the ReadMe document for finalizing and testing 
# your submission prior to commiting and pushing your submission.



