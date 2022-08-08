# Authorization Code Grant

Before starting, please read the about the OAuth Authorization Code Grant at
https://alexbilbie.com/guide-to-oauth-2-grants/#authorisation-code-grant-section-41 .
That page gives a very clear and practical explanation of the flow along with the details
needed to set it up.

The Authorization Code grant type should only be used in applications where you can
keep your *secret* private and you have an agent or web browser that can request permissions
for access to the Dryad web application from the user. You should *never* expose your
secret in user-readable code such as client-side javascript.

The basic flow the user sees:
1. They are directed to the Dryad application from an external application.
2. they must complete a login to Dryad if they're not already logged in.
3. They are asked to give permission for the external application to access their Dryad
   account if they haven't approved the access yet.
4. They are redirected back to a callback URL at the external application once completing these steps.

Before beginning, please obtain your client ID and secret for the dryad repository.  You will also
be asked for a redirect URL for your application which is a URL that is *called back* after an
Dryad authenticates the user and authorizes access by OAuth2.

## Example setup for a sample external application

This application is in Ruby and Rails, but the concepts will be very similar in many frameworks and
languages.  

1. Add `http.rb` to the Gemfile and run `bundle install` to make the gem (library) available.
2. Create a controller called `test_controller.rb` to the appropriate place.
3. Add these two routes to the `routes.rb` so that we can use two paths with that controller.
```ruby
  get 'test', to: 'test#index'
  match '/oauth/callback', to: 'test#callback', via: [:get, :post]
```
4. Create a very basic page with these contents in the file `index.html.erb` for the `test` views.
```html
<h1>Test page for oauth</h1>
<%= link_to 'Click to authorize Dryad access', TestController::OAUTH_URL %>
```
5. Create a very basic response page that shows that you are able to access the API with
   permissions for the User's account.  It is named `callback.html.erb` in the `test` views.
```html
<h1>Accessed the API for the following user</h1>

<p>user_id: <%= @user_id %></p>
<p>message: <%= @welcome_message %></p>
```
6. Most of the work happens inside the `test_controller.rb` which you created earlier. The
   contents look like this and will be explained below.
```ruby
require 'http'

class TestController < ApplicationController

    CLIENT_ID = '<fill-in-value-here>'
    CLIENT_SECRET = '<fill-in-value-here>'
    # change REDIRECT_URI if your settings are different and must match server/path configured when you
    # set up the key and secret with Dryad
    REDIRECT_URI = 'http://localhost:3000/oauth/callback'
    OAUTH_URL = "https://dryad-stg.cdlib.org/oauth/authorize?" \
        "client_id=#{ERB::Util.url_encode(CLIENT_ID)}" \
        "&redirect_uri=#{ERB::Util.url_encode(REDIRECT_URI)}" \
        "&response_type=code&scope=all"

    def index

    end

    def callback
      # make a request to get the access token
      resp = HTTP.post('https://dryad-stg.cdlib.org/oauth/token', 
                json: { client_id: CLIENT_ID,
                        client_secret: CLIENT_SECRET,
                        grant_type: 'authorization_code',
                        code: params[:code],
                        redirect_uri: REDIRECT_URI })
      
      token = resp.parse['access_token']

      # make a test request to the API using the access token
      resp = HTTP.headers('Authorization': "Bearer #{token}").get('https://dryad-stg.cdlib.org/api/v2/test')

      hash = resp.parse
      @welcome_message = hash['message']
      @user_id = hash['user_id']
    end
end
```

## Walkthrough of the example

1. Start the server so you have your web site running (in example, on `localhost:3000`).
2. Go to `http://localhost:3000/test`
3. Click the link `Click to authorize Dryad access`.
4. Go through log in process for Dryad.
5. Authorize Dryad access by clicking the `accept` button.
6. You are redirected back from Dryad to `http://localhost:3000/oauth/callback` which 
   is now able to obtain a `bearer token` based on the `code` returned to the callback and your other
   API information.
7. A test API call is made to Dryad using the `bearer token` that retrieves your user_id and
   name and displays the information on the page.

## Additional work for a real appplication

1. Add a `state` CSRF token when directing someone to the Dryad authorization server as explained
   at https://alexbilbie.com/guide-to-oauth-2-grants/#authorisation-code-grant-section-41 .
   Then check that the state matches the state in the user's session when it is returned to you
   callback URL. This help secure your application.
2. Handle the case when a user rejects the authorization request and no `code` is returned
   to your callback URL.
3. If you need to add additional keys and values to be passed through the authorization process
   then you can add them to your REDIRECT_URI, though storing in the session is easier and more
   secure if you're ok with the values being available to all tabs or browser windows the
   user may have open for your site.