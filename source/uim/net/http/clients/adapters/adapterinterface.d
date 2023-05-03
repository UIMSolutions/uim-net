/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.http.clients;

import uim.net;
@safe:

// Http client adapter interface.
interface IAdapter {
    /**
     * Send a request and get a response back.
     *
     * @param \Psr\Http\messages.IRequest myRequest The request object to send.
     * @param array<string, mixed> myOptions Array of options for the stream.
     * @return array<uim.net.http\Client\Response> Array of populated Response objects
     */
    array send(IRequest myRequest, array myOptions);
}
