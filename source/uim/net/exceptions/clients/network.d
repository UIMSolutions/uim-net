module uim.net.exceptions.clients.network

import uim.net;
@safe:

/**
 * Thrown when the request cannot be completed because of network issues.
 *
 * There is no response object as this exception is thrown when no response has been received.
 * Example: the target host name can not be resolved or the connection failed.
 */
class NetworkException : UIMException, INetworkException {
  /**
    * Constructor.
    *
    * @param string aMessage Exeception message.
    * @param \Psr\Http\messages.IRequest $request Request instance.
    * @param \Throwable|null $previous Previous Exception
    */
  this(string aMessage, IRequest aRequest, Throwable nextInChain = null) {
      _request = aRequest;
      super(aMessage, 0, nextInChain);
  }

  /**
    * Returns the request.
    *
    * The request object MAY be a different object from the one passed to ClientInterface::sendRequest()
    */
  protected IRequest _request;
  IRequest getRequest():  {
      return _request;
  }
}
