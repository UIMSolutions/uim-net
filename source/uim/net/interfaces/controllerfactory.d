/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.interfaces.controllerfactory;

import uim.net;
@safe:

// Factory method for building controllers from request/response pairs.
interface IControllerFactory {
    /**
     * Create a controller for a given request
     *
     * @param \Psr\Http\messages.IServerRequest $request The request to build a controller for.
     * @return mixed
     * @throws uim.net.http.exceptions.MissingControllerException
     */
    DController create(IServerRequest $request);

    /**
     * Invoke a controller"s action and wrapping methods.
     *
     * @param mixed $controller The controller to invoke.
     * @return \Psr\Http\messages.IResponse The response
     * @psalm-param TController $controller
     */
    DController invoke($controller): IResponse;
}
