###############################
###############################
###data preparation script
###############################
###############################

###############################
###set up
###############################

# AG: to enhance reproducibility, I reccommend including the names of the packages so that we know what needs to be installed first, in case we don't have some of the packages you are using. Also, I think it would be useful to put a note for people that are less experienced in r (like me) that they need to follow the prompts when openening the libraries of the packages you have, like lme4, lmerTest, and cowplot. At first I didn't do that and I was not being able to see the tidied data. 


# Install required packages

# install.packages("tidyverse")
# install.packages("lme4")
# install.packages("lmerTest")
# install.packages("cowplot")
# install.packages("wesanderson")
# install.packages("here")
# install.packages("rio")
# install.packages("lubridate")
# install.packages("cowplot")
# install.packages("wesanderson")
# install.packages("forcats")
# install.packages("pander")

#load required packages
library(tidyverse)
library(lme4)
library(lmerTest)
library(here)
library(rio)
library(lubridate)
library(cowplot)
library(wesanderson)
library(forcats)
library(pander)

#create function to find column numbers given column names
.rcol <- function(column.name.as.string = NULL, data = df) {
  grep(column.name.as.string, colnames(data))
}

#import data
df <- import(here::here("data", "dataSPSS.sav"), setclass = "tibble") %>%
  janitor::clean_names() 

head(df) # AG: I like to use head() and View() to check if my data frame looks how I expect. I will be using it here and there to see how your data frame changes with each step. 

#characterize all columns except for age and books1 (the spss labels were causing the numeric values to be recorded as NAs for those columns)
df[, -c(.rcol("age"), 
        .rcol("books1"))] <- characterize(df[, -c(.rcol("age"), 
                                                  .rcol("books1"))]) # AG: Such an efficient way to characterize the variables, I am wriying it down in my notes! 

###############################
###data tidying
###############################

#select only variables of interest
df <- df %>%
  select(-comp, 
         -state:-qs1,
         -intmob,
         -home4nw:-device1d,
         -web1f:-web1h, #dropped because we don't have frequency values
         -pial5a:-pial5d,
         -pial11a:-pial11_igbm,
         -marital:-racem4,
         -birth_hisp,
         -partyln:-cellweight)
  
#parse date for interview date column
df <- df %>%
  mutate(int_date = ymd(int_date))

head(df)

#remove participants who do not occasionally use the internet or email
df <- df %>% 
  filter(eminuse == "Yes") %>% 
  select(-eminuse) # AG: Did you needed to filter it if you were going to delete the column altogether? 

#over gather the sns_use and sns_freq_use columns, and spread them back out
df <- df %>%
  gather(key = "websites", value = "value", starts_with("sns"), starts_with("web")) %>%
  separate(websites, into = c("temp", "website"), sep = "[[:digit:]]") %>%
  spread(key = "temp", value = "value")

# View(df)

#change "no, do not do this" in the sns_use column to "Rarely if ever" in the sns_freq_use columns
df[which(df[, "web"] == "No, do not do this"), "sns"] <- "Rarely if ever"

# View(df)

#drop now unneeded sns_use column
df <- df %>%
  select(-web)

head(df)

#rename the values in the website column
df <- df %>%
  mutate(website = recode(website, a = "Twitter",
                                   b = "Instagram",
                                   c = "Facebook",
                                   d = "Snapchat",
                                   e = "YouTube"))
head(df)

#rename poorly named columns for sanity
df <- df %>%
  rename(id = respid,
         date = int_date,
         int_use_freq = intfreq,
         int_good_society = pial11,
         int_good_self = pial12,
         total_books_read = books1,
         books_print = books2a,
         books_audio = books2b,
         books_elect = books2c,
         race = racecmb,
         income = inc,
         sns_freq_use = sns,
         sns = website)

head(df)

#convert factors to factors
df <- df %>%
  mutate(books_print = factor(books_print),
         books_audio = factor(books_audio),
         books_elect = factor(books_elect),
         sex = factor(sex),
         race = factor(race),
         party = factor(party),
         sns = factor(sns),
         int_good_society = factor(int_good_society),
         int_good_self = factor(int_good_self),
         int_use_freq = factor(int_use_freq),
         sns_freq_use = factor(sns_freq_use))

