library(shiny)
library(jsonlite) # install.packages("jsonlite", repos="http://cran.r-project.org")
# NOTE : Only this version of jsonlite works, not the rstudio-cran or github one :/
library(sp)
library(rgdal)
library(rCharts) # github dev branch
library(ggmap)
library(reshape)

shinyServer(function(input, output) {
  
  geocodedCoords <- reactive({
    if (input$runQuery > 0){
    place <- isolate(input$location)
    myPlace <- ggmap::geocode(place)
    return(paste(rev(myPlace), collapse=","))
    }
  })
  
  getFBData <- reactive({
    if (input$runQuery > 0){

    fbToken <- "288831644599402|11c28468d6499cbb58ff8493c9f77cdc"
    baseQuery <- sprintf("https://graph.facebook.com/search?type=place&limit=10000&fields=id,name,checkins,likes,location,category,category_list&center=%s&distance=%s&access_token=%s", geocodedCoords(), isolate(input$maxDistance), fbToken)
    rawData <- try(jsonlite::fromJSON(baseQuery))
    if (class(rawData) == "try-error") {return()}
    fbData <- fbJSONtoDF(rawData$data)
    row.names(fbData) <- fbData$id
    rawData <- jsonlite::fromJSON(rawData$paging$`next`)
    while (length(rawData$data) > 0){
          newData <- fbJSONtoDF(rawData$data)
          row.names(newData) <- newData$id
          fbData <- rbind(fbData, newData)
          rawData <- jsonlite::fromJSON(rawData$paging$`next`)
         }
    fbData <- as.data.frame(apply(X=fbData, MARGIN=c(1:2), FUN=enc2utf8), stringsAsFactors=FALSE)
    fbData <- as.data.frame(apply(X=fbData, MARGIN=c(1:2), FUN=function(x){return(gsub(pattern="\023", replacement="-", x=x))}), stringsAsFactors=FALSE)
    fbData <- as.data.frame(apply(X=fbData, MARGIN=c(1:2), FUN=function(x){return(gsub(pattern="\031", replacement="'", x=x))}), stringsAsFactors=FALSE)
    fbData <- as.data.frame(apply(X=fbData, MARGIN=c(1:2), FUN=function(x){return(gsub(pattern="\"", replacement="", x=x))}), stringsAsFactors=FALSE)
    fbData$latitude <- as.numeric(fbData$latitude)
    fbData$longitude <- as.numeric(fbData$longitude)
    fbData$likes <- as.numeric(fbData$likes)
    fbData$checkins <- as.numeric(fbData$checkins)
    return(fbData[fbData$category!="City",])
    } else {
      return()
    }
  })
  
  getGeoContent <- reactive({
    if (is.null(getFBData())){return()}
    WGS84 <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
    L93 <- CRS("+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
        
    df <- getFBData()
    geoDF <- df
    coordinates(obj=geoDF) <- ~ longitude + latitude
    centerCoords <- as.double(unlist(strsplit(geocodedCoords(), split=",")))
    centerPoint <- SpatialPoints(data.frame(latitude=centerCoords[2], longitude=centerCoords[1]), proj4string=WGS84)
    proj4string(geoDF) <- WGS84

    geoDF <- spTransform(geoDF, L93)
    centerPoint <- spTransform(centerPoint, L93)
    geoDF@data$distance <- as.numeric(spDists(geoDF, centerPoint, longlat=FALSE))
 
    return(geoDF)
  })
  
  
   
  output$placesTable <- renderDataTable({
    if(is.null(getFBData())){return()}
    myDF <- getFBData()
    myDF$name <- sprintf('<a href="http://www.facebook.com/%s" target="_blank">%s</a>', myDF$id, myDF$name)
    return(myDF)
  })
  
  output$placesMap <- renderMap({
    if (is.null(getGeoContent())){
    return(rCharts::Leaflet$new())
    }
    geom <- getGeoContent()
    geom <- spTransform(x=geom, CRSobj=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))
    myDF <- as.data.frame(cbind(geom, as.data.frame(geom@coords)))
    centerCoords <- as.double(unlist(strsplit(geocodedCoords(), split=",")))
    placesMap <- Leaflet$new()
    userDist <- isolate(input$maxDistance)
    if (userDist <= 5000){
      zoomLvl <- 12
    } else if (userDist <= 15000) {
      zoomLvl <- 11
    } else {
      zoomLvl <- 10
    }
    placesMap$setView(centerCoords, zoom = zoomLvl)
    for (i in 1:nrow(myDF)){
      curCoords <- c(myDF$latitude[i], myDF$longitude[i])
      placesMap$marker(curCoords, bindPopup=sprintf('<p><a href="http://www.facebook.com/%s" target="_blank">%s</a></p>', myDF$id[i], myDF$name[i]))
    }
    placesMap$tileLayer(provider = "MapQuestOpen.OSM")
    return(placesMap)
  })
  
  output$placesStats <- renderChart({
    if (is.null(getGeoContent())){return(rCharts::nvd3Plot$new())}
    df <- getGeoContent()@data
    df <- df[order(df$distance),]
    df <- df[,c("id", "distance","likes","checkins")]
    df <- na.omit(df)
    
    df$distanceCumulee <- cumsum(rep(x=1, times=nrow(df))) / nrow(df) * 100
    df$likesCumules <- cumsum(na.exclude(df$likes)) / sum(df$likes, na.rm=TRUE) * 100
    df$checkinsCumules <- cumsum(na.exclude(df$checkins)) / sum(df$checkins, na.rm=TRUE) * 100
    
    plotDF <- melt(df, value.name="value", measure.vars=c("distanceCumulee", "likesCumules", "checkinsCumules"))
    #str(plotDF)
    n1 <- nPlot(value ~ distance, data = plotDF, group="variable", type = "lineChart")
    n1$xAxis(axisLabel = 'Distance to geocoded point (m)')
    n1$yAxis(axisLabel = 'Cumulative frequency')
    n1$addParams(dom="placesStats")
    return(n1)
  })
  
  output$downloadShp <- downloadHandler(
    filename = 'fbCrawlExport.zip',
    content = function(file) {
      if (length(Sys.glob("fbCrawl.*"))>0){
        file.remove(Sys.glob("fbCrawl.*"))
      }
      writeOGR(getGeoContent(), dsn="fbCrawl.shp", layer="fbCrawl", driver="ESRI Shapefile")
      write.csv(as.data.frame(cbind(getGeoContent()@data, as.data.frame(getGeoContent()@coords))), "fbCrawl.csv")
      zip(zipfile='fbCrawlExport.zip', files=Sys.glob("fbCrawl.*"))
      file.copy("fbCrawlExport.zip", file)
      if (length(Sys.glob("fbCrawl.*"))>0){
        file.remove(Sys.glob("fbCrawl.*"))
      }
    }
  )
  
  
  })
