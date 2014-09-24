package DB::Create;
use base 'DB';

use strict;
use warnings;

#----------------------------------------------
sub new{
#----------------------------------------------
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};

   bless($self, $class);
return $self;
}#-------------

#----------------------------------------------
sub create_table{
#----------------------------------------------
my $self = shift;
my($tab_name, $key);

if(@_){ ($tab_name, $key) = @_; }

$self = {
		'level' => sub{
                        eval{
                            DB->db->query(qq[create table $tab_name(
										   							level varchar(7),
                                          							id int(3) auto_increment,
																	parent_dir varchar(100) not null,
                                          							title varchar(100) not null,
                                                                    title_alias varchar(100) not null, 
                                          							url varchar(100) not null, 
                                          							template varchar(15) not null, 
                                          							description varchar(255), 
                                          							keywords varchar(255),
                                          							list_enable varchar(3),
                                                                    children VARCHAR(3),
																	queue int(3),
                                                                    menu TEXT,
                                                                    PRIMARY KEY(id)
                                                                    );]
                                            );
							   };
                            return;
                            },
                            
        'main' => sub{
                        eval{
                            DB->db->query(qq[create table  $tab_name(
                                        id int(3) auto_increment,
                                        level varchar(7) not null,
                                        level_id int(3) not null,
                                        rubric_id int(3), 
                                        curr_date datetime not null, 
                                        head varchar(250) not null, 
                                        lead_img varchar(250),
                                        announce mediumtext not null,  
                                        content TEXT,
                                        description varchar(255),
                                        keywords varchar(255),
                                        author varchar(100),
                                        template varchar(15) not null,
                                        comment_enable varchar(3),
                                        PRIMARY KEY(id)
                                        );]
                                        );

							   };
                            return;
                            }
        };

return $self->{$key}->($tab_name);
}#---------------
1;