# View(df)

df <- df %>%
  mutate(int_good_self    = fct_recode(int_good_self,
                                       "Bad" = "Bad thing",
                                       "Good" = "Good thing",
                                       "Some of both" = "(VOL) Some of both",
                                       "Other" = "(VOL) Don't know",
                                       "Other" = "(VOL) Refused"),
         int_good_society = fct_recode(int_good_society,
                                       "Bad" = "Bad thing",
                                       "Good" = "Good thing",
                                       "Some of both" = "(VOL) Some of both",
                                       "Other" = "(VOL) Don't know",
                                       "Other" = "(VOL) Refused"),
         party            = fct_recode(party,
                                       "Other" = "(VOL) Other party",
                                       "Other" = "(VOL) Don't know",
                                       "Other" = "(VOL) No preference",
                                       "Refused" = "(VOL) Refused"),
         race             = fct_recode(race,
                                       "Asian" = "Asian or Asian-American",
                                       "Black" = "Black or African-American",
                                       "Other" = "Or some other race",
                                       "Mixed" = "Mixed Race"))


df <- df %>%
  mutate(int_good_society = factor(int_good_society, 
                                   levels = c("Other", 
                                               "Bad", 
                                               "Some of both", 
                                               "Good")),
         int_good_self    = factor(int_good_self, 
                                   levels = c("Other", 
                                              "Bad", 
                                              "Some of both", 
                                              "Good")),
         int_use_freq     = factor(int_use_freq, 
                                   levels = c("(VOL) Don't know", 
                                              "Less often?", 
                                              "Several times a week, OR", 
                                              "About once a day", 
                                              "Several times a day", 
                                              "Almost constantly")),
         sns_freq_use     = factor(sns_freq_use,
                                   levels = c("(VOL) Don't know",
                                              "Rarely if ever",
                                              "Less often",
                                              "Every few weeks",
                                              "A few times a week", 
                                              "About once a day", 
                                              "Several times a day")))


# View(df) # AG: This is a very nice looking tidy data frame. I was able to follow along each step. Really Well done, you make it look easy! 

#################################################
########### Analyses and Data Viz ###############
#################################################

# Examine whether age trends in reading differs as a function of book format 
# (e.g. do older readers spend more time with paper copy books whereas younger users may spend more time with audiobooks or digital print?). 

# Subset the original data and tidy for plotting
plot_data <- df %>% 
  select(age, total_books_read, books_print, books_audio, books_elect) %>% 
  gather(book_format, yn, -age, -total_books_read) %>% 
  separate(book_format, c("dis", "book_format"), sep = "_", convert = TRUE) %>% 
  select(-dis) %>% 
  filter(!is.na(yn) & !str_detect(yn, "VOL")) %>% 
  mutate(book_format = factor(book_format),
         yn = factor(yn)) 

head(plot_data) # AG: You really have this tidy skills down. I am impressed! 


####

# Bar Chart: looking at average books read across age.
bar_plot <- plot_data %>% 
  group_by(age) %>% 
  summarize(mean_books = mean(total_books_read)) %>% 
  ggplot(aes(x = age, y = mean_books, fill = age)) + 
  geom_col() +
  scale_fill_viridis_c() + 
  theme(legend.position = "none") +
  labs(y = "Average Books Read",
       x = "Age",
       title = "Average Number of Books Read by Age",
       subtitle = "Books Read in the Past Year. Respondents 18-99.") +
  theme(plot.subtitle = element_text(size = 11, hjust = 0, face = "italic", color = "black"),
        plot.title = element_text(size = 15, hjust = 0))

bar_plot # AG: Beautiful plot! You use some "tricks" in here that will definitely make my plots look better.



