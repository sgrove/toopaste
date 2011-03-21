Geekpaste
=========

Simple pastebin forked from [zapnap](https://github.com/zapnap/toopaste)
to learn Sinatra.

Live Demo: [paste.geekosphere.org](http://paste.geekosphere.org)

[Contributors](https://github.com/jessor/toopaste/contributors)


Hints:
------

* Change password in config, then delete snippets from the cli with

        curl -u <user>:<password> -X DELETE http://domain.tld/<snippetid>


TODO:
-----

* tags
* line wrapping?
* spam protection
