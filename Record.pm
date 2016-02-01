package Record;
#地点(R)
#机构名称表征词(U)
#机构类型(T)
#名称后缀(S)
sub new
{
    my $class = shift;
    my $self = {
#	_id =>shift,
        _name => shift,
        _name_letter  => shift,
        u_py       => shift,
	t_py       => shift,
	s_py       => shift,
	p_py       => shift,
	_full_py_bigram	=> shift,
	_score		=>undef,
    };


    bless $self, $class;
    return $self;
}

sub getName {
	my( $self ) = @_;
	return $self->{_name};
}

sub setName {
	my ($self,$v) = @_ ;
	$self->{_name} = $v ;
}

sub getPinYinInitials {
	my( $self ) = @_;
	return $self->{_name_letter};
}

sub setPyinYinInitials {
	my ($self,$v) = @_ ;
	$self->{_name_letter} = $v ;
}

# R - location pinyin
sub getRPinyin {
	my( $self ) = @_;
	return $self->{p_py};
}

sub setRPinyin {
	my ($self,$v) = @_ ;
	$self->{p_py} = $v ;
}

#set U (Key) Pinyin
sub getUPinyin {
	my( $self ) = @_;
	return $self->{u_py};
}

sub setUPinyin {
	my ($self,$v) = @_ ;
	$self->{u_py} = $v  ;
}

#set T (Type) Pinyin
sub getTPinyin {
	my( $self ) = @_;
	return $self->{t_py} ;
}

sub setTPinyin {
	my ($self,$v) = @_ ;
	$self->{t_py} = $v ;
}

#set S (Suffix) Pinyin
sub getSPinyin {
	my( $self ) = @_;
	return $self->{s_py} ;
}

sub setSPinyin {
	my ($self,$v) = @_ ;
	$self->{s_py} = $v ;
}

sub setPinyinBigram {
	my ($self,$v) = @_ ;
	$self->{_full_py_bigram} = $v ;
}
sub getPinyinBigram {
	my( $self ) = @_;
	return $self->{_full_py_bigram};
}

sub setScore {
	my( $self ,$v) = @_;
	$self->{_score} = $v ;
}

sub getScore {
	my( $self ) = @_;
	return $self->{_score};
}
sub toString {
	my( $self ) = @_;
	my $str = "$self->{_name_letter},"."$self->{_full_py_bigram}"; 
	return "$str";
}

1;

