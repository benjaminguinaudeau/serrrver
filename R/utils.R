

#' @export
sudo <- function(command = "", pwd = ""){
  glue::glue('echo "{pwd}" | sudo -S {command}')
}

#' @export
is_server_down <- function(ip_server){
  ping <- suppressWarnings(base::system(glue::glue("ping {ip_server}"), wait = T, timeout = 1, intern = T))
  as.numeric(str_extract(str_subset(ping, "received"), "\\d(?= received)")) == 0
}

#' @export
connect_openvpn <- function(host, port = port, pwd, file, log_path){
  root <- ssh::ssh_connect(host = glue::glue("root@{host}:{port}"), passwd = pwd)
  ssh::ssh_exec_wait(root, command = glue::glue("openvpn /etc/openvpn/{file} > {log_path}&"))
}

#' @export
start_openvpn <- function(host, port, pwd, file, log_path = NULL){
  if (is.null(log_path)) {
    log_path <- glue::glue("/etc/openvpn/vpn_log_{str_replace(as.character(Sys.time()), '\\\\s', '_')}.txt")
  }

  proc <- callr::r_bg(connect_openvpn, args = list(host = host, port = port, pwd = pwd, file = file, log_path = log_path))
  Sys.sleep(1)
}

#' @export
connect_cisco <- function(host, port, pwd, cisco_server, user, password){
  root <- ssh::ssh_connect(host = glue::glue("root@{host}:{port}"), passwd = pwd)
  ssh::ssh_exec_wait(root, command = c(
    glue::glue('echo {password} | openconnect -u {user} {cisco_server}')
  ))
}

#' @export
start_cisco <- function(host, port, pwd, user, password, cisco_server){
  proc <- callr::r_bg(connect_cisco, args = list(host = host, port = port, pwd = pwd,
                                                 user = user, password = password,
                                                 cisco_server = cisco_server))
  Sys.sleep(1)
}
