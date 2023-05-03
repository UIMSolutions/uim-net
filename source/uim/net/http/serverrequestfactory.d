/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.http.serverrequestfactory;

import uim.net;
@safe:

/**
 * Factory for making ServerRequest instances.
 *
 * This adds in UIM specific behavior to populate the basePath and webroot
 * attributes. Furthermore the Uri"s path is corrected to only contain the
 * "virtual" path for the request.
 */
abstract class ServerRequestFactory : ServerRequestFactoryInterface
{
    /**
     * Create a request from the supplied superglobal values.
     *
     * If any argument is not supplied, the corresponding superglobal value will
     * be used.
     *
     * @param array|null $server _SERVER superglobal
     * @param array|null $query _GET superglobal
     * @param array|null $parsedBody _POST superglobal
     * @param array|null $cookies _COOKIE superglobal
     * @param array|null $files _FILES superglobal
     * @return uim.net.http.ServerRequest
     * @throws \InvalidArgumentException for invalid file values
     */
    static function fromGlobals(
        ?array $server = null,
        ?array $query = null,
        ?array $parsedBody = null,
        ?array $cookies = null,
        ?array $files = null
    ): ServerRequest {
        $server = normalizeServer($server ?: _SERVER);
        $uri = static::createUri($server);

        $webroot = "";
        $base = "";
        if ($uri instanceof CakeUri) {
            // Unwrap our shim for base and webroot.
            // For 5.x we should change the interface on createUri() to return a
            // tuple of [$uri, $base, $webroot] and remove the wrapper.
            $webroot = $uri.getWebroot();
            $base = $uri.getBase();
            $uri.getUri();
        }

        /** @psalm-suppress NoInterfaceProperties */
        $sessionConfig = (array)Configure::read("Session") + [
            "defaults": "php",
            "cookiePath": $webroot,
        ];
        $session = Session::create($sessionConfig);

        myServerRequest = new ServerRequest([
            "environment": $server,
            "uri": $uri,
            "cookies": $cookies ?: _COOKIE,
            "query": $query ?: _GET,
            "webroot": $webroot,
            "base": $base,
            "session": $session,
            "input": $server["CAKEPHP_INPUT"] ?? null,
        ]);

        myServerRequest = static::marshalBodyAndRequestMethod($parsedBody ?? _POST, myServerRequest);
        // This is required as `ServerRequest::scheme()` ignores the value of
        // `HTTP_X_FORWARDED_PROTO` unless `trustProxy` is enabled, while the
        // `Uri` instance intially created always takes values of `HTTP_X_FORWARDED_PROTO`
        // into account.
        $uri = myServerRequest.getUri().withScheme(myServerRequest.scheme());
        myServerRequest = myServerRequest.withUri($uri, true);

        return static::marshalFiles($files ?? _FILES, myServerRequest);
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
     * @param uim.net.http.ServerRequest myServerRequest Request instance.
     * @return uim.net.http.ServerRequest
     */
    protected static function marshalBodyAndRequestMethod(array $parsedBody, ServerRequest myServerRequest): ServerRequest
    {
        $method = myServerRequest.getMethod();
        $override = false;

        if (
            hasAllValues($method, ["PUT", "DELETE", "PATCH"], true) &&
            strpos((string)myServerRequest.contentType(), "application/x-www-form-urlencoded") == 0
        ) {
            $data = (string)myServerRequest.getBody();
            parse_str($data, $parsedBody);
        }
        if (myServerRequest.hasHeader("X-Http-Method-Override")) {
            $parsedBody["_method"] = myServerRequest.getHeaderLine("X-Http-Method-Override");
            $override = true;
        }

        myServerRequest = myServerRequest.withEnv("ORIGINAL_REQUEST_METHOD", $method);
        if (isset($parsedBody["_method"])) {
            myServerRequest = myServerRequest.withEnv("REQUEST_METHOD", $parsedBody["_method"]);
            unset($parsedBody["_method"]);
            $override = true;
        }

        if (
            $override &&
            !hasAllValues(myServerRequest.getMethod(), ["PUT", "POST", "DELETE", "PATCH"], true)
        ) {
            $parsedBody = null;
        }

        return myServerRequest.withParsedBody($parsedBody);
    }

    /**
     * Process uploaded files and move things onto the parsed body.
     *
     * @param array $files Files array for normalization and merging in parsed body.
     * @param uim.net.http.ServerRequest myServerRequest Request instance.
     * @return uim.net.http.ServerRequest
     */
    protected static function marshalFiles(array $files, ServerRequest myServerRequest): ServerRequest
    {
        $files = normalizeUploadedFiles($files);
        myServerRequest = myServerRequest.withUploadedFiles($files);

        $parsedBody = myServerRequest.getParsedBody();
        if (!is_array($parsedBody)) {
            return myServerRequest;
        }

        if (Configure::read("App.uploadedFilesAsObjects", true)) {
            $parsedBody = Hash::merge($parsedBody, $files);
        } else {
            // Make a flat map that can be inserted into body for BC.
            $fileMap = Hash::flatten($files);
            foreach ($fileMap as $key: $file) {
                $error = $file.getError();
                $tmpName = "";
                if ($error == UPLOAD_ERR_OK) {
                    $tmpName = $file.getStream().getMetadata("uri");
                }
                $parsedBody = Hash::insert($parsedBody, (string)$key, [
                    "tmp_name": $tmpName,
                    "error": $error,
                    "name": $file.getClientFilename(),
                    "type": $file.getClientMediaType(),
                    "size": $file.getSize(),
                ]);
            }
        }

        return myServerRequest.withParsedBody($parsedBody);
    }

    /**
     * Create a new server request.
     *
     * Note that server-params are taken precisely as given - no parsing/processing
     * of the given values is performed, and, in particular, no attempt is made to
     * determine the HTTP method or URI, which must be provided explicitly.
     *
     * @param string $method The HTTP method associated with the request.
     * @param \Psr\Http\messages.UriInterface|string $uri The URI associated with the request. If
     *     the value is a string, the factory MUST create a UriInterface
     *     instance based on it.
     * @param array $serverParams Array of SAPI parameters with which to seed
     *     the generated request instance.
     * @return \Psr\Http\messages.IServerRequest
     */
    function createServerRequest(string $method, $uri, array $serverParams = null): IServerRequest
    {
        $serverParams["REQUEST_METHOD"] = $method;
        $options = ["environment": $serverParams];

        if ($uri instanceof UriInterface) {
            $options["uri"] = $uri;
        } else {
            $options["url"] = $uri;
        }

        return new ServerRequest($options);
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
     * @return uim.net.http.Uri A constructed Uri
     */
    protected static function marshalUriFromSapi(array $server, array $headers): UriInterface
    {
        /** @psalm-suppress DeprecatedFunction */
        $uri = marshalUriFromSapi($server, $headers);
        [$base, $webroot] = static::getBase($uri, $server);

        // Look in PATH_INFO first, as this is the exact value we need prepared
        // by PHP.
        $pathInfo = Hash::get($server, "PATH_INFO");
        if ($pathInfo) {
            $uri = $uri.withPath($pathInfo);
        } else {
            $uri = static::updatePath($base, $uri);
        }

        if (!$uri.getHost()) {
            $uri = $uri.withHost("localhost");
        }

        return new CakeUri($uri, $base, $webroot);
    }

    /**
     * Updates the request URI to remove the base directory.
     *
     * @param string $base The base path to remove.
     * @param \Psr\Http\messages.UriInterface $uri The uri to update.
     * @return \Psr\Http\messages.UriInterface The modified Uri instance.
     */
    protected static function updatePath(string $base, UriInterface $uri): UriInterface
    {
        $path = $uri.getPath();
        if ($base != "" && strpos($path, $base) == 0) {
            $path = substr($path, strlen($base));
        }
        if ($path == "/index.php" && $uri.getQuery()) {
            $path = $uri.getQuery();
        }
        if (empty($path) || $path == "/" || $path == "//" || $path == "/index.php") {
            $path = "/";
        }
        $endsWithIndex = "/" ~ (Configure::read("App.webroot") ?: "webroot") ~ "/index.php";
        $endsWithLength = strlen($endsWithIndex);
        if (
            strlen($path) >= $endsWithLength &&
            substr($path, -$endsWithLength) == $endsWithIndex
        ) {
            $path = "/";
        }

        return $uri.withPath($path);
    }

    /**
     * Calculate the base directory and webroot directory.
     *
     * @param \Psr\Http\messages.UriInterface $uri The Uri instance.
     * @param array $server The SERVER data to use.
     * @return array An array containing the [baseDir, webroot]
     */
    protected static array getBase(UriInterface $uri, array $server) {
        aConfig = (array)Configure::read("App") + [
            "base": null,
            "webroot": null,
            "baseUrl": null,
        ];
        $base = aConfig["base"];
        $baseUrl = aConfig["baseUrl"];
        $webroot = aConfig["webroot"];

        if ($base != false && $base != null) {
            return [$base, $base ~ "/"];
        }

        if (!$baseUrl) {
            $base = dirname(Hash::get($server, "PHP_SELF"));
            // Clean up additional / which cause following code to fail..
            $base = preg_replace("#/+#", "/", $base);

            $indexPos = strpos($base, "/" ~ $webroot ~ "/index.php");
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

        $file = "/" ~ basename($baseUrl);
        $base = dirname($baseUrl);

        if ($base == DIRECTORY_SEPARATOR || $base == ".") {
            $base = "";
        }
        $webrootDir = $base ~ "/";

        $docRoot = Hash::get($server, "DOCUMENT_ROOT");
        $docRootContainsWebroot = strpos($docRoot, $webroot);

        if (!empty($base) || !$docRootContainsWebroot) {
            if (strpos($webrootDir, "/" ~ $webroot ~ "/") == false) {
                $webrootDir ~= $webroot ~ "/";
            }
        }

        return [$base . $file, $webrootDir];
    }
}
