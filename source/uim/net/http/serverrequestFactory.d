module uim.net.https;

import uim.net;
@safe:

/**
 * Factory for making ServerRequest instances.
 *
 * This subclass adds in UIM specific behavior to populate
 * the basePath and webroot attributes. Furthermore the Uri"s path
 * is corrected to only contain the "virtual" path for the request.
 */
abstract class ServerRequestFactory : ServerRequestFactoryInterface
{
    /**
     * Create a request from the supplied superglobal values.
     *
     * If any argument is not supplied, the corresponding superglobal value will
     * be used.
     *
     * The ServerRequest created is then passed to the fromServer() method in
     * order to marshal the request URI and headers.
     *
     * @see fromServer()
     * @param array|null $server _SERVER superglobal
     * @param array|null myQuery _GET superglobal
     * @param array|null $parsedBody _POST superglobal
     * @param array|null $cookies _COOKIE superglobal
     * @param array|null myfiles _FILES superglobal
     * @return uim.net.http.ServerRequest
     * @throws \InvalidArgumentException for invalid file values
     */
    static function fromGlobals(
        ?array $server = null,
        ?array myQuery = null,
        ?array $parsedBody = null,
        ?array $cookies = null,
        ?array myfiles = null
    ): ServerRequest {
        $server = normalizeServer($server ?: _SERVER);
        $uri = static::createUri($server);

        /** @psalm-suppress NoInterfaceProperties */
        $sessionConfig = (array)Configure::read("Session") + [
            "defaults":"php",
            "cookiePath":$uri.webroot,
        ];
        $session = Session::create($sessionConfig);

        /** @psalm-suppress NoInterfaceProperties */
        myRequest = new ServerRequest([
<<<<<<< HEAD
            "environment":$server,
            "uri":$uri,
            "cookies":$cookies ?: _COOKIE,
            "query":myQuery ?: _GET,
            "webroot":$uri.webroot,
            "base":$uri.base,
            "session":$session,
            "input":$server["CAKEPHP_INPUT"] ?? null,
!=
            "environment": $server,
            "uri": $uri,
            "cookies": $cookies ?: _COOKIE,
            "query": myQuery ?: _GET,
            "webroot": $uri.webroot,
            "base": $uri.base,
            "session": $session,
            "input": $server["UIM_INPUT"] ?? null,
>>>>>>> 7150a867e48cdb2613daa023accf8964a29f88b9
        ]);

        myRequest = static::marshalBodyAndRequestMethod($parsedBody ?? _POST, myRequest);
        myRequest = static::marshalFiles(myfiles ?? _FILES, myRequest);

        return myRequest;
    }

    /**
     * Sets the REQUEST_METHOD environment variable based on the simulated _method
     * HTTP override value. The "ORIGINAL_REQUEST_METHOD" is also preserved, if you
     * want the read the non-simulated HTTP method the client used.
     *
     * Request body of content type "application/x-www-form-urlencoded" is parsed
     * into array for PUT/PATCH/DELETE requests.
     *
     * @param array $parsedBody Parsed body.
     * @param uim.net.http.ServerRequest myRequest Request instance.
     * @return uim.net.http.ServerRequest
     */
    protected static function marshalBodyAndRequestMethod(array $parsedBody, ServerRequest myRequest): ServerRequest
    {
        $method = myRequest.getMethod();
        $override = false;

        if (
            hasAllValues($method, ["PUT", "DELETE", "PATCH"], true) &&
            indexOf((string)myRequest.contentType(), "application/x-www-form-urlencoded") == 0
        ) {
            myData = (string)myRequest.getBody();
            parse_str(myData, $parsedBody);
        }
        if (myRequest.hasHeader("X-Http-Method-Override")) {
            $parsedBody["_method"] = myRequest.getHeaderLine("X-Http-Method-Override");
            $override = true;
        }

        myRequest = myRequest.withEnv("ORIGINAL_REQUEST_METHOD", $method);
        if (isset($parsedBody["_method"])) {
            myRequest = myRequest.withEnv("REQUEST_METHOD", $parsedBody["_method"]);
            unset($parsedBody["_method"]);
            $override = true;
        }

        if (
            $override &&
            !hasAllValues(myRequest.getMethod(), ["PUT", "POST", "DELETE", "PATCH"], true)
        ) {
            $parsedBody = null;
        }

        return myRequest.withParsedBody($parsedBody);
    }

