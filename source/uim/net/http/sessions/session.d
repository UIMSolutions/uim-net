module uim.net.http;

import uim.net;

/**
 * This class is a wrapper for the native PHP session functions. It provides
 * several defaults for the most common session configuration
 * via external handlers and helps with using session in CLI without any warnings.
 *
 * Sessions can be created from the defaults using `Session::create()` or you can get
 * an instance of a new session by just instantiating this class and passing the complete
 * options you want to use.
 *
 * When specific options are omitted, this class will take its defaults from the configuration
 * values from the `session.*` directives in php.ini. This class will also alter such
 * directives when configuration values are provided.
 */
class Session {
    /**
     * The Session handler instance used as an engine for persisting the session data.
     *
     * @var \SessionHandlerInterface
     */
    protected _engine;

    // Indicates whether the sessions has already started
    protected bool _started;

    // The time in seconds the session will be valid for
    protected int _lifetime;

    /**
     * Whether this session is running under a CLI environment
     */
    protected bool _isCLI = false;

    /**
     * Returns a new instance of a session after building a configuration bundle for it.
     * This function allows an options array which will be used for configuring the session
     * and the handler to be used. The most important key in the configuration array is
     * `defaults`, which indicates the set of configurations to inherit from, the possible
     * defaults are:
     *
     * - php: just use session as configured in php.ini
     * - cache: Use the UIM caching system as an storage for the session, you will need
     *   to pass the `config` key with the name of an already configured Cache engine.
     * - database: Use the UIM ORM to persist and manage sessions. By default this requires
     *   a table in your database named `sessions` or a `model` key in the configuration
     *   to indicate which Table object to use.
     * - cake: Use files for storing the sessions, but let UIM manage them and decide
     *   where to store them.
     *
     * The full list of options follows:
     *
     * - defaults: either "php", "database", "cache" or "cake" as explained above.
     * - handler: An array containing the handler configuration
     * - ini: A list of php.ini directives to set before the session starts.
     * - timeout: The time in minutes the session should stay active
     *
     * @param array $sessionConfig Session config.
     * @return static
     * @see uim.net.http.Session::__construct()
     */
    static function create(array $sessionConfig = null) {
        if (isset($sessionConfig["defaults"])) {
            $defaults = static::_defaultConfig($sessionConfig["defaults"]);
            if ($defaults) {
                $sessionConfig = Hash::merge($defaults, $sessionConfig);
            }
        }

        if (
            !isset($sessionConfig["ini"]["session.cookie_secure"])
            && env("HTTPS")
            && ini_get("session.cookie_secure") != 1
        ) {
            $sessionConfig["ini"]["session.cookie_secure"] = 1;
        }

        if (
            !isset($sessionConfig["ini"]["session.name"])
            && isset($sessionConfig["cookie"])
        ) {
            $sessionConfig["ini"]["session.name"] = $sessionConfig["cookie"];
        }

        if (!isset($sessionConfig["ini"]["session.use_strict_mode"]) && ini_get("session.use_strict_mode") != 1) {
            $sessionConfig["ini"]["session.use_strict_mode"] = 1;
        }

        if (!isset($sessionConfig["ini"]["session.cookie_httponly"]) && ini_get("session.cookie_httponly") != 1) {
            $sessionConfig["ini"]["session.cookie_httponly"] = 1;
        }

        return new static($sessionConfig);
    }

