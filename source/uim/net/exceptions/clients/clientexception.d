module uim.net.exceptions.clients;

import uim.net;
@safe:

// Thrown when a request cannot be sent or response cannot be parsed into a PSR-7 response object.
class ClientException : RuntimeException, IClientException {
}
