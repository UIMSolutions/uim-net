module uim.net.http.clients;

import uim.net;
@safe:

/**
 * Provides an interface for building
 * multipart/form-encoded message bodies.
 *
 * Used by Http\Client to upload POST/PUT data
 * and files.
 */
class FormData : Countable {
    // Boundary marker.
    protected string _boundary;

    // Whether this formdata object has attached files.
    protected bool _hasFile = false;

    // Whether this formdata object has a complex part.
    protected bool _hasComplexPart = false;

    // The parts in the form data.
    protected FormDataPart[] _parts = null;

    // Get the boundary marker
    string boundary() {
      if (_boundary) {
        return _boundary;
      }
      _boundary = md5(uniqid((string)time()));

      return _boundary;
    }

    /**
     * Method for creating new instances of Part
     *
     * @param string myName The name of the part.
     * @param string myValue The value to add.
     * returns DHTPFormDataPart
     */
    DHTPFormDataPart newPart(string myName, string myValue) {
      return new FormDataPart(myName, myValue);
    }

    /**
     * Add a new part to the data.
     *
     * The value for a part can be a string, array, int,
     * float, filehandle, or object implementing __toString()
     *
     * If the myValue is an array, multiple parts will be added.
     * Files will be read from their current position and saved in memory.
     *
     * @param uim.net.http.Client\FormDataPart|string myName The name of the part to add,
     *   or the part data object.
     * @param mixed myValue The value for the part.
     * @return this
     */
    function add(myName, myValue = null) {
      if (is_string(myName)) {
        if (is_array(myValue)) {
            this.addRecursive(myName, myValue);
        } elseif (is_resource(myValue)) {
            this.addFile(myName, myValue);
        } else {
            _parts ~= this.newPart(myName, (string)myValue);
        }
      } else {
          _hasComplexPart = true;
          _parts ~= myName;
      }

      return this;
    }

    /**
     * Add multiple parts at once.
     *
     * Iterates the parameter and adds all the key/values.
     *
     * @return this
     */
    O addMany(this O)(array dataToAdd) {
      foreach (myName, myValue; dataToAdd) {
          this.add(myName, myValue);
      }

      return cst(O)this;
    }

    /**
     * Add either a file reference (string starting with @)
     * or a file handle.
     *
     * @param string myName The name to use.
     * @param mixed myValue Either a string filename, or a filehandle.
     * returns DHTPFormDataPart
     */
    DHTPFormDataPart addFile(string myName, myValue) {
      _hasFile = true;

      myfilename = false;
      myContentsType = "application/octet-stream";
      if (is_resource(myValue)) {
        myContents = stream_get_contents(myValue);
        if (stream_is_local(myValue)) {
          $finfo = new finfo(FILEINFO_MIME);
          $metadata = stream_get_meta_data(myValue);
          myContentsType = $finfo.file($metadata["uri"]);
          myfilename = basename($metadata["uri"]);
        }
      } else {
        $finfo = new finfo(FILEINFO_MIME);
        myValue = substr(myValue, 1);
        myfilename = basename(myValue);
        myContents = file_get_contents(myValue);
        myContentsType = $finfo.file(myValue);
      }
      $part = this.newPart(myName, myContents);
      $part.type(myContentsType);
      if (myfilename) {
          $part.filename(myfilename);
      }
      this.add($part);

      return $part;
    }

    /**
     * Recursively add data.
     *
     * @param string myName The name to use.
     * @param mixed myValue The value to add.
     */
    void addRecursive(string myName, myValue) {
      foreach (myValue as myKey: myValue) {
        myKey = myName ~ "[" ~ myKey ~ "]";
        this.add(myKey, myValue);
      }
    }

    /**
     * Returns the count of parts inside this object.
     */
    size_t count() {
      return count(_parts);
    }

    /**
     * Check whether the current payload
     * has any files.
     *
     * @return bool Whether there is a file in this payload.
     */
    bool hasFile() {
      return _hasFile;
    }

    /**
     * Check whether the current payload
     * is multipart.
     *
     * A payload will become multipart when you add files
     * or use add() with a Part instance.
     *
     * @return bool Whether the payload is multipart.
     */
    bool isMultipart() {
      return this.hasFile() || _hasComplexPart;
    }

    /**
     * Get the content type for this payload.
     *
     * If this object contains files, `multipart/form-data` will be used,
     * otherwise `application/x-www-form-urlencoded` will be used.
     */
    string contentType() {
      if (!this.isMultipart()) {
          return "application/x-www-form-urlencoded";
      }

      return "multipart/form-data; boundary=" ~ this.boundary();
    }

    /**
     * Converts the FormData and its parts into a string suitable
     * for use in an HTTP request.
     */
    string toString() {
      if (this.isMultipart()) {
        $boundary = this.boundary();
        $out = "";
        foreach (_parts as $part) {
            $out ~= "--$boundary\r\n";
            $out ~= (string)$part;
            $out ~= "\r\n";
        }
        $out ~= "--$boundary--\r\n";

        return $out;
      }
      myData = null;
      foreach (_parts as $part) {
        myData[$part.name()] = $part.value();
      }

      return http_build_query(myData);
    }
}