    /**
     * Process uploaded files and move things onto the parsed body.
     *
     * @param array myfiles Files array for normalization and merging in parsed body.
     * @param uim.net.http.ServerRequest myRequest Request instance.
     * @return uim.net.http.ServerRequest
     */
    protected static function marshalFiles(array myfiles, ServerRequest myRequest): ServerRequest
    {
        myfiles = normalizeUploadedFiles(myfiles);
        myRequest = myRequest.withUploadedFiles(myfiles);

        $parsedBody = myRequest.getParsedBody();
        if (!is_array($parsedBody)) {
            return myRequest;
        }

        if (Configure::read("App.uploadedFilesAsObjects", true)) {
            $parsedBody = Hash::merge($parsedBody, myfiles);
        } else {
            // Make a flat map that can be inserted into body for BC.
            myfileMap = Hash::flatten(myfiles);
            foreach (myfileMap as myKey: myfile) {
                myError = myfile.getError();
                $tmpName = "";
                if (myError == UPLOAD_ERR_OK) {
                    $tmpName = myfile.getStream().getMetadata("uri");
                }
                $parsedBody = Hash::insert($parsedBody, (string)myKey, [
                    "tmp_name":$tmpName,
                    "error":myError,
                    "name":myfile.getClientFilename(),
                    "type":myfile.getClientMediaType(),
                    "size":myfile.getSize(),
                ]);
            }
        }

        return myRequest.withParsedBody($parsedBody);
    }

    /**
     * Create a new server request.
     *
     * Note that server-params are taken precisely as given - no parsing/processing
     * of the given values is performed, and, in particular, no attempt is made to
     * determine the HTTP method or URI, which must be provided explicitly.
     *
     * @param string method The HTTP method associated with the request.
     * @param \Psr\Http\messages.UriInterface|string uri The URI associated with the request. If
     *     the value is a string, the factory MUST create a UriInterface
     *     instance based on it.
     * @param array $serverParams Array of SAPI parameters with which to seed
     *     the generated request instance.
     * @return \Psr\Http\messages.IServerRequest
     */
    function createServerRequest(string method, $uri, array $serverParams = null): IServerRequest
    {
        $serverParams["REQUEST_METHOD"] = $method;
        myOptions = ["environment":$serverParams];

        if ($uri instanceof UriInterface) {
            myOptions["uri"] = $uri;
        } else {
            myOptions["url"] = $uri;
        }

        return new ServerRequest(myOptions);
    }

    /**
     * Create a new Uri instance from the provided server data.
     *
     * @param array $server Array of server data to build the Uri from.
     *   _SERVER will be added into the $server parameter.
     * @return \Psr\Http\messages.UriInterface New instance.
     */
    static function createUri(array $server = null): UriInterface
    {
        $server += _SERVER;
        $server = normalizeServer($server);
        $headers = marshalHeadersFromSapi($server);

        return static::marshalUriFromSapi($server, $headers);
    }

