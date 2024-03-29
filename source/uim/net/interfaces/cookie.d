module uim.net.interfaces.cookie;

import uim.net;
@safe:

// Cookie Interface
interface ICookie {
    // Expires attribute format.
    const string EXPIRES_FORMAT = "D, d-M-Y H:i:s T";

    // SameSite attribute value: Lax
    const string SAMESITE_LAX = "Lax";

    // SameSite attribute value: Strict
    const string SAMESITE_STRICT = "Strict";

    // SameSite attribute value: None
    const string SAMESITE_NONE = "None";

    // Valid values for "SameSite" attribute.
    const string[] SAMESITE_VALUES = [
        self::SAMESITE_LAX,
        self::SAMESITE_STRICT,
        self::SAMESITE_NONE,
    ];

    /**
     * Sets the cookie name
     *
     * @param string myName Name of the cookie
     * @return static
     */
    void withName(string myName);

    // Gets the cookie name
    string name();

    // Gets the cookie value
    auto Json value();

    /**
     * Gets the cookie value as scalar.
     *
     * This will collapse any complex data in the cookie with json_encode()
     *
     * @return mixed
     */
    auto getScalarValue();

    /**
     * Create a cookie with an updated value.
     *
     * @param array|string myValue Value of the cookie to set
     * @return static
     */
    function withValue(myValue);

    // Get the id for a cookie. Cookies are unique across name, domain, path tuples.
    string id();

    // Get the path attribute.
    string pPath();

    /**
     * Create a new cookie with an updated path
     *
     * @param string myPath Sets the path
     * @return static
     */
    function withPath(string myPath);

    // Get the domain attribute.
    string domain();

    /**
     * Create a cookie with an updated domain
     *
     * @param string domain Domain to set
     * @return static
     */
    function withDomain(string domain);

    /**
     * Get the current expiry time
     *
     * @return \DateTime|\DateTimeImmutable|null Timestamp of expiry or null
     */
    auto getExpiry();

    // Get the timestamp from the expiration time
    int getExpiresTimestamp();

    // Builds the expiration value part of the header string
    string getFormattedExpires();

    /**
     * Create a cookie with an updated expiration date
     *
     * @param \DateTime|\DateTimeImmutable $dateTime Date time object
     * @return static
     */
    function withExpiry($dateTime);

    // Create a new cookie that will virtually never expire.
    function withNeverExpire();

    /**
     * Create a new cookie that will expire/delete the cookie from the browser.
     *
     * This is done by setting the expiration time to 1 year ago
     *
     * @return static
     */
    function withExpired();

    /**
     * Check if a cookie is expired when compared to $time
     *
     * Cookies without an expiration date always return false.
     *
     * @param \DateTime|\DateTimeImmutable $time The time to test against. Defaults to "now" in UTC.
     */
    bool isExpired($time = null);

    // Check if the cookie is HTTP only
    bool isHttpOnly();

    /**
     * Create a cookie with HTTP Only updated
     *
     * @param bool $httpOnly HTTP Only
     * @return static
     */
    function withHttpOnly(bool $httpOnly);

    // Check if the cookie is secure
    bool isSecure();

    // Create a cookie with Secure updated
    void withSecure(bool secureMode);

    // Get the SameSite attribute.
    string sameSite();

    /**
     * Create a cookie with an updated SameSite option.
     *
     * @param string|null $sameSite Value for to set for Samesite option.
     *   One of ICookie::SAMESITE_* constants.
     * @return static
     */
    function withSameSite(Nullable!string sameSite);

    // Get cookie options
    Json[string] getOptions();

    /**
     * Get cookie data as array.
     *
     * @return array<string, mixed> With keys `name`, `value`, `expires` etc. options.
     */
    array toArray();

    // Returns the cookie as header value
    string toHeaderValue();
}
