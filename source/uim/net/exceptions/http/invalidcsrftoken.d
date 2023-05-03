/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.exceptions.http.invalidcsrftoken;

import uim.net;
@safe:

// Represents an HTTP 403 error caused by an invalid CSRF token
class InvalidCsrfTokenException : HttpException {
  this(string myMessage = null, int theCode = 0, Throwable nextInChain = null) {
    super(myMessage, code, nextInChain);
  }

  void initialize(Json configSettings = Json(null)) {
    this
      .defaultCode(403)
      .message("Invalid CSRF Token");
  }
}