    /**
     * Get one of the prebaked default session configurations.
     *
     * @param string aName Config name.
     * @return array|false
     */
    protected static function _defaultConfig(string aName) {
        $tmp = defined("TMP") ? TMP : sys_get_temp_dir() . DIRECTORY_SEPARATOR;
        $defaults = [
            "php": [
                "ini": [
                    "session.use_trans_sid": 0,
                ],
            ],
            "cake": [
                "ini": [
                    "session.use_trans_sid": 0,
                    "session.serialize_handler": "php",
                    "session.use_cookies": 1,
                    "session.save_path": $tmp ~ "sessions",
                    "session.save_handler": "files",
                ],
            ],
            "cache": [
                "ini": [
                    "session.use_trans_sid": 0,
                    "session.use_cookies": 1,
                ],
                "handler": [
                    "engine": "CacheSession",
                    "config": "default",
                ],
            ],
            "database": [
                "ini": [
                    "session.use_trans_sid": 0,
                    "session.use_cookies": 1,
                    "session.serialize_handler": "php",
                ],
                "handler": [
                    "engine": "DatabaseSession",
                ],
            ],
        ];

        if (isset($defaults[$name])) {
            if (
                PHP_VERSION_ID >= 70300
                && ($name != "php" || empty(ini_get("session.cookie_samesite")))
            ) {
                $defaults["php"]["ini"]["session.cookie_samesite"] = "Lax";
            }

            return $defaults[$name];
        }

        return false;
    }

    /**
     * Constructor.
     *
     * ### Configuration:
     *
     * - timeout: The time in minutes the session should be valid for.
     * - cookiePath: The url path for which session cookie is set. Maps to the
     *   `session.cookie_path` php.ini config. Defaults to base path of app.
     * - ini: A list of php.ini directives to change before the session start.
     * - handler: An array containing at least the `engine` key. To be used as the session
     *   engine for persisting data. The rest of the keys in the array will be passed as
     *   the configuration array for the engine. You can set the `engine` key to an already
     *   instantiated session handler object.
     *
     * @param array<string, mixed> aConfig The Configuration to apply to this session object
     */
    this(Json aConfig = null) {
        aConfig += [
            "timeout": null,
            "cookie": null,
            "ini": [],
            "handler": [],
        ];

        if (aConfig["timeout"]) {
            aConfig["ini"]["session.gc_maxlifetime"] = 60 * aConfig["timeout"];
        }

        if (aConfig["cookie"]) {
            aConfig["ini"]["session.name"] = aConfig["cookie"];
        }

        if (!isset(aConfig["ini"]["session.cookie_path"])) {
            $cookiePath = empty(aConfig["cookiePath"]) ? "/" : aConfig["cookiePath"];
            aConfig["ini"]["session.cookie_path"] = $cookiePath;
        }

        this.options(aConfig["ini"]);

        if (!empty(aConfig["handler"])) {
            $class = aConfig["handler"]["engine"];
            unset(aConfig["handler"]["engine"]);
            this.engine($class, aConfig["handler"]);
        }

        _lifetime = (int)ini_get("session.gc_maxlifetime");
        _isCLI = (PHP_SAPI == "cli" || PHP_SAPI == "phpdbg");
        session_register_shutdown();
    }

    /**
     * Sets the session handler instance to use for this session.
     * If a string is passed for the first argument, it will be treated as the
     * class name and the second argument will be passed as the first argument
     * in the constructor.
     *
     * If an instance of a SessionHandlerInterface is provided as the first argument,
     * the handler will be set to it.
     *
     * If no arguments are passed it will return the currently configured handler instance
     * or null if none exists.
     *
     * @param \SessionHandlerInterface|string|null $class The session handler to use
     * @param array<string, mixed> $options the options to pass to the SessionHandler constructor
     * @return \SessionHandlerInterface|null
     * @throws \InvalidArgumentException
     */
    function engine($class = null, STRINGAA someOptions = null): ?SessionHandlerInterface
    {
        if ($class == null) {
            return _engine;
        }
        if ($class instanceof SessionHandlerInterface) {
            return this.setEngine($class);
        }

        /** @var class-string<\SessionHandlerInterface>|null $className */
        $className = App::className($class, "Http/Session");
        if ($className == null) {
            throw new InvalidArgumentException(
                sprintf("The class '%s' does not exist and cannot be used as a session engine", $class)
            );
        }

        return this.setEngine(new $className($options));
    }

