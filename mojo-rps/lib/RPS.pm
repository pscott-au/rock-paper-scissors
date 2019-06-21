package RPS;
use Mojo::Base 'Mojolicious';

#use Mojolicious::Plugin::OAuth2;
#use Mojolicious::Plugin::OpenAPI;
#use MojoX::JSON::RPC::Service;
#use JSON::RPC2::Server;
use Data::Dump qw/pp/;



sub startup 
{
    my ( $self ) = @_;
    #$self->{mysql} = Mojo::mysql->strict_mode('mysql://root@localhost/rps');
    #app->plugin('Config');
    my $config = $self->plugin('Config');
    say pp $config;# ->{foo};
    $self->sessions->cookie_name('rockpaperscissor');
    $self->app->secrets(['Mrockpaperscissorfdsfdsrrockpaperscissorsrockpaperscissor']); ## NB this prolly clobbers config.
#app->start;

#$self->helper(  mysql => sub { state $mysql = Mojo::mysql->strict_mode('mysql://root@localhost/rps') } );


  ## If user hasn't entered their name then assume no session and force user to
  ## the page with form to enter their name.


  # Router
  my $r = $self->routes;

  ## ensure that the player has a session - get player name if none
  ##  $r->under('/' => sub{
  ##  });
    #$r->get('/now')->to(controller => 'Game', action => 'now' );
    $r->get('/')->to('game#home' );
    $r->get('/now')->to('game#now' );
    $r->post('/post_user_details')->to('game#post_user_details');
    $r->post('/post_player_choice')->to('game#post_player_choice');

};



1;


