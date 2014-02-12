
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
require(httr)
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
  token <- "CAACEdEose0cBALbUzGXgMatmZBB6zegBgcCX37zrnLwnBVoMZC2mkSB7c5L8x82y4chdMfDSrS31CFj6O9RQQ6XzZC1hvmXJYr9hZAswWKDj8ku9TTJkb54UHngS648Lt9q8J3nuMyS3ZAYW8RzbEBwU0vHpPGE3j4hJZCfg5SN8w4SxmJJhhYgnm24x2ZCJ8MZD"
  token2 <- "CAACEdEose0cBANavxSTkTPSVuup2ESHarnji60YO8OxoV2xm7E1bg7d3QFCaf6jOJ0BH2L8ni5c9IRf9g3ASQfKAEDmFB7IZCCZBQ9zZBZBt6nuOzCQZCuLaq32AGgHmaSvRh2v3E7HRYM6MJx0ZBQjsac4oLVL9JHZCAIMbuEeEYjhldcOCgPxh1FAXHClDTUZD"
  query <- gsub(" ","+",gsub("\n", "+",query))
  urlQuery <- paste("https://graph.facebook.com/fql?q=",query,"&access_token=", token2)
  
  ### CHECK : https://github.com/tuxette/fbs/blob/master/server.R
  
})
