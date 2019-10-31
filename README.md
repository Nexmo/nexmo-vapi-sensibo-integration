# Nexmo Voice API and Sensibo AC Controller Integration

A Rails application that provides your air conditioner unit with a phone number. Call your air conditioner and get relevant information on its current state, and change its settings without needing access to any external mobile or web applications.

* [Dependencies](#requirements)
* [Installation and Usage](#installation-and-usage)
* [Contributing](#contributing)
* [License](#license)

## Dependencies

* [Nexmo VAPI](https://developer.nexmo.com/voice/voice-api/overview)
* [Sensibo API](https://sensibo.github.io/)

## Installation and Usage

In order to properly use this application you need to create accounts with:

* [Nexmo](https://dashboard.nexmo.com)
* [Sensibo](https://home.sensibo.com)

You will need the relevant API credentials from each of those services for full functionality. Once you have your API credentials, you can enter them in `.env.sample` and rename the file to `.env`. 

This application connects your Sensibo powered air conditioner to a Nexmo phone number. As such, you must sign up for a [Nexmo account](https://dashboard.nexmo.com) and provision a Nexmo phone number from the dashboard. Once you have provisioned a number, you then need to create a Voice application from the dashboard and link your new application to your new number from within the applicatipn's dashboard settings. Add your `NEXMO_APPLICATION_ID` and `NEXMO_NUMBER` to your `.env` file.

To start the application execute `rails s` from the command line. This will initiate your Rails application. 

Your application needs to be externally accessible for the APIs to successfully connect with it. For local development work [ngrok](https://ngrok.io) is a great option. Make sure to provide your ngrok URL to the external API providers in their dashboards so they know where to find your application. Within the Nexmo dashboard you can provide both your `event` and `answer` webhook external URLs inside the settings for your Nexmo Voice application. (Note: As of Rails 6, you must whitelist external URLs in development that are not localhost, or disable the whitelist check completely. See this [StackOverflow post](https://stackoverflow.com/questions/53878453/upgraded-rails-to-6-getting-blocked-host-error) for more info and the note in this app's [development.rb](/config/environments/development.rb#9) initializer.)

## Contributing
We ❤️ contributions from everyone! [Bug reports](https://github.com/Nexmo/nexmo-vapi-sensibo-integration/issues), [bug fixes](https://github.com/Nexmo/nexmo-vapi-sensibo-integration/pulls) and feedback on the library is always appreciated. Look at the [Contributor Guidelines](https://github.com/Nexmo/nexmo-vapi-sensibo-integration/blob/master/CONTRIBUTING.md) for more information and please follow the [GitHub Flow](https://guides.github.com/introduction/flow/index.html).

## License
This project is under the [MIT LICENSE](https://github.com/Nexmo/nexmo-vapi-sensibo-integration/blob/master/LICENSE).
