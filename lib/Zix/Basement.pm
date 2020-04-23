
package Zix::Basement;

use strict;
use warnings;
use Data::Dumper;

use utf8;
use Encode qw(decode encode);

use LWP::UserAgent;
use JSON::XS;
use Encode qw(decode encode);
use Term::ANSIColor;



=head2 constructor
    
    my $z = new Zix(
        home     => 'https://domain.tld/zabbix',
        
        user     => 'Admin',
        password => '***password',
        
        #basic_user     => 'userlogin',
        #basic_password => '***password',
    );
    
=cut
sub new{
    my $c = shift;
    my $class = ref $c || $c;
    my %args = @_;
    
    my $self = {
        %args,
    };
    
    
    
    $self->{ua} = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0 },
    );
    $self->{ua}->agent('Zix/Great Perl/0.1');
    
    #$self->{db} = DBI->connect('dbi:Pg:dbname=zix;host=127.0.0.1', 'zix', 'zix') or die DBI->errstr;
    
    bless $self, $class;
}

=head2 make_request
    
    General income point for api.zabbix
    
    Return decode_json($res->content) for http success (code 200)
    
    Parameters 'from', 'method', 'url' are required. Other arguments attach to request.
    
    Examples:
    
    make_request(
        from   => 'checkToken',
        GET    => '/api/ver1.0/client/@me/client/',
        arg1   => 1,
        arg2   => 'second',
    )
    
    make_request(
        from   => 'initCallback',
        POST   => '/api/ver1.0/extension/' . $user_id . '/callback/',
        arg6   => 6,
        arg7   => 7,
        body   => encode_json({
            caller_id_name => 'RR is calling',
            src_num        => [$src],
            dst_num        => $dst,
        }),
    )
    
=cut
sub make_request {
    my $self = shift;
    my %arg = ( @_ );
    
    die 'api.zabbix.make_request: param "from" is required' unless ( $arg{from} );
    
    
    die 'api.zabbix.make_request require GET, POST or PUT url parameter' unless ( $arg{POST} || $arg{GET} || $arg{PUT} );
    my $method = $arg{GET} ? 'GET' : $arg{POST} ? 'POST' : 'PUT';
    my $url = $arg{GET} || $arg{POST} || $arg{PUT};
    
    
    my $args_str = '';
    if ( $method ne 'POST' ){
        
        while (my ($key, $value) = each %arg) {
            $args_str .= $key.'='.$value.'&' if ( !grep(/^$key$/, qw(from body content_type GET POST PUT)) );
        }
        $args_str = "?$args_str" if ($args_str);
    }
    
    
    
    my $stderr_pref = color('bold blue').$arg{from}.'->make_request: ' . $method . color('reset'). ' ' . $self->{home} . $url . $args_str;
    print STDERR $stderr_pref ."\n";
    
    
    
    my $req = HTTP::Request->new(
        $method => $self->{home} . $url . $args_str,
    );
    
    $req->authorization_basic($self->{basic_user}, $self->{basic_password}) if ($self->{basic_user});
    
    $arg{content_type} ? $req->content_type( $arg{content_type} ) : $req->content_type( 'application/json; charset=UTF-8' );
    
    
    if ($arg{body}){
        
        warn 'body: '.encode('UTF-8', $arg{body});
        $req->content($arg{body});
    }
    
    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
        
        return decode_json($res->content);
        
    } else {
        
        print STDERR color('bold red').$stderr_pref . ' status_line: ' . color('reset') . $res->status_line."\n";
        print STDERR color('bold red').$stderr_pref . ' content: ' . color('reset') . $res->content."\n";
        return 0;
    }
    
}




=head2 universal
    
    Make universal request with auth
    
    as example:
    
    $z->universal(
        'application.get',
        
        hostids => 10107,
    );
    
    $z->universal(
        'item.get',
        
        hostid => 10114,
    );
    
    $z->universal(
        'item.create',
        
        name         => $it.'['.$dev.']',
        key_         => $it.'['.$dev.']',
        hostid       => 10107,
        interfaceid  => 3,
        type         => 0,
        value_type   => 3, # 3 - numeric unsigned; 0 - numeric float;
        applications => [506],
        delay        => 30,
        delta        => 1, # 1 - Delta, speed per second; # 2 - Delta, simple change.
    );
    
    $z->universal(
        'host.create',
        
        host => 'host name 1',
        groups => [
            {
                groupid => 2,
            }
        ],
        interfaces => [
            {
                type  => 1,
                main  => 1,
                useip => 1,
                ip    => 'x.x.x.x',
                port  => 10050,
                dns   => '',
            }
        ],
        templates => [
            {
                templateid => 10001,
            }
        ],
    );
    
=cut
sub universal {
    my $self = shift;
    my $method = shift;
    my %arg = @_;
    
    my $res = $self->make_request(
        from => 'universal',
        POST => '/api_jsonrpc.php',
        body => JSON::XS->new->utf8(1)->encode({
            jsonrpc => 2.0,
            method  => $method,
            params  => {
                %arg
            },
            id   => 1,
            auth => $self->{auth},
        }),
    );
    
    warn 'error: '.Dumper($res->{error}) if( $res && $res->{error} );
    
    return $res->{result} if( $res && $res->{result} );
    
    $res;
}


1;
