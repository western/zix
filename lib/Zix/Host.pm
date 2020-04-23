
package Zix::Host;

use base Zix::Basement;

use strict;
use warnings;
use Data::Dumper;


no strict 'refs';
for my $n (qw(hostid host )){
    *{"Zix::Host::${n}"} = sub{ shift->{$n} };
}
use strict 'refs';



sub application {
    my $self = shift;
    
    $self->universal(
        'application.get',
        
        hostids => $self->hostid,
    );
}

sub item {
    my $self = shift;
    my %arg = @_;
    
    $self->universal(
        'item.get',
        
        hostids => $self->hostid,
        $arg{applicationids} ? (applicationids => $arg{applicationids}) : (),
    );
}

sub hostgroup {
    my $self = shift;
    my %arg = @_;
    
    $self->universal(
        'hostgroup.get',
        
        hostids => $self->hostid,
    );
}

sub hostinterface {
    my $self = shift;
    my %arg = @_;
    
    $self->universal(
        'hostinterface.get',
        
        hostids => $self->hostid,
    );
}

sub template {
    my $self = shift;
    my %arg = @_;
    
    $self->universal(
        'template.get',
        
        hostids => $self->hostid,
    );
}



1;
