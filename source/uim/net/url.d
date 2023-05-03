module uim.net.url;

import uim.net;
@safe:
/*
A URL is a Universal Resource Locator. Not only can a URL point to a file in a directory, but that file and directory can exist on any computer on the network and be served through any of several different methods. and maybe not even something as simple as a file: URLs can also refer to queries, documents, or records stored in databases or whatever.
*/

class DURL {
  this() {}
  this(String spec) { this(); }
  this(String protocol, String host, int port, String file) { this(); }
  // this(String protocol, String host, int port, String file, URLStreamHandler handler) { this(); }
  this(String protocol, String host, String file) { this(); }
  this(URL context, String spec) { this(); }
  // this(URL context, String spec, URLStreamHandler handler) { this(); }

  /// 
  unittest {
    auto myURL = new DURL("http://www.sicherheitsschmiede.de/pages/");
    auto toLoginURL = new DURL(myURL, "login.html");
    auto toLogoutURL = new DURL(myURL, "logout.html");
    auto toLoginTopURL = new DURL(toLoginURL,"#TOP");
    auto toLoginURL2 = new DURL("http", "www.sicherheitsschmiede.de", "/pages/login.html");
    auto adminURL = new DURL("http", "www.sicherheitsschmiede.de", 8080, "/pages/login.html");
  }

  // Compares this URL for equality with another object.
/*   bool equals(DURL aURL) {
    if () {
      return true;
    }
    return false;
  } */

  // Gets the authority part of this URL.
  string getAuthority()

  // Gets the contents of this URL.
  final Object getContent()

  // Gets the contents of this URL.
  final Object getContent(Class<?>[] classes)

  // Gets the default port number of the protocol associated with this URL.
  int getDefaultPort()

  // Gets the file name of this URL.
  string getFile()

  // host name of URL, if applicable.
  mixin(OProperty!("string", "host"));
  ///
  unittest {
    auto aURL = new DURL("http://www.sicherheitsschmiede.de:80/page/index.html?show=history#ACCESS");
    assert(aURL.host == "www.sicherheitsschmiede.de");
    assert(aURL.host == "www.sicherheitsschmiede.de");
  }

  // path part of URL.
  mixin(OProperty!("string", "path"));
  ///
  unittest {
    auto aURL = new DURL("http://www.sicherheitsschmiede.de:80/page/index.html?show=history#ACCESS");
    assert(aUrl.host == "/page/index.html");
  }

  // Gets the port number of this URL.
  int getPort()

  // Gets the protocol name of this URL.
  string getProtocol()

  // Gets the query part of this URL.
  string getQuery()

  // Gets the anchor (also known as the "reference") of this URL.
  string getRef()

  // Gets the userInfo part of this URL.
  string getUserInfo()

  // Creates an integer suitable for hash table indexing.
  int hashCode()

  Creates a URL from a URI, as if by invoking uri.toURL(), but associating it with the given URLStreamHandler, if allowed.
  static URL of(URI uri, URLStreamHandler handler)

  // Returns a URLConnection instance that represents a connection to the remote object referred to by the URL.
  URLConnection openConnection()

  // Same as openConnection(), except that the connection will be made through the specified proxy; Protocol handlers that do not support proxying will ignore the proxy parameter and make a normal connection.
  URLConnection openConnection(Proxy proxy)

  // Opens a connection to this URL and returns an InputStream for reading from that connection.
  final InputStream openStream()

  // Compares two URLs, excluding the fragment component.
  bool sameFile(URL other)

  // Sets an application's URLStreamHandlerFactory.
  static void setURLStreamHandlerFactory(URLStreamHandlerFactory fac)

  // Constructs a string representation of this URL.
  string toExternalForm()

  // Constructs a string representation of this URL.
  string toString()
  
  // Returns a URI equivalent to this URL.
  URI toURI() */
}