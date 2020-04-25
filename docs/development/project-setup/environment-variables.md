---
path: "/docs/environment-variables"
title: "Environment Variables"
---


### Database configuration

Use the following values in database.yml which lives inside `config` directory.

```bash
development:
  <<: *default
  username: postgres
  password:
  database: chatwoot_dev
```

We use `dotenv-rails` gem to manage the environment variables. There is a file called `env.example` in the root directory of this project with all the environment variables set to empty value. You can set the correct values as per the following options. Once you set the values, you should rename the file to `.env` before you start the server.

### Configure FB Channel

To use FB Channel, you have to create an Facebook app in developer portal. You can find more details about creating FB channels [here](https://developers.facebook.com/docs/apps/#register)

```bash
FB_VERIFY_TOKEN=
FB_APP_SECRET=
FB_APP_ID=
```

### Configure emails

For development, you don't need an email provider. Chatwoot uses [letter-opener](https://github.com/ryanb/letter_opener) gem to test emails locally

For production use, use the following variables to set SMTP server.

```bash
MAILER_SENDER_EMAIL=
SMTP_ADDRESS=
SMTP_USERNAME=
SMTP_PASSWORD=
```

### Configure frontend URL

Provide the following value as frontend url

```bash
FRONTEND_URL='http://localhost:3000'
```

### Configure storage

Chatwoot uses [active storage](https://edgeguides.rubyonrails.org/active_storage_overview.html) for storing attachments. The default storage option is the local storage on your server. 

But you can change it to use any of the cloud providers like amazon s3, microsoft azure and google gcs etc. Refer [configuring cloud storage](./configuring-cloud-storage) for additional environment variables required.

```bash
ACTIVE_STORAGE_SERVICE='local'
```

### Configure Redis

For development, you can use the following url to connect to redis.

```bash
REDIS_URL='redis:://127.0.0.1:6379'
```

To authenticate redis connections made by app server and sidekiq, if it's protected by a password, use the following
environment variable to set the password.

```bash
REDIS_PASSWORD=
```

### Configure Postgres host

You can set the following environment variable to set the host for postgres.

```bash
POSTGRES_HOST=localhost
```

For production and testing you have the following variables for defining the postgres database,
username and password.

```bash
POSTGRES_DATABASE=chatwoot_production
POSTGRES_USERNAME=admin
POSTGRES_PASSWORD=password
```

### Rails Production Variables

For production deployment, you have to set the following variables

```bash
RAILS_ENV=production
SECRET_KEY_BASE=replace_with_your_own_secret_string
```

You can generate `SECRET_KEY_BASE` using `rake secret` command from project root folder.

### Rails Logging Variables

By default chatwoot will capture `info` level logs in production. Ref [rails docs](https://guides.rubyonrails.org/debugging_rails_applications.html#log-levels) for the additional log level options.  
We will also retain 1 GB of your recent logs and your last shifted log file.  
You can fine tune these settings using the following environment variables

```bash
# possible values: 'debug', 'info', 'warn', 'error', 'fatal' and 'unknown'
LOG_LEVEL=debug
# value in megabytes
LOG_SIZE= 1024
```