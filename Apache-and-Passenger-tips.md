If you encounter issues with images, such as thumbnails, not rendering and you are deploying Hyku via Apache and/or Passenger, you might try the following:

* Use the `AllowEncodedSlashes NoDecode` directive in your Apache HTTPD config (e.g., within the `VirtualHost`)
* Include `PassengerAllowEncodedSlashes on` in Passenger's config file