
package Zix;

use strict;
use warnings;
use Data::Dumper;

use utf8;
use Encode qw(decode encode);

use LWP::UserAgent;
#use DBI;
use JSON::XS;
#use DateTime;
#use File::Temp;
#use Encode qw(decode encode);
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
    
    Общая точка входа для создания запроса к api.zabbix.
    
    Возвращает decode_json($res->content) если HTTP запрос успешен (code 200)
    В случае ошибки напишет в STDERR + вернет 0
    
    Параметры from, method, url являются обязательными, все остальные параметры
    будут добавлены в запрос
    
    Примеры:
    
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


=head2 is_auth
    
    Method for request auth key.
    This key use for all next requests.
    
=cut
sub is_auth {
    my $self = shift;
    
    my $res = $self->make_request(
        from => 'is_auth',
        POST => '/api_jsonrpc.php',
        body => JSON::XS->new->utf8(1)->encode({
            jsonrpc => 2.0,
            method  => 'user.login',
            params  => {
                user     => $self->{user},
                password => $self->{password},
            },
            id   => 1,
            auth => undef,
        }),
    );
    
    
    print STDERR color('bold red') . 'error: ' . color('reset') . Dumper($res) if ( $res && $res->{error} );
    
    $self->{auth} = $res->{result} if ( $res && $res->{result} );
    
    $res;
}

=head2 apiinfo_version
    
    Get api version
    
=cut
sub apiinfo_version {
    my $self = shift;
    
    $self->make_request(
        from => 'apiinfo_version',
        POST => '/api_jsonrpc.php',
        body => JSON::XS->new->utf8(1)->encode({
            jsonrpc => 2.0,
            method  => 'apiinfo.version',
            params => [],
            id   => 1,
            auth => undef,
        }),
    );
}

=head2 host_get
    
    Get host info
    
=cut
sub host_get {
    my $self = shift;
    
    $self->make_request(
        from => 'host_get',
        POST => '/api_jsonrpc.php',
        body => JSON::XS->new->utf8(1)->encode({
            jsonrpc => 2.0,
            method  => 'host.get',
            params  => {
                output => [
                    'hostid',
                    'host',
                    'interfaces',
                    'groups',
                    'templates',
                ],
                selectInterfaces => [
                    'interfaceid',
                    'ip',
                    'type',
                    'main',
                    'port',
                    'userip',
                ],
            },
            id   => 1,
            auth => $self->{auth},
        }),
    );
}

=head2 host_create
    
    Get host create
    
=cut
sub host_create {
    my $self = shift;
    my %arg = @_;
    
    $self->make_request(
        from => 'host_create',
        POST => '/api_jsonrpc.php',
        body => JSON::XS->new->utf8(1)->encode({
            jsonrpc => 2.0,
            method  => 'host.create',
            params  => {
                %arg
            },
            id   => 1,
            auth => $self->{auth},
        }),
    );
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
                type => 1,
                main => 1,
                useip => 1,
                ip => 'x.x.x.x',
                port => 10050,
                dns => '',
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
