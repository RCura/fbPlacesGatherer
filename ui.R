
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
    textInput(inputId="fbToken", label="Facebook Access Token", value="CAACEdEose0cBAMKPWNC8rUV1fbFMsPEBC17QitQk16A5cOJXk0NUAv3KDr7f8Gk3whxCHf4RtmJvJLyHhWL2vRPJMCHrc7E5NJ7VsYY4vsPjKnXkHmedNGVYEKDeF7thZB14mg6SmgsmZCCZASzCaofPbsQAIZAF3ZAuhV14rnZBEMCPlSaXLajSrXUh03cQ0ZD"),
    helpModal(title="FB Access Token", link="fbTokenHelp", content='<p>Go to <a href="https://developers.facebook.com/tools/explorer">https://developers.facebook.com/tools/explorer</a>, log-in, get an access token, and paste it here</p>'),
   textInput(inputId="location", label="Location", value="Mulhouse, France"),
   helpModal(title="Location", link="locationHelp", content="<p> Enter any location here, and it shall be geocoded. The more precise you are, the most efficient the geocoding is."),
   sliderInput(inputId="maxDistance", label="Max distance (m)", min=1000, max=20000, value=5000, step=1000),
   submitButton(text='Get Data !')
   
  ),
  
  mainPanel(
    tabsetPanel(
      tabPanel("Plots",
               showOutput(outputId="placesMap", "leaflet"),
               tags$hr(),
               downloadButton('downloadShp', 'Download shapefile'),
               #showOutput(outputId="heatMap", "leaflet"),
               plotOutput(output="placesStats")),
      tabPanel(title="Table",
                  dataTableOutput(outputId="placesTable"))
    )
  )
))
