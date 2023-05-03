/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.exceptions.http.missingcontroller;

import uim.net;
@safe:

// Missing Controller exception - used when a controller cannot be found.
class MissingControllerException : UIMException {
  this(string myMessage = null, int theCode = 0, Throwable nextInChain = null) {
    super(myMessage, code, nextInChain);
  }

  void initialize(Json configSettings = Json(null)) {
    this
      .defaultCode(404)
      .messageTemplate("Controller class %s could not be found.");
  }
}
