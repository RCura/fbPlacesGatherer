
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
require(RCurl)
require(rjson)
require(jsonlite)

shinyServer(function(input, output) {
  
  getFBData <- reactive({
    mtcars[1:input$maxDistance,]
  })
   
  output$placesTable <- renderDataTable({
    getFBData()
  })
  
  output$placesMap <- renderPlot({
    plot(getFBData())
  })
  
  output$test <- renderText({
    query
  })

  
  query <- 'SELECT page_id, name, were_here_count, checkins, fan_count, talking_about_count, type, categories
FROM page WHERE page_id in (
SELECT page_id
FROM place
WHERE distance(latitude, longitude, "47.75", "7.33333") < 5000 and NOT is_city 
LIMIT 100)
ORDER BY were_here_count DESC
LIMIT 100'
  token <- "CAACEdEose0cBALCYk6Nk2XaynTFQDWZBAsQZAqbL0JQWL6ZBBj2RfhLRZAqklt45DskNINnuvSZBSoKyJReVZB3XoYmL1hiiBh7y6FHA6Q5mzzk6wYljiEWwGusqU44heNrlO7fZAlvPp7fI7XVdFwSd53rnc4BIoh9vaZAFR2wlSxR2gdUEpTDIrAvaz8FaMlgZD"

  query <- gsub(" ","+",gsub("\n", "+",query))
  urlQuery <- paste("https://graph.facebook.com/fql?q=",query,"&access_token=", token)

  
  abc <- "https://graph.facebook.com/search?q=places&type=place&center=48.813333,2.344444&distance=50000&limit=100&fields=id,name,checkins,likes,location,category,category_list&access_token="
  abcd <- paste(abc, token, sep="")
  test <- fromJSON(abcd)
  
  #test <- rbind(test, fromJSON(test$paging$`next`)$data)
  myDF <- test$data
  while (!is.null(test$data)){
    print(nrow(myDF))
    test <- fromJSON(test$paging$`next`)
    newData <- test$data
    print(nrow(newData))
    currLength <- nrow(myDF)
    newLength <- nrow(myDF) + nrow(newData)
    row.names(newData) <- (currLength + 1):(newLength)
    myDF <- rbind(myDF, newData)
  }
  View(cbind(test$data, test$data$location))

  })
