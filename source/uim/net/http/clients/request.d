module uim.net.http.clients.request;

import uim.net;
@safe:

/**
 * : methods for HTTP requests.
 *
 * Used by Cake\Http\Client to contain request information
 * for making requests.
 */
class Request : Message : IRequest {
    use RequestTrait;

    /**
     * Constructor
     *
     * Provides backwards compatible defaults for some properties.
     *
     * @phpstan-param array<non-empty-string, non-empty-string> $headers
     * @param string myUrl The request URL
     * @param string method The HTTP method to use.
     * @param array $headers The HTTP headers to set.
     * @param array|string|null myData The request body to use.
     */
    this(string myUrl = "", string method = self::METHOD_GET, array $headers = null, myData = null) {
        this.setMethod($method);
        this.uri = this.createUri(myUrl);
        $headers += [
<<<<<<< HEAD
            "Connection":"close",
            "User-Agent":ini_get("user_agent") ?: "UIM",
!=
            "Connection": "close",
            "User-Agent": ini_get("user_agent") ?: "UIM",
>>>>>>> 7150a867e48cdb2613daa023accf8964a29f88b9
        ];
        this.addHeaders($headers);

        if (myData is null) {
            this.stream = new Stream("php://memory", "rw");
        } else {
            this.setContent(myData);
        }
    }

    /**
     * Add an array of headers to the request.
     *
     * @phpstan-param array<non-empty-string, non-empty-string> $headers
     * @param array<string, string> $headers The headers to add.
     */
    protected void addHeaders(array $headers) {
        foreach ($headers as myKey: $val) {
            $normalized = strtolower(myKey);
            this.headers[myKey] = (array)$val;
            this.headerNames[$normalized] = myKey;
        }
    }

    /**
     * Set the body/payload for the message.
     *
     * Array data will be serialized with {@link uim.net.http\FormData},
     * and the content-type will be set.
     *
     * @param array|string myContents The body for the request.
     * @return this
     */
    protected auto setContent(myContents) {
        if (is_array(myContents)) {
            $formData = new FormData();
            $formData.addMany(myContents);
            /** @phpstan-var array<non-empty-string, non-empty-string> $headers */
            $headers = ["Content-Type":$formData.contentType()];
            this.addHeaders($headers);
            myContents = (string)$formData;
        }

        $stream = new Stream("php://memory", "rw");
        $stream.write(myContents);
        this.stream = $stream;

        return this;
    }
}
