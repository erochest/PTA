package PTA::Parser;

use vars qw( @ISA );
use PTA::Buffer;

@ISA = qw( PTA::Buffer );

my(@open_tags);

sub new {
    my($self) = new PTA::Buffer;
    bless $self;
}

# various tools
sub copy_open_tags {
    my($self) = @_;
    my(@list) = ();
    my($item);

    foreach $item (@open_tags) {
	push @list, $item;
    }

    return @list;
}

# here are the various networks
sub start_tag {
    my($self, $gi, $attributes) = @_;
    my($count, $char, $temp) = (0, '', '');

    # state one: '<'
    unless ($self->peek_buffer eq '<') {
	return 0;
    }
    $char = $self->pop_buffer;
    $count++;

    # state two: term
    unless ($temp = $self->term($gi)) {
	$self->push_buffer($count);
	return 0;
    }
    $count += $temp;

    # state three: '>' (to state four) or attributes (to state three)
    while ($self->peek_buffer ne '>') {
	unless ($temp = $self->attribute($attributes)) {
	    $self->push_buffer($count);
	    return 0;
	}
    }
    $self->pop_buffer; # get rid of the >
    $count++;

    # state four
    return $count;
}

sub term {
    my($self, $term) = @_;
    my($char, $count, $temp) = ('', 0, '');

    # state one: an alphabetic character
    unless ($self->peek_buffer =~ /\w/) {
	return 0;
    }
    $char = $self->pop_buffer;
    $count++;

    # state two: an alpha-numeric character
    while ($self->peek_buffer =~ /\w|\d/) {
	$char .= $self->pop_buffer;
	$count++;
    }
    $$term = $char;
    return $count;
}

sub attribute {
    my($self, $attributes) = @_;
    my($char, $count, $temp) = ('', 0, 0);
    my($attr, $value) = ('', '');

    # state one: space
    unless ($temp = $self->space) {
	return 0;
    }
    $count += $temp;

    # state two: term
    unless ($temp = $self->term(\$attr)) {
	return 0;
    }
    $count += $temp;

    # state three: '='
    unless ($self->peek_buffer eq '=') {
	$self->push_buffer($count);
	return 0;
    }
    $self->pop_buffer;
    $count++;

    # state four: '"', a term, or a number
    if ($self->peek_buffer eq '"') {
	$self->pop_buffer;
	$count++;

	# state five: the value string
	while ($self->peek_buffer ne '"') {
	    $value .= $self->pop_buffer;
	    $count++;
	}

	# get rid of the '"', set up the parameter, and exit
	$self->pop_buffer;
	$count++;

	$attributes->{$attr} = $value;
	return $count;
    } elsif ($temp = $self->number(\$value)) {
	$attributes->{$attr} = $value;
	return $count + $temp;
    } elsif ($temp = $self->term(\$value)) {
	$attributes->{$attr} = $value;
	return $count + $temp;
    }

    # something's gone wrong in state four: bail out!
    $self->push_buffer($count);
    return 0;
}

sub end_tag {
    my($self, $gi) = @_;
    my($char, $count, $temp) = ('', 0, 0);

    # state one: '<'
    unless ($self->peek_buffer eq '<') {
	return 0;
    }
    $self->pop_buffer;
    $count++;

    # state two: '/'
    unless ($self->peek_buffer eq '/') {
	$self->push_buffer($count);
	return 0;
    }
    $self->pop_buffer;
    $count++;
    
    # state three: term
    unless ($temp = $self->term($gi)) {
	$self->push_buffer($count);
	return 0;
    }
    $count += $temp;

    # state three: '>'
    unless ($self->peek_buffer eq '>') {
	$self->push_buffer($count);
	return 0;
    }
    $self->pop_buffer;
    $count++;

    return $count;
}

sub entity {
    my($self, $entity) = @_;
    my($char, $count, $temp) = ('', 0, '');

    # state one: '&'
    unless ($self->peek_buffer eq '&') {
	return 0;
    }
    $self->pop_buffer;
    $count++;
    
    # state two: term
    unless ($temp = $self->term($entity)) {
	$self->push_buffer($count);
	return 0;
    }
    $count += $temp;

    # state three: ';'
    unless ($self->peek_buffer eq ';') {
	$self->push_buffer($count);
	return 0;
    }
    $self->pop_buffer;
    $count++;

    return $count;
}

