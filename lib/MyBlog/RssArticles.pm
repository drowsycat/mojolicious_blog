package MyBlog::RssArticles;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt);
use XML::RSS;
use DB::Select;
use Transliter;
use MyBlog::PubDate;

#---------------------------
sub rss_articles {
#---------------------------
my($app, $self) = @_;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
require $template.'/TitleAliasList.pm';
my $table_rss_setting = $self->top_config->{'table'}->{'rss_setting'};
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my(%date_Data_hash);

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my($title, $description, $list_number) = $db->select($table_rss_setting, ['title', 'description', 'list_number'])->list;

############# Формуємо файл RSS публікацій #####################################
# Якщо таблиця даних для RSS порожня
my @title_alias = @{TitleAliasList->title_alias_list($self)};
    
    foreach my $curr_table(@title_alias){

        my $result = $db->query(qq[ SELECT $curr_table.curr_date, $curr_table.level, 
                                           $curr_table.id, $curr_table.rubric_id, 
                                           $curr_table.head, $curr_table.announce, $curr_table.description, 
                                           $table_rubric.rubric FROM $curr_table, $table_rubric
                                           WHERE $curr_table.rubric_id = $table_rubric.id ]);
        while(my $data_rss = $result->hash){
            $data_rss->{'rubric'} = uc $data_rss->{'rubric'} if $data_rss->{'rubric'};
            my $literal_ident = Transliter->transliter($data_rss->{'head'});
            $literal_ident =~ s/\_/\-/g if($literal_ident =~ /\_/);
            my $url = $db->select( $data_rss->{'level'}, ['url'], {'title_alias' => "$curr_table"} )->list;
            $data_rss->{'url'} = $url.'/'.$data_rss->{'id'}.'/'.$literal_ident;
            $data_rss->{'url'} = "" if($url eq '/');
            $date_Data_hash{$data_rss->{'curr_date'}} = $data_rss;
        }
    }
    
my $rss = XML::RSS->new (version => '2.0');
 $rss->channel(title          => $title,
               link           => 'http://'.$self->req->headers->host,
               language       => $self->top_config->{'exist_langs'},
               description    => $description,
               #rating         => '(PICS-1.1 "http://www.classify.org/safesurf/" 1 r (SS~~000 1))',
               #copyright      => 'Copyright 1999, Freshmeat.net',
               #pubDate        => 'Thu, 23 Aug 1999 07:00:00 GMT',
               lastBuildDate  => MyBlog::PubDate->pub_date($self, DB::Select->now_time),
               #docs           => 'http://www.blahblah.org/fm.cdf',
               #managingEditor => 'scoop@freshmeat.net',
               webMaster      => $self->top_config->{'webMaster'}
               );

my $i = 0;
foreach(reverse sort keys %date_Data_hash){
$i++;
    last if $i > $list_number;
    
    $rss->add_item(title => $date_Data_hash{$_}->{'head'},
        # creates a guid field with permaLink=true
        #permaLink  => $date_Data_hash{$_}->{'url'},
        link  => 'http://'.$self->req->headers->host.$date_Data_hash{$_}->{'url'},
        # alternately creates a guid field with permaLink=false
        # guid     => "gtkeyboard-0.85"
        pubDate     => MyBlog::PubDate->pub_date($self, $date_Data_hash{$_}->{'curr_date'}),
        description => $date_Data_hash{$_}->{'announce'}
 );
}

$rss->save($self->top_config->{'rss_articles_path'});
}#-------------

#---------------------------
sub rss_comments {
#---------------------------
my($app, $self) = @_;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
require $template.'/TitleAliasList.pm';
my $table_rss_setting = $self->top_config->{'table'}->{'rss_setting'};
my $table_comments = $self->top_config->{'table'}->{'comments'};
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my(%date_Data_hash);

my $db = DB->db();
$db->abstract = SQL::Abstract->new;
my $db2 = $db;
$db2->abstract = SQL::Abstract->new;

my($title, $description, $list_number) = $db->select($table_rss_setting, ['title', 'description', 'list_number'])->list;

############# Формуємо файл RSS коментарів #####################################

        my $result = $db->select($table_comments, ['id', 'curr_date', 'page_id', 'table_name', 'url', 'comment'],
                                                  {'press_indicat' => 'yes'}, 'curr_date');
        while(my $data_rss = $result->hash){
            $data_rss->{'url'} = $data_rss->{'url'}.'#'.$data_rss->{'id'};
            #$data_rss->{'url'} = "" if($url eq '/');
            $data_rss->{'comment'} = (split(/\./, $data_rss->{'comment'}))[0];
            $data_rss->{'head'} = $db2->select($data_rss->{'table_name'}, ['head'], {'id' => $data_rss->{'page_id'}})->list;
            $date_Data_hash{$data_rss->{'curr_date'}} = $data_rss;
        }
    
my $rss = XML::RSS->new (version => '2.0');
 $rss->channel(title          => $title,
               link           => 'http://'.$self->req->headers->host,
               language       => $self->top_config->{'exist_langs'},
               description    => $description,
               #rating         => '(PICS-1.1 "http://www.classify.org/safesurf/" 1 r (SS~~000 1))',
               #copyright      => 'Copyright 1999, Freshmeat.net',
               #pubDate        => 'Thu, 23 Aug 1999 07:00:00 GMT',
               lastBuildDate  => MyBlog::PubDate->pub_date($self, DB::Select->now_time),
               #docs           => 'http://www.blahblah.org/fm.cdf',
               #managingEditor => 'scoop@freshmeat.net',
               webMaster      => $self->top_config->{'webMaster'}
               );

my $i = 0;
foreach(reverse sort keys %date_Data_hash){
$i++;
    last if $i > $list_number;
    $rss->add_item(title => $date_Data_hash{$_}->{'head'},
        # creates a guid field with permaLink=true
        #permaLink  => $date_Data_hash{$_}->{'url'},
        link  => 'http://'.$self->req->headers->host.$date_Data_hash{$_}->{'url'},
        # alternately creates a guid field with permaLink=false
        # guid     => "gtkeyboard-0.85"
        pubDate     => MyBlog::PubDate->pub_date($self, $date_Data_hash{$_}->{'curr_date'}),
        description => $date_Data_hash{$_}->{'comment'}
 );
}

$rss->save($self->top_config->{'rss_comments_path'});
}#-------------
1;