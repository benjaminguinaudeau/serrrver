
<!-- README.md is generated from README.Rmd. Please edit that file -->

# serrrver

<!-- badges: start -->
<!-- badges: end -->

`serrrver` allows you to manage any type of remote server from within R.
It proposes one main R6-Class, which initialize a connection to the
remote server. Once the connexion is initialized modules can be loaded
depending on the use case. For now 2 modules are available:

1.  Docker: allows to manage docker container on the remote server
2.  VPN: allows to manage VPN tunnels (for now only compatible with
    nordvpn) on the remote server

Following modules are planed: 1. R: Install R and execute code 2.
Rstudio-server: Run a rstudio-server 3. Shiny-Server: Run a shiny-server
and expose a specific app

## Installation

You can install the released version of serrrver from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("benjaminguinaudeau/serrrver")
```

## Example

``` r
library(serrrver)
```

``` r
server <- srv$new(host = "192.168.1.14", user = "pi", port = 22, pwd = Sys.getenv("SERVER_PASS"))
```

## Docker Mod

``` r
# Init docker module
server$init_docker_mod()

# List containers
server$list_container()
#> # A tibble: 2 x 7
#>   container_id         image    command     created   status   ports       names
#>   <chr>                <chr>    <chr>       <chr>     <chr>    <chr>       <chr>
#> 1 "3cc231ff328b4975a8… "chrome… "\"/opt/bi… "4 weeks… "Up 2 d… "0.0.0.0:3… "chr…
#> 2 ""                   ""       ""          ""        ""       ""          ""
```

## VPN Mod

``` r
# Init vpn module
server$init_vpn_mod()

# Get ip
server$vpn_ip()
#> [1] "64.44.55.36"
```
