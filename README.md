# :zap:ix

Yet:smiling_imp: another zabbix perl:camel: api engine ;)

# Examples

Make some constructor:
```perl
#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use lib 'lib';
use Zix;

my $z = new Zix(
    home     => 'https://domain.tld/zabbix',
    
    user     => 'Admin',
    password => '***password',
    
    #basic_user     => 'userlogin',
    #basic_password => '***password',
);

```

Then call api version. There is non auth :)
```perl
warn 'apiinfo.version: '.$z->apiinfo_version->{result};
```

Auth check wrapper
```perl

if( $z->is_auth ){
    
    # get all hosts
    my $hosts = $z->host_get;
    for my $h ( @$hosts ){
        warn 'hostid: '.$h->hostid;
        warn 'name: '.$h->host;
    }
    
    # get one host object
    my $h = $z->host_get('media');
    
    warn $h->hostid;
    warn Dumper($h->application);
    warn Dumper($h->item);
    warn Dumper($h->item(applicationids => 498));
    warn Dumper($h->hostgroup);
    warn Dumper($h->hostinterface);
    warn Dumper($h->template);
    
}

```

Use this universal method (theatrical pause) **->universal** :smiley: It's flexible:
```perl
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
```
