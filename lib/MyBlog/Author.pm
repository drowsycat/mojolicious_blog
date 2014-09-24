package MyBlog::Author;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt trim);
use MyBlog::RegExp;
use DB::Create;
use DB::Insert;
use DB::Select;

# This action will render a template
#---------------------------------
sub access {
#---------------------------------
my $self = shift;

my(%err_hash, $message);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->top_config->{'routine'};
my $table_attr  = $self->top_config->{'adm'}->{'table'}->{$template}->{'access'};
my $table = $table_attr->{'name'};
my $columns = $table_attr->{'columns'};
my $mess_prefix = $self->lang_config->{'labels'}->{$language}->{'wrong_configure_db'};
# Масив полів форми, що обов'язково мають бути заповнені
my $registration_required_fields = $self->top_config->{'adm'}->{'registration_required_fields'}->{$template};

my($db, $err) = DB->connect_db();

# Якщо є помилка, виводимо повідомлення про неправильне конфігурування БД для шаблону
$message = $mess_prefix.' '."<b style=\"color:red\">$err</b>" if($err);

if( $self->param('access') ){
    %err_hash = $self->serve->err_hash_fields($self, $registration_required_fields);
}
    foreach(@$registration_required_fields){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash($_.'_err' => $err_hash{$_});
    }
    
if( $self->param('access') && scalar(keys %err_hash) <= 0 ){
   $db->abstract = SQL::Abstract->new;
   
   my $login = MyBlog::RegExp->new->name_clean( trim($self->param('login')) );
   my $pass  = MyBlog::RegExp->new->name_clean( trim($self->param('pass')) );
   my($email, $error) = MyBlog::RegExp->new->email_clean( $self, trim($self->param('email')) );
   if( $error ){ $self->stash(email_err => 'Wrong symbols'); goto EN; };
   my @data = $db->select($table, '*')->list;
   if( @data ){
        $db->update($table, {$columns->[0] => $login, $columns->[1] => $pass, $columns->[2] => $email});
   }else{
        $db->insert($table, [$login, $pass, $email]);
   }
$self->redirect_to('admin');
}

#$self->redirect_to('dbaccess') unless $db;
EN:
$self->render(
language => $language,
message => $message,
title => $self->lang_config->{'labels'}->{$language}->{'access_admin_config'}
);
}#---------------

#---------------------------------
sub dbaccess {
#---------------------------------
my $self = shift;
use Cwd;
chdir cwd();
# Створюємо директорії, яких може не бути в 'git', але які є необхвдними
foreach(@{$self->top_config->{'need_ditectories'}}){
    mkdir($_, 0755);
}

my(%err_hash, $message, $host_name);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->top_config->{'routine'};
my $db_pack_file = 'lib/DB.pm';
# Масив полів форми, що обов'язково мають бути заповнені
my $dbaccess_required_fields = $self->top_config->{'adm'}->{'dbaccess_required_fields'}->{$template};

# Надсилається запит
if( $self->param('dbaccess') ){
    %err_hash = $self->serve->err_hash_fields($self, $dbaccess_required_fields);
}

    foreach(@$dbaccess_required_fields){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash($_.'_err' => $err_hash{$_});
    }

#**********************************
if( $self->param('dbaccess') && scalar(keys %err_hash) <= 0 ){
#**********************************

    $host_name   = trim($self->param('host'));
    my $username = trim($self->param('user'));
    my $pass     = trim($self->param('pass'));
    my $database = trim($self->param('dbname'));
    
my $phold=<<PH;

host => \'$host_name\', #HOST
username => \'$username\', #USER
password => \'$pass\',    #PASSW
database => \'$database\', #DBNAME
PH
    
    my $file = Mojo::Asset::File->new(path => $db_pack_file);
    my $connect_db_file = $file->slurp;

    $connect_db_file =~ /\#BEGIN\#\#([\w\W]+)\#END\#\#/;
    $connect_db_file =~ s/$1/$phold/;
    spurt $connect_db_file, $db_pack_file;
    
$self->redirect_to('/access');
}#***********

$self->render(
message => $message,
host_name => $host_name,
language => $language,
title => $self->lang_config->{'labels'}->{$language}->{'dbaccess_admin_config'}
);
}#---------------

#---------------------------------
sub admin {
#---------------------------------
my $self = shift;

my(%err_hash, $message, $db);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
require "$template.pm";
my $table_attr  = $self->top_config->{'adm'}->{'table'}->{$template}->{'access'};
#Таблиця 'user_passw' атрибутів достубу до консолі адміну
my $table_access = $table_attr->{'name'};
#Масив таблиць рівнів для даного шаблону
my @levels = @{$self->top_config->{$template}->{'levels'}};
push @levels, 'main';
# Масив полів форми, що обов'язково мають бути заповнені
my $admin_required_fields = $self->top_config->{'adm'}->{'admin_required_fields'}->{$template};
#$message = "";

# Надсилається запит
#*****************************
if( $self->param('enter') ){
#*****************************
    %err_hash = $self->serve->err_hash_fields($self, $admin_required_fields);
}#**********

    foreach(@$admin_required_fields){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash($_.'_err' => $err_hash{$_});
    }

#****************************************
if( $self->param('enter') && scalar(keys %err_hash) <= 0 ){
#****************************************
    $db = DB->db();
    $db->abstract = SQL::Abstract->new;
    my @data = $db->select($table_access, '*')->list;
    
    if( $data[0] eq trim($self->param('login')) && $data[1] eq trim($self->param('pass')) ){

    foreach(@{$self->top_config->{'need_tables_main'}}){
        my($table, $key) = split(/\-/, $_);
        my @data = $db->select($table, '*')->list;

        if( !@data ){
            #DB::Create->create_table($table, $key);
            DB::Insert->insert($self, $table, $table);
        }
    }
    $self->session(admin => $data[0]);
    $self->redirect_to('manager');
    }else{
        $message = $self->lang_config->{'alert'}->{$language}->{'invalid_login_or_passw'};
    }
    
    my $menu = $template->get_menu( $self, $self->serve->select_struct(\@{$self->top_config->{$template}->{'levels'}}) );
    print "\$menu \= $menu\n";
    $template->menu_rewrite( $self, $menu, [@{$self->top_config->{$template}->{'levels'}}] );

}#*************

# Масив назв таблиць рівнів
foreach( @levels ){#-------------
    # Перевіряємо наявність поточної таблиці рівня
    my($table_live) = DB::Select->like_table($_);
    # Створюємо таблицю рівня, якщо її немає
    if( !$table_live ){
            DB::Create->create_table($_, 'level');
        }
}#---------------------------------------------------------------------

$self->render(
message => $message,
language => $language,
title => $self->lang_config->{'labels'}->{$language}->{'admin_console'}
);
}#---------------
1;