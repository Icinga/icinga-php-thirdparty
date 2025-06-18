# clue/reactphp-socks

[![CI status](https://github.com/clue/reactphp-socks/actions/workflows/ci.yml/badge.svg)](https://github.com/clue/reactphp-socks/actions)
[![installs on Packagist](https://img.shields.io/packagist/dt/clue/socks-react?color=blue&label=installs%20on%20Packagist)](https://packagist.org/packages/clue/socks-react)

Async SOCKS proxy connector client and server implementation, tunnel any TCP/IP-based
protocol through a SOCKS5 or SOCKS4(a) proxy server, built on top of
[ReactPHP](https://reactphp.org/).

The SOCKS proxy protocol family (SOCKS5, SOCKS4 and SOCKS4a) is commonly used to
tunnel HTTP(S) traffic through an intermediary ("proxy"), to conceal the origin
address (anonymity) or to circumvent address blocking (geoblocking). While many
(public) SOCKS proxy servers often limit this to HTTP(S) port `80` and `443`
only, this can technically be used to tunnel any TCP/IP-based protocol (HTTP,
SMTP, IMAP etc.).
This library provides a simple API to create these tunneled connections for you.
Because it implements ReactPHP's standard
[`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface),
it can simply be used in place of a normal connector.
This makes it fairly simple to add SOCKS proxy support to pretty much any
existing higher-level protocol implementation.
Besides the client side, it also provides a simple SOCKS server implementation
which allows you to build your own SOCKS proxy servers with custom business logic.

* **Async execution of connections** -
  Send any number of SOCKS requests in parallel and process their
  responses as soon as results come in.
  The Promise-based design provides a *sane* interface to working with out of
  order responses and possible connection errors.
* **Standard interfaces** -
  Allows easy integration with existing higher-level components by implementing
  ReactPHP's standard
  [`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface).
* **Lightweight, SOLID design** -
  Provides a thin abstraction that is [*just good enough*](https://en.wikipedia.org/wiki/Principle_of_good_enough)
  and does not get in your way.
  Builds on top of well-tested components and well-established concepts instead of reinventing the wheel.
* **Good test coverage** -
  Comes with an automated tests suite and is regularly tested against actual proxy servers in the wild.

**Table of contents**

* [Support us](#support-us)
* [Quickstart example](#quickstart-example)
* [Usage](#usage)
    * [Client](#client)
        * [Plain TCP connections](#plain-tcp-connections)
        * [Secure TLS connections](#secure-tls-connections)
        * [HTTP requests](#http-requests)
        * [Protocol version](#protocol-version)
        * [DNS resolution](#dns-resolution)
        * [Authentication](#authentication)
        * [Proxy chaining](#proxy-chaining)
        * [Connection timeout](#connection-timeout)
        * [SOCKS over TLS](#socks-over-tls)
        * [Unix domain sockets](#unix-domain-sockets)
    * [Server](#server)
        * [Server connector](#server-connector)
        * [Authentication](#server-authentication)
        * [Proxy chaining](#server-proxy-chaining)
        * [SOCKS over TLS](#server-socks-over-tls)
        * [Unix domain sockets](#server-unix-domain-sockets)
* [Servers](#servers)
    * [Using a PHP SOCKS server](#using-a-php-socks-server)
    * [Using SSH as a SOCKS server](#using-ssh-as-a-socks-server)
    * [Using the Tor (anonymity network) to tunnel SOCKS connections](#using-the-tor-anonymity-network-to-tunnel-socks-connections)
* [Install](#install)
* [Tests](#tests)
* [License](#license)
* [More](#more)

## Support us

We invest a lot of time developing, maintaining and updating our awesome
open-source projects. You can help us sustain this high-quality of our work by
[becoming a sponsor on GitHub](https://github.com/sponsors/clue). Sponsors get
numerous benefits in return, see our [sponsoring page](https://github.com/sponsors/clue)
for details.

Let's take these projects to the next level together! 🚀

## Quickstart example

Once [installed](#install), you can use the following code to send a secure
HTTPS request to google.com through a local SOCKS proxy server:

```php
<?php

require __DIR__ . '/vendor/autoload.php';

$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'dns' => false
));

$browser = new React\Http\Browser($connector);

$browser->get('https://google.com/')->then(function (Psr\Http\Message\ResponseInterface $response) {
    var_dump($response->getHeaders(), (string) $response->getBody());
}, function (Exception $e) {
    echo 'Error: ' . $e->getMessage() . PHP_EOL;
});
```

If you're not already running any other [SOCKS proxy server](#servers),
you can use the following code to create a SOCKS
proxy server listening for connections on `127.0.0.1:1080`:

```php
<?php

require __DIR__ . '/vendor/autoload.php';

// start a new SOCKS proxy server
$socks = new Clue\React\Socks\Server();

// listen on 127.0.0.1:1080
$socket = new React\Socket\SocketServer('127.0.0.1:1080');
$socks->listen($socket);
```

See also the [examples](examples).

## Usage

### Client

The `Client` is responsible for communication with your SOCKS server instance.

Its constructor simply accepts a SOCKS proxy URI with the SOCKS proxy server address:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');
```

You can omit the port if you're using the default SOCKS port 1080:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1');
```

If you need custom connector settings (DNS resolution, TLS parameters, timeouts,
proxy servers etc.), you can explicitly pass a custom instance of the
[`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface):

```php
$connector = new React\Socket\Connector(array(
    'dns' => '127.0.0.1',
    'tcp' => array(
        'bindto' => '192.168.10.1:0'
    )
));

$proxy = new Clue\React\Socks\Client('my-socks-server.local:1080', $connector);
```

This is one of the two main classes in this package.
Because it implements ReactPHP's standard
[`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface),
it can simply be used in place of a normal connector.
Accordingly, it provides only a single public method, the
[`connect()`](https://github.com/reactphp/socket#connect) method.
The `connect(string $uri): PromiseInterface<ConnectionInterface, Exception>`
method can be used to establish a streaming connection.
It returns a [Promise](https://github.com/reactphp/promise) which either
fulfills with a [ConnectionInterface](https://github.com/reactphp/socket#connectioninterface)
on success or rejects with an `Exception` on error.

This makes it fairly simple to add SOCKS proxy support to pretty much any
higher-level component:

```diff
- $acme = new AcmeApi($connector);
+ $proxy = new Clue\React\Socks\Client('127.0.0.1:1080', $connector);
+ $acme = new AcmeApi($proxy);
```

#### Plain TCP connections

SOCKS proxies are most frequently used to issue HTTP(S) requests to your destination.
However, this is actually performed on a higher protocol layer and this
connector is actually inherently a general-purpose plain TCP/IP connector.
As documented above, you can simply invoke its `connect()` method to establish
a streaming plain TCP/IP connection and use any higher level protocol like so:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$proxy->connect('tcp://www.google.com:80')->then(function (React\Socket\ConnectionInterface $connection) {
    echo 'connected to www.google.com:80';
    $connection->write("GET / HTTP/1.0\r\n\r\n");

    $connection->on('data', function ($chunk) {
        echo $chunk;
    });
});
```

You can either use the `Client` directly or you may want to wrap this connector
in ReactPHP's [`Connector`](https://github.com/reactphp/socket#connector):

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'dns' => false
));

$connector->connect('tcp://www.google.com:80')->then(function (React\Socket\ConnectionInterface $connection) {
    echo 'connected to www.google.com:80';
    $connection->write("GET / HTTP/1.0\r\n\r\n");

    $connection->on('data', function ($chunk) {
        echo $chunk;
    });
});
```

See also the [first example](examples).

The `tcp://` scheme can also be omitted.
Passing any other scheme will reject the promise.

Pending connection attempts can be cancelled by cancelling its pending promise like so:

```php
$promise = $connector->connect($uri);

$promise->cancel();
```

Calling `cancel()` on a pending promise will cancel the underlying TCP/IP
connection to the SOCKS server and/or the SOCKS protocol negotiation and reject
the resulting promise.

#### Secure TLS connections

This class can also be used if you want to establish a secure TLS connection
(formerly known as SSL) between you and your destination, such as when using
secure HTTPS to your destination site. You can simply wrap this connector in
ReactPHP's [`Connector`](https://github.com/reactphp/socket#connector):

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'dns' => false
));

$connector->connect('tls://www.google.com:443')->then(function (React\Socket\ConnectionInterface $connection) {
    // proceed with just the plain text data
    // everything is encrypted/decrypted automatically
    echo 'connected to SSL encrypted www.google.com';
    $connection->write("GET / HTTP/1.0\r\n\r\n");

    $connection->on('data', function ($chunk) {
        echo $chunk;
    });
});
```

See also the [second example](examples).

Pending connection attempts can be cancelled by canceling its pending promise
as usual.

> Note how secure TLS connections are in fact entirely handled outside of
  this SOCKS client implementation.

You can optionally pass additional
[SSL context options](http://php.net/manual/en/context.ssl.php)
to the constructor like this:

```php
$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'tls' => array(
        'verify_peer' => false,
        'verify_peer_name' => false
    ),
    'dns' => false
));
```

#### HTTP requests

This library also allows you to send
[HTTP requests through a SOCKS proxy server](https://github.com/reactphp/http#socks-proxy).

In order to send HTTP requests, you first have to add a dependency for
[ReactPHP's async HTTP client](https://github.com/reactphp/http#client-usage).
This allows you to send both plain HTTP and TLS-encrypted HTTPS requests like this:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'dns' => false
));

$browser = new React\Http\Browser($connector);

$browser->get('https://example.com/')->then(function (Psr\Http\Message\ResponseInterface $response) {
    var_dump($response->getHeaders(), (string) $response->getBody());
}, function (Exception $e) {
    echo 'Error: ' . $e->getMessage() . PHP_EOL;
});
```

See also [ReactPHP's HTTP client](https://github.com/reactphp/http#client-usage)
and any of the [examples](examples) for more details.

#### Protocol version

This library supports the SOCKS5 and SOCKS4(a) protocol versions.
It focuses on the most commonly used core feature of connecting to a destination
host through the SOCKS proxy server. In this mode, a SOCKS proxy server acts as
a generic proxy allowing higher level application protocols to work through it.

<table>
  <tr>
    <th></th>
    <th>SOCKS5</th>
    <th>SOCKS4(a)</th>
  </tr>
  <tr>
    <th>Protocol specification</th>
    <td><a href="https://tools.ietf.org/html/rfc1928">RFC 1928</a></td>
    <td>
      <a href="https://ftp.icm.edu.pl/packages/socks/socks4/SOCKS4.protocol">SOCKS4.protocol</a> /
      <a href="https://ftp.icm.edu.pl/packages/socks/socks4/SOCKS4A.protocol">SOCKS4A.protocol</a>
    </td>
  </tr>
  <tr>
    <th>Tunnel outgoing TCP/IP connections</th>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <th><a href="#dns-resolution">Remote DNS resolution</a></th>
    <td>✓</td>
    <td>✗ / ✓</td>
  </tr>
  <tr>
    <th>IPv6 addresses</th>
    <td>✓</td>
    <td>✗</td>
  </tr>
  <tr>
    <th><a href="#authentication">Username/Password authentication</a></th>
    <td>✓ (as per <a href="https://tools.ietf.org/html/rfc1929">RFC 1929</a>)</td>
    <td>✗</td>
  </tr>
  <tr>
    <th>Handshake # roundtrips</th>
    <td>2 (3 with authentication)</td>
    <td>1</td>
  </tr>
  <tr>
    <th>Handshake traffic<br />+ remote DNS</th>
    <td><em>variable</em> (+ auth + IPv6)<br />+ hostname - 3</td>
    <td>17 bytes<br />+ hostname + 1</td>
  </tr>
  <tr>
    <th>Incoming BIND requests</th>
    <td><em>not implemented</em></td>
    <td><em>not implemented</em></td>
  </tr>
  <tr>
    <th>UDP datagrams</th>
    <td><em>not implemented</em></td>
    <td>✗</td>
  </tr>
  <tr>
    <th>GSSAPI authentication</th>
    <td><em>not implemented</em></td>
    <td>✗</td>
  </tr>
</table>

By default, the `Client` communicates via SOCKS5 with the SOCKS server.
This is done because SOCKS5 is the latest version from the SOCKS protocol family
and generally has best support across other vendors.
You can also omit the default `socks://` URI scheme. Similarly, the `socks5://`
URI scheme acts as an alias for the default `socks://` URI scheme.

```php
// all three forms are equivalent
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');
$proxy = new Clue\React\Socks\Client('socks://127.0.0.1:1080');
$proxy = new Clue\React\Socks\Client('socks5://127.0.0.1:1080');
```

If want to explicitly set the protocol version to SOCKS4(a), you can use the URI
scheme `socks4://` as part of the SOCKS URI:

```php
$proxy = new Clue\React\Socks\Client('socks4://127.0.0.1:1080');
```

#### DNS resolution

By default, the `Client` does not perform any DNS resolution at all and simply
forwards any hostname you're trying to connect to to the SOCKS server.
The remote SOCKS server is thus responsible for looking up any hostnames via DNS
(this default mode is thus called *remote DNS resolution*).
As seen above, this mode is supported by the SOCKS5 and SOCKS4a protocols, but
not the original SOCKS4 protocol, as the protocol lacks a way to communicate hostnames.

On the other hand, all SOCKS protocol versions support sending destination IP
addresses to the SOCKS server.
In this mode you either have to stick to using IPs only (which is ofen unfeasable)
or perform any DNS lookups locally and only transmit the resolved destination IPs
(this mode is thus called *local DNS resolution*).

The default *remote DNS resolution* is useful if your local `Client` either can
not resolve target hostnames because it has no direct access to the internet or
if it should not resolve target hostnames because its outgoing DNS traffic might
be intercepted (in particular when using the
[Tor network](#using-the-tor-anonymity-network-to-tunnel-socks-connections)).

As noted above, the `Client` defaults to using remote DNS resolution.
However, wrapping the `Client` in ReactPHP's
[`Connector`](https://github.com/reactphp/socket#connector) actually
performs local DNS resolution unless explicitly defined otherwise.
Given that remote DNS resolution is assumed to be the preferred mode, all
other examples explicitly disable DNS resolution like this:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'dns' => false
));
```

If you want to explicitly use *local DNS resolution* (such as when explicitly
using SOCKS4), you can use the following code:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

// set up Connector which uses Google's public DNS (8.8.8.8)
$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'dns' => '8.8.8.8'
));
```

See also the [fourth example](examples).

Pending connection attempts can be cancelled by cancelling its pending promise
as usual.

> Note how local DNS resolution is in fact entirely handled outside of this
  SOCKS client implementation.

#### Authentication

This library supports username/password authentication for SOCKS5 servers as
defined in [RFC 1929](https://tools.ietf.org/html/rfc1929).

On the client side, simply pass your username and password to use for
authentication (see below).
For each further connection the client will merely send a flag to the server
indicating authentication information is available.
Only if the server requests authentication during the initial handshake,
the actual authentication credentials will be transmitted to the server.

Note that the password is transmitted in cleartext to the SOCKS proxy server,
so this methods should not be used on a network where you have to worry about eavesdropping.

You can simply pass the authentication information as part of the SOCKS URI:

```php
$proxy = new Clue\React\Socks\Client('alice:password@127.0.0.1:1080');
```

Note that both the username and password must be percent-encoded if they contain
special characters:

```php
$user = 'he:llo';
$pass = 'p@ss';
$url = rawurlencode($user) . ':' . rawurlencode($pass) . '@127.0.0.1:1080';

$proxy = new Clue\React\Socks\Client($url);
```

> The authentication details will be transmitted in cleartext to the SOCKS proxy
  server only if it requires username/password authentication.
  If the authentication details are missing or not accepted by the remote SOCKS
  proxy server, it is expected to reject each connection attempt with an
  exception error code of `SOCKET_EACCES` (13).

Authentication is only supported by protocol version 5 (SOCKS5),
so passing authentication to the `Client` enforces communication with protocol
version 5 and complains if you have explicitly set anything else:

```php
// throws InvalidArgumentException
new Clue\React\Socks\Client('socks4://alice:password@127.0.0.1:1080');
```

#### Proxy chaining

The `Client` is responsible for creating connections to the SOCKS server which
then connects to the target host.

```
Client -> SocksServer -> TargetHost
```

Sometimes it may be required to establish outgoing connections via another SOCKS
server.
For example, this can be useful if you want to conceal your origin address.

```
Client -> MiddlemanSocksServer -> TargetSocksServer -> TargetHost
```

The `Client` uses any instance of the `ConnectorInterface` to establish
outgoing connections.
In order to connect through another SOCKS server, you can simply use another
SOCKS connector from another SOCKS client like this:

```php
// https via the proxy chain  "MiddlemanSocksServer -> TargetSocksServer -> TargetHost"
// please note how the client uses TargetSocksServer (not MiddlemanSocksServer!),
// which in turn then uses MiddlemanSocksServer.
// this creates a TCP/IP connection to MiddlemanSocksServer, which then connects
// to TargetSocksServer, which then connects to the TargetHost
$middle = new Clue\React\Socks\Client('127.0.0.1:1080');
$target = new Clue\React\Socks\Client('example.com:1080', $middle);

$connector = new React\Socket\Connector(array(
    'tcp' => $target,
    'dns' => false
));

$connector->connect('tls://www.google.com:443')->then(function (React\Socket\ConnectionInterface $connection) {
    // …
});
```

See also the [third example](examples).

Pending connection attempts can be canceled by canceling its pending promise
as usual.

Proxy chaining can happen on the server side and/or the client side:

* If you ask your client to chain through multiple proxies, then each proxy
  server does not really know anything about chaining at all.
  This means that this is a client-only property.

* If you ask your server to chain through another proxy, then your client does
  not really know anything about chaining at all.
  This means that this is a server-only property and not part of this class.
  For example, you can find this in the below [`Server`](#server-proxy-chaining)
  class or somewhat similar when you're using the
  [Tor network](#using-the-tor-anonymity-network-to-tunnel-socks-connections).

#### Connection timeout

By default, the `Client` does not implement any timeouts for establishing remote
connections.
Your underlying operating system may impose limits on pending and/or idle TCP/IP
connections, anywhere in a range of a few minutes to several hours.

Many use cases require more control over the timeout and likely values much
smaller, usually in the range of a few seconds only.

You can use ReactPHP's [`Connector`](https://github.com/reactphp/socket#connector)
to decorate any given `ConnectorInterface` instance.
It provides the same `connect()` method, but will automatically reject the
underlying connection attempt if it takes too long:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$connector = new React\Socket\Connector(array(
    'tcp' => $proxy,
    'dns' => false,
    'timeout' => 3.0
));

$connector->connect('tcp://google.com:80')->then(function (React\Socket\ConnectionInterface $connection) {
    // connection succeeded within 3.0 seconds
});
```

See also any of the [examples](examples).

Pending connection attempts can be cancelled by cancelling its pending promise
as usual.

> Note how connection timeout is in fact entirely handled outside of this
  SOCKS client implementation.

#### SOCKS over TLS

All [SOCKS protocol versions](#protocol-version) support forwarding TCP/IP
based connections and higher level protocols.
This implies that you can also use [secure TLS connections](#secure-tls-connections)
to transfer sensitive data across SOCKS proxy servers.
This means that no eavesdropper nor the proxy server will be able to decrypt
your data.

However, the initial SOCKS communication between the client and the proxy is
usually via an unencrypted, plain TCP/IP connection.
This means that an eavesdropper may be able to see *where* you connect to and
may also be able to see your [SOCKS authentication](#authentication) details
in cleartext.

As an alternative, you may establish a secure TLS connection to your SOCKS
proxy before starting the initial SOCKS communication.
This means that no eavesdroppper will be able to see the destination address
you want to connect to or your [SOCKS authentication](#authentication) details.

You can use the `sockss://` URI scheme or use an explicit
[SOCKS protocol version](#protocol-version) like this:

```php
$proxy = new Clue\React\Socks\Client('sockss://127.0.0.1:1080');

$proxy = new Clue\React\Socks\Client('socks4s://127.0.0.1:1080');
```

See also [example 32](examples).

Similarly, you can also combine this with [authentication](#authentication)
like this:

```php
$proxy = new Clue\React\Socks\Client('sockss://alice:password@127.0.0.1:1080');
```

> Note that for most use cases, [secure TLS connections](#secure-tls-connections)
  should be used instead. SOCKS over TLS is considered advanced usage and is
  used very rarely in practice.
  In particular, the SOCKS server has to accept secure TLS connections, see
  also [Server SOCKS over TLS](#server-socks-over-tls) for more details.
  Also, PHP does not support "double encryption" over a single connection.
  This means that enabling [secure TLS connections](#secure-tls-connections)
  over a communication channel that has been opened with SOCKS over TLS
  may not be supported.

> Note that the SOCKS protocol does not support the notion of TLS. The above
  works reasonably well because TLS is only used for the connection between
  client and proxy server and the SOCKS protocol data is otherwise identical.
  This implies that this may also have only limited support for
  [proxy chaining](#proxy-chaining) over multiple TLS paths.

#### Unix domain sockets

All [SOCKS protocol versions](#protocol-version) support forwarding TCP/IP
based connections and higher level protocols.
In some advanced cases, it may be useful to let your SOCKS server listen on a
Unix domain socket (UDS) path instead of a IP:port combination.
For example, this allows you to rely on file system permissions instead of
having to rely on explicit [authentication](#authentication).

You can use the `socks+unix://` URI scheme or use an explicit
[SOCKS protocol version](#protocol-version) like this:

```php
$proxy = new Clue\React\Socks\Client('socks+unix:///tmp/proxy.sock');

$proxy = new Clue\React\Socks\Client('socks4+unix:///tmp/proxy.sock');
```

Similarly, you can also combine this with [authentication](#authentication)
like this:

```php
$proxy = new Clue\React\Socks\Client('socks+unix://alice:password@/tmp/proxy.sock');
```

> Note that Unix domain sockets (UDS) are considered advanced usage and PHP only
  has limited support for this.
  In particular, enabling [secure TLS](#secure-tls-connections) may not be
  supported.

> Note that the SOCKS protocol does not support the notion of UDS paths. The above
  works reasonably well because UDS is only used for the connection between
  client and proxy server and the path will not actually passed over the protocol.
  This implies that this does also not support [proxy chaining](#proxy-chaining)
  over multiple UDS paths.

### Server

The `Server` is responsible for accepting incoming communication from SOCKS clients
and forwarding the requested connection to the target host.
It supports the SOCKS5 and SOCKS4(a) protocol versions by default.
You can start listening on an underlying TCP/IP socket server like this:

```php
$socks = new Clue\React\Socks\Server();

// listen on 127.0.0.1:1080
$socket = new React\Socket\SocketServer('127.0.0.1:1080');
$socks->listen($socket);
```

This class takes an optional `LoopInterface|null $loop` parameter that can be used to
pass the event loop instance to use for this object. You can use a `null` value
here in order to use the [default loop](https://github.com/reactphp/event-loop#loop).
This value SHOULD NOT be given unless you're sure you want to explicitly use a
given event loop instance.

Additionally, the `Server` constructor accepts optional parameters to explicitly
configure the [connector](#server-connector) to use and to require
[authentication](#server-authentication). For more details, read on...

#### Server connector

The `Server` uses an instance of ReactPHP's
[`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface)
to establish outgoing connections for each incoming connection request.

If you need custom connector settings (DNS resolution, TLS parameters, timeouts,
proxy servers etc.), you can explicitly pass a custom instance of the
[`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface):

```php
$connector = new React\Socket\Connector(array(
    'dns' => '127.0.0.1',
    'tcp' => array(
        'bindto' => '192.168.10.1:0'
    )
));

$socks = new Clue\React\Socks\Server(null, $connector);
```

If you want to forward the outgoing connection through another SOCKS proxy, you
may also pass a [`Client`](#client) instance as a connector, see also
[server proxy chaining](#server-proxy-chaining) for more details.

Internally, the `Server` uses ReactPHP's normal
[`connect()`](https://github.com/reactphp/socket#connect) method, but
it also passes the original client IP as the `?source={remote}` parameter.
The `source` parameter contains the full remote URI, including the protocol
and any authentication details, for example `socks://alice:password@1.2.3.4:5678`
or `socks4://1.2.3.4:5678` for legacy SOCKS4(a).
You can use this parameter for logging purposes or to restrict connection
requests for certain clients by providing a custom implementation of the
[`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface).

#### Server authentication

By default, the `Server` does not require any authentication from the clients.
You can enable authentication support so that clients need to pass a valid
username and password before forwarding any connections.

Setting authentication on the `Server` enforces each further connected client
to use protocol version 5 (SOCKS5).
If a client tries to use any other protocol version, does not send along
authentication details or if authentication details can not be verified,
the connection will be rejected.

If you only want to accept static authentication details, you can simply pass an
additional assoc array with your authentication details to the `Server` like this:

```php
$socks = new Clue\React\Socks\Server(null, null, array(
    'alice' => 'password',
    'bob' => 's3cret!1'
));
```

See also [example #12](examples).

If you want more control over authentication, you can pass an authenticator
function that should return a `bool` value like this synchronous example:

```php
$socks = new Clue\React\Socks\Server(null, null, function ($username, $password, $remote) {
    // $remote is a full URI à la socks://alice:password@192.168.1.1:1234
    // or sockss://alice:password@192.168.1.1:1234 for SOCKS over TLS
    // or may be null when remote is unknown (SOCKS over Unix Domain Sockets)
    // useful for logging or extracting parts, such as the remote IP
    $ip = parse_url($remote, PHP_URL_HOST);

    return ($username === 'root' && $password === 'secret' && $ip === '127.0.0.1');
});
```

Because your authentication mechanism might take some time to actually check the
provided authentication credentials (like querying a remote database or webservice),
the server also supports a [Promise](https://github.com/reactphp/promise)-based
interface. While this might seem more complex at first, it actually provides a
very powerful way of handling a large number of connections concurrently without
ever blocking any connections. You can return a [Promise](https://github.com/reactphp/promise)
from the authenticator function that will fulfill with a `bool` value like this
async example:

```php
$socks = new Clue\React\Socks\Server(null, null, function ($username, $password) use ($db) {
    // pseudo-code: query database for given authentication details
    return $db->query(
        'SELECT 1 FROM users WHERE name = ? AND password = ?',
        array($username, $password)
    )->then(function (QueryResult $result) {
        // ensure we find exactly one match in the database
        return count($result->resultRows) === 1;
    });
});
```

#### Server proxy chaining

The `Server` is responsible for creating connections to the target host.

```
Client -> SocksServer -> TargetHost
```

Sometimes it may be required to establish outgoing connections via another SOCKS
server.
For example, this can be useful if your target SOCKS server requires
authentication, but your client does not support sending authentication
information (e.g. like most webbrowser).

```
Client -> MiddlemanSocksServer -> TargetSocksServer -> TargetHost
```

The `Server` uses any instance of the `ConnectorInterface` to establish outgoing
connections.
In order to connect through another SOCKS server, you can simply use the
[`Client`](#client) SOCKS connector from above.
You can create a SOCKS `Client` instance like this: 

```php
// set next SOCKS server example.com:1080 as target
$proxy = new Clue\React\Socks\Client('alice:password@example.com:1080');

// start a new server which forwards all connections to the other SOCKS server
$socks = new Clue\React\Socks\Server(null, $proxy);

// listen on 127.0.0.1:1080
$socket = new React\Socket\SocketServer('127.0.0.1:1080');
$socks->listen($socket);
```

See also [example #21](examples).

Proxy chaining can happen on the server side and/or the client side:

* If you ask your client to chain through multiple proxies, then each proxy
  server does not really know anything about chaining at all.
  This means that this is a client-only property and not part of this class.
  For example, you can find this in the above [`Client`](#proxy-chaining) class.

* If you ask your server to chain through another proxy, then your client does
  not really know anything about chaining at all.
  This means that this is a server-only property and can be implemented as above.

#### Server SOCKS over TLS

Both SOCKS5 and SOCKS4(a) protocol versions support forwarding TCP/IP based
connections and higher level protocols.
This implies that you can also use [secure TLS connections](#secure-tls-connections)
to transfer sensitive data across SOCKS proxy servers.
This means that no eavesdropper nor the proxy server will be able to decrypt
your data.

However, the initial SOCKS communication between the client and the proxy is
usually via an unencrypted, plain TCP/IP connection.
This means that an eavesdropper may be able to see *where* the client connects
to and may also be able to see the [SOCKS authentication](#authentication)
details in cleartext.

As an alternative, you may listen for SOCKS over TLS connections so
that the client has to establish a secure TLS connection to your SOCKS
proxy before starting the initial SOCKS communication.
This means that no eavesdroppper will be able to see the destination address
the client wants to connect to or their [SOCKS authentication](#authentication)
details.

You can simply start your listening socket on the `tls://` URI scheme like this:

```php
$socks = new Clue\React\Socks\Server();

// listen on tls://127.0.0.1:1080 with the given server certificate
$socket = new React\Socket\SocketServer('tls://127.0.0.1:1080', array(
    'tls' => array(
        'local_cert' => __DIR__ . '/localhost.pem',
    )
));
$socks->listen($socket);
```

See also [example 31](examples).

> Note that for most use cases, [secure TLS connections](#secure-tls-connections)
  should be used instead. SOCKS over TLS is considered advanced usage and is
  used very rarely in practice.

> Note that the SOCKS protocol does not support the notion of TLS. The above
  works reasonably well because TLS is only used for the connection between
  client and proxy server and the SOCKS protocol data is otherwise identical.
  This implies that this does also not support [proxy chaining](#server-proxy-chaining)
  over multiple TLS paths.

#### Server Unix domain sockets

Both SOCKS5 and SOCKS4(a) protocol versions support forwarding TCP/IP based
connections and higher level protocols.
In some advanced cases, it may be useful to let your SOCKS server listen on a
Unix domain socket (UDS) path instead of a IP:port combination.
For example, this allows you to rely on file system permissions instead of
having to rely on explicit [authentication](#server-authentication).

You can simply start your listening socket on the `unix://` URI scheme like this:

```php
$socks = new Clue\React\Socks\Server();

// listen on /tmp/proxy.sock
$socket = new React\Socket\SocketServer('unix:///tmp/proxy.sock');
$socks->listen($socket);
```

> Note that Unix domain sockets (UDS) are considered advanced usage and that
  the SOCKS protocol does not support the notion of UDS paths. The above
  works reasonably well because UDS is only used for the connection between
  client and proxy server and the path will not actually passed over the protocol.
  This implies that this does also not support [proxy chaining](#server-proxy-chaining)
  over multiple UDS paths.

## Servers

### Using a PHP SOCKS server

* If you're looking for an end-user SOCKS server daemon, you may want to use
  [LeProxy](https://leproxy.org/) or [clue/psocksd](https://github.com/clue/psocksd).
* If you're looking for a SOCKS server implementation, consider using
  the above [`Server`](#server) class.

### Using SSH as a SOCKS server

If you already have an SSH server set up, you can easily use it as a SOCKS
tunnel end point. On your client, simply start your SSH client and use
the `-D <port>` option to start a local SOCKS server (quoting the man page:
a `local "dynamic" application-level port forwarding`).

You can start a local SOCKS server by creating a loopback connection to your
local system if you already run an SSH daemon:

```bash
ssh -D 1080 localhost
```

Alternatively, you can start a local SOCKS server tunneling through a given
remote host that runs an SSH daemon:

```bash
ssh -D 1080 example.com
```

Now you can simply use this SSH SOCKS server like this:

```PHP
$proxy = new Clue\React\Socks\Client('127.0.0.1:1080');

$proxy->connect('tcp://www.google.com:80')->then(function (React\Socket\ConnectionInterface $connection) {
    $connection->write("GET / HTTP/1.0\r\n\r\n");

    $connection->on('data', function ($chunk) {
        echo $chunk;
    });
});
```

Note that the above will allow all users on the local system to connect over
your SOCKS server without authentication which may or may not be what you need.
As an alternative, recent OpenSSH client versions also support
[Unix domain sockets](#unix-domain-sockets) (UDS) paths so that you can rely
on Unix file system permissions instead:

```bash
ssh -D/tmp/proxy.sock example.com
```

Now you can simply use this SSH SOCKS server like this:

```PHP
$proxy = new Clue\React\Socks\Client('socks+unix:///tmp/proxy.sock');

$proxy->connect('tcp://www.google.com:80')->then(function (React\Socket\ConnectionInterface $connection) {
    $connection->write("GET / HTTP/1.0\r\n\r\n");

    $connection->on('data', function ($chunk) {
        echo $chunk;
    });
});
```

> As an alternative to requiring this manual setup, you may also want to look
  into using [clue/reactphp-ssh-proxy](https://github.com/clue/reactphp-ssh-proxy)
  which automatically creates this SSH tunnel for you. It provides an implementation of the same
  [`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface)
  so that supporting either proxy protocol should be fairly trivial.

### Using the Tor (anonymity network) to tunnel SOCKS connections

The [Tor anonymity network](https://www.torproject.org/) client software is designed
to encrypt your traffic and route it over a network of several nodes to conceal its origin.
It presents a SOCKS5 and SOCKS4(a) interface on TCP port 9050 by default
which allows you to tunnel any traffic through the anonymity network:

```php
$proxy = new Clue\React\Socks\Client('127.0.0.1:9050');

$proxy->connect('tcp://www.google.com:80')->then(function (React\Socket\ConnectionInterface $connection) {
    $connection->write("GET / HTTP/1.0\r\n\r\n");

    $connection->on('data', function ($chunk) {
        echo $chunk;
    });
});
```

In most common scenarios you probably want to stick to default
[remote DNS resolution](#dns-resolution) and don't want your client to resolve the target hostnames,
because you would leak DNS information to anybody observing your local traffic.
Also, Tor provides hidden services through an `.onion` pseudo top-level domain
which have to be resolved by Tor.

## Install

The recommended way to install this library is [through Composer](https://getcomposer.org/).
[New to Composer?](https://getcomposer.org/doc/00-intro.md)

This project follows [SemVer](https://semver.org/).
This will install the latest supported version:

```bash
composer require clue/socks-react:^1.4
```

See also the [CHANGELOG](CHANGELOG.md) for details about version upgrades.

This project aims to run on any platform and thus does not require any PHP
extensions and supports running on legacy PHP 5.3 through current PHP 8+ and
HHVM.
It's *highly recommended to use the latest supported PHP version* for this project.

## Tests

To run the test suite, you first need to clone this repo and then install all
dependencies [through Composer](https://getcomposer.org/):

```bash
composer install
```

To run the test suite, go to the project root and run:

```bash
vendor/bin/phpunit
```

The test suite contains a number of tests that rely on a working internet
connection, alternatively you can also run it like this:

```bash
vendor/bin/phpunit --exclude-group internet
```

## License

This project is released under the permissive [MIT license](LICENSE).

> Did you know that I offer custom development services and issuing invoices for
  sponsorships of releases and for contributions? Contact me (@clue) for details.

## More

* If you want to learn more about how the
  [`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface)
  and its usual implementations look like, refer to the documentation of the
  underlying [react/socket component](https://github.com/reactphp/socket).
* If you want to learn more about processing streams of data, refer to the
  documentation of the underlying
  [react/stream](https://github.com/reactphp/stream) component.
* As an alternative to a SOCKS5 / SOCKS4(a) proxy, you may also want to look into
  using an HTTP CONNECT proxy instead.
  You may want to use [clue/reactphp-http-proxy](https://github.com/clue/reactphp-http-proxy)
  which also provides an implementation of the same
  [`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface)
  so that supporting either proxy protocol should be fairly trivial.
* As an alternative to a SOCKS5 / SOCKS4(a) proxy, you may also want to look into
  using an SSH proxy (SSH tunnel) instead.
  You may want to use [clue/reactphp-ssh-proxy](https://github.com/clue/reactphp-ssh-proxy)
  which also provides an implementation of the same
  [`ConnectorInterface`](https://github.com/reactphp/socket#connectorinterface)
  so that supporting either proxy protocol should be fairly trivial.
* If you're dealing with public proxies, you'll likely have to work with mixed
  quality and unreliable proxies. You may want to look into using
  [clue/reactphp-connection-manager-extra](https://github.com/clue/reactphp-connection-manager-extra)
  which allows retrying unreliable ones, implying connection timeouts,
  concurrently working with multiple connectors and more.
* If you're looking for an end-user SOCKS server daemon, you may want to use
  [LeProxy](https://leproxy.org/) or [clue/psocksd](https://github.com/clue/psocksd).
