/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.net.http.responseemitter;

import uim.net;
@safe:

/**
 * Emits a Response to the PHP Server API.
 *
 * This emitter offers a few changes from the emitters offered by
 * diactoros:
 *
 * - It logs headers sent using UIM"s logging tools.
 * - Cookies are emitted using setcookie() to not conflict with ext/session
 */
class ResponseEmitter : IEmitter {
    /**
     * Maximum output buffering size for each iteration.
     */
    protected int $maxBufferLength;

    /**
     * Constructor
     *
     * @param int $maxBufferLength Maximum output buffering size for each iteration.
     */
    this(int $maxBufferLength = 8192) {
        this.maxBufferLength = $maxBufferLength;
    }

    /**
     * Emit a response.
     *
     * Emits a response, including status line, headers, and the message body,
     * according to the environment.
     *
     * @param \Psr\Http\messages.IResponse $response The response to emit.
     */
    bool emit(IResponse $response) {
        $file = "";
        $line = 0;
        if (headers_sent($file, $line)) {
            $message = "Unable to emit headers. Headers sent in file=$file line=$line";
            trigger_error($message, E_USER_WARNING);
        }

        this.emitStatusLine($response);
        this.emitHeaders($response);
        this.flush();

        $range = this.parseContentRange($response.getHeaderLine("Content-Range"));
        if (is_array($range)) {
            this.emitBodyRange($range, $response);
        } else {
            this.emitBody($response);
        }

        if (function_exists("fastcgi_finish_request")) {
            fastcgi_finish_request();
        }

        return true;
    }

    /**
     * Emit the message body.
     *
     * @param \Psr\Http\messages.IResponse $response The response to emit
     */
    protected void emitBody(IResponse $response) {
        if (hasAllValues($response.getStatusCode(), [204, 304], true)) {
            return;
        }
        $body = $response.getBody();

        if (!$body.isSeekable()) {
            writeln($body;

            return;
        }

        $body.rewind();
        while (!$body.eof()) {
            writeln($body.read(this.maxBufferLength);
        }
    }

    /**
     * Emit a range of the message body.
     *
     * @param array $range The range data to emit
     * @param \Psr\Http\messages.IResponse $response The response to emit
     */
    protected void emitBodyRange(array $range, IResponse $response) {
        [, $first, $last] = $range;

        $body = $response.getBody();

        if (!$body.isSeekable()) {
            $contents = $body.getContents();
            writeln(substr($contents, $first, $last - $first + 1);

            return;
        }

        $body = new RelativeStream($body, $first);
        $body.rewind();
        $pos = 0;
        $length = $last - $first + 1;
        while (!$body.eof() && $pos < $length) {
            if ($pos + this.maxBufferLength > $length) {
                writeln($body.read($length - $pos);
                break;
            }

            writeln($body.read(this.maxBufferLength);
            $pos = $body.tell();
        }
    }

    /**
     * Emit the status line.
     *
     * Emits the status line using the protocol version and status code from
     * the response; if a reason phrase is available, it, too, is emitted.
     *
     * @param \Psr\Http\messages.IResponse $response The response to emit
     */
    protected void emitStatusLine(IResponse $response) {
        $reasonPhrase = $response.getReasonPhrase();
        header(sprintf(
            "HTTP/%s %d%s",
            $response.getProtocolVersion(),
            $response.getStatusCode(),
            ($reasonPhrase ? " " ~ $reasonPhrase : "")
        ));
    }

    /**
     * Emit response headers.
     *
     * Loops through each header, emitting each; if the header value
     * is an array with multiple values, ensures that each is sent
     * in such a way as to create aggregate headers (instead of replace
     * the previous).
     *
     * @param \Psr\Http\messages.IResponse $response The response to emit
     */
    protected void emitHeaders(IResponse $response) {
        $cookies = null;
        if (method_exists($response, "getCookieCollection")) {
            $cookies = iterator_to_array($response.getCookieCollection());
        }

        foreach ($response.getHeaders() as $name: $values) {
            if (strtolower($name) == "set-cookie") {
                $cookies = array_merge($cookies, $values);
                continue;
            }
            $first = true;
            foreach ($values as $value) {
                header(sprintf(
                    "%s: %s",
                    $name,
                    $value
                ), $first);
                $first = false;
            }
        }

        this.emitCookies($cookies);
    }

    /**
     * Emit cookies using setcookie()
     *
     * @param array<uim.net.http\Cookie\CookieInterface|string> $cookies An array of cookies.
     */
    protected void emitCookies(array $cookies) {
        foreach ($cookies as $cookie) {
            this.setCookie($cookie);
        }
    }

    /**
     * Helper methods to set cookie.
     *
     * @param uim.net.http.Cookie\CookieInterface|string $cookie Cookie.
     */
    protected bool setCookie($cookie) {
        if (is_string($cookie)) {
            $cookie = Cookie::createFromHeaderString($cookie, ["path": ""]);
        }

        if (PHP_VERSION_ID >= 70300) {
            /** @psalm-suppress InvalidArgument */
            return setcookie($cookie.getName(), $cookie.getScalarValue(), $cookie.getOptions());
        }

        $path = $cookie.getPath();
        $sameSite = $cookie.getSameSite();
        if ($sameSite != null) {
            // Temporary hack for PHP 7.2 to set "SameSite" attribute
            // https://stackoverflow.com/questions/39750906/php-setcookie-samesite-strict
            $path ~= "; samesite=" ~ $sameSite;
        }

        return setcookie(
            $cookie.getName(),
            $cookie.getScalarValue(),
            $cookie.getExpiresTimestamp() ?: 0,
            $path,
            $cookie.getDomain(),
            $cookie.isSecure(),
            $cookie.isHttpOnly()
        );
    }

    /**
     * Loops through the output buffer, flushing each, before emitting
     * the response.
     *
     * @param int|null $maxBufferLevel Flush up to this buffer level.
     */
    protected void flush(Nullable!int $maxBufferLevel = null) {
        if ($maxBufferLevel == null) {
            $maxBufferLevel = ob_get_level();
        }

        while (ob_get_level() > $maxBufferLevel) {
            ob_end_flush();
        }
    }

    /**
     * Parse content-range header
     * https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.16
     *
     * @param string $header The Content-Range header to parse.
     * @return array|false [unit, first, last, length]; returns false if no
     *     content range or an invalid content range is provided
     */
    protected function parseContentRange(string $header) {
        if (preg_match("/(?P<unit>[\w]+)\s+(?P<first>\d+)-(?P<last>\d+)\/(?P<length>\d+|\*)/", $header, $matches)) {
            return [
                $matches["unit"],
                (int)$matches["first"],
                (int)$matches["last"],
                $matches["length"] == "*" ? "*" : (int)$matches["length"],
            ];
        }

        return false;
    }
}
