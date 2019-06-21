# Controller
package RPS::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::mysql;
use Data::Dumper;
use JSON;

## TODO: review handling of db at https://github.com/mojolicious/mojo/wiki/Hypnotoad-prefork-web-server#database-connection-problem-in-preforking

my $mysql = Mojo::mysql->strict_mode('mysql://root@localhost/rps') || die($!);
my $PLAYER_COMPUTER_DIST = 2;


sub now  {
    my ( $self ) = @_;

    # Manipulate session
    $self->session->{foo} = 'bar';
    my $foo = $self->session->{foo};
    #delete $self->session->{foo};

    # Expiration date in seconds from now (persists between requests)
    $self->session(expiration => 604800); # aprx 1 week

    #$self->session(key => "some value");
    #$self->render(text => 'hello world');
    #$self->render(json => $self->{mysql}->db->query('select now() as time')->hash);
    my $db = $mysql->db;
    $self->render(json => $db->query('select now() as time')->hash);
} ############################################

=head2 get_or_start_session()

# triggered by HTTP POST of username by web page 
  - returns existing session if is valid, otherwise
  creates a new session in the DB and populates the session id
  into the session object.

  returns a game state structure

=cut
sub get_or_start_session  
{
    my ( $self ) = @_;
    ## if cookie available or POSTed values,  try to recover session
          # Select one row at a time
    my $name  = $self->param('name'); # || undef; # $self->session->{name} || undef;
    my $email = $self->param('email');# || undef; # $self->session->{email}


    $name = $self->session->{name} if ( $self->session->{name} and not defined $name );
    $email = $self->session->{email} if ( $self->session->{email} and not defined $email );
    my $id = undef;

    #print qq{
    #name = $name
    #email = $email
    #};
    #print Dumper $self->param;


    my $game = undef;

    my $db = $mysql->db;
    if ( defined $name and defined $email ) ## try to retrieve session ID from DB
    {
        
        my $results = $db->query('SELECT * FROM user_sessions WHERE name=? AND email=?', $name, $email );
        if  (my $next = $results->hash) {
            #say $next->{name};
            $self->session->{name}  = $next->{name};
            $self->session->{email} = $next->{email};
            $self->session->{id}    = $next->{id};
            #$game = from_json( $next->{gamestate} );
            $game = $next->{gamestate};
            #print "game = $game\n";
            $id = $next->{id};
        }

    }

    ## if no session yet then use cookie or POST values to create one
    if ( not defined $id  && ( defined $name and defined $email ) ) 
    {
        ## set default starter game state
        $game = to_json( { 
                 window => [ 
                     qw/
                        RPS
                        RSP 
                        PRS 
                        PSR 
                        SPR 
                        SRP 
                        /
                ],
                player_index => 3,
                computer_choice => $self->get_computer_choice(),
                stats => {
                    player_wins          => 0,
                    computer_wins        => 0,
                    draws                => 0,
                    player_won_last_hand => 0,
                    level                => 0,
                    wins_this_level      => 0
                },
            })  || die($!);
         $id = $db->query('INSERT INTO user_sessions (name,email,gamestate ) VALUES (?,?,?)', $name, $email, $game )->last_insert_id;
            $self->session->{name}  = $name;
            $self->session->{email} = $email;
            $self->session->{id}    = $id;

    }

    #$self->session->{foo} = 'bar';
    #$self->session(expiration => 604800);
    #$self->render(json => $self->get_game_state() );
    return $game ; ## NB - this is JSON text

} ############################################


## ROUTES HANDLING


=head2 post_user_selection()

    receives a posted user move - applies this to the game state and updates,
    then returns new game state to player.

=cut
sub post_user_selection 
{
    my ( $self ) = @_;
} ############################################


=head2 transform_full_game_state_for_player()

    receives a posted user move - applies this to the game state and updates,
    then returns new game state to player.

=cut

sub transform_full_game_state_for_player
{
    my ( $self, $full_game_state ) = @_;

    say  'Full Game State = ' . Dumper $full_game_state;
    my $game = from_json($full_game_state );
    return  { as_text => $self->generate_simple_gamestate_as_html( $game ),
                player_wins => $game->{stats}{player_wins},
                computer_wins => $game->{stats}{computer_wins},
                level => $game->{stats}{level},
                level_wins => $game->{stats}{wins_this_level},
                name => $self->session->{name}
            };

    #return $full_game_state;
} ############################################



