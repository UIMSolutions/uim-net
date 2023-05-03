module uim.net.authentication.authenticator;

static Authenticator
getDefault()
Gets the default authenticator.

class DAuthenticator {
/*   // Called when password authorization is needed.
  protected PasswordAuthentication passwordAuthentication();

  // Gets the hostname of the site or proxy requesting authentication, or null if not available.
  protected string requestingHost()

  // Gets the port number for the requested connection.
  protected int requestingPort()

  // Gets the prompt string given by the requestor.
  protected string requestingPrompt()

  // Give the protocol that's requesting the connection.
  protected string requestingProtocol()

  // Gets the scheme of the requestor (the HTTP scheme for an HTTP firewall, for example).
  protected string requestingScheme()

  // Gets the InetAddress of the site requesting authorization, or null if not available.
  protected InetAddress requestingSite()

  // Returns the URL that resulted in this request for authentication.
  protected URL requestingURL()

  // Returns whether the requestor is a Proxy or a Server.
  protected Authenticator.RequestorType requestorType()

  // Ask the authenticator that has been registered with the system for a password.
  static PasswordAuthentication requestPasswordAuthentication(String host, InetAddress addr, int port, String protocol, String prompt, String scheme)

  // Ask the authenticator that has been registered with the system for a password.
  static PasswordAuthentication requestPasswordAuthentication(String host, InetAddress addr, int port, String protocol, String prompt, String scheme, URL url, Authenticator.RequestorType reqType)

  // Ask the given authenticator for a password.
  static PasswordAuthentication requestPasswordAuthentication(Authenticator authenticator, String host, InetAddress addr, int port, String protocol, String prompt, String scheme, URL url, Authenticator.RequestorType reqType)

  // Ask the authenticator that has been registered with the system for a password.
  static PasswordAuthentication requestPasswordAuthentication(InetAddress addr, int port, String protocol, String prompt, String scheme)

  // Ask this authenticator for a password.
  PasswordAuthentication requestPasswordAuthenticationInstance(String host, InetAddress addr, int port, String protocol, String prompt, String scheme, URL url, Authenticator.RequestorType reqType)

  static void setDefault(Authenticator a) */
}