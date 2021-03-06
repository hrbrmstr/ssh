% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/connect.R
\name{ssh_connect}
\alias{ssh_connect}
\alias{ssh}
\alias{ssh_info}
\alias{ssh_disconnect}
\alias{libssh_version}
\title{SSH Client}
\usage{
ssh_connect(host, user = NULL, port = NULL, keyfile = NULL,
  passwd = askpass, config = NULL, verbose = FALSE)

ssh_info(session)

ssh_disconnect(session)

libssh_version()
}
\arguments{
\item{host}{an ssh server string of the form \code{[user@]hostname[:@port]} \emph{or}
just a host name or IPv4/IPv6 address if you intend to use the \code{user} and \code{port}
parameters. If using IPv6 you must specify \code{host}, \code{user} and \code{port} separately.
If using IPv6 you must specify \code{host}, \code{user} and \code{port} separately. You
can also specify \code{host}, \code{user} and \code{port} separately for IPv4 addresses or
hostnames.}

\item{user}{either \code{NULL} (the default) or your username on the ssh server.
If using IPv6 you must specify \code{host}, \code{user} and \code{port} separately. You
can also specify \code{host}, \code{user} and \code{port} separately for IPv4 addresses or
hostnames.}

\item{port}{either \code{NULL} (the default) or the port on the ssh server.
If using IPv6 you must specify \code{host}, \code{user} and \code{port} separately. You
can also specify \code{host}, \code{user} and \code{port} separately for IPv4 addresses or
hostnames.}

\item{keyfile}{path to private key file. Must be in OpenSSH format (see details)}

\item{passwd}{either a string or a callback function for password prompt}

\item{config}{if specified, the path to the desired SSH \code{config} file to use
(e.g "\code{~/.ssh/config}"). \code{\link[=path.expand]{path.expand()}} will be called on this value if not \code{NULL}.}

\item{verbose}{either TRUE/FALSE or a value between 0 and 4 indicating log level:
0: no logging, 1: only warnings, 2: protocol, 3: packets or 4: full stack trace.}

\item{session}{ssh connection created with \code{\link[=ssh_connect]{ssh_connect()}}}
}
\description{
Create an ssh session using \code{ssh_connect()}. The session can be used to execute
commands, scp files or setup a tunnel.
}
\details{
The client first tries to authenticate using a private key, either from ssh-agent
or \code{/.ssh/id_rsa} in the user home directory. If this fails it falls back on
challenge-response (interactive) and password auth if allowed by the server. The
\code{passwd} parameter can be used to provide a passphrase or a callback function to
ask prompt the user for the passphrase when needed.

The session will automatically be disconnected when the session object is removed
or when R exits but you can also use \code{\link[=ssh_disconnect]{ssh_disconnect()}}.

\strong{Windows users:} the private key must be in OpenSSH PEM format. If you open it in
a text editor the first line must be: \code{-----BEGIN RSA PRIVATE KEY-----}.
To convert a Putty PKK key, open it in the \emph{PuttyGen} utility and go to
\emph{Conversions -> Export OpenSSH}.
}
\examples{
\dontrun{
session <- ssh_connect("dev.opencpu.org")
ssh_exec_wait(session, command = "whoami")
ssh_disconnect(session)

# ssh_connect("user@localhost:22")
# ssh_connect("fe80::cb3:cc39:1354:d87b\%en0", "user", 22)
# ssh_connect("fe80::cb3:cc39:1354:d87b\%en0", "user", 22)
# ssh_connect("localhost", "user", 22)
# ssh_connect("::1")
# ssh_connect("somehostname", "bob", 22)
}
}
\seealso{
Other ssh: \code{\link{scp}}, \code{\link{ssh_exec}},
  \code{\link{ssh_tunnel}}
}
\concept{ssh}