sub post_user_details 
{
    my ( $self ) = @_;

    ## returns the game state if successful otherwise return null
    #return undef;
    #say "Posted Name = " . $self->param('name');
    $self->render(json => $self->transform_full_game_state_for_player( $self->get_or_start_session() ) ); ## this will result in HTML game=null which should present the user form 

} ############################################

sub home 
{
    my ( $self ) = @_;
      #$log->info( 'Welcome' );
    #$self->render( json => $self->get_game_state() );
    $self->stash( initial_game => 'null');

    #say Dumper $self->session;
    ## if cookie include name and email then use those to get the initial game
    if ( defined $self->session->{name} && defined $self->session->{email} )
    {
        my $sn = $self->get_or_start_session();
        #say "it is : " . $sn;
        $self->stash( initial_game =>  to_json( $self->transform_full_game_state_for_player(  $sn ))  );
    }

    #$self->render(  );
} ############################################

#sub get_game_state
#{
#    my ( $self ) = @_;
#    #print Dumper $self->session->{session_id};
#    return $self->session;
#    return { history => ['RPS'],1=>2 };
#} ############################################



##################################################
###################### GAME MECHANICS ############
##################################################

=pod 
{
          'stats' => {
                       'player_wins' => 0,
                       'computer_wins' => 0,
                       'level' => 0,
                       'player_won_last_hand' => 0,
                       'draws' => 0,
                       'wins_this_level' => 0
                     },
          'computer_choice' => 0,
          'player_index' => 3,
          'window' => [
                        'RPS',
                        'RSP',
                        'PRS',
                        'PSR',
                        'SPR',
                        'SRP'

=cut

sub does_player_win
{
    my ( $self, $game, $player_selected ) = @_;
    
    my $player_scroll_index = $game->{player_index};
    
    my $computer_choice =  $game->{computer_choice};
    my $scroll  = $game->{window};


    my $ret = 0;
    my $description = '';

    ## returns 1 if the player beats the computer else returns 0
    #my $player_selected = substr( $scroll->[$player_scroll_index], $player_choice, 1); #   [];
    print "Player selected $player_selected\n";# if $DEBUG;
    my $computer_selected = substr( $scroll->[$player_scroll_index-$PLAYER_COMPUTER_DIST], $computer_choice, 1); #   [];
    print "Computer selected $computer_selected\n";# if $DEBUG;
    
    if ( $computer_selected eq $player_selected )
    {
        $description = 'Draw<br/><br/>';
        $ret = -1 ;
    }

    my $beats = {
        'R' => 'S',
        'P' => 'R',
        'S' => 'P'
    };
    my $beats_descriptions = {
        'R' => { 'S' => 'Rock Smashes Scissors' },
        'P' => { 'R' => 'Paper Wraps Rock'},
        'S' => { 'P' => 'Scissors Cut Paper' }
    };
    
    if ( $beats->{$player_selected} eq $computer_selected )
    {
        $description =  qq{<div style='color: green;'>Player Wins -  $beats_descriptions->{$player_selected}{$computer_selected} - Hands Scroll Up</div><br/>};
        $ret = 1 ;
    } 
    elsif ( $computer_selected ne $player_selected )  
    {
        $description =  qq{<div  style='color: red;'>Computer Wins  - $beats_descriptions->{$computer_selected}{$player_selected} - Hands Scroll Down</div><br/>};
        $ret = 0;
    }
    say $description;
    return ( $ret, $description );
} ############################################


sub save_player_game_state
{
    my ( $self, $game ) = @_;
    my $db = $mysql->db;
    say "Saving Game State:";
    say to_json($game);
    say 'name=' . $self->session->{name};
    say 'email=' . $self->session->{email};
    say 'id=' . $self->session->{id};
    $db->insert('user_sessions', {id => $self->session->{id}, 
                                    name => $self->session->{name}, 
                                  email => $self->session->{email}, 
                                  gamestate => to_json($game)
                                },
                                  {on_conflict => 'replace'});
   # $db->query('UPDATE user_sessions SET gamestate = ? WHERE name =? AND email = ? AND id = ? ) VALUES (?,?,?,?)', 
   #                  to_json($game), $self->session->{name}, $self->session->{email}, $self->session->{id} );


}

## Player posts choice of R|P|S
sub post_player_choice
{
    my ( $self ) = @_;
    
    say "GOT PLAYER CHOICE = " . $self->param('player_choice');
    my $game = from_json( $self->get_or_start_session() );  ## NB This is a 
    say  $game->{message};
    my $player_wins = -1;
     ( $player_wins, $game->{message} ) = $self->does_player_win( $game, $self->param('player_choice') );

    if ( $player_wins == 1 )
    {

        ( $game->{window}, $game->{player_index} ) = $self->shift_scrollwindow( $game->{window}, $game->{player_index}, 1 );
                #($scroll, $player1_scroll_index)   = handle_player_win($scroll, $player1_scroll_index) ;
        $game->{stats}{player_wins}++;
        $game->{stats}{wins_this_level}++;
        ## Next level if we've won 5
        if ( $game->{stats}{wins_this_level} ==5 )
        {
            $game->{stats}{wins_this_level} = 0;
            $game->{stats}{level}++;
        }


    } 
    elsif ( $player_wins == 0 )
    {
        ( $game->{window}, $game->{player_index} ) = $self->shift_scrollwindow( $game->{window}, $game->{player_index}, -1 );
                #($scroll, $player1_scroll_index)   = handle_player_win($scroll, $player1_scroll_index) ;
        $game->{stats}{computer_wins}++;
        $game->{stats}{wins_this_level}=0;


    } ## else == -1 == draw
    else 
    {
        $game->{stats}{draws}++;
    }

    $game->{computer_choice} = $self->get_computer_choice();
    $self->save_player_game_state( $game );



=pod
 

=cut









    $self->render(json => $self->transform_full_game_state_for_player( $self->get_or_start_session() ) ); 
}  

# nb count is the number of steps to shift down - so up is negative.
sub shift_scrollwindow  
{
    my ($self,  $scroll, $player1_scroll_index, $offset ) = @_;

    ## If the new index requires new elements at the beginning then insert them 
    while ( $player1_scroll_index + $offset - $PLAYER_COMPUTER_DIST < 0 ) 
    {
        $offset++;
        unshift @$scroll, generate_random_hand();
    }    
    die("Player has scrolled off the top of the list ($player1_scroll_index) - something has gone wrong") if $player1_scroll_index<0;
    $player1_scroll_index += $offset;
    ## If the new index requires new elements at the beginning then append them 
    while ( $player1_scroll_index >= @$scroll )
    {
         push @$scroll, generate_random_hand();
    }
    return (  $scroll, $player1_scroll_index );
} ############################################

sub get_computer_choice
{
    return int(rand(3)); 
} ############################################

sub button_hand
{
    my ( $self, $hand, $selected_idx ) = @_;
    $selected_idx = -9999999 unless (defined $selected_idx && $selected_idx =~ /\d/m);
    #print chr(0x270A) . "\n" . chr(0x270B) . "\n" . BOLD, WHITE, chr(0x2704) . "\n", RESET ; 
    my $hand_to_char = {
        'R' => q{<button onclick='post_player_choice("R")'>} . chr(0x270A) . q{</button>},
        'P' => q{<button onclick='post_player_choice("P")'>} . chr(0x270B) . q{</button>}, 
        'S' => q{<button onclick='post_player_choice("S")'>} . chr(0x2704) . q{</button>}, 
    };
    my $ret = ''; my $selected_ret = '';
    my $i = 0;
    foreach my $h ( split(//, $hand ))
    {
        $ret .= ' ' . $hand_to_char->{$h} . ' ';

        if ( $selected_idx == $i )
        {            
            $selected_ret .= ' '.  chr(0x1F447). ' ';
        }
        else 
        {
            $selected_ret .= ' O ';
        }
        $i++;         
    }

    if ( $selected_idx >= 0 )
    {
        return $selected_ret;
        return "$selected_ret    with $selected_idx";
    }
    return $ret;
    #return " $ret with $selected_idx";
} ############################################


sub color_hand 
{
    my ( $hand, $selected_idx ) = @_;
    $selected_idx = -9999999 unless (defined $selected_idx && $selected_idx =~ /\d/m);
    #print chr(0x270A) . "\n" . chr(0x270B) . "\n" . BOLD, WHITE, chr(0x2704) . "\n", RESET ; 
    my $hand_to_char = {
        'R' => chr(0x270A),
        'P' => chr(0x270B), 
        'S' => chr(0x2704)
    };
    my $ret = ''; my $selected_ret = '';
    my $i = 0;
    foreach my $h ( split(//, $hand ))
    {
        $ret .= ' ' . $hand_to_char->{$h} . ' ';

        if ( $selected_idx == $i )
        {            
            $selected_ret .= ' '.  chr(0x1F447). ' ';
        }
        else 
        {
            $selected_ret .= ' O ';
        }
        $i++;         
    }

    if ( $selected_idx >= 0 )
    {
        return $selected_ret;
        return "$selected_ret    with $selected_idx";
    }
    return $ret;
    #return " $ret with $selected_idx";
} ############################################

sub generate_simple_gamestate_as_html
{
    my ( $self, $game ) = @_;

    
    my $r = $game->{message} . '<table >'; ## return text  -- style="border-style: solid"
    my $scroll               = $game->{window};
    my $player1_scroll_index = $game->{player_index};
    my $computer_choice      = $game->{computer_choice};

    if ( $game->{stats}{level} == 0 )
    {
        $r .= '<tr><td>COMPUTER HAND:</td><td>' . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], $computer_choice ) . "</td></tr>\n";
        $r .= '<tr><td> </td><td>' . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ] ) .   "</td></tr>\n";
        $r .= '<tr><td>MIDDLE HAND:</td><td>' . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ] ) .  "</td></tr>\n";
        $r .=  '<tr><td>YOUR HAND:</td><td>' . $self->button_hand($scroll->[ $player1_scroll_index ] ).  "</td></tr></table>\n";
    }
    elsif ( $game->{stats}{level} == 1 )
    {
        $r .= "<tr><td>COMPUTER HAND: </td><td>" . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], $computer_choice ) . "</td></tr>\n";
        $r .= "<tr><td>       </td><td>        " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], 999 ) .  "</td></tr>\n";
        $r .= "<tr><td>MIDDLE HAND:</td><td>   " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ] ) .  "</td></tr>\n";
