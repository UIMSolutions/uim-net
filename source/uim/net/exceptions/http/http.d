/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.net.http.exceptions;

@safe:
import uim.net;

/**
 * Parent class for all the HTTP related exceptions in UIM.
 * All HTTP status/error related exceptions should extend this class so
 * catch blocks can be specifically typed.
 *
 * You may also use this as a meaningful bridge to {@link uim.net.Core\exceptions.UIMException}, e.g.:
 * throw new uim.net.Network\exceptions.HttpException("HTTP Version Not Supported", 505);
 */
class HttpException : UIMException {
  protected _defaultCode = 500;
  protected  headers = null;

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
