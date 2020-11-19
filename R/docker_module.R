#' @export
srv_create_container = function(self,
                                image_src = NULL,
                                container_name = NULL,
                                other_arguments = NULL,
                                expose_port = NULL,
                                port = NULL){

  name <- ifelse(is.null(container_name), "", glue::glue("--name { container_name }"))
  expose_port <- ifelse(is.null(expose_port), "", glue::glue_collapse(glue::glue("--expose { expose_port }"), " "))
  port <- ifelse(is.null(port), "P", glue::glue(" -p { port }"))
  arg <- ifelse(is.null(other_arguments), "", other_arguments)

  ssh::ssh_exec_wait(self$session, command = c(glue::glue("docker run -dt{ port} { arg } {expose_port} { name } {image_src}")))

  if(container_name %in% self$list_container()[["names"]]){
    message(glue::glue("{ container_name } was successfully started"))
  }
}

#' @export
srv_active_vnc = function(self){
  ssh::ssh_exec_wait(self$root, command = c("docker exec -dt chrome /bin/bash -c 'x11vnc ${X11VNC_OPTS} -forever -shared -rfbport 5900 -display ${DISPLAY}'"))
}

#' @export
srv_list_container = function(self){
  raw_list <- rawToChar(ssh::ssh_exec_internal(self$session, command = c("docker ps -a --no-trunc"))[["stdout"]]) %>%
    stringr::str_split("\n") %>%
    .[[1]]

  col_names <- raw_list[1]  %>%
    stringr::str_extract_all("(?<=\\s{2}|^).*?(\\s{2,}|$)") %>% .[[1]] %>%
    stringr::str_trim(.)

  border <- raw_list[1]  %>%
    stringr::str_locate_all("(?<=\\s{2}|^).*?(\\s{2,}|$)") %>% .[[1]]

  containers <- raw_list %>%
    tail(-1) %>%
    purrr::map_dfr(~{
      border[nrow(border),2] <- stringr::str_length(.x)

      .x %>%
        stringr::str_sub(start = border[,1], end = border[,2]) %>%
        purrr::map2_dfc(col_names, ~tibble::tibble(a = .x) %>% purrr::set_names(.y)) %>%
        janitor::clean_names(.)
    })

  return(containers)

}

#' @export
srv_running_containers = function(self){
  dplyr::filter(self$list_container(), status %>% stringr::str_detect("^Up"))[["names"]]
}

#' @export
srv_stopped_containers = function(self){
  dplyr::filter(self$list_container(), status %>% stringr::str_detect("^Up", negate = T))[["names"]]
}

#' @export
srv_remove_container = function(self, container_name){

  if(container_name %in% self$running_containers()){
    ssh::ssh_exec_wait(self$session, command = c(glue::glue("docker stop { container_name }")))
  }

  if(container_name %in% self$stopped_containers()){
    ssh::ssh_exec_wait(self$session, command = c(glue::glue("docker rm { container_name }")))
  }
}

#' @export
srv_start_container = function(self, container_name){
  if(container_name %in% self$stopped_containers()){
    ssh::ssh_exec_wait(self$session, command = c(glue::glue("docker start { container_name }")))
  }
}

#' @export
srv_get_port = function(self, container_name, filter_port = NULL){

  if(container_name %in% self$running_containers()){

    ports <- self$list_container() %>%
      dplyr::filter(names == container_name) %>%
      dplyr::pull(ports) %>%
      stringr::str_split(", ") %>%
      unlist %>%
      purrr::map(~{
        .x %>%
          stringr::str_extract("\\d+->\\d+") %>%
          stringr::str_split("->") %>%
          unlist %>%
          as.integer %>%
          purrr::set_names("origin", "target") %>%
          dplyr::bind_rows(.)
      }) %>%
      purrr::reduce(dplyr::bind_rows)

    if(is.null(filter_port)){
      return(ports)
    }


    if(length(filter_port) == 1){
      return(
        ports %>%
          dplyr::filter(target == filter_port) %>%
          dplyr::pull(origin)
      )
    }

    if(length(filter_port) > 1){
      return(ports %>% dplyr::filter(target %in% filter_port))
    }
  }
}


