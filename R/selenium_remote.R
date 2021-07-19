#' @export
chrome_remote <- function (srv, name = "", ua = NULL, cache = NULL){

  if (!name %in% srv$list_container()[["names"]]) {
    srv$create_container(container_name = name,
                         other_arguments = "--shm-size=2g",
                         image_src = "chrome")
    bashR::wait(4, 0.5)
  }
  if (name %in% srv$stopped_containers()) {
    srv$start_container(name)
    bashR::wait(4, 0.5)
  }
  if (name %in% srv$running_containers()) {
    browser <- tidyselenium::get_driver(host = srv$host, port = srv$get_port(name, 4444), ua = ua, cache_id = cache, browser = "chrome")
  }

  return(browser)
}

