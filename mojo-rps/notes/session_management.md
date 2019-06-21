# Discussion of approaches to setting the session 

The session identifies the user to the backend to allow tracking of their game state, name etc.
When the player first arrives they will not have a game state and so the front-end and back end need
to coordinate this.

Desired Functionality:
  - if a page is loaded and there is no session then assume this is the first visit to the game and
    create a new session id and backend stored game state associated with that user session.


## Consideration of the Front End
The page can handle some of the logic by checking whether a cookie is set. If it is not set then it can hide the game 
play components and present a login form which will be posted by the JS to set the cookie and obtain the game state.

function render_screen() 
{ /* called on page load and whenever there is an event that should result in screen redraw */

  if (  no_session_yet() )
  {
      document.getElementByID("game_state_section").style.display = "none";
      document.getElementByID("login_form_section").style.display = "block";

  } 
  else 
  {
      document.getElementByID("game_state_section").style.display = "block";
      document.getElementByID("login_form_section").style.display = "none";

  }
}

In Mojolicious there is no default session id set, though there are tools to manage session cookies etc that can be
included at a number of points in the request route handling flow.



Modules that may help:
    Mojolicious::Sessions:ThreeS


Candidate approaches to setting the user session:




Session cookie contains hashed values of the name and email. These can later be used to recover the session
in the event that the cookie is expired/deleted etc. NB - these are not secure credentials - anyone with the
name/email combination can retrieve and continue to play and update the backend storage for this session.

When the homepage is requested, the backend checks the cookie and if populated with name/email it then queries the 
database to retrieve the session game state. If the session does not exist in the database it will be created.

Where no cookie session is set in the browser, the home page html will solicit the name/email through a form and ajax post this to the backend where a new session will be created. If a backend session already exists with these values, then the session will load them.

To prevent multiple browsers 


## The Minimal Browser Game State Requirements

stats 
    level
    wins this level
    total player wins
    total computer wins
    
computer selection 
hands => [
    [ 'R', 'P', 'S' ], ## Computer hand
    [ 'R', 'P', 'S' ], ## Middle hand
    [ 'R', 'P', 'S' ], ## Player hand
]

