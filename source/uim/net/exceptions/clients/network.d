module uim.net.exceptions.clients.network

import uim.net;
@safe:

/**
 * Thrown when the request cannot be completed because of network issues.
 *
 * There is no response object as this exception is thrown when no response has been received.
 *
 * Example: the target host name can not be resolved or the connection failed.
 */
class NetworkException : RuntimeException, INetworkException {
    /**
     * @var \Psr\Http\messages.IRequest
     */
    protected $request;

    /**
     * Constructor.
     *
     * @param string $message Exeception message.
     * @param \Psr\Http\messages.IRequest $request Request instance.
     * @param \Throwable|null $previous Previous Exception
     */
    this(string $message, IRequest $request, ?Throwable $previous = null) {
        this.request = $request;
        super(($message, 0, $previous);
    }

    /**
     * Returns the request.
     *
     * The request object MAY be a different object from the one passed to ClientInterface::sendRequest()
     *
     * @return \Psr\Http\messages.IRequest
     */
    IRequest getRequest():  {
        return this.request;
    }
}
