package PTA::Buffer;

sub new { bless { 'buffer' => { 'line' => 0, 'col' => 0 }} }

# here are the buffer access subroutines
sub inc_buffer {
    my($self) = @_;

    if ($self->{'buffer'}{'line'} > $#{$self->{'text'}}) {
	return undef;
    }
    
    $self->{'buffer'}{'col'}++;
    if ($self->{'buffer'}{'col'} >= length($self->{'text'}[$self->{'buffer'}{'line'}])) {
	$self->{'buffer'}{'col'} = 0;
	$self->{'buffer'}{'line'}++;
    }
}

sub dec_buffer {
    my($self) = @_;

    $self->{'buffer'}{'col'}--;
    if ($self->{'buffer'}{'col'} < 0) {
	$self->{'buffer'}{'line'}--;
	if ($self->{'buffer'}{'line'} < 0) {
	    $self->{'buffer'}{'line'} = $self->{'buffer'}{'col'} = 0;
	} else {
	    $self->{'buffer'}{'col'} = length($self->{'text'}[$self->{'buffer'}{'line'}]) - 1;
	}
    }
}

sub buffer_eof {
    my($self) = @_;

    return ($self->{'buffer'}{'line'} > $#{$self->{'text'}});
}

sub peek_buffer {
    my($self) = @_;

    return substr $self->{'text'}[$self->{'buffer'}{'line'}], $self->{'buffer'}{'col'}, 1;
}

sub pop_buffer {
    my($self) = @_;
    my($pop) = substr $self->{'text'}[$self->{'buffer'}{'line'}], $self->{'buffer'}{'col'}, 1;

    $self->inc_buffer;
    return $pop;
}

sub push_buffer {
    my($self, $count) = @_;
    my($x);

    $count || ($count = 1);

    for ($x = $count; $x > 0; $x--) {
	$self->dec_buffer;
    }

    return substr $self->{'text'}[$self->{'buffer'}{'line'}], $self->{'buffer'}{'col'}, 1;
}

1;
