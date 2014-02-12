
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)

shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("FB Places Crawler"),
  
  sidebarPanel(
   textInput(inputId="fbToken", label="Facebook Access Token"),
   textInput(inputId="pageID", label="Page ID", value="110522035635343"),
   sliderInput(inputId="maxDistance", label="Max distance", min=1, max=30, value=10, step=1),
   submitButton(text='Get Data !')
   
  ),
  
  mainPanel(
    textOutput(outputId="test"),
    dataTableOutput(outputId="placesTable"),
    plotOutput(outputId="placesMap")
  )
))
