#' @export
init_nordvpn <- function(self, nord_user = "", nord_pwd ="", force = F){
  trig <- any(stringr::str_detect(capture.output(ssh::ssh_exec_wait(self$session, command = c(sudo('ls /etc/openvpn/', pwd = self$pwd)))), ".nordvpn.com.tcp"))

  if(!trig | force){

    ssh::ssh_exec_wait(self$session, command = c(sudo('mkdir /etc/openvpn/', pwd = self$pwd),
                                                 "cd /etc/openvpn/",
                                                 sudo("wget https://nordvpn.com/api/files/zip", pwd = self$pwd),
                                                 sudo("unzip -o zip", pwd = self$pwd)))

    ssh::ssh_exec_wait(self$session, command = c(sudo("touch /etc/openvpn/auth.txt", pwd = self$pwd),
                                                 sudo("chmod 777 /etc/openvpn/auth.txt", pwd = self$pwd),
                                                 glue::glue('echo "{self$nord_user}" > /etc/openvpn/auth.txt'),
                                                 glue::glue('echo "{self$nord_pwd}" >> /etc/openvpn/auth.txt')
    ))

    ssh::ssh_exec_wait(self$session, command = c(sudo("cat /etc/openvpn/auth.txt", pwd = self$pwd)))
  }

}

#' @export
vpn_connect <- function(self, files = NULL, cisco_server = NULL, user = NULL, password = NULL, type = "openvpn"){

  if(type == "openvpn"){
    index <- 1
    ip <- current_ip <- self$vpn_ip()
    while(index < 5 & ip == current_ip){
      last_config_line <- rawToChar(ssh::ssh_exec_internal(self$root, glue::glue("cat /etc/openvpn/{files[index]} | tail -n 1"))$stdout)
      if(!str_detect(last_config_line, "auth-user-pass")){
        ssh::ssh_exec_wait(self$root, command = c(glue::glue('echo "auth-user-pass /etc/openvpn/auth.txt" >> /etc/openvpn/{files[index]}')))
      }
      Sys.sleep(.2)
      start_openvpn(host = self$host, port = self$port,pwd =  self$pwd, file = files[index])
      connect_index <- 1
      while(connect_index < 10 & ip == current_ip){
        Sys.sleep(2)
        ip <- self$vpn_ip()
        connect_index <- connect_index + 1
      }

      index <- index + 1
    }

    if(index == 5){
      return(F)
    } else {
      return(T)
    }
  }
  if(type == "cisco"){
    index <- 1
    ip <- current_ip <- self$vpn_ip()

    start_cisco(host = self$host,port = self$port,pwd =  self$pwd,
                user = user, password = password, cisco_server = cisco_server)
    connect_index <- 1
    while(connect_index < 10 & ip == current_ip){
      Sys.sleep(2)
      ip <- self$vpn_ip()
      connect_index <- connect_index + 1
    }

    if(connect_index == 10){
      return(F)
    } else {
      return(T)
    }
  }
}

#' @export
vpn_disconnect <- function(self){
  ssh::ssh_exec_wait(self$session, command = c(sudo("killall openvpn", pwd = self$pwd)))
  ssh::ssh_exec_wait(self$session, command = c(sudo("killall openconnect", pwd = self$pwd)))
}

#' @export
vpn_ip <- function(self){
  self$ip <- rawToChar(ssh::ssh_exec_internal(self$session, command = "dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com")$stdout) %>%
    stringr::str_squish() %>%
    stringr::str_remove_all('"')
  return(self$ip)
}
