Intercom Challenges
===================
* Solution for the first challenge is in the textfile itself: `1-IntercomSettings_examples.txt`
* Solution for second problem is in the `0-instructions.txt` file.
* Solution for the third problem is made on the original file. Also included are some basic tests. `gem install rspec` and `gem install sqlite3`, then type `rspec` to run actual tests.
* The way the tests are set up is probably not ideal; it took some research and tinkering to mimic an activerecord 'environment' outside of rails. There's probably a better way to do this (the way the database is setup doesn't actually work quite correctly), perhaps have keep a rails app skeleton set up and port the code to mimic the user's rails app. Or alternatively, mock and stub anything and everything within the tests.
