module uim.net.https\Exception;

@safe:
import uim.net;

/**
 * Missing Controller exception - used when a controller
 * cannot be found.
 */
class MissingControllerException : UIMException {

    protected _defaultCode = 404;


    protected _messageTemplate = "Controller class %s could not be found.";
}
