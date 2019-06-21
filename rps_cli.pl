#!/usr/bin/env perl


use Data::Dumper;
use strict;
use warnings;
use Term::ANSIScreen qw(cls);
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
binmode(STDOUT, ':utf8');
my $PLAYER_COMPUTER_DIST = 2; ## the number of indexes in $scroll that seperate computer and player.
my $DEBUG = 0;
my $CLS = cls();
my $LAST_OUTCOME = '';

#print chr(0x263a) . "\n";
#print BOLD, BLUE, chr(0x263a) , RESET;
#print BOLD, WHITE, chr(0x2700) . "\n" , RESET; ## SCISSORS
#print BOLD, RED, chr(0x270A) . "\n" , RESET; ## ROCK
#print BOLD, BLUE, chr(0x270B) . "\n" , RESET; ## PAPER
#print BOLD, RED, chr(0x270A) . "\n" , RESET; ## ROCK
#exit;
print chr(0x270A) . "\n" . chr(0x270B) . "\n" . BOLD, WHITE, chr(0x2704) . "\n", RESET ; 
print $CLS;
=pod
  
=cut

my $scroll = 
  [ qw/
        RPS
        RSP 
        PRS 
        PSR 
        SPR 
        SRP 
        /
  ]; ## conceptually the player holds a hand and the computer holds the hand $PLAYER_COMPUTER_DIST (2)  above
#print Dumper $scroll;
my $player1_scroll_index = 3;
my $player1_choice       = undef; ## NB 0..2
my $computer_choice      = undef;

my $stats = {
  player_wins          => 0,
  computer_wins        => 0,
  draws                => 0,
  player_won_last_hand => 0,
  level                => 0,
  wins_this_level      => 0,
  level_wincounts => { ## the required number of wins to progress to next level
      0 => 5, ## full disclosure of computer hand
      1 => 5, ## full disclosure of middle hand
      2 => 5, ## full disclosure of player hand only
  },
};
## NB - Computer scroll index will always = $player1_scroll_index - 2 at the beginning of any round


=pod

=head2 player_choice_wins( $player1_scroll_index, $player1_choice, $computer_choice, $scroll  )

Returns:
 1 if player wins
 0 if computer wins
 undef if draw

=cut
sub player_choice_wins
{
    my ( $player1_scroll_index, $player1_choice, $computer_choice, $scroll  ) = @_;
    ## returns 1 if the player beats the computer else returns 0
    my $player_selected = substr( $scroll->[$player1_scroll_index], $player1_choice, 1); #   [];
    print "Player selected $player_selected\n" if $DEBUG;
    my $computer_selected = substr( $scroll->[$player1_scroll_index-$PLAYER_COMPUTER_DIST], $computer_choice, 1); #   [];
    print "Computer selected $computer_selected\n" if $DEBUG;
    
    if ( $computer_selected eq $player_selected )
    {
        $LAST_OUTCOME = 'Draw';
        return undef ;
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
        $LAST_OUTCOME =  "Player Wins -  $beats_descriptions->{$player_selected}{$computer_selected} - Hands Scroll Up";
        return 1 ;
    } 
    else 
    {
        $LAST_OUTCOME =  "Computer Wins  - $beats_descriptions->{$computer_selected}{$player_selected} - Hands Scroll Down";
        return 0;
    }

    
}


sub render_debug
{
    my ( $player1_scroll_index, $scroll, $computer_choice  ) = @_;
    for ( my $i=0; $i<@$scroll; $i++ )
    {
        my $sep = '';
        $sep = '/' if $i == $player1_scroll_index - $PLAYER_COMPUTER_DIST;
        $sep = '|' if $i == $player1_scroll_index;
        print "$i> $sep $scroll->[$i] $sep\n";
    }

}

as

