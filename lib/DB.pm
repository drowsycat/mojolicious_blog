package DB;
use Mojo::Base 'Mojolicious::Controller';

use strict;
use warnings;
use DBIx::Simple;
use SQL::Abstract;

#----------------------------------------------
sub new{
#----------------------------------------------
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};

   bless($self, $class);
return $self;
}#-------------

my $db;
#-------------------------------------------------------
sub connect_db{
#-------------------------------------------------------
my($self, $ref_need_tables) = @_;
use DBI;
my $dbh;
my $table_live;

my %db_attr = (
#BEGIN##
host => 'localhost', #HOST
username => 'root', #USER
password => 'vangog',    #PASSW
database => 'myblog_git', #DBNAME
#END##
);

my($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn("DBI:mysql:$db_attr{'database'}:$db_attr{'host'}");
return unless scalar(split(/\:/, $driver_dsn)) >=2;

eval{
$dbh = DBI->connect( "DBI:mysql:$db_attr{'database'}:$db_attr{'host'}", $db_attr{'username'}, $db_attr{'password'} );
                      #or die "Can't connect: $DBI::errstr\n";
};
my $err = $DBI::errstr;
return ($dbh, $err) if $err;

$dbh->{'mysql_enable_utf8'} = 1;
$dbh->do("set names 'cp1251'");

#return $dbh;
$db = DBIx::Simple->connect($dbh);

# Перевіряємо наявність усіх необхідних таблиць
#my @need_tables = @{$self->top_config->{'need_tables_adm'}};
foreach(@$ref_need_tables){
    my($table_live) = $db->query(qq[SHOW TABLES LIKE "$_"])->list;
    if(!$table_live){
        $self->create_db_structure($_, $_);
    };
}

return DBIx::Simple->connect($dbh);
} #-------------

#----------------------------------
sub db {
#----------------------------------
    return $db if $db;
    #croak "You should init model first!";
}#----------

#-------------------------------------
sub create_db_structure{
#-------------------------------------
my $self = shift;
my($action, $tab_name);

if(@_){ ($action, $tab_name) = @_; }

$self = {
    'user_passw' => sub{
                        eval{
                        __PACKAGE__->db->query(
                                        'CREATE TABLE user_passw(user VARCHAR(50) not null,
                                        password VARCHAR(50) not null,
                                        email VARCHAR(50) not null
                                        );'
                        );
                        };
                        return 1;
                       },
                       
    'illustrations' => sub{
                        eval{
                        __PACKAGE__->db->query(qq[create table illustrations(
                                        id INT(4) auto_increment,
                                        level VARCHAR(7) not null,
                                        level_id INT(4) not null,
                                        title_alias VARCHAR(100) not null, 
                                        page_id INT(5) not null, 
                                        path varchar(250) not null, 
                                        file varchar(100) not null, 
                                        INDEX page_id_index(page_id),
                                        PRIMARY KEY(id)
                                    );]
                                    );
                        };
                        return 1;
                       },
                       
    'documents' => sub{
                        __PACKAGE__->db->query(qq[create table documents(
                                        id INT(4) auto_increment,
                                        level VARCHAR(7) not null,
                                        level_id INT(4) not null,
                                        title_alias VARCHAR(100) not null, 
                                        page_id INT(5) not null, 
                                        path varchar(250) not null, 
                                        file varchar(100) not null, 
                                        INDEX page_id_index(page_id),
                                        PRIMARY KEY(id)
                                    );]
                                    );

                        return 1;
                       },
                       
    'media' => sub{
                        __PACKAGE__->db->query(qq[create table media(
                                        id INT(4) auto_increment,
                                        level VARCHAR(7) not null,
                                        level_id INT(4) not null,
                                        title_alias VARCHAR(100) not null, 
                                        page_id INT(5) not null, 
                                        path varchar(250) not null, 
                                        file varchar(100) not null, 
                                        INDEX page_id_index(page_id),
                                        PRIMARY KEY(id)
                                    );]
                                    );

                        return 1;
                       },
                       
        'user' => sub{
                       __PACKAGE__->db->query(qq[create table user(
                                        id int(4) auto_increment, 
                                        curr_date datetime not null,  
                                        login varchar(50) not null, 
                                        pass varchar(100) not null, 
                                        email varchar(100) not null,
                                        comment_quant int(4),
                                        view_status varchar(4),
                                        newsletter varchar(4),
                                        edit_priority text,
                                        PRIMARY KEY(id)
                                    );]
                                    );

                        return 1;
                       },
                       
        'rubric' => sub{
                       __PACKAGE__->db->query(qq[create table rubric(
                                        id int(3) auto_increment, 
                                        rubric varchar(254) not null,
                                        PRIMARY KEY(id)
                                    );]
                                    );

                        return 1;
                       },        
                       
    'comments_artcl' => sub{
                        __PACKAGE__->db->query(qq[create table $tab_name(
                                        id INT(4) auto_increment,
                                        curr_date DATETIME not null,
                                        parent_id INT(4),
                                        level INT(4),
                                        menu_level VARCHAR(10) not null,
                                        nickname VARCHAR(100) not null,
                                        name VARCHAR(100) not null,
                                        table_name VARCHAR(100) not null,
                                        page_id INT(4) not null, 
                                        url VARCHAR(250) not null,
                                        comment TEXT, 
                                        press_indicat VARCHAR(3),
                                        INDEX columnindex(page_id, table_name, level, nickname, parent_id, menu_level),
                                        PRIMARY KEY(id)
                                    );]
                                    );
                        return 1;
                       },
                       
    'search' => sub{
                        __PACKAGE__->db->query(qq[create table $tab_name(
                                        id INT(4) auto_increment,
                                        url VARCHAR(250) not null,
                                        table_name VARCHAR(250) not null,
                                        page_id INT(3) not null,
                                        head VARCHAR(250) not null,
                                        description VARCHAR(250) not null,
                                        search_text TEXT not null,
                                        FULLTEXT(head, description, search_text),
                                        PRIMARY KEY(id)
                                    );]
                                    );
                        return 1;
                       },
                       
    'archive_menu' => sub{
                        __PACKAGE__->db->query(qq[create table $tab_name(
                                        id INT(4) auto_increment,
                                        url VARCHAR(250) not null,
                                        menu TEXT not null,
                                        PRIMARY KEY(id)
                                    );]
                                    );
                        return 1;
                       },
                       
    'rss_setting' => sub{
                        __PACKAGE__->db->query(qq[create table $tab_name(
                                        title TINYTEXT not null,
                                        description TINYTEXT not null,
                                        list_number INT(2) not null
                                    );]
                                    );
                        return 1;
                       },
                       
    'rss_data' => sub{
                        __PACKAGE__->db->query(qq[create table $tab_name(
                                        curr_date DATETIME not null,
                                        level VARCHAR(7) not null,
                                        page_id INT(5) not null,
                                        table_name VARCHAR(255) not null,
                                        url VARCHAR(255) not null,
                                        description TEXT not null,
                                        category TINYTEXT not null,
                                        PRIMARY KEY(curr_date)
                                    );]
                                    );
                        return 1;
                       }
};
return $self->{$action}->();
}#-----------
1;