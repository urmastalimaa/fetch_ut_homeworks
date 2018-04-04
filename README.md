# Goal

The goal of this project is to programmatically fetch and prepare a list of
University of Tartu homeworks for grading.

# Usage

```sh
bundle install
bundle exec ruby download_homework.rb --help
```

# Session ID

Using this tool requires logging in to courses.cs.ut.ee and extracting you
COURSESSID cookie. The value of the cookie must be provided as the session_id
parameter.
