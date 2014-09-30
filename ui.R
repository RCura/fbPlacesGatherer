library(shiny)

shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("fb Places Gatherer", tags$head(includeScript("analytics.js"))),
  
  sidebarPanel(
   textInput(inputId="location", label="Location", value="Vallauris, France"),
   helpModal(title="Location", link="locationHelp", content="<p> Enter any location here, and it shall be geocoded. The more precise you are, the most efficient the geocoding is."),
   sliderInput(inputId="maxDistance", label="Max distance (m)", min=1000, max=20000, value=5000, step=1000),
   actionButton(inputId="runQuery",label='Get Data !')
   
  ),
  
  mainPanel(
    tabsetPanel(
      tabPanel("Plots",
               chartOutput(outputId = "placesMap", lib = 'leaflet'),
               tags$hr(),
               downloadButton('downloadShp', 'Download Shapefile (Lambert 93)'),
               showOutput(outputId="placesStats", lib = "nvd3", )
               ),
      tabPanel(title="Table",
               dataTableOutput(outputId="placesTable")),
      tabPanel(title="About", includeMarkdown("README.md"))
    )
  )
))
