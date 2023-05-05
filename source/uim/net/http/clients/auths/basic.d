module uim.net.http.clients.auths.basic;

import uim.net;
@safe:

/**
 * Basic authentication adapter for Cake\Http\Client
 *
 * Generally not directly constructed, but instead used by {@link uim.net.http\Client}
 * when $options["auth"]["type"] is "basic"
 */
class Basic {
  /**
    * Add Authorization header to the request.
    *
    * @param uim.net.http.Client\Request $request Request instance.
    * @param array $credentials Credentials.
    * returns DHTPRequest The updated request.
    * @see https://www.ietf.org/rfc/rfc2617.txt
    */
  Request authentication(Request aRequest, array $credentials) {
    auto result = aRequest;
    if (isset($credentials["username"], $credentials["password"])) {
      $value = _generateHeader($credentials["username"], $credentials["password"]);
      /** var DHTP.Client\Request $request */
      result = aRequest.withHeader("Authorization", $value);
    }

    return result;
  }

  /**
    * Proxy Authentication
    *
    * @param uim.net.http.Client\Request $request Request instance.
    * @param array $credentials Credentials.
    * returns DHTPRequest The updated request.
    * @see https://www.ietf.org/rfc/rfc2617.txt
    */
  Request proxyAuthentication(Request $request, array $credentials) {
    if (isset($credentials["username"], $credentials["password"])) {
      $value = _generateHeader($credentials["username"], $credentials["password"]);
      /** var DHTP.Client\Request $request */
      $request = $request.withHeader("Proxy-Authorization", $value);
    }

    return $request;
  }

  // Generate basic [proxy] authentication header
  protected string _generateHeader(string username, string password) {
      return "Basic " ~ base64_encode($user ~ ":" ~ $pass);
  }
}
