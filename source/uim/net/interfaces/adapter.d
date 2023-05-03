/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.interfaces.adapter;

import uim.net;
@safe:

// Http client adapter interface.
interface IAdapter {
  /**
    * Send a request and get a response back.
    *
    * myRequest - The request object to send.
    * options - Array of options for the stream.
    * returns Array of populated Response objects
    */
  IResponse[] send(IRequest myRequest, Json options = Json(null));
}