    /**
     * Build a UriInterface object.
     *
     * Add in some UIM specific logic/properties that help
     * preserve backwards compatibility.
     *
     * @param array $server The server parameters.
     * @param array $headers The normalized headers
     * @return \Psr\Http\messages.UriInterface a constructed Uri
     */
    protected static function marshalUriFromSapi(array $server, array $headers): UriInterface
    {
        $uri = marshalUriFromSapi($server, $headers);
        [$base, $webroot] = static::getBase($uri, $server);

        // Look in PATH_INFO first, as this is the exact value we need prepared
        // by PHP.
        myPathInfo = Hash::get($server, "PATH_INFO");
        if (myPathInfo) {
            $uri = $uri.withPath(myPathInfo);
        } else {
            $uri = static::updatePath($base, $uri);
        }

        if (!$uri.getHost()) {
            $uri = $uri.withHost("localhost");
        }

        // Splat on some extra attributes to save
        // some method calls.
        /** @psalm-suppress NoInterfaceProperties */
        $uri.base = $base;
        /** @psalm-suppress NoInterfaceProperties */
        $uri.webroot = $webroot;

        return $uri;
    }

    /**
     * Updates the request URI to remove the base directory.
     *
     * @param string base The base path to remove.
     * @param \Psr\Http\messages.UriInterface $uri The uri to update.
     * @return \Psr\Http\messages.UriInterface The modified Uri instance.
     */
    protected static function updatePath(string base, UriInterface $uri): UriInterface
    {
        myPath = $uri.getPath();
        if ($base != "" && indexOf(myPath, $base) == 0) {
            myPath = substr(myPath, strlen($base));
        }
        if (myPath == "/index.php" && $uri.getQuery()) {
            myPath = $uri.getQuery();
        }
        if (empty(myPath) || myPath == "/" || myPath == "//" || myPath == "/index.php") {
            myPath = "/";
        }
        $endsWithIndex = "/" ~ (Configure::read("App.webroot") ?: "webroot") ~ "/index.php";
        $endsWithLength = strlen($endsWithIndex);
        if (
            strlen(myPath) >= $endsWithLength &&
            substr(myPath, -$endsWithLength) == $endsWithIndex
        ) {
            myPath = "/";
        }

        return $uri.withPath(myPath);
    }

    /**
     * Calculate the base directory and webroot directory.
     *
     * @param \Psr\Http\messages.UriInterface $uri The Uri instance.
     * @param array $server The SERVER data to use.
     * @return array An array containing the [baseDir, webroot]
     */
    protected static auto getBase(UriInterface $uri, array $server) {
        myConfig = (array)Configure::read("App") + [
            "base":null,
            "webroot":null,
            "baseUrl":null,
        ];
        $base = myConfig["base"];
        $baseUrl = myConfig["baseUrl"];
        $webroot = myConfig["webroot"];

        if ($base != false && $base  !is null) {
            return [$base, $base ~ "/"];
        }

        if (!$baseUrl) {
            $base = dirname(Hash::get($server, "PHP_SELF"));
            // Clean up additional / which cause following code to fail..
            $base = preg_replace("#/+#", "/", $base);

            $indexPos = indexOf($base, "/" ~ $webroot ~ "/index.php");
            if ($indexPos != false) {
                $base = substr($base, 0, $indexPos) ~ "/" ~ $webroot;
            }
            if ($webroot == basename($base)) {
                $base = dirname($base);
            }

            if ($base == DIRECTORY_SEPARATOR || $base == ".") {
                $base = "";
            }
            $base = implode("/", array_map("rawurlencode", explode("/", $base)));

            return [$base, $base ~ "/"];
        }

        myfile = "/" ~ basename($baseUrl);
        $base = dirname($baseUrl);

        if ($base == DIRECTORY_SEPARATOR || $base == ".") {
            $base = "";
        }
        $webrootDir = $base ~ "/";

        $docRoot = Hash::get($server, "DOCUMENT_ROOT");
        $docRootContainsWebroot = indexOf($docRoot, $webroot);

        if (!empty($base) || !$docRootContainsWebroot) {
            if (indexOf($webrootDir, "/" ~ $webroot ~ "/") == false) {
                $webrootDir ~= $webroot ~ "/";
            }
        }

        return [$base . myfile, $webrootDir];
    }
}
