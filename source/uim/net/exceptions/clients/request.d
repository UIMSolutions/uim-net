module uim.net.exceptions.clients.request;

import uim.net;
@safe:

/**
 * Exception for when a request failed.
 *
 * Examples:
 *
 *   - Request is invalid (e.g. method is missing)
 *   - Runtime request errors (e.g. the body stream is not seekable)
 */
class RequestException : UIMException, IRequestException {
  /**
    * Constructor.
    *
    * @param string aMessage Exeception message.
    * @param \Psr\Http\messages.IRequest $request Request instance.
    * @param \Throwable|null $previous Previous Exception
    */
  this(string aMessage, IRequest $request, ?Throwable $previous = null) {
    this.request = $request;
    super(message, 0, $previous);
  }

  /**
    * Returns the request.
    * The request object MAY be a different object from the one passed to ClientInterface::sendRequest()
    */
  protected IRequest _request;
  IRequest request() {
      return _request;
  }
}