# Bar Chart: Average books read by format
bar_plot2 <- plot_data %>% 
  group_by(age, book_format) %>% 
  summarize(mean_books = mean(total_books_read)) %>% 
  ggplot(aes(x = age, y = mean_books, fill = book_format)) + 
  geom_col() +
  facet_wrap(~book_format, nrow = 3, ncol = 1) +
  theme(legend.position = "none") +
  labs(y = "Average Books Read",
       x = "Age",
       title = "Average Books Read by Format",
       subtitle = "Average Books Read in the Past Year. Respondents 18-99.") +
  theme(plot.subtitle = element_text(size = 11, hjust = 0, face = "italic", color = "black"),
        plot.title = element_text(size = 15, hjust = 0))

bar_plot2

## Scatter Plots: 
# Total books read by format
point_plot <- plot_data %>% 
  filter(yn == 'Yes') %>% 
  group_by(age, book_format) %>% 
  count(yn) %>% 
  ggplot(aes(x = age, y = n)) + 
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_wrap(~book_format, nrow = 3, ncol = 1) +
  theme(legend.position = "none") +
  labs(y = "Total Books Read",
       x = "Age",
       title = "Total Books Read by Format",
       subtitle = "Total Books Read in the Past Year. Respondents 18-99.") +
  theme(plot.subtitle = element_text(size = 11, hjust = 0, face = "italic", color = "black"),
        plot.title = element_text(size = 15, hjust = 0))

point_plot

# Average books read by format
point_plot2 <- plot_data %>% 
  group_by(age, book_format) %>% 
  summarize(mean_books = mean(total_books_read)) %>% 
  ggplot(aes(x = age, y = mean_books)) + 
  geom_point() +
  geom_smooth(method = 'lm',
              aes(color = book_format)) +
  scale_color_manual(values = wes_palette("Darjeeling1")) +
  facet_wrap(~book_format, nrow = 3, ncol = 1) +
  theme(legend.position = "none") +
  labs(y = "Average Books Read",
       x = "Age",
       title = "Average Books Read by Format",
       subtitle = "Average Books Read in the Past Year. Respondents 18-99.") +
  theme(plot.subtitle = element_text(size = 11, hjust = 0, face = "italic", color = "black"),
        plot.title = element_text(size = 15, hjust = 0))

point_plot2

# Regression model to see how age and format of books relates to average number of books read. 
reg_data <- plot_data %>%
  group_by(age, book_format) %>% 
  summarize(mean_books = mean(total_books_read))

model <- lm(mean_books ~ age * book_format, data = reg_data)
model

# Put anova of regression model into a table
pander(anova(model)) # AG: I didn't know this way of making a table. Going to my notes too!

###############################################
######### Ash's Data Visualizations ###########
###############################################

#Examine whether perceptions of social media use vary as age, political party, and social media site

#Prep data

plot_data_ash <- df %>% 
  select(age, sex, race, cregion, party, sns, sns_freq_use, int_good_society, int_good_self, int_use_freq)

#FINALLY ready for the first graph:

#Graphing ratings of how good vs bad the internet is for society as a function of political party

plot_ash1 <- plot_data_ash %>%
  mutate(int_good_self = as.numeric(int_good_self), # AG: Interesting. I didn't know you could do this. Good idea!
         int_good_society = as.numeric(int_good_society)) %>%
  filter(party != "Refused") %>% # AG: I'll try this in my plot to avoid cluttering the view. Thanks!
  group_by(party) %>%
  summarize(m_age = mean(age),
            m_self = mean(int_good_self),
            m_society = mean(int_good_society)) %>%
  ggplot(aes(x = party, y = m_society)) +
  geom_col(alpha = 0.5, fill = "turquoise3", color = "turquoise4") +
  geom_hline(yintercept = 3.5) + #Note that this line represents the overall mean
  theme_bw() +
  labs(title = "Ash's Plot 1.",
       subtitle = "Ratings on a 4 point scale of how good or bad the internet is for society as a function of political party",
       x = "Political Party", 
       y = "Mean Rating") +
  coord_cartesian(ylim = c(2.5, 4)) 


plot_ash1

#Graph number 2 data prep:

