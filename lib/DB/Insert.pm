package DB::Insert;
use base 'DB';
use Mojo::Base 'Mojolicious::Controller';

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
sub insert{
#----------------------------------------------
my $self = shift;
my $c = shift;
my($tab_name, $key);

if(@_){ ($tab_name, $key) = @_; }

$self = {
		'level0' => sub{
                        my $db = DB->db;
                        $db->abstract = SQL::Abstract->new;
                        #my $head = $c->lang_config->{'new_page_content'}->{$c->top_config->{'exist_langs'}}
                        #print "title \= ", $c->lang_config->{'new_page_content'}->{$c->top_config->{'exist_langs'}};
                        eval{
                        $db->insert($tab_name, {
                                                    level       => 'level0',
                                                    title       => $c->lang_config->{'labels'}->{$c->top_config->{'exist_langs'}}->{'main'},
                                                    title_alias => 'main',
                                                    parent_dir  => 'NULL',
                                                    url         => '/',
                                                    template    => 'article',
                                                    list_enable => 'no',
                                                    queue       => 0
                                                    });
                            
							   };
                            return;
                            },
                            
        'main' => sub{
                        my $db = DB->db;
                        $db->abstract = SQL::Abstract->new;
                        #my $head = $c->lang_config->{'new_page_content'}->{$c->top_config->{'exist_langs'}}
                        #print "title \= ", $c->lang_config->{'new_page_content'}->{$c->top_config->{'exist_langs'}};
                        eval{
                        $db->insert($tab_name, {
                                                    level       => 'level0',
                                                    level_id    => DB::Select->level_id('level0', 'main'),
                                                    rubric_id   => 0,
                                                    curr_date   => DB::Select->now_time,
                                                    head        => $c->lang_config->{'new_page_content'}->{$c->top_config->{'exist_langs'}},
                                                    announce    => $c->lang_config->{'new_page_content'}->{$c->top_config->{'exist_langs'}},
                                                    content     => $c->lang_config->{'new_page_content'}->{$c->top_config->{'exist_langs'}},
                                                    description => '',
                                                    keywords    => '',
                                                    author      => '',
                                                    template    => 'article',
                                                    comment_enable => 'no'
                                                    });
                            
							   };
                            return;
                            }
        };

return $self -> {$key} -> ($tab_name);
}#---------------
1;
