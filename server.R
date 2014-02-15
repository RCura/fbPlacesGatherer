
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
library(jsonlite)
library(sp)
library(rgdal)
library(rCharts)
library(rMaps)
library(ggmap)

shinyServer(function(input, output) {
  
  geocodedCoords <- reactive({
    place <- input$location
    myPlace <- ggmap::geocode(place)
    return(paste(rev(myPlace), collapse=","))
  })
  
  getFBData <- reactive({
    #baseQuery <- "https://graph.facebook.com/search?q=places&type=place&center=48.813333,2.344444&distance=50000&limit=100&fields=id,name,checkins,likes,location,category,category_list&access_token=CAACEdEose0cBADIV3jMw7y2u0A7nShSP7ECD6ZAhZB39JVo6xA1bp5rRyJhtFY3KPv1yNjbKiJDzNws5FfNFEIZAdiuYZBBDSIZAAanPSh6MWQFuoTpNO5r64EoZBVGQKfNFodP8r27Gcco5kbAtdbZAqHjzW55RPCrnZAnJErq5KOoyD8DhgIuOuZAy6goxrUXMZD" 
    baseQuery <- sprintf("https://graph.facebook.com/search?type=place&limit=10000&fields=id,name,checkins,likes,location,category,category_list&center=%s&distance=%s&access_token=%s", geocodedCoords(), input$maxDistance, input$fbToken)
    print(baseQuery)
    rawData <- jsonlite::fromJSON(baseQuery)
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
    #print(fbData)
    fbData$latitude <- as.numeric(fbData$latitude)
    fbData$longitude <- as.numeric(fbData$longitude)
    fbData$likes <- as.numeric(fbData$likes)
    fbData$checkins <- as.numeric(fbData$checkins)
    #str(fbData)
    return(fbData[fbData$category!="City",])
  })
  
  getGeoContent <- reactive({
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
    getFBData()
  })
  
  
  output$placesStats <- renderPlot({
    df <- getGeoContent()@data
    df <- df[order(df$distance),]
    df <- df[,c("id", "distance","likes","checkins")]
    df <- na.omit(df)
    
    distanceCumulee <- cumsum(rep(x=1, times=nrow(df))) / nrow(df) * 100
    likesCumulee <- cumsum(na.exclude(df$likes)) / sum(df$likes, na.rm=TRUE) * 100
    checkinsCumulee <- cumsum(na.exclude(df$checkins)) / sum(df$checkins, na.rm=TRUE) * 100

    plot(x=df$distance, y=distanceCumulee, type="l", col="green")
    lines(x=df$distance, y=checkinsCumulee, col="red")
    lines(x=df$distance, y=likesCumulee, col="blue")
    
  })
  
  output$placesMap <- renderChart({
    geom <- getGeoContent()
    geom <- spTransform(x=geom, CRSobj=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))
    #print(geom@coords)
    myDF <- as.data.frame(cbind(geom, as.data.frame(geom@coords)))
    #str(myDF)
    centerCoords <- as.double(unlist(strsplit(geocodedCoords(), split=",")))
    placesMap <- Leaflet$new()
    
    placesMap$setView(centerCoords, zoom = 12)
    for (i in 1:nrow(myDF)){
      curCoords <- c(myDF$latitude[i], myDF$longitude[i])
      placesMap$marker(curCoords, bindPopup=sprintf('<p><a href="http://www.facebook.com/%s">%s</a></p>', myDF$id[i], myDF$name[i]))
    }
    placesMap$tileLayer(provider = "MapQuestOpen.OSM")
    placesMap$addParams(dom = 'placesMap')
    return(placesMap)
  })
  
  output$heatMap <- renderChart({
    centerCoords <- as.double(unlist(strsplit(geocodedCoords(), split=",")))
    heatMap <- Leaflet$new()
    heatMap$setView(centerCoords, 8)
    heatMap$tileLayer(provider = "MapQuestOpen.OSM")
    heatMap$addParams(dom="heatMap")
    return(heatMap)
  })
  
  output$downloadShp <- downloadHandler(
    filename = 'fbCrawlExport.zip',
    content = function(file) {
      if (length(Sys.glob("fbCrawl.*"))>0){
        file.remove(Sys.glob("fbCrawl.*"))
      }
      writeOGR(getGeoContent(), dsn="fbCrawl.shp", layer="fbCrawl", driver="ESRI Shapefile")
      zip(zipfile='fbCrawlExport.zip', files=Sys.glob("fbCrawl.*"))
      file.copy("fbCrawlExport.zip", file)
      if (length(Sys.glob("fbCrawl.*"))>0){
        file.remove(Sys.glob("fbCrawl.*"))
      }
    }
  )
  
  
  })
