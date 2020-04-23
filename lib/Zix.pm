
package Zix;

use base Zix::Basement;
use Zix::Host;

use strict;
use warnings;
use Data::Dumper;

use utf8;
use Encode qw(decode encode);

use JSON::XS;





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
            params  => [],
            id      => 1,
            auth    => undef,
        }),
    );
}

=head2 host_get
    
    Get host info
    
    host_get -> {
        'Host name 1' => Zix::Host('Host name 1'),
        'Host name 2' => Zix::Host('Host name 2'),
        'Host name 3' => ...,
    }
    
    host_get('hostname') -> Zix::Host('hostname')
    
    my $h = host_get('hostname')
    warn 'hostid: '.$h->hostid;
    warn 'host: '.$h->host;
    
    
=cut
sub host_get {
    my $self     = shift;
    my $hostname = shift;
    
    my $hosts = $self->universal(
        'host.get'
    );
    
    my $hosts2;
    for my $h ( @$hosts ){
        
        for my $k (qw(
            home
            user
            password
            basic_user
            basic_password
            auth
        )){
            $h->{$k} = $self->{$k} if ( $self->{$k} );
        }
        
        if( $hostname && $h->{name} eq $hostname ){
            
            return new Zix::Host( %$h );
            
        }elsif( !$hostname ){
            
            $hosts2->{ $h->{name} } = new Zix::Host( %$h );
        }
    }
    
    $hosts2;
}





1;