sub render_play_screen ## IE The hands
{
    my ( $player1_scroll_index, $scroll, $computer_choice  ) = @_;
    #$computer_choice = 1 unless defined $computer_choice; ## hacky - remove !
    ## render header with scores 
    render_debug( $player1_scroll_index, $scroll, $computer_choice  ) if $DEBUG;
    #print BOLD, BLUE, "O\n", RESET;
    #print BOLD, CYAN, "This text is in bold CYAN.\n", RESET;
    #print BOLD, RED, "This text is in bold RED.\n", RESET;
    #print "WINDOW  = @$scroll\nplayer index = $player1_scroll_index\n";
    #print qq{ Computer Hand = } . $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST  ] . "  where computer selects $computer_choice \n";
    #print "$computer_choice\n";
    if ( $stats->{level} == 0 )
    {
        print "COMPUTER HAND: " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], $computer_choice ), "\n";
        print "               " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ] ), "\n";
        print "MIDDLE HAND:   " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ] ), "\n";
    }
    elsif ( $stats->{level} == 1 )
    {
        print "COMPUTER HAND: " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], $computer_choice ), "\n";
        print "               " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], 999 ), "\n";
        print "MIDDLE HAND:   " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ] ), "\n";

    }
    elsif ( $stats->{level} == 2 )
    {
        print "COMPUTER HAND: " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], $computer_choice ), "\n";
        print "               " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], 999 ), "\n";
        print "MIDDLE HAND:   " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ],999 ), "\n"; ## 999 offscreen - so no choice selected
        
    }
    else 
    {
        print "You win !!!\n";
        exit;
    }

    #    print "COMPUTER HAND: " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST ], $computer_choice ), "\n";
    #print qq{  Middle Hand = } .  $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ] . "\n"; ## NB - closest to computer
    #    print "MIDDLE HAND:   " . color_hand( $scroll->[ $player1_scroll_index - $PLAYER_COMPUTER_DIST + 1 ] ), "\n";
    #print qq{  Player Hand = } . $scroll->[ $player1_scroll_index ] . "\n";
    print "YOUR HAND:     " . color_hand($scroll->[ $player1_scroll_index ] ), "\n";
}

