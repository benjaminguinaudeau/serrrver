
#' @export
srv <- R6::R6Class(
  "raspberry-pi",
  lock_objects = F,
  public = list(

    # Default
    host = "",
    user = "",
    port = "",
    pwd = "",
    session = NULL,
    root = NULL,

    initialize = function(host = "localhost", user = "ben", port = 22, pwd = ""){

      self$user <- user
      self$host <- host
      self$port <- port
      self$pwd <- pwd
      self$session <- ssh::ssh_connect(host = glue::glue("{user}@{host}:{port}"), passwd = pwd)
      self$root <- ssh::ssh_connect(host = glue::glue("root@{host}:{port}"), passwd = pwd)

    },
    # init_r_mod = function(){
    #
    # },
    # init_rstudio_mod = function(){
    #
    # },
    # init_shinyserver_mod = function(){
    #
    # },

    init_vpn_mod = function(tbl = "novpn", tbl_index = 201, gateway = "192.168.178.1", interface = "enp3s0"){

      self$tbl <- tbl
      self$tbl_index <- tbl_index
      self$gateway <- gateway
      self$interface <- interface
      self$init_nordvpn <- function(...) init_nordvpn(self, ...)
      self$vpn_connect <- function(...) vpn_connect(self, ...)
      self$vpn_disconnect <- function() vpn_disconnect(self)
      self$vpn_ip <- function() vpn_ip(self)

    },
    init_docker_mod = function(){

      self$create_container <- function(...) srv_create_container(self, ...)
      self$active_vnc <- function(...) srv_active_vnc(self, ...)
      self$list_container <- function() srv_list_container(self)
      self$running_containers <- function() srv_running_containers(self)
      self$stopped_containers <- function() srv_stopped_containers(self)
      self$remove_container <- function(...) srv_remove_container(self, ...)
      self$start_container <- function(...) srv_start_container(self, ...)
      self$get_port <- function(...) srv_get_port(self, ...)

    },
    rscript = function(script_path = ""){
      ssh::scp_upload(self$session, script_path, to = glue::glue("/home/{self$user}/tmp.R"), verbose = F)
      ssh::ssh_exec_wait(self$session, command = glue::glue("Rscript --no-save /home/{self$user}/tmp.R"))
    },
    upload = function(files = "", to = ""){
      ssh::scp_upload(self$session, files, to)
    },
    download = function(files = "", to = ""){
      ssh::scp_download(self$session, files, to)
    }
  )
)
