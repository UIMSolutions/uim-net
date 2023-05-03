/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.net.https\Exception;

use Throwable;

/**
 * Represents an HTTP 405 error.
 */
class MethodNotAllowedException : HttpException {

    protected _defaultCode = 405;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given "Method Not Allowed" will be the message
     * @param int|null $code Status code, defaults to 405
     * @param \Throwable|null $previous The previous exception.
     */
    this(Nullable!string myMessage = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty(myMessage)) {
            myMessage = "Method Not Allowed";
        }
        super.this(myMessage, $code, $previous);
    }
}
