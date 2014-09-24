package MyBlog::SearchType;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(trim encode decode);
use strict;
use warnings;

#---------------------------
sub one_word {
#---------------------------
my($self, $c, $db, $arg) = @_;
my $language = $c->top_config->{'exist_langs'};
my $table_search = $c->top_config->{'table'}->{'search_artcl'};
$arg = lc $arg;

my $result = $db->query(qq[SELECT * FROM $table_search WHERE search_text LIKE "%$arg%" 
                           OR search_text LIKE "$arg%"
                           OR search_text LIKE "%$arg" LIMIT 50])->hashes;

if(!$result->[0]->{'search_text'}){
    #return [{'search_text' => $c->lang_config->{'no_search_result'}->{$language}}];
    return [{'search_text' => 'no'}];
}

return $result;
}#-------------

#---------------------------
sub multy_word_first {
#---------------------------
my($self, $c, $db, $arg) = @_;
my $language = $c->top_config->{'exist_langs'};
my $table_search = $c->top_config->{'table'}->{'search_artcl'};
$arg = lc $arg;

#my $result = $db->query(qq[SELECT * FROM $table_search WHERE search_text LIKE "$frase" LIMIT 50])->hashes;
my $result = $db->query(qq[SELECT * FROM $table_search 
                           WHERE MATCH (head, description, search_text) AGAINST ("$arg")])->hashes;

#print "SEARCH_RESULT \= ", $result->[0]->{'search_text'}, "\n";

if(!$result->[0]->{'search_text'}){
    #return [{'search_text' => $c->lang_config->{'no_search_result'}->{$language}}];
    return [{'search_text' => 'no'}];
}

return $result;
}#-------------

#---------------------------
sub multy_word {
#---------------------------
my($self, $c, $db, $arg) = @_;
my $language = $c->top_config->{'exist_langs'};
my $table_search = $c->top_config->{'table'}->{'search_artcl'};
$arg = lc $arg;

my @frase = split(/ /, $arg);
my $frase = '%'.join('%', @frase).'%';

my $result = $db->query(qq[SELECT * FROM $table_search WHERE search_text LIKE "$frase" LIMIT 50])->hashes;
#my $result = $db->query(qq[SELECT * FROM $table_search 
#                           WHERE MATCH (head, description, search_text) AGAINST ("$arg")])->hashes;

#print "SEARCH_RESULT \= ", $result->[0]->{'search_text'}, "\n";

if(!$result->[0]->{'search_text'}){
    #return [{'search_text' => $c->lang_config->{'no_search_result'}->{$language}}];
    return [{'search_text' => 'no'}];
}

return $result;
}#-------------

#---------------------------
sub modif_frase {
#---------------------------
my($self, $frase) = @_;

my @words = split(/ /, $frase);
my @words_copy = @words;
my $i = 0;
foreach(@words){
    if(length $_ > 3){
        $words_copy[$i] = substr($_, 0, -2);
    }
$i++;
}

return join(' ', @words_copy);
}#-------------

#---------------------------
sub modif_frase_more {
#---------------------------
my($self, $frase) = @_;

my @words = split(/ /, $frase);
my @words_copy = @words;
my $i = 0;
foreach(@words){
    if(length $_ > 3){
        $words_copy[$i] = substr($_, 1);
        $words_copy[$i] = substr($_, 0, -2);
    }
$i++;
}

return join(' ', @words_copy);
}#-------------

#---------------------------
sub clean_frase {
#---------------------------
my($self, $frase) = @_;

my @words = split(/ /, $frase);
my @words_copy = @words;

my $i = 0;
foreach(@words_copy){
    my $length = length $_;
    if(length $_ < 3){
        splice(@words, $i, 1);
        $i = $i - 1;
    }
$i++;
}
return join(' ', @words);
}#-------------

#---------------------------
sub reverse_frase {
#---------------------------
my($self, $frase) = @_;

my @words = split(/ /, $frase);

return join(' ', reverse @words);
}#-------------
1;