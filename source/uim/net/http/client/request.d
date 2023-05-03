/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.http.Client;

use Laminas\Diactoros\RequestTrait;
use Laminas\Diactoros\Stream;
use Psr\Http\messages.IRequest;

/**
 * : methods for HTTP requests.
 *
 * Used by Cake\Http\Client to contain request information
 * for making requests.
 */
class Request : Message : IRequest
{
    use RequestTrait;

    /**
     * Constructor
     *
     * Provides backwards compatible defaults for some properties.
     *
     * @phpstan-param array<non-empty-string, non-empty-string> $headers
     * @param string $url The request URL
     * @param string $method The HTTP method to use.
     * @param array $headers The HTTP headers to set.
     * @param array|string|null $data The request body to use.
     */
    this(string $url = "", string $method = self::METHOD_GET, array $headers = null, $data = null) {
        this.setMethod($method);
        this.uri = this.createUri($url);
        $headers += [
            "Connection": "close",
            "User-Agent": ini_get("user_agent") ?: "UIM",
        ];
        this.addHeaders($headers);

        if ($data == null) {
            this.stream = new Stream("php://memory", "rw");
        } else {
            this.setContent($data);
        }
    }

    /**
     * Add an array of headers to the request.
     *
     * @phpstan-param array<non-empty-string, non-empty-string> $headers
     * @param array<string, string> $headers The headers to add.
     */
    protected void addHeaders(array $headers) {
        foreach ($headers as $key: $val) {
            $normalized = $key.toLower;
            this.headers[$key] = (array)$val;
            this.headerNames[$normalized] = $key;
        }
    }

    /**
     * Set the body/payload for the message.
     *
     * Array data will be serialized with {@link uim.net.http\FormData},
     * and the content-type will be set.
     *
     * @param array|string $content The body for the request.
     * @return this
     */
    protected function setContent($content) {
        if (is_array($content)) {
            $formData = new FormData();
            $formData.addMany($content);
            /** @phpstan-var array<non-empty-string, non-empty-string> $headers */
            $headers = ["Content-Type": $formData.contentType()];
            this.addHeaders($headers);
            $content = (string)$formData;
        }

        $stream = new Stream("php://memory", "rw");
        $stream.write($content);
        this.stream = $stream;

        return this;
    }
}
