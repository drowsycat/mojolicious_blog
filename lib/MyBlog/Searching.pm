package MyBlog::Searching;
use Mojo::Base 'Mojolicious::Controller';
use MyBlog::RegExp;
use MyBlog::AuthorizeForm;
use MyBlog::SearchType;
use Templ1::RubricList;
use DB::Select;
use Mojo::Util qw(trim encode decode);

#---------------------------
sub search_artcl {
#---------------------------
my $self = shift;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
#my $templ = 'registration';
my $table_search = $self->top_config->{'table'}->{'search_artcl'};
my $table_archive_menu = $self->top_config->{'table'}->{'archive_menu'};
#my $redirect_to = $self->param('redirect_to');
my(%err_hash, $message, $search_frase, $search_frase_begin, $search_frase_begin_begin, $size, $search_result, $length);

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

#**********************************
if($self->param('search_frase')){
#**********************************
    $search_frase_begin = $search_frase = $self->param('search_frase');
    $search_frase_begin_begin = $search_frase_begin;
    $search_frase = MyBlog::RegExp->search_clean( trim($search_frase) );
    $size = scalar(split(/\s+/, $search_frase));
    $length = length $search_frase;
    
    # Якщо пошукова фраза має тільки одне слово
    #********************
    if($size ==1){
    #********************
        # Якщо слово має менше трьох літер
        if($length < 3){
            $search_result = [{'search_text' => $self->lang_config->{'not_enough_chars'}->{$language}}];
            goto EN;
        }
        $search_result = MyBlog::SearchType->one_word($self, $db, $search_frase);
        # Якщо результат пошуку відсутній, відстригаємо дві літери з кінця слова
        if( $search_result->[0]->{'search_text'} eq 'no'){
            #$search_frase = substr($search_frase_begin, 0, $length-2);
            $length = length $search_frase;
            if(length($search_frase) > 3){
                $search_frase = substr($search_frase, 0, $length-1);
            }
            elsif(length($search_frase) > 4){
                $search_frase = substr($search_frase, 0, $length-2);
            }
            $search_result = MyBlog::SearchType->one_word($self, $db, $search_frase);
        }
        # Якщо результат пошуку відсутній, відстригаємо одну літеру на початку слова
        if( $search_result->[0]->{'search_text'} eq 'no'){
            if(length($search_frase) > 3){
                $search_frase = substr($search_frase, 1);
            }
            $search_result = MyBlog::SearchType->one_word($self, $db, $search_frase);
        }
    }#**********
    # Якщо фраза має більше, ніж одну літеру
    else{
        # Якщо фраза має менше шести знаків
        if($length < 7){
            $search_result = [{'search_text' => $self->lang_config->{'not_enough_chars'}->{$language}}];
            goto EN;
        }
        $search_frase = MyBlog::SearchType->clean_frase($search_frase);
        $search_frase_begin = $search_frase;
        $search_result = MyBlog::SearchType->multy_word($self, $db, $search_frase);
            #$search_result = MyBlog::SearchType->multy_word_first($self, $db, $search_frase);
            #goto EN if($search_result->[0]->{'search_text'} ne 'no');
            #print "search_result \= ", $search_result->[0]->{'search_text'}, "\n";
        # Якщо результат пошуку відсутній, застосовуємо інший алгоритм
        #if( $search_result->[0]->{'search_text'} eq 'no'){
        #    $search_result = MyBlog::SearchType->multy_word($self, $db, $search_frase);
            #goto EN if($search_result->[0]->{'search_text'} ne 'no');
        #}
        # Якщо результат пошуку відсутній, переробляємо пошукову фразу
        if( $search_result->[0]->{'search_text'} eq 'no'){
            $search_frase = MyBlog::SearchType->modif_frase($search_frase);
            $search_result = MyBlog::SearchType->multy_word($self, $db, $search_frase);
            goto EN if($search_result->[0]->{'search_text'} ne 'no');
        }
        # Якщо результат пошуку відсутній, переробляємо пошукову фразу
        if( $search_result->[0]->{'search_text'} eq 'no'){
            $search_frase = MyBlog::SearchType->modif_frase_more($search_frase_begin);
            $search_result = MyBlog::SearchType->multy_word($self, $db, $search_frase);
            goto EN if($search_result->[0]->{'search_text'} ne 'no');
        }
        # Якщо результат пошуку відсутній, переробляємо пошукову фразу, змінивши порядок слів на зворотній
        if( $search_result->[0]->{'search_text'} eq 'no'){
            $search_frase = MyBlog::SearchType->reverse_frase($search_frase);
            $search_result = MyBlog::SearchType->multy_word($self, $db, $search_frase);
            goto EN if($search_result->[0]->{'search_text'} ne 'no');
        }
        # Якщо результат пошуку відсутній, шукаємо збіги по словах, що складають пошукову фразу
        if( $search_result->[0]->{'search_text'} eq 'no'){
            $size = 1;
            foreach(split(/ /, $search_frase_begin)){
                $length = length $_;
                if($length > 3){
                    # Відстригаємо одну літеру на початку слова для більшої вірогідності збігу
                    $search_frase = substr($_, 1);
                }
                $search_result = MyBlog::SearchType->one_word($self, $db, $search_frase);
                goto EN if($search_result->[0]->{'search_text'} ne 'no');
            }
        }
        # Якщо результат пошуку відсутній, шукаємо збіги по словах, що складають пошукову фразу
        if( $search_result->[0]->{'search_text'} eq 'no'){
            $size = 1;
            foreach(split(/ /, $search_frase_begin)){
                $length = length $_;
                $search_frase = $_;
                if($length > 3){
                    $search_frase = substr($_, 1);
                    $length = length $search_frase;
                    # Відстригаємо дві літери з кінця слова
                    $search_frase = substr($search_frase, 0, $length-2);
                }
                $search_result = MyBlog::SearchType->one_word($self, $db, $search_frase);
                goto EN if($search_result->[0]->{'search_text'} ne 'no');
            }
        }
        
    }#**********
}#***********
EN:
my($menu) = $db->select('level0', ['menu'], {'url' => '/'})->list;
$menu =~ s/\s+class\=\"active\"//;
$message = MyBlog::AuthorizeForm->authorize_form( $self, uc($template).'/search_artcl' );
my($archive_menu) = $db->select($table_archive_menu, ['menu'], {'url' => 'common'})->list;
my $ref_id_name_rubric = Templ1::RubricList->rubric_list($self);

$self->render(
template => uc($template).'/search_artcl',
language => $language,
menu => $menu,
archive_menu => $archive_menu,
#redirect_to => $redirect_to,
#search_frase => $search_frase.':'.$size, 
size => $size,
length => $length,
search_frase_begin => $search_frase_begin_begin,
#search_frase_begin => $search_frase,
search_frase => $search_frase, 
search_result => $search_result, 
message => $message,
title => $self->lang_config->{'labels'}->{$language}->{'search'}.' '.$self->param('search_frase'),
rubrics => $ref_id_name_rubric
);
}#-------------
1;