plot2_data_ash <- plot_data_ash %>%
  mutate(int_good_self = as.numeric(int_good_self),
         int_good_society = as.numeric(int_good_society)) %>%
  select(-party, -age) %>%
  filter(int_use_freq != "(VOL) Don't know",
         race != "Don't know/Refused (VOL.)") %>%
  group_by(cregion, race) %>%
  summarize(m_self = mean(int_good_self),
            m_society = mean(int_good_society))

plot2_data_ash <- plot2_data_ash %>%
  mutate(self_vs_society = m_self - m_society)

head(plot2_data_ash)

#Plot comparing ratings between how good the internet is for the self.. 
#relative to how good the internet is for society.. 
#as a function of race and region in the US

plot_ash2 <- ggplot(plot2_data_ash, aes(x = race, y = self_vs_society, fill = race)) +
  geom_col(alpha = 0.8) +
  facet_wrap(~cregion, ncol = 4) +
  scale_fill_viridis_d() +
  theme_bw() +
  theme(legend.position = "") +
  labs(title = "Ash's Plot 2.",
       subtitle = "Mean difference in ratings between how good the internet is for the self 
relative to how good the internet is for society as a funtion of race and region in the US",
       x = "Race", 
       y = "Mean rating for self - Mean rating for society") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) # AG: I added this so the labels don't overlap. 

plot_ash2

#Another plot

plot_ash3 <- plot_data_ash %>%
  mutate(int_good_self = as.numeric(int_good_self),
         int_good_society = as.numeric(int_good_society),
         int_use_freq = as.numeric(int_use_freq),
         sns_freq_use = as.numeric(sns_freq_use)) %>%
  filter(party != "Refused",
         sns_freq_use != "<NA>",
         sns_freq_use != "(VOL) Don't know") %>%
  ggplot(aes(x = age, y = sns_freq_use)) +
  geom_smooth(aes(group = party, colour = party), method = "lm", se = FALSE) +
  facet_wrap(~sns) +
  scale_colour_viridis_d() +
  theme_bw() +
  labs(title = "Ash's Plot 3.",
       subtitle = "The relation between age and frequency of social media use as a function of political party and social media site",
       x = "Age", 
       y = "Frequency of social media use",
       colour = "Political party")

plot_ash3

#Yet another plot

plot_ash4 <- plot_data_ash %>%
  mutate(int_good_self = as.numeric(int_good_self),
         int_good_society = as.numeric(int_good_society),
         int_use_freq = as.numeric(int_use_freq),
         sns_freq_use = as.numeric(sns_freq_use)) %>%
  filter(party != "Refused",
         sns_freq_use != "<NA>",
         sns_freq_use != "(VOL) Don't know") %>%
  ggplot(aes(x = age, y = sns_freq_use)) +
  geom_smooth(aes(group = sex, colour = sex), method = "lm", se = FALSE, lwd = 2) +
  scale_color_manual(values = c("turquoise3", "purple3")) +
  facet_wrap(~sns) +
  theme_bw() +
  labs(title = "Ash and Cam's plot 4.",
       subtitle = "The relation between age and frequency of social media use as a function of gender identity and social media site",
       x = "Age", 
       y = "Frequency of social media use",
       colour = "Gender identity") # AG: I suggest changing "gender identity" for "sex" as female and male are just the options for assigned sex. Using gender identity may lead your readers to think that you are including the several other possibilities in the spectrum ;) 

plot_ash4

# Overall: You did a fantastic job tyding the data. Honestly, I couldn't have done it better, thus I have really no suggestions to make in this area. You maintain a consistent use of the coding style that is easy to read. Your comments were useful to guide me to the process of what you were doing in each step. Some of your code is new to me. I found it very efficient and even elegant! Several things I saw here will enhance my tiding skills. Thank you! 

# To me, it is evident that you know how to do this, so my only suggestion is in relation to enhancing reproducibilit, especially for less experenced r users. In general, your code is very reproducible and easy to follow, but It took my a while to "set up" the libraries with all the functions needed to run the code. I suggest just including a few messages at the beginning so your reader does not get stuck in the first part. 

# Again, really great job! I hope you find my very few suggestions useful. I made comments and used my initials "AG" before the comments. 