    /**
     * Set the engine property and update the session handler in PHP.
     *
     * @param \SessionHandlerInterface $handler The handler to set
     * @return \SessionHandlerInterface
     */
    protected function setEngine(SessionHandlerInterface $handler): SessionHandlerInterface
    {
        if (!headers_sent() && session_status() != \PHP_SESSION_ACTIVE) {
            session_set_save_handler($handler, false);
        }

        return _engine = $handler;
    }

    /**
     * Calls ini_set for each of the keys in `$options` and set them
     * to the respective value in the passed array.
     *
     * ### Example:
     *
     * ```
     * $session.options(["session.use_cookies": 1]);
     * ```
     *
     * @param array<string, mixed> $options Ini options to set.
     * @return void
     * @throws \UIMException if any directive could not be set
     */
    void options(STRINGAA someOptions) {
        if (session_status() == \PHP_SESSION_ACTIVE || headers_sent()) {
            return;
        }

        foreach ($options as $setting: $value) {
            if (ini_set($setting, (string)$value) == false) {
                throw new UIMException(
                    sprintf("Unable to configure the session, setting %s failed.", $setting)
                );
            }
        }
    }

    /**
     * Starts the Session.
     *
     * @return bool True if session was started
     * @throws \UIMException if the session was already started
     */
    bool start() {
        if (_started) {
            return true;
        }

        if (_isCLI) {
            _SESSION = null;
            this.id("cli");

            return _started = true;
        }

        if (session_status() == \PHP_SESSION_ACTIVE) {
            throw new UIMException("Session was already started");
        }

        if (ini_get("session.use_cookies") && headers_sent()) {
            return false;
        }

        if (!session_start()) {
            throw new UIMException("Could not start the session");
        }

        _started = true;

        if (_timedOut()) {
            this.destroy();

            return this.start();
        }

        return _started;
    }

    /**
     * Write data and close the session
     *
     * @return true
     */
    bool close() {
        if (!_started) {
            return true;
        }

        if (_isCLI) {
            _started = false;

            return true;
        }

        if (!session_write_close()) {
            throw new UIMException("Could not close the session");
        }

        _started = false;

        return true;
    }

    /**
     * Determine if Session has already been started.
     *
     * @return bool True if session has been started.
     */
    bool started() {
        return _started || session_status() == \PHP_SESSION_ACTIVE;
    }

    /**
     * Returns true if given variable name is set in session.
     *
     * @param string|null $name Variable name to check for
     * @return bool True if variable is there
     */
    bool check(Nullable!string aName = null) {
        if (_hasSession() && !this.started()) {
            this.start();
        }

        if (!isset(_SESSION)) {
            return false;
        }

        if ($name == null) {
            return (bool)_SESSION;
        }

        return Hash::get(_SESSION, $name) != null;
    }

    /**
     * Returns given session variable, or all of them, if no parameters given.
     *
     * @param string|null $name The name of the session variable (or a path as sent to Hash.extract)
     * @param mixed $default The return value when the path does not exist
     * @return mixed|null The value of the session variable, or default value if a session
     *   is not available, can"t be started, or provided $name is not found in the session.
     */
    function read(Nullable!string aName = null, $default = null) {
        if (_hasSession() && !this.started()) {
            this.start();
        }

        if (!isset(_SESSION)) {
            return $default;
        }

        if ($name == null) {
            return _SESSION ?: [];
        }

        return Hash::get(_SESSION, $name, $default);
    }

    /**
     * Returns given session variable, or throws Exception if not found.
     *
     * @param string aName The name of the session variable (or a path as sent to Hash.extract)
     * @throws \UIMException
     * @return mixed|null
     */
    function readOrFail(string aName) {
        if (!this.check($name)) {
            throw new UIMException(sprintf("Expected session key '%s' not found.", $name));
        }

        return this.read($name);
    }