$r .=  '<tr><td>YOUR HAND:</td><td>' . $self->button_hand($scroll->[ $player1_scroll_index ] ).  "</td></tr></table>\n";
    }
    elsif ( $game->{stats}{level} == 2 )
    {
        $r .= "<tr><td>COMPUTER HAND:</td><td> " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], $computer_choice ) .  "</td></tr>\n";
        $r .= "<tr><td>               </td><td>" . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], 999 ) .  "</td></tr>\n";
        $r .= "<tr><td>MIDDLE HAND:  </td><td> " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ],999 ) .  "</td></tr>\n"; ## 999 offscreen - so no choice selected
        $r .=  '<tr><td>YOUR HAND:</td><td>' . $self->button_hand($scroll->[ $player1_scroll_index ] ).  "</td></tr></table>\n";
    }
    else 
    {
        $r = "You've won the entire game - Well Done You !!!\n";
    }
    

    return $r;

}############################################

sub generate_random_hand
{
    my $opts = [ qw/
        RPS
        RSP 
        PRS 
        PSR 
        SPR 
        SRP / ];
    return $opts->[   int(rand(5)) ];
} ############################################


1;
=pod

    my $c  = shift;
    my $db = $c->mysql->db;
    $c->render(json => $db->query('select now() as time')->hash);

DROP TABLE user_sessions;
CREATE TABLE user_sessions
(
    id SERIAL,
    expiry int DEFAULT -1,
    name varchar(80) DEFAULT '',
    email varchar(200) DEFAULT '',
    gamestate JSON DEFAULT NULL,
    PRIMARY KEY(id)
);

DROP TABLE user_sessions;
CREATE TABLE `user_sessions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `expiry` int(11) DEFAULT -1,
  `name` varchar(80)  NOT NULL  DEFAULT '',
  `email` varchar(200) NOT NULL DEFAULT '',
  `gamestate` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name_email` (`name`, `email`)
);


            { 
                 window => [ 
                     qw/
                        RPS
                        RSP 
                        PRS 
                        PSR 
                        SPR 
                        SRP 
                        /
                ],
                player_index => 3,
                computer_choice => $self->get_computer_choice(),
                stats => {
                    player_wins          => 0,
                    computer_wins        => 0,
                    draws                => 0,
                    player_won_last_hand => 0,
                    level                => 0,
                    wins_this_level      => 0
                },
            }

=cut