sub word {
    my($self, $word) = @_;
    my($char, $count, $temp, $temp2, $entity) = ('', 0, '', '', '');

    # state one: entity or [a-zA-Z]
    if ($self->peek_buffer =~ /[a-zA-Z]/) {
	$char .= $self->pop_buffer;
	$count++;
    } elsif ($temp = $self->entity(\$entity)) {
	$char .= '&' . $entity . ';';
	$count += 2 + length($entity);
    } else {
	return 0;
    }

    # state two: entity or /[a-zA-Z]/
  WORDLOOP: while () {
      if ($self->peek_buffer =~ /[a-zA-Z]/) {
	  $char .= $self->pop_buffer;
	  $count++;
      } elsif ($temp = $self->entity(\$entity)) {
	  $char .= '&' . $entity . ';';
	  $count += $temp;
      # state three: contractions
      } elsif ($self->peek_buffer eq '\'') {
	  $temp = $self->pop_buffer;
	  if ($self->peek_buffer =~ /[a-zA-Z]/) {
	      $char .= $temp . $self->pop_buffer;
	      $count += 1 + 1;
	  } elsif ($temp2 = $self->entity(\$entity)) {
	      $char .= $temp . '&' . $entity . ';';
	      $count += 1 + $temp2;
	  } else {
	      $self->push_buffer;
	      last WORDLOOP;
	  }
      } else {
	  last WORDLOOP;
      }
  }

    # exit
    $$word = $char;
    return $count;
}

sub number {
    my($self, $number) = @_;
    my($char, $count, $temp) = ('', 0, '');

    # state one: \d
    unless ($self->peek_buffer =~ /\d/) {
	return 0;
    }
    $char .= $self->pop_buffer;
    $count++;

    # state two: \d or . (and another number)
  NUMBERLOOP: while () {
      if ($self->peek_buffer =~ /\d/) {
	  $char .= $self->pop_buffer;
	  $count++;
      } elsif ($self->peek_buffer eq '.') {
	  $temp = $self->pop_buffer;
	  # if the next character isn't a digit, we're through!
	  unless ($self->peek_buffer =~ /\d/) {
	      $self->push_buffer;
	      last NUMBERLOOP;
	  }
	  $char .= $temp;
	  $count++;
      } else {
	  last NUMBERLOOP;
      }
  }

    # exit
    $$number = $char;
    return $count;
}
	      
sub space {
    my($self) = @_;
    my($count) = (0);

    unless ($self->peek_buffer =~ /\s/) {
	return 0;
    }

    while ($self->peek_buffer =~ /\s/) {
	$self->pop_buffer;
	$count++;
    }

    return $count;
}

sub punctuation {
    my($self, $punct) = @_;

    if ($self->peek_buffer =~ /[\.,;:'""'?!&()\[\]{}-]/) {
	$$punct = $self->pop_buffer;
	return 1;
    } else {
	return 0;
    }
}

sub tagged_text {
    my($self, $text) = @_;
    my($char, $count, $temp) = ('', 0, '');
    my($gi, %attr, $gi_end, %tt, $word, $number, $punctuation);
    my(@list, @tag_list);
    my($line, $col);

    # state one: start tag
    unless ($temp = $self->start_tag(\$gi, \%attr)) {
	return 0;
    }
    $count += $temp;
    push @open_tags, {'gi' => $gi, 'attributes' => \%attr};

    # state two: endless everything
  TAGGED_TEXTLOOP: while () {
      # get me outta here
      if ($self->buffer_eof) {
	  last TAGGED_TEXTLOOP;
      }
      if ($temp = $self->end_tag(\$gi_end)) {
	  if ($gi eq $gi_end) {
	      $count += $temp;
	  } else {
	      $self->push_buffer($temp);
	  }
	  last TAGGED_TEXTLOOP;
      }

      # the main loop
      $line = $self->{'buffer'}{'line'};
      $col = $self->{'buffer'}{'col'};
      if ($temp = $self->tagged_text(\%tt)) {
	  $count += $temp;
      } elsif ($temp = $self->word(\$word)) {
	  @tag_list = $self->copy_open_tags;
	  push @list, {'word' => lc($word),
		       'line' => $line,
		       'col' => $col,
		       'tags' => \@tag_list};
	  $count += $temp;
      } elsif ($temp = $self->number(\$number)) {
	  @tag_list = $self->copy_open_tags;
	  push @list, {'word' => $number,
		       'line' => $line,
		       'col' => $col,
		       'tags' => \@tag_list};
	  $count += $temp;
      } elsif ($temp = $self->space) {
	  $count += $temp;
      } elsif ($temp = $self->punctuation(\$punctuation)) {
	  $count += $temp;
      } else {
	  $self->push_buffer($count);
	  return 0;
      }
  }

    # state three: outta here, babe
    push(@{$self->{'tags'}}, pop(@open_tags));
    push(@{$self->{'list'}}, @list);
    return $count;
}

1;
