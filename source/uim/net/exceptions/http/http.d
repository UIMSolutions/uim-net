/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.exceptions.http.http;

import uim.net;
@safe:

/**
 * Parent class for all the HTTP related exceptions in UIM.
 * All HTTP status/error related exceptions should extend this class so catch blocks can be specifically typed.
 */
class HttpException : UIMException {
  void initialize(Json configSettings = Json(null)) {
    this
      .defaultCode(500);
  }

  // Response Headers
  mixin(OProperty!("string[][string]", "headers"));

  // Set a single HTTP response header.
  void header(string aHeaderName, string[] values = null) {
    _headers[aHeader] = values;
  }

  override opIndexAssign(string[] values, string index) {
    _headers[index] = values;
  }
  string[] opIndex(string index) {
    return _headers.get(index, null);
  }
}
