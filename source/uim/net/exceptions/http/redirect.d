/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.exceptions.http.redirect;

import uim.net;
@safe:

/**
 * An exception subclass used by routing and application code to trigger a redirect.
 *
 * The URL and status code are provided as constructor arguments. Example:
 * throw new RedirectException("http://example.com/some/path", 301);
*
 * Additional headers can also be provided in the constructor, or using the addHeaders() method.
 */
class RedirectException : HttpException {
  /**
    * Constructor
    *
    * myRedirectTarget - The URL to redirect to.
    * code - The exception code that will be used as a HTTP status code
    * headersThe headers that -  should be sent in the unauthorized challenge response.
    */
  this(string myRedirectTarget, int code = 302, string[][string] someHeaders = null) {
    super.this(myTarget, code);

    foreach (myValues, myKey; someHeaders) {
      headers[myKey] = myValues;
    }
  }
}
