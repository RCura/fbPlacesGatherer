fbJSONtoDF <- function(jsonDF){
  id <- jsonDF$id
  name <- jsonDF$name
  Encoding(name) <- "latin1"
  checkins <- as.numeric(jsonDF$checkins)
  likes <- as.numeric(jsonDF$likes)
  category <- jsonDF$category
  Encoding(category) <- "latin1"
  category_list <- as.character(lapply(jsonDF$category_list, FUN=function(x){return(paste(unlist(x$name), sep="", collapse="/"))}))
  Encoding(category_list) <- "latin1"
  street <- jsonDF$location$street
  Encoding(street) <- "latin1"
  city <- jsonDF$location$city
  Encoding(city) <- "latin1"
  state <- jsonDF$location$state
  Encoding(state) <- "latin1"
  country <- jsonDF$location$country
  Encoding(country) <- "latin1"
  zip <- jsonDF$location$zip
  latitude <- jsonDF$location$latitude
  longitude <- jsonDF$location$longitude
  cleanDF <- data.frame(id, name, category, category_list, street, city, state, country, zip, latitude, longitude, checkins, likes, stringsAsFactors=FALSE)
  return(cleanDF)
}

helpPopup <- function(title, content,
                      placement=c('right', 'top', 'left', 'bottom'),
                      trigger=c('click', 'hover', 'focus', 'manual')) {
  tagList(
    singleton(
      tags$head(
        tags$script("$(function() { $(\"[data-toggle='popover']\").popover(); })")
      )
    ),
    tags$a(
      href = "#", class = "btn btn-mini", `data-toggle` = "popover",
      title = title, `data-content` = content, `data-animation` = TRUE,
      `data-placement` = match.arg(placement, several.ok=TRUE)[1],
      `data-trigger` = match.arg(trigger, several.ok=TRUE)[1],
      tags$i(class="icon-question-sign")
    )
  )
}

helpModal <- function(title, link, content) {
  html <- sprintf("<div id='%s' class='modal hide fade in' style='display: none; '>
                     <div class='modal-header'><a class='close' data-dismiss='modal' href='#'>&times;</a>
                       <h3>%s</h3>
                     </div>
                     <div class='modal-body'>%s</div>
                   </div>
                   <a title='Help' data-toggle='modal' href='#%s' class='icon-question-sign'></a>", link, title, content, link)
  Encoding(html) <- 'UTF-8'
  HTML(html)
}