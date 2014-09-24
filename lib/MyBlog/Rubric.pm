package MyBlog::Rubric;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(trim);
use MyBlog::RegExp;
use Transliter;

#---------------------------------
sub add_rubric {
#---------------------------------
my $self = shift;

my(%err_hash, @rubric_list, $message);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->top_config->{'routine'};
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my $db = DB->db();

my $table = $self->param('title_alias');
my $id    = $self->param('id');
my($level, $level_id, $head) = $db->select($table, ['level', 'level_id', 'head'], {id => "$id"})->list;

# Масив полів форми, що обов'язково мають бути заповнені
my $add_rubric_required_fields = $self->top_config->{'add_rubric_required_fields'};
if( $self->param('add_rubric') ){
    %err_hash = $self->serve->err_hash_fields($self, $add_rubric_required_fields);
}
foreach(@$add_rubric_required_fields){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash($_.'_err' => $err_hash{$_});
    }
    
if( $self->param('add_rubric') && scalar(keys %err_hash) <= 0 ){
    $db->abstract = SQL::Abstract->new;
    my $rubric = MyBlog::RegExp->name_clean( trim($self->param('rubric')) );
    
    my($indicr) = $db->select($table_rubric, ['rubric'], { rubric => "$rubric" })->list;
    # Якшо вже існує така рубрика, виводимо попередження $message
    if($indicr){
        $message = "<b style=\"color:red\">".$self->lang_config->{'alert'}->{$language}->{'rubric_exist'}."</b>\n";
        goto EN;
    }    
    $db->insert( $table_rubric, {rubric => "$rubric"} );
}

EN:
# Дістаємо список наявних рубрик @rubric_list
my $result = $db->select( $table_rubric, ['rubric'], {}, 'id' );
    while( my($rubr_item) = $result->list ){
        push @rubric_list, $rubr_item;
    }

$self->render(
language => $language,
message => $message,
title_alias => $table,
head => $head,
id => $id,
rubric_list => [@rubric_list],
redirect_to => $self->param('redirect_to'),
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->lang_config->{'labels'}->{$language}->{'add_rubric'}
);
}#------------

#---------------------------------
sub edit_rubric {
#---------------------------------
my $self = shift;

my( %err_hash, @rubric_list, @edit_rubric_required_fields, 
    $edit_rubric_required_fields, $message, @rubrics);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->top_config->{'routine'};
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my $db = DB->db();

my $table = $self->param('title_alias');
my $id    = $self->param('id');
my($level, $level_id, $head) = $db->select($table, ['level', 'level_id', 'head'], {id => "$id"})->list;

# Дістаємо список наявних рубрик @rubric_list
my $rubric_ref = $db->select( $table_rubric, ['*'], {}, 'id' )->hashes;
foreach(@$rubric_ref){
    push @edit_rubric_required_fields, 'rubric_'."$_->{'id'}";
}
# Масив полів форми, що обов'язково мають бути заповнені
$edit_rubric_required_fields = [@edit_rubric_required_fields];

if( $self->param('edit_rubric') ){
    %err_hash = $self->serve->err_hash_fields($self, $edit_rubric_required_fields);
}

foreach(@$edit_rubric_required_fields){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash( $_ => $err_hash{$_} );
    }
    
if( $self->param('edit_rubric') && scalar(keys %err_hash) <= 0 ){
    
    foreach($self->param()){
        push @rubrics, (split(/\_/, $_))[-1].'|'.MyBlog::RegExp->name_clean( trim($self->param($_)) ) if($_ =~ /^rubric_/);
    }
$db->abstract = SQL::Abstract->new;
foreach(@rubrics){
    my($id_rubric, $val_rubric) = split(/\|/, $_);
    $db->update($table_rubric, { rubric => "$val_rubric" }, {id => "$id_rubric"});
}
$rubric_ref = $db->select( $table_rubric, ['*'], {}, 'id' )->hashes;
}

$self->render(
language => $language,
message => $message,
title_alias => $table,
head => $head,
id => $id,
rubric_ref => $rubric_ref,
err_hash => {%err_hash},
redirect_to => $self->param('redirect_to'),
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->lang_config->{'labels'}->{$language}->{'edit_rubric'}
);
}#------------
1;