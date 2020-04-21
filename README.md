# zix
Zabbix api caller

# Synopsis
Yet another zabbix perl api engine ;)

# Examples

Make a some constructor:
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
```
