module uim.net.https.middlewares;

@safe:
import uim.net

use Closure;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;

/**
 * Parse encoded request body data.
 *
 * Enables JSON and XML request payloads to be parsed into the request"s body.
 * You can also add your own request body parsers using the `addParser()` method.
 */
class BodyParserMiddleware : IMiddleware {
    /**
     * Registered Parsers
     *
     * @var array<\Closure>
     */
    protected $parsers = null;

    /**
     * The HTTP methods to parse data on.
     *
     * @var array<string>
     */
    protected $methods = ["PUT", "POST", "PATCH", "DELETE"];

    /**
     * Constructor
     *
     * ### Options
     *
     * - `json` Set to false to disable JSON body parsing.
     * - `xml` Set to true to enable XML parsing. Defaults to false, as XML
     *   handling requires more care than JSON does.
     * - `methods` The HTTP methods to parse on. Defaults to PUT, POST, PATCH DELETE.
     *
     * @param array<string, mixed> $options The options to use. See above.
     */
    this(STRINGAA someOptions = null) {
        $options += ["json": true, "xml": false, "methods": null];
        if ($options["json"]) {
            this.addParser(
                ["application/json", "text/json"],
                Closure::fromCallable([this, "decodeJson"])
            );
        }
        if ($options["xml"]) {
            this.addParser(
                ["application/xml", "text/xml"],
                Closure::fromCallable([this, "decodeXml"])
            );
        }
        if ($options["methods"]) {
            this.setMethods($options["methods"]);
        }
    }

    /**
     * Set the HTTP methods to parse request bodies on.
     *
     * @param array<string> $methods The methods to parse data on.
     * @return this
     */
    function setMethods(array $methods) {
        this.methods = $methods;

        return this;
    }

    /**
     * Get the HTTP methods to parse request bodies on.
     *
     * @return array<string>
     */
    string[] getMethods() {
        return this.methods;
    }

    /**
     * Add a parser.
     *
     * Map a set of content-type header values to be parsed by the $parser.
     *
     * ### Example
     *
     * An naive CSV request body parser could be built like so:
     *
     * ```
     * $parser.addParser(["text/csv"], function ($body) {
     *   return str_getcsv($body);
     * });
     * ```
     *
     * @param array<string> $types An array of content-type header values to match. eg. application/json
     * @param \Closure $parser The parser function. Must return an array of data to be inserted
     *   into the request.
     * @return this
     */
    function addParser(array $types, Closure $parser) {
        foreach ($types as $type) {
            $type = strtolower($type);
            this.parsers[$type] = $parser;
        }

        return this;
    }

    /**
     * Get the current parsers
     *
     * @return array<\Closure>
     */
    array getParsers() {
        return this.parsers;
    }

    /**
     * Apply the middleware.
     *
     * Will modify the request adding a parsed body if the content-type is known.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        if (!hasAllValues($request.getMethod(), this.methods, true)) {
            return $handler.handle($request);
        }
        [$type] = explode(";", $request.getHeaderLine("Content-Type"));
        $type = strtolower($type);
        if (!isset(this.parsers[$type])) {
            return $handler.handle($request);
        }

        $parser = this.parsers[$type];
        $result = $parser($request.getBody().getContents());
        if (!is_array($result)) {
            throw new BadRequestException();
        }
        $request = $request.withParsedBody($result);

        return $handler.handle($request);
    }

    /**
     * Decode JSON into an array.
     *
     * @param string $body The request body to decode
     * @return array|null
     */
    protected function decodeJson(string $body) {
        if ($body == "") {
            return [];
        }
        $decoded = json_decode($body, true);
        if (json_last_error() == JSON_ERROR_NONE) {
            return (array)$decoded;
        }

        return null;
    }

    /**
     * Decode XML into an array.
     *
     * @param string $body The request body to decode
     */
    protected array decodeXml(string $body) {
        try {
            $xml = Xml::build($body, ["return": "domdocument", "readFile": false]);
            // We might not get child nodes if there are nested inline entities.
            if ((int)$xml.childNodes.length > 0) {
                return Xml::toArray($xml);
            }

            return [];
        } catch (XmlException $e) {
            return [];
        }
    }
}
