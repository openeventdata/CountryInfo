#!/usr/local/bin/rscript
library(jsonlite,quietly = TRUE,warn.conflicts = FALSE)
library(tibble,quietly = TRUE,warn.conflicts = FALSE)
library(dplyr,quietly = TRUE,warn.conflicts = FALSE)
library(pluralize,quietly = TRUE,warn.conflicts = FALSE)
library(glue,quietly = TRUE,warn.conflicts = FALSE)
library(stringr,quietly = TRUE,warn.conflicts = FALSE)

#####################################

getLeaders <- function(country){
  leaders <- tibble(country = character(),
                    name = character(),
                    title = character(),
                    startYr = character(),
                    endYr = character())
  
  titles <- names(country$leaders)
  for(title in titles){
    for(leader in country$leaders[[title]]){
      row <- list(
        country = unlist(country$countryname)[1],
        name = leader$name,
        title = title,
        startYr = leader$startYr,
        endYr = leader$endYr
      )
      leaders <- bind_rows(row,leaders)
    }
  }
  leaders
}

getGov <- function(country){
  gov <- tibble(country = character(),
                name = character(),
                description = character(),
                startYr = character(),
                endYr = character())
  
  for(entry in country$government){
    row <- list(
      country = unlist(country$countryname)[1],
      name = entry$name,
      description = entry$description,
      startYr = entry$startYr,
      endYr = entry$endYr
    )
    gov <- bind_rows(row,gov)
  }
  gov
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

#####################################

getPeople <- function(dat){
  
  
  leadersOut <- tibble(country = character(),
                       name = character(),
                       title = character(),
                       startYr = character(),
                       endYr = character())
  govOut <- tibble(country = character(),
                   name = character(),
                   description = character(),
                   startYr = character(),
                   endYr = character())
  
  for(country in dat){
    fields <- names(country)
    hasLeaders <- 'leaders'%in% fields
    hasGov <- 'government' %in% fields
    
    if(hasGov){
      hasGov <- length(country$government) != 0
    }
    
    if(hasLeaders){
      leaders <- getLeaders(country)
      leaders$title <- singularize.words(leaders$title)
      leadersOut <- bind_rows(leadersOut,leaders)
    } else {
      leaders <- NA
    }
    
    
    if(hasGov){
      gov <- getGov(country)
      govOut <- bind_rows(govOut,gov)
    } else {
      gov <- NA
    }
    
  }
  out <- list('leaders' = leadersOut,
              'gov' = govOut)
  out
}

#####################################

if(length(commandArgs(trailingOnly = TRUE))!=2){
  stop('usage : profiles.R -cinfo.json -outfolder')
}

file <- commandArgs(trailingOnly = TRUE)[1]
dest <- commandArgs(trailingOnly = TRUE)[2]



dat <- read_json(file)
people <- getPeople(dat)
for(n in names(people)){
  filename <- paste(dest,'/','people_',n,'.csv',sep='')
  write.csv(people[[n]],filename)
}
