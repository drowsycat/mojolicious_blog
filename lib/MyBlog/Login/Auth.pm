package MyBlog::Login::Auth;
use MyBlog::RegExp;
use DB::Select;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(trim);

#---------------------------
sub registration {
#---------------------------
my $self = shift;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
my $templ = 'registration';
my $table = $self->top_config->{'table'}->{'users'};
my $redirect_to = $self->param('redirect_to');
my(%err_hash, $message);

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

# Масив полів форми, що обов'язково мають бути заповнені
my $registration_required_fields = $self->top_config->{'adm'}->{'registration_required_fields'}->{$template};

if($self->param('register')){
    %err_hash = $self->serve->err_hash_fields($self, $registration_required_fields);
    
    my $login = MyBlog::RegExp->name_clean( trim($self->param('login')) );
    my $password = MyBlog::RegExp->name_clean( trim($self->param('pass')) );
    my $email = MyBlog::RegExp->name_clean( trim($self->param('email')) );
    
    #my $param_val = $self->req->params->to_hash;
    if( $login && $password && $email ){
    # Перевіряємо чи немає серед зареєстрованих з введеними login або email
    my @where = ( {login => "$login"}, {email => "$email"} );
    my($exist_login_email_check) = $db->select( $table, ['id'], \@where )->list;

    # Попередження про те, що такий логін або пароль вже існує в БД
    $message = $self->lang_config->{'alert'}->{$language}->{'existing_login_or_passw'} if $exist_login_email_check;
    
    if(!$message){
        $db->insert($table, {
                             'curr_date' => DB::Select->now_time,
                             'login' => "$login",
                             'pass' => "$password",
                             'email' => "$email",
                             'comment_quant' => 0,
                             'view_status' => 'yes',
                             'newsletter' => 'no',
                             'edit_priority' => ""
                            });
                    
    $self->redirect_to($redirect_to);
                    
    }
    }
    
}

foreach(@$registration_required_fields){
    # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
    # формується з назви поля з приєднаним '_err'
    $self->stash(template => $templ, $_.'_err' => $err_hash{$_});
}

$self->render(
templ => $templ,
language => $language,
redirect_to => $redirect_to,
message => $message,
title => $self->lang_config->{'labels'}->{$language}->{'registration'}
);
}#-------------
1;