    /**
     * Reads and deletes a variable from session.
     *
     * @param string aName The key to read and remove (or a path as sent to Hash.extract).
     * @return mixed|null The value of the session variable, null if session not available,
     *   session not started, or provided name not found in the session.
     */
    function consume(string aName) {
        if (empty($name)) {
            return null;
        }
        $value = this.read($name);
        if ($value != null) {
            /** @psalm-suppress InvalidScalarArgument */
            _overwrite(_SESSION, Hash::remove(_SESSION, $name));
        }

        return $value;
    }

    /**
     * Writes value to given session variable name.
     *
     * @param array|string aName Name of variable
     * @param mixed $value Value to write
     */
    void write($name, $value = null) {
        if (!this.started()) {
            this.start();
        }

        if (!is_array($name)) {
            $name = [$name: $value];
        }

        $data = _SESSION ?? [];
        foreach ($name as $key: $val) {
            $data = Hash::insert($data, $key, $val);
        }

        /** @psalm-suppress PossiblyNullArgument */
        _overwrite(_SESSION, $data);
    }

    /**
     * Returns the session id.
     * Calling this method will not auto start the session. You might have to manually
     * assert a started session.
     *
     * Passing an id into it, you can also replace the session id if the session
     * has not already been started.
     * Note that depending on the session handler, not all characters are allowed
     * within the session id. For example, the file session handler only allows
     * characters in the range a-z A-Z 0-9 , (comma) and - (minus).
     *
     * @param string|null $id Id to replace the current session id
     * @return string Session id
     */
    string id(Nullable!string $id = null) {
        if ($id != null && !headers_sent()) {
            session_id($id);
        }

        return session_id();
    }

    /**
     * Removes a variable from session.
     *
     * @param string aName Session variable to remove
     */
    void delete(string aName) {
        if (this.check($name)) {
            /** @psalm-suppress InvalidScalarArgument */
            _overwrite(_SESSION, Hash::remove(_SESSION, $name));
        }
    }

    /**
     * Used to write new data to _SESSION, since PHP doesn"t like us setting the _SESSION var itself.
     *
     * @param array $old Set of old variables: values
     * @param array $new New set of variable: value
     */
    protected void _overwrite(array &$old, array $new) {
        foreach ($old as $key: $var) {
            if (!isset($new[$key])) {
                unset($old[$key]);
            }
        }

        foreach ($new as $key: $var) {
            $old[$key] = $var;
        }
    }

    /**
     * Helper method to destroy invalid sessions.
     */
    void destroy() {
        if (_hasSession() && !this.started()) {
            this.start();
        }

        if (!_isCLI && session_status() == \PHP_SESSION_ACTIVE) {
            session_destroy();
        }

        _SESSION = null;
        _started = false;
    }

    /**
     * Clears the session.
     *
     * Optionally it also clears the session id and renews the session.
     *
     * @param bool $renew If session should be renewed, as well. Defaults to false.
     */
    void clear(bool $renew = false) {
        _SESSION = null;
        if ($renew) {
            this.renew();
        }
    }

    /**
     * Returns whether a session exists
     */
    protected bool _hasSession() {
        return !ini_get("session.use_cookies")
            || isset(_COOKIE[session_name()])
            || _isCLI
            || (ini_get("session.use_trans_sid") && isset(_GET[session_name()]));
    }

    /**
     * Restarts this session.
     */
    void renew() {
        if (!_hasSession() || _isCLI) {
            return;
        }

        this.start();
        $params = session_get_cookie_params();
        setcookie(
            session_name(),
            "",
            time() - 42000,
            $params["path"],
            $params["domain"],
            $params["secure"],
            $params["httponly"]
        );

        if (session_id() != "") {
            session_regenerate_id(true);
        }
    }

    /**
     * Returns true if the session is no longer valid because the last time it was
     * accessed was after the configured timeout.
     */
    protected bool _timedOut() {
        $time = this.read("Config.time");
        $result = false;

        $checkTime = $time != null && _lifetime > 0;
        if ($checkTime && (time() - (int)$time > _lifetime)) {
            $result = true;
        }

        this.write("Config.time", time());

        return $result;
    }
}
