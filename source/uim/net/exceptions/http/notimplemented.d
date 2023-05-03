/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.exceptions.http.forbidden;

import uim.net;
@safe:

// Not Implemented Exception - used when an API method is not implemented
class NotImplementedException : HttpException {
  this(string myMessage = null, int theCode = 0, Throwable nextInChain = null) {
    super(myMessage, code, nextInChain);
  }

  void initialize(Json configSettings = Json(null)) {
    this
      .defaultCode(501)
      .messageTemplate("%s is not implemented.");
  }
}