sub get_player1_choice 
{
    my ( $hand ) = @_;
    ## returns 0 or 1 or 2

    #print "Use Keys (R)ock (P)aper (S)cissors or (H)elp or (Q)uit:  ";
    print "Use Keys (R)ock (P)aper (S)cissors or (Q)uit:  ";
    my $char;
    if ( 1==0 ) ## first block to just use standard input with CR
    {
        print "select index: ";
        $char = <STDIN>;
        chomp($char);
    }
    else 
    {
        ReadMode 4; # Turn off controls keys
        while  ( not defined ($char = ReadKey(-1)))
        {
            # no key yet
        }
        ReadMode 0; ## Reset tty mode
        exit if ( uc($char) eq 'Q');
       # help() if  ## NB screen resets so need to rework flow if want to do this here
    }


    
    ## if hand param provided  then allow user to enter P S R options. 
    if ( defined $hand )
    {
        my $i = 0;
        foreach my $opt ( split(//, $hand ) )
        {
            if ( uc($char)  eq $opt)
            {
                print "You selected $char which translates to $i\n" if $DEBUG;
                $char = $i;
            }
            
            $i++;
        }        
    }

    
    if ( $char =~ /^[0|1|2]$/)
    {
        return $char;
    }
    else 
    {
        warn "Setting Player default value of 1 as selection not valid ($char)\n";
        return 1;
    }

}

sub get_computer_choice
{
    return int(rand(3)); 
}

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
}

sub shift_scrollwindow  ## nb count is the number of steps to shift down - so up is negative.
{
    my ( $scroll, $player1_scroll_index, $offset ) = @_;

    ## If the new index requires new elements at the beginning then insert them 
    while ( $player1_scroll_index + $offset - $PLAYER_COMPUTER_DIST < 0 ) 
    {
        #my $t = $player1_scroll_index + $offset - $PLAYER_COMPUTER_DIST;
        #print "\t\t$player1_scroll_index + $offset - $PLAYER_COMPUTER_DIST = $t\n";
        $offset++;
        #$player1_scroll_index;
        unshift @$scroll, generate_random_hand();
        #print "head padding with offset=$offset\n";
        
    }
    
    die("Player has scrolled off the top of the list ($player1_scroll_index) - something has gone wrong") if $player1_scroll_index<0;

    $player1_scroll_index += $offset;

    ## If the new index requires new elements at the beginning then append them 
    while ( $player1_scroll_index >= @$scroll )
    {
         push @$scroll, generate_random_hand();

    }
    return (  $scroll, $player1_scroll_index );
}

=pod

my $stats = {
  player_wins          => 0,
  computer_wins        => 0,
  draws                => 0,
  player_won_last_hand => 0,
  level                => 0,
  wins_this_level      => 0,
  level_wincounts => { ## the required number of wins to progress to next level
      0 => 5, ## full disclosure of computer hand
      1 => 5, ## full disclosure of middle hand
      2 => 5, ## full disclosure of player hand only
  },
};

=cut
sub display_level_progress 
{
    ## If ncessary transition to next level
    if ( $stats->{level_wincounts}{ $stats->{level} } - $stats->{wins_this_level} <= 0 )
    {
        $stats->{level}++;
        $stats->{wins_this_level} = 0;
    }


    print $CLS;
    my $wins_needed = $stats->{level_wincounts}{ $stats->{level} } - $stats->{wins_this_level};
    print qq{
------------------------------------------
PLAYER WINS: $stats->{player_wins}\tDRAWS: $stats->{draws}\tCOMPUTER: $stats->{computer_wins}
------------------------------------------

        Level: $stats->{level}
        Consecutive Wins to Next Level: $wins_needed
\n};
print  BOLD, GREEN, $LAST_OUTCOME, RESET if ( $LAST_OUTCOME =~ /PLAYER/im);
print  BOLD, RED, $LAST_OUTCOME, RESET if ( $LAST_OUTCOME =~ /COMPUTER/im);
print "\n";




}
## MAIN 

#print generate_random_hand() . "\n";
#exit;

=pod
for ( my $i = -8; $i<5; $i++)
{
    $computer_choice = get_computer_choice();
    render_play_screen(  $player1_scroll_index, $scroll, $computer_choice );
    ( $scroll, $player1_scroll_index ) = shift_scrollwindow( $scroll, $player1_scroll_index, $i );
    
    $player1_choice = get_player1_choice();
}
exit;

=cut

while (1)
{

display_level_progress();

    $computer_choice = get_computer_choice();
    render_play_screen(  $player1_scroll_index, $scroll, $computer_choice );
    #exit;

    $player1_choice = get_player1_choice( $scroll->[$player1_scroll_index] );
    

    ## DETERMINE WINNER AND PROCESS IT 
    if ( my $res =player_choice_wins( $player1_scroll_index, $player1_choice, $computer_choice, $scroll ) )
    { ## PLAYER WINS
        #print qq{PLAYER WINS $res \n};
        
        ( $scroll, $player1_scroll_index ) = shift_scrollwindow( $scroll, $player1_scroll_index, 1 );
        #($scroll, $player1_scroll_index)   = handle_player_win($scroll, $player1_scroll_index) ;
        $stats->{player_wins}++;
        $stats->{wins_this_level}++;
    }
    else  ## Computer wins or draw
    {
        if (! defined $res )
        {
            print "Draw \n";
            $stats->{draws}++;
        } 
        else 
        {
            print "Computer Wins with result  = $res\n";
            $stats->{computer_wins}++;
            $stats->{wins_this_level} = 0;            
            ( $scroll, $player1_scroll_index ) = shift_scrollwindow( $scroll, $player1_scroll_index, -1 );
        }
    }
}


=pod


computer_scroll_index = player1_scroll_index - 2
computer_choice = 0
player1_choice = 2
winner_stats = {
  winner_stack = [0,1,1,0,1 ], ##
};
player_win_bias = 0; ## if 0 then the computer aims to mimic the average memory/random success as the player 

GAME FUNCTIONS 


=cut