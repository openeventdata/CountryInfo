library(jsonlite)
library(tibble)
library(dplyr)

file <- commandArgs(trailingOnly = TRUE)[1]

dat <- read_json(file)

getLeaders <- function(country){
  leaders <- tibble(country = character(),
                    name = character(),
                    title = character())
  titles <- names(country$leaders)
  for(title in titles){
    for(leader in country$leaders[[title]]){
      row <- list(
        country = unlist(country$countryname),
        name = leader,
        title = title
      )
      leaders <- bind_rows(row,leaders)
    }
  }
  leaders
}

#####################################

allLeaders <- tibble(country = character(),
                     name = character(),
                     title = character())
allGov <- tibble(country = character(),
                 name = character())

#####################################

for(country in dat){
  fields <- names(country)
  hasLeaders <- 'leaders'%in% fields
  hasGov <- 'government' %in% fields
  
  if(hasLeaders){
    print(paste('Getting',country$countryname))
    leaders <- getLeaders(country)
  } else {
    leaders <- NA
  }
  
  
#  if(hasGov){
#    gov <- getGov(country)
#  } else {
#    gov <- NA
#  }
  if(!is.na(leaders)){
    allLeaders <- bind_rows(allLeaders,leaders)
  }
#  if(!is.na(gov)){
#    allGov <- bind_rows(allGov,gov)
#  }
}

#####################################

singularize.words <- function(words_vector){
  sapply(words_vector,function(words){
    str_replace_all(words,pattern='_',' ')%>%
    str_split('(-| )')%>%
    lapply(function(word){
      singularize(word)%>%
      glue_collapse(sep=' ')
    })%>%
    unlist()
  })
}