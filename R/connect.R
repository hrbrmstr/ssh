#' SSH Client
#'
#' Create an ssh session using `ssh_connect()`. The session can be used to execute
#' commands, scp files or setup a tunnel.
#'
#' The client first tries to authenticate using a private key, either from ssh-agent
#' or `/.ssh/id_rsa` in the user home directory. If this fails it falls back on
#' challenge-response (interactive) and password auth if allowed by the server. The
#' `passwd` parameter can be used to provide a passphrase or a callback function to
#' ask prompt the user for the passphrase when needed.
#'
#' The session will automatically be disconnected when the session object is removed
#' or when R exits but you can also use [ssh_disconnect()].
#'
#' __Windows users:__ the private key must be in OpenSSH PEM format. If you open it in
#' a text editor the first line must be: `-----BEGIN RSA PRIVATE KEY-----`.
#' To convert a Putty PKK key, open it in the *PuttyGen* utility and go to
#' *Conversions -> Export OpenSSH*.
#'
#' @export
#' @useDynLib ssh C_start_session
#' @rdname ssh
#' @aliases ssh
#' @param host an ssh server string of the form `[user@]hostname[:@port]` _or_
#' just a host name or IPv4/IPv6 address if you intend to use the `user` and `port`
#' parameters. If using IPv6 you must specify `host`, `user` and `port` separately.
#' If using IPv6 you must specify `host`, `user` and `port` separately. You
#' can also specify `host`, `user` and `port` separately for IPv4 addresses or
#' hostnames.
#' @param user either `NULL` (the default) or your username on the ssh server.
#' If using IPv6 you must specify `host`, `user` and `port` separately. You
#' can also specify `host`, `user` and `port` separately for IPv4 addresses or
#' hostnames.
#' @param port either `NULL` (the default) or the port on the ssh server.
#' If using IPv6 you must specify `host`, `user` and `port` separately. You
#' can also specify `host`, `user` and `port` separately for IPv4 addresses or
#' hostnames.
#' @param passwd either a string or a callback function for password prompt
#' @param keyfile path to private key file. Must be in OpenSSH format (see details)
#' @param config if specified, the path to the desired SSH `config` file to use
#' (e.g "`~/.ssh/config`"). [path.expand()] will be called on this value if not `NULL`.
#' @param verbose either TRUE/FALSE or a value between 0 and 4 indicating log level:
#' 0: no logging, 1: only warnings, 2: protocol, 3: packets or 4: full stack trace.
#' @family ssh
#' @examples \dontrun{
#' session <- ssh_connect("dev.opencpu.org")
#' ssh_exec_wait(session, command = "whoami")
#' ssh_disconnect(session)
#'
#' # ssh_connect("user@@localhost:22")
#' # ssh_connect("fe80::cb3:cc39:1354:d87b%en0", "user", 22)
#' # ssh_connect("fe80::cb3:cc39:1354:d87b%en0", "user", 22)
#' # ssh_connect("localhost", "user", 22)
#' # ssh_connect("::1")
#' # ssh_connect("somehostname", "bob", 22)
#' }
ssh_connect <- function(host, user=NULL, port=NULL, keyfile = NULL, passwd = askpass, config=NULL, verbose = FALSE) {
  if(is.logical(verbose))
    verbose <- 2 * verbose # TRUE == 'protocol'
  stopifnot(verbose %in% 0:4)
  stopifnot(is.character(host))
  stopifnot(is.character(passwd) || is.function(passwd))
  details <- parse_host(host, user, port, default_port = 22)
  if(length(keyfile))
    keyfile <- normalizePath(keyfile, mustWork = TRUE)
  if (length(config)) {
    config <- path.expand(config)
    if (!file.exists(config)) {
      warning("Config file ", config, " not found. Attempting to connect without the config file")
    }
  }
  .Call(C_start_session, details$host, details$port, details$user, keyfile, passwd, config, verbose)
}

#' @export
#' @rdname ssh
#' @useDynLib ssh C_ssh_info
ssh_info <- function(session){
  assert_session(session)
  out <- .Call(C_ssh_info, session)
  structure(out, names = c("user", "host", "identity", "port", "connected", "sha1"))
}

#' @export
#' @rdname ssh
#' @useDynLib ssh C_disconnect_session
#' @param session ssh connection created with [ssh_connect()]
ssh_disconnect <- function(session){
  assert_session(session)
  .Call(C_disconnect_session, session)
  invisible()
}

parse_host <- function(str, user = NULL, port = NULL, default_port){
  stopifnot(is.character(str) && length(str) == 1)
  stopifnot(is.null(user) || (is.character(user) && (length(user) == 1)))
  stopifnot(is.null(port) || (is.numeric(port) && (length(port) == 1)))
  if (!is.na(iptools::is_ipv6(str))) { # either IPv6 or IPv4
    list(
      host = str,
      user = if (length(user)) user else me(),
      port = if (length(port)) port else as.numeric(default_port)
    )
  } else {
    str <- sub("^@", "", str)
    str <- sub(":$", "", str)
    x <- strsplit(str, "@", fixed = TRUE)[[1]]
    if(length(x) > 2) stop("host string contains multiple '@' characters")
    host <- if(length(x) > 1){
      user <- x[1]
      x[2]
    } else {
      user <- me()
      x[1]
    }
    x <- strsplit(host, ":", fixed = TRUE)[[1]]
    if(length(x) > 2) stop("host string contains multiple ':' characters")
    host <- x[1]
    port <- if(length(x) > 1){
      as.numeric(x[2])
    } else {
      as.numeric(default_port)
    }
    list(
      user = user,
      host = host,
      port = port
    )
  }
}

me <- function(){
  tolower(Sys.info()[["user"]])
}

askpass <- function(prompt = "Please enter your password: "){
  FUN <- getOption("askpass", getPass::getPass)
  FUN(prompt)
}

assert_session <- function(x){
  if(!inherits(x, "ssh_session"))
    stop('Argument "session" must be an ssh session', call. = FALSE)
}

#' @export
print.ssh_session <- function(x, ...){
  info <- ssh_info(x)
  cat(sprintf("<ssh session>\nconnected: %s@%s:%d\nserver: %s\n", info$user, info$host, info$port, info$sha1))
}

#' @export
#' @useDynLib ssh C_libssh_version
#' @rdname ssh
libssh_version <- function(){
  .Call(C_libssh_version)
}
