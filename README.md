# gh-tg-notify

## About

This is a GitHub webhook which notifies in your Telegram group, whenever a new commit is pushed.
It uses bash and CGI.

## .env example

This file should be in the same directory as script

```sh
TG_TOKEN="...:..."
```

## Setup notifications

- Open webhook settings in your GitHub repository
- Add a new webhook with `URL of script?chat=your_chat_id`, and content-type application/json
