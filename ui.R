library(shiny)

shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("fb Places Gatherer"),
  
  sidebarPanel(
    textInput(inputId="fbToken", label="Facebook Access Token"),
    helpModal(title="FB Access Token", link="fbTokenHelp", content='<p>Go to <a href="https://developers.facebook.com/tools/explorer" target="_blank">https://developers.facebook.com/tools/explorer</a>, log-in, get an access token, and paste it here</p>'),
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
               downloadButton('downloadShp', 'Download Shapefile (Lambert 93)'),
               showOutput(outputId="placesStats", "nvd3")),
      tabPanel(title="Table",
                  dataTableOutput(outputId="placesTable")),
      tabPanel(title="About", includeMarkdown("README.md"))
    )
  